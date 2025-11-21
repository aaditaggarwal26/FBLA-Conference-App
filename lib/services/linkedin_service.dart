import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  // Scopes needed for posting
  static const String _scopes = 'w_member_social';

  /// Check if LinkedIn is connected for the current user/school
  Future<bool> isConnected({String? schoolId}) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final doc = await _getLinkedInDoc(userId, schoolId);
      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>?;
      final accessToken = data?['accessToken'] as String?;

      if (accessToken == null || accessToken.isEmpty) return false;

      // Verify token is still valid by checking if we can get user profile
      return await _verifyToken(accessToken);
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

      // Get user profile to get username
      final profile = await _getUserProfile(accessToken);
      final username = profile?['localizedFirstName'] ?? 'LinkedIn User';

      // Store tokens
      await _storeTokens(
        userId: userId,
        schoolId: schoolId,
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresIn: expiresIn,
        username: username,
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

      // Get user's LinkedIn URN (unique identifier)
      final profile = await _getUserProfile(accessToken);
      if (profile == null) throw Exception('Could not get LinkedIn profile');

      final personUrn = profile['id'] as String;

      // Create share content
      final shareContent = {
        'author': 'urn:li:person:$personUrn',
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

      if (response.statusCode == 201) {
        return true;
      } else {
        print(
          'LinkedIn post failed: ${response.statusCode} - ${response.body}',
        );
        return false;
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
  }) async {
    final docRef = _getLinkedInDocRef(userId, schoolId);

    final data = {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'username': username,
      'connectedAt': FieldValue.serverTimestamp(),
      'autoPost': false,
    };

    if (expiresIn != null) {
      data['expiresAt'] = Timestamp.fromDate(
        DateTime.now().add(Duration(seconds: expiresIn)),
      );
    }

    await docRef.set(data, SetOptions(merge: true));
  }

  Future<bool> _verifyToken(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/me'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> _getUserProfile(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/me'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }
}
