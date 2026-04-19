import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';
import '../models/user_model.dart';

/// Service to handle user authentication via Firebase Auth.
/// Supports Email/Password, Google Sign-In, and Apple Sign-In.
class AuthService {
  static const String _appleGoogleClientId =
      '518774774037-u8t6pfdumr2a449hrnif8c0jiu4esmmh.apps.googleusercontent.com';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: _googleClientIdForCurrentPlatform,
  );

  String? get _googleClientIdForCurrentPlatform {
    if (kIsWeb) {
      return null;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return _appleGoogleClientId;
      default:
        return null;
    }
  }

  /// Returns the currently signed-in user, or null if none.
  User? get currentUser => _auth.currentUser;
  
  /// Stream of auth state changes (user sign-in/sign-out).
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Signs in a user with email and password.
  /// Returns the UserCredential on success.
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Registers a new user with email, password, and name.
  /// Creates a corresponding user document in Firestore.
  Future<UserCredential?> registerWithEmail(
    String email,
    String password,
    String name,
  ) async {
    try {
      // Create user in Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Create user document in Firestore
        final userModel = UserModel(
          id: credential.user!.uid,
          email: email,
          name: name,
          registeredEvents: [],
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .set(userModel.toFirestore());
      }

      return credential;
    } catch (e) {
      rethrow;
    }
  }

  /// Signs out the current user from all providers.
  Future<void> signOut() async {
    await Future.wait([_googleSignIn.signOut(), _auth.signOut()]);
  }

  /// Signs in a user using Google Sign-In.
  /// Creates a user document if one doesn't exist.
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the Google Authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);

      // Create or update user document in Firestore
      if (userCredential.user != null) {
        final userDoc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (!userDoc.exists) {
          final userModel = UserModel(
            id: userCredential.user!.uid,
            email: userCredential.user!.email ?? '',
            name: userCredential.user!.displayName ?? '',
            photoUrl: userCredential.user!.photoURL,
            registeredEvents: [],
            createdAt: DateTime.now(),
          );

          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .set(userModel.toFirestore());
        }
      }

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  /// Generates a random nonce for Apple Sign-In security.
  String generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  /// Returns the SHA256 hash of a string.
  String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Signs in a user using Apple Sign-In.
  /// Handles nonce generation and Firestore user creation.
  Future<UserCredential?> signInWithApple() async {
    try {
      final rawNonce = generateNonce();
      final nonce = sha256ofString(rawNonce);

      // Request credential from Apple
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      // Create an OAuth Credential with the Apple ID token
      final oauthCredential = OAuthProvider(
        "apple.com",
      ).credential(idToken: appleCredential.identityToken, rawNonce: rawNonce);

      // Sign in to Firebase
      final userCredential = await _auth.signInWithCredential(oauthCredential);

      // Create or update user document
      if (userCredential.user != null) {
        final userDoc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (!userDoc.exists) {
          String displayName = userCredential.user!.displayName ?? '';
          if (displayName.isEmpty && appleCredential.givenName != null) {
            displayName =
                '${appleCredential.givenName} ${appleCredential.familyName ?? ''}'
                    .trim();
          }

          final userModel = UserModel(
            id: userCredential.user!.uid,
            email: userCredential.user!.email ?? appleCredential.email ?? '',
            name: displayName.isEmpty ? 'Apple User' : displayName,
            photoUrl: userCredential.user!.photoURL,
            registeredEvents: [],
            createdAt: DateTime.now(),
          );

          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .set(userModel.toFirestore());
        }
      }

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  /// Retrieves user data from Firestore by UID.
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Returns a stream of user data for real-time updates.
  Stream<UserModel?> getUserStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) {
          if (doc.exists) {
            return UserModel.fromFirestore(doc);
          }
          return null;
        });
  }

  /// Updates specific fields in the user's profile.
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
  }

  /// Updates the user's school association and role.
  /// Handles backward compatibility for single school ID vs list of school IDs.
  Future<void> updateUserSchoolInfo(
    String uid,
    String schoolId, {
    bool isOwner = false,
    bool isAdmin = false,
    bool isTeacher = false,
  }) async {
    String schoolRole = 'student';
    if (isOwner || isAdmin) {
      schoolRole = 'schoolAdmin';
    } else if (isTeacher) {
      schoolRole = 'teacher';
    }

    // Get current user to update schoolIds array
    final user = await getUserData(uid);
    if (user != null) {
      final updatedSchoolIds = List<String>.from(user.schoolIds);
      if (!updatedSchoolIds.contains(schoolId)) {
        updatedSchoolIds.add(schoolId);
      }

      await _firestore.collection('users').doc(uid).update({
        'schoolId': updatedSchoolIds.first, // Backwards compatibility
        'schoolIds': updatedSchoolIds,
        'schoolRole': schoolRole,
        'isSchoolOwner': isOwner,
      });
    } else {
      // Fallback for new users or if user data fetch fails
      await _firestore.collection('users').doc(uid).update({
        'schoolId': schoolId,
        'schoolIds': [schoolId],
        'schoolRole': schoolRole,
        'isSchoolOwner': isOwner,
      });
    }
  }

  /// Sends a password reset email to the specified address.
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Deletes the user's account and associated data.
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user is currently signed in');
    }

    // Delete user document from Firestore
    try {
      await _firestore.collection('users').doc(user.uid).delete();
    } catch (e) {
      // Continue even if Firestore delete fails (e.g., permission issues)
      print('Error deleting user document: $e');
    }

    // Delete user from Firebase Auth
    await user.delete();
  }
}
