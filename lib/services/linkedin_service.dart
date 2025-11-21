import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// LinkedIn API Service
/// Handles OAuth authentication and posting to LinkedIn
class LinkedInService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // LinkedIn OAuth endpoints
  static const String _authorizationUrl =
      'https://www.linkedin.com/oauth/v2/authorization';
  static const String _tokenUrl =
      'https://www.linkedin.com/oauth/v2/accessToken';
  static const String _apiBaseUrl = 'https://api.linkedin.com/v2';

  // Note: These should be stored in environment variables or Firebase config
  // For now, using placeholder values that need to be configured
  static const String _clientId = 'YOUR_LINKEDIN_CLIENT_ID';
  static const String _clientSecret = 'YOUR_LINKEDIN_CLIENT_SECRET';
  static const String _redirectUri =
      'https://fbla-conference-app.firebaseapp.com/linkedin/callback.html';

  // Scopes needed for posting and retrieving the member ID
  // w_member_social: allows posting to LinkedIn (Share on LinkedIn product)
  // openid/profile/email: OpenID Connect info
  // r_liteprofile: gives numeric member ID via /me endpoint
  static const String _scopes =
      'w_member_social openid profile email r_basicprofile';

  /// Check if LinkedIn is connected for the current user/school
  Future<bool> isConnected({String? schoolId}) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final doc = await _getLinkedInDoc(userId, schoolId);
      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>?;
      final accessToken = data?['accessToken'] as String?;

      // Just check if token exists - don't verify it here (that will happen when posting)
      // This avoids unnecessary API calls and potential failures
      return accessToken != null && accessToken.isNotEmpty;
    } catch (e) {
      print('Error checking LinkedIn connection: $e');
      return false;
    }
  }

  /// Get LinkedIn connection status
  Future<Map<String, dynamic>?> getConnectionStatus({String? schoolId}) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return null;

      final doc = await _getLinkedInDoc(userId, schoolId);
      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>?;
      return {
        'connected': data?['accessToken'] != null,
        'username': data?['username'],
        'connectedAt': data?['connectedAt'],
        'autoPost': data?['autoPost'] ?? false,
      };
    } catch (e) {
      print('Error getting LinkedIn status: $e');
      return null;
    }
  }

  /// Initiate LinkedIn OAuth flow
  /// Returns the authorization URL to open in browser
  String getAuthorizationUrl() {
    final state = DateTime.now().millisecondsSinceEpoch.toString();

    final params = {
      'response_type': 'code',
      'client_id': _clientId,
      'redirect_uri': _redirectUri,
      'state': state,
      'scope': _scopes,
    };

    final uri = Uri.parse(_authorizationUrl).replace(queryParameters: params);
    return uri.toString();
  }

  /// Handle OAuth callback and exchange code for access token
  Future<bool> handleOAuthCallback(String code, {String? schoolId}) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      // Exchange authorization code for access token
      final tokenResponse = await http.post(
        Uri.parse(_tokenUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': _redirectUri,
          'client_id': _clientId,
          'client_secret': _clientSecret,
        },
      );

      if (tokenResponse.statusCode != 200) {
        print('Token exchange failed: ${tokenResponse.body}');
        return false;
      }

      final tokenData = json.decode(tokenResponse.body);
      final accessToken = tokenData['access_token'] as String;
      final expiresIn = tokenData['expires_in'] as int?;
      final refreshToken = tokenData['refresh_token'] as String?;

      // Try to get person URN from token response (if available)
      String? personUrn;
      String username = 'LinkedIn User';

      // First, check if token response itself contains member ID
      // Sometimes LinkedIn includes it in the token response
      if (tokenData.containsKey('linkedin_member_id')) {
        final memberId = tokenData['linkedin_member_id'] as String;
        personUrn = 'urn:li:member:$memberId';
        print('Got member ID from token response: $personUrn');
      }

      // Check if token response contains user info via ID token
      if ((personUrn == null || personUrn.isEmpty) &&
          tokenData.containsKey('id_token')) {
        // If using OpenID Connect, decode the ID token
        try {
          // ID token is a JWT, we can decode it to get user info
          final idToken = tokenData['id_token'] as String;
          final parts = idToken.split('.');
          if (parts.length >= 2) {
            // Decode the payload (base64)
            final payload = parts[1];
            // Add padding if needed
            String normalizedPayload = payload;
            switch (payload.length % 4) {
              case 1:
                normalizedPayload += '===';
                break;
              case 2:
                normalizedPayload += '==';
                break;
              case 3:
                normalizedPayload += '=';
                break;
            }
            final decoded = utf8.decode(base64.decode(normalizedPayload));
            final idTokenData = json.decode(decoded) as Map<String, dynamic>;

            if (idTokenData.containsKey('sub')) {
              final sub = idTokenData['sub'] as String;
              print('ID token sub claim: $sub');
              final normalizedUrn = _normalizeMemberUrn(sub);
              if (normalizedUrn != null) {
                personUrn = normalizedUrn;
                print('Got member URN from ID token: $personUrn');
              }
            }

            // Also check for other fields that might contain member ID
            print('ID token data keys: ${idTokenData.keys.toList()}');
            for (final key in idTokenData.keys) {
              print('ID token $key: ${idTokenData[key]}');
            }
            if (idTokenData.containsKey('given_name')) {
              username = idTokenData['given_name'] as String;
            }
          }
        } catch (e) {
          print('Error decoding ID token: $e');
        }
      }

      // If we still don't have person URN from ID token, that's okay
      // We'll get it when posting (the UGC Posts API might provide it)
      // Store tokens and person URN (if we have it)
      await _storeTokens(
        userId: userId,
        schoolId: schoolId,
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresIn: expiresIn,
        username: username,
        personUrn: personUrn,
      );

      return true;
    } catch (e) {
      print('Error handling OAuth callback: $e');
      return false;
    }
  }

  /// Post text content to LinkedIn
  Future<bool> postToLinkedIn({required String text, String? schoolId}) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final doc = await _getLinkedInDoc(userId, schoolId);
      if (!doc.exists) throw Exception('LinkedIn not connected');

      final data = doc.data() as Map<String, dynamic>?;
      final accessToken = data?['accessToken'] as String?;

      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('LinkedIn access token not found');
      }

      // Get person URN from stored data
      String? personUrn = data?['personUrn'] as String?;

      // If we don't have person URN stored, try alternative methods
      if (personUrn == null || personUrn.isEmpty) {
        // Method 1: Try to get from UGC Posts API by making a minimal request
        // Sometimes LinkedIn returns the person URN in error messages
        try {
          // Try posting with a placeholder to see if we get person URN in response
          final testResponse = await http.post(
            Uri.parse('$_apiBaseUrl/ugcPosts'),
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
              'X-Restli-Protocol-Version': '2.0.0',
            },
            body: json.encode({
              'author': 'urn:li:person:INVALID',
              'lifecycleState': 'PUBLISHED',
              'specificContent': {
                'com.linkedin.ugc.ShareContent': {
                  'shareCommentary': {'text': 'test'},
                  'shareMediaCategory': 'NONE',
                },
              },
              'visibility': {
                'com.linkedin.ugc.MemberNetworkVisibility': 'PUBLIC',
              },
            }),
          );

          // Check error response for person URN hints
          if (testResponse.statusCode != 201) {
            final errorBody = testResponse.body;
            print('Test post error (looking for person URN): $errorBody');

            // Try to extract member ID from error message
            // Error format: "urn:li:member:\d+" or similar
            try {
              final errorData = json.decode(errorBody) as Map<String, dynamic>;
              final message = errorData['message'] as String? ?? '';

              // Look for member ID pattern in error message
              final memberIdRegex = RegExp(r'urn:li:member:(\d+)');
              final match = memberIdRegex.firstMatch(message);
              if (match != null) {
                final memberId = match.group(1);
                personUrn = 'urn:li:member:$memberId';
                print('Extracted member ID from error: $personUrn');
              }
            } catch (e) {
              print('Error parsing test post error: $e');
            }
          }
        } catch (e) {
          print('Error in test post: $e');
        }

        // Method 2: Try LinkedIn's user info endpoint (OpenID Connect endpoint)
        // This should now work because we request openid/profile/email scopes
        if (personUrn == null || personUrn.isEmpty) {
          try {
            final userInfoResponse = await http.get(
              Uri.parse('https://api.linkedin.com/v2/userinfo'),
              headers: {'Authorization': 'Bearer $accessToken'},
            );

            print('User info response status: ${userInfoResponse.statusCode}');
            print('User info response body: ${userInfoResponse.body}');

            if (userInfoResponse.statusCode == 200) {
              final userInfo =
                  json.decode(userInfoResponse.body) as Map<String, dynamic>;
              if (userInfo.containsKey('sub')) {
                final sub = userInfo['sub'] as String;
                final normalizedUrn = _normalizeMemberUrn(sub);
                if (normalizedUrn != null) {
                  personUrn = normalizedUrn;
                  print('Got person URN from userinfo: $personUrn');
                }
              }
            }
          } catch (e) {
            print('Error getting user info: $e');
          }
        }

        // Method 3: Try the /me endpoint (requires r_liteprofile)
        if (personUrn == null || personUrn.isEmpty) {
          final profileUrn = await _getMemberUrnFromProfile(accessToken);
          if (profileUrn != null) {
            personUrn = profileUrn;
            print('Got person URN from /me profile: $personUrn');
          }
        }

        // If we got it, store it for future use
        if (personUrn != null && personUrn.isNotEmpty) {
          await _getLinkedInDocRef(
            userId,
            schoolId,
          ).update({'personUrn': personUrn});
        } else {
          print('Warning: Could not determine LinkedIn member URN.');
          await _openLinkedInShareFallback(text);
          return true;
        }
      }

      // Create share content with a valid member URN
      var authorUrn = personUrn;
      if (!authorUrn.startsWith('urn:li:member:')) {
        if (authorUrn.startsWith('urn:li:person:')) {
          final id = authorUrn.replaceFirst('urn:li:person:', '');
          final numericId = id.replaceAll(RegExp(r'[^\d]'), '');
          authorUrn = 'urn:li:member:$numericId';
        } else {
          final numericId = authorUrn.replaceAll(RegExp(r'[^\d]'), '');
          authorUrn = 'urn:li:member:$numericId';
        }
      }

      final shareContent = {
        'author': authorUrn,
        'lifecycleState': 'PUBLISHED',
        'specificContent': {
          'com.linkedin.ugc.ShareContent': {
            'shareCommentary': {'text': text},
            'shareMediaCategory': 'NONE',
          },
        },
        'visibility': {'com.linkedin.ugc.MemberNetworkVisibility': 'PUBLIC'},
      };

      // Post to LinkedIn
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/ugcPosts'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'X-Restli-Protocol-Version': '2.0.0',
        },
        body: json.encode(shareContent),
      );

      print('LinkedIn post response: ${response.statusCode}');
      print('LinkedIn post body: ${response.body}');

      if (response.statusCode == 201) {
        return true;
      } else {
        final errorBody = response.body;
        print('LinkedIn post failed: ${response.statusCode} - $errorBody');

        if (response.statusCode == 401) {
          throw Exception(
            'LinkedIn token expired. Please reconnect your LinkedIn account.',
          );
        }

        if (response.statusCode == 400) {
          throw Exception('Invalid LinkedIn request. Please try again.');
        }

        if (response.statusCode == 403 ||
            response.statusCode == 422 ||
            response.statusCode == 500) {
          await _openLinkedInShareFallback(text);
          return true;
        }

        throw Exception('LinkedIn API error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error posting to LinkedIn: $e');
      return false;
    }
  }

  /// Share event to LinkedIn with formatted text
  Future<bool> shareEvent({
    required String title,
    required String description,
    required DateTime startTime,
    required String location,
    String? schoolId,
  }) async {
    final dateFormat =
        '${startTime.month}/${startTime.day}/${startTime.year} at ${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}';

    final text =
        '''🎯 $title

📅 $dateFormat
📍 $location

$description

#FBLA #Conference #Networking''';

    return await postToLinkedIn(text: text, schoolId: schoolId);
  }

  /// Share announcement to LinkedIn
  Future<bool> shareAnnouncement({
    required String title,
    required String content,
    String? schoolId,
  }) async {
    final text =
        '''📢 $title

$content

#FBLA #Announcement''';

    return await postToLinkedIn(text: text, schoolId: schoolId);
  }

  /// Share pin to LinkedIn
  Future<bool> sharePin({
    required String pinName,
    String? description,
    String? condition,
    String? schoolId,
  }) async {
    final text =
        '''📌 Trading: $pinName${condition != null ? '\n\nCondition: $condition' : ''}${description != null ? '\n\n$description' : ''}

#FBLA #PinTrading #FBLAConference''';

    return await postToLinkedIn(text: text, schoolId: schoolId);
  }

  Future<void> _openLinkedInShareFallback(String text) async {
    try {
      final lines = text
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .toList();
      final title = lines.isNotEmpty
          ? lines.first.trim()
          : 'FBLA Conference Update';
      final summary = text.length > 280
          ? '${text.substring(0, 277)}…'
          : text.trim();

      final previewPage = Uri.https(
        'fbla-conference-app.firebaseapp.com',
        '/linkedin/share.html',
        {'text': text},
      );

      final shareUrl = Uri.parse(
        'https://www.linkedin.com/shareArticle?mini=true'
        '&url=${Uri.encodeComponent(previewPage.toString())}'
        '&title=${Uri.encodeComponent(title)}'
        '&summary=${Uri.encodeComponent(summary)}'
        '&source=FBLA%20Conference%20App',
      );

      final launched = await launchUrl(
        shareUrl,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );

      if (!launched) {
        await launchUrl(shareUrl, webOnlyWindowName: '_blank');
      }
    } catch (e) {
      print('Error launching LinkedIn fallback share: $e');
    }
  }

  /// Disconnect LinkedIn account
  Future<void> disconnect({String? schoolId}) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final docRef = _getLinkedInDocRef(userId, schoolId);
      await docRef.delete();
    } catch (e) {
      print('Error disconnecting LinkedIn: $e');
    }
  }

  /// Set auto-post preference
  Future<void> setAutoPost(bool enabled, {String? schoolId}) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final docRef = _getLinkedInDocRef(userId, schoolId);
      await docRef.update({'autoPost': enabled});
    } catch (e) {
      print('Error setting auto-post: $e');
    }
  }

  // Private helper methods

  Future<DocumentSnapshot> _getLinkedInDoc(
    String userId,
    String? schoolId,
  ) async {
    if (schoolId != null) {
      return await _firestore
          .collection('schools')
          .doc(schoolId)
          .collection('socialMedia')
          .doc('linkedin')
          .get();
    } else {
      return await _firestore
          .collection('users')
          .doc(userId)
          .collection('socialMedia')
          .doc('linkedin')
          .get();
    }
  }

  DocumentReference _getLinkedInDocRef(String userId, String? schoolId) {
    if (schoolId != null) {
      return _firestore
          .collection('schools')
          .doc(schoolId)
          .collection('socialMedia')
          .doc('linkedin');
    } else {
      return _firestore
          .collection('users')
          .doc(userId)
          .collection('socialMedia')
          .doc('linkedin');
    }
  }

  Future<void> _storeTokens({
    required String userId,
    String? schoolId,
    required String accessToken,
    String? refreshToken,
    int? expiresIn,
    required String username,
    String? personUrn,
  }) async {
    final docRef = _getLinkedInDocRef(userId, schoolId);

    final data = {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'username': username,
      'connectedAt': FieldValue.serverTimestamp(),
      'autoPost': false,
    };

    if (personUrn != null && personUrn.isNotEmpty) {
      data['personUrn'] = personUrn;
    }

    if (expiresIn != null) {
      data['expiresAt'] = Timestamp.fromDate(
        DateTime.now().add(Duration(seconds: expiresIn)),
      );
    }

    await docRef.set(data, SetOptions(merge: true));
  }

  Future<String?> _getMemberUrnFromProfile(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/me?projection=(id)'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'X-Restli-Protocol-Version': '2.0.0',
        },
      );

      print('Profile /me response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final rawId = data['id'] as String?;
        if (rawId == null) return null;
        return _normalizeMemberUrn(rawId);
      }
    } catch (e) {
      print('Error getting member ID from /me endpoint: $e');
    }
    return null;
  }

  String? _normalizeMemberUrn(String rawId) {
    if (rawId.isEmpty) return null;

    if (rawId.startsWith('urn:li:member:')) {
      final digits = _extractDigits(rawId.replaceFirst('urn:li:member:', ''));
      return digits.isNotEmpty ? 'urn:li:member:$digits' : null;
    }

    if (rawId.startsWith('urn:li:person:')) {
      final digits = _extractDigits(rawId.replaceFirst('urn:li:person:', ''));
      return digits.isNotEmpty ? 'urn:li:member:$digits' : null;
    }

    final digits = _extractDigits(rawId);
    return digits.isNotEmpty ? 'urn:li:member:$digits' : null;
  }

  String _extractDigits(String input) {
    return input.replaceAll(RegExp(r'[^\d]'), '');
  }
}
