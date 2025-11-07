import 'dart:developer' as dv;
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

// import '../../app_info.dart';
import '../../app_info.dart';
import '../../backend/models.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
    ],
  );

  static UserCredential? userCredential;

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // final scaffoldContext = ScaffoldMessenger.of(context);
      // final navigatorState = Navigator.of(context);

      userCredential = await _auth.signInWithCredential(credential);

      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userCredential!.user!.uid)
          .get();

      print(userCredential);

      String fullName;

      if (userDoc.exists) {
        fullName = userDoc.get('name') ?? '';
        await AppInfo.getCurrentUserData();
      } else {
        fullName =
            await _getFullNameSafely(context, userCredential!.user!) ?? '';

        if (fullName.isNotEmpty) {
          UserModel newUser = UserModel(
            id: userCredential!.user!.uid,
            email: userCredential!.user!.email ?? '',
            profilePic: userCredential!.user!.photoURL ?? '',
            name: fullName,
            pastEvents: [],
            compEvents: [],
            grade: 12,
            isExec: false,
            approved: true,
            openedAppSinceApproved: false,
            currentChapter: '',
            chapters: [],
            topicsSubscribed: [],
          );
          dv.log('here');

          UserModel.writeUser(newUser);
          AppInfo.currentUser = newUser;
          // Toasts.toast(
          //     "Account created! Tap \"Sign in with Google\" again to be signed in.",
          //     false);
        }
      }

      return;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code} - ${e.message}');

      if (e.code == 'internal-error' &&
          e.message?.contains('DUPLICATE_RAW_ID') == true) {
        try {
          final currentUser = _auth.currentUser;
          if (currentUser != null) {
            userCredential =
                await _auth.signInWithCredential(GoogleAuthProvider.credential(
              accessToken: await currentUser.getIdToken(),
              idToken: await currentUser.getIdToken(),
            ));
            return;
          }
        } catch (signInError) {
          print('Error signing in with existing account: $signInError');
          dv.log(signInError.toString());
        }
      }

      return;
    } catch (e) {
      print('Unexpected error signing in with Google: $e');
      dv.log(e.toString());
      return;
    }
  }

  Future<String?> _getFullNameSafely(BuildContext context, User user) async {
    if (user.displayName != null && user.displayName!.contains(' ')) {
      return user.displayName;
    }

    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        final firstNameController = TextEditingController();
        final lastNameController = TextEditingController();

        if (user.displayName != null) {
          firstNameController.text = user.displayName!;
        }

        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Complete Your Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  hintText: 'Enter your first name',
                ),
              ),
              TextField(
                controller: lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  hintText: 'Enter your last name',
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Submit',
                style: TextStyle(color: Colors.black),
              ),
              onPressed: () {
                if (firstNameController.text.isNotEmpty &&
                    lastNameController.text.isNotEmpty) {
                  String fullName =
                      '${firstNameController.text} ${lastNameController.text}';
                  Navigator.of(dialogContext).pop(fullName);
                } else {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                        content: Text('Please enter both first and last name')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> signInWithApple(BuildContext context) async {
    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        webAuthenticationOptions: WebAuthenticationOptions(
            clientId: "com.wesimplex.madx-33e96",
            redirectUri: Uri.parse(
                "https://madx-33e96.firebaseapp.com/__/auth/handler")),
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      if (appleCredential == null) {
        return;
      }

      final oauthCredential = OAuthProvider("apple.com").credential(
          idToken: appleCredential.identityToken,
          rawNonce: rawNonce,
          accessToken: appleCredential.authorizationCode);

      if (oauthCredential == null) {
        return;
      }

      userCredential = await _auth.signInWithCredential(oauthCredential);
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userCredential!.user!.uid)
          .get();
      String fullName;

      if (userDoc.exists) {
        fullName = userDoc.get('name') ?? '';
        await AppInfo.getCurrentUserData();
      } else {
        String name = "";
        if (appleCredential.givenName != null && appleCredential.familyName != null) {
          name = appleCredential.givenName! + " " + appleCredential.familyName!;
          await userCredential!.user!.updateDisplayName(
            appleCredential.givenName! + " " + appleCredential.familyName!);
        } else {
          throw Exception("Name is null despite first apple login");
        }
        // fullName =
        //     await _getFullNameSafely(context, userCredential!.user!) ?? '';
        UserModel newUser = UserModel(
          id: userCredential!.user!.uid,
          email: userCredential!.user!.email ?? '',
          profilePic: userCredential!.user!.photoURL ?? '',
          // name: userDoc.get('name') ?? 'User',
          // name should be "User " and then the first 5 characters of the ID
          name: name,
          pastEvents: [],
          compEvents: [],
          grade: 12,
          isExec: false,
          approved: true,
          openedAppSinceApproved: false,
          currentChapter: '',
          chapters: [],
          topicsSubscribed: [],
        );

        UserModel.writeUser(newUser);
        AppInfo.currentUser = newUser;
      }

      return;
    } on SignInWithAppleAuthorizationException catch (e) {
      print('Apple Sign-In Authorization Error:');
      print('Error code: ${e.code}');
      print('Error message: ${e.message}');
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error:');
      print('Error code: ${e.code}');
      print('Error message: ${e.message}');
    } catch (e) {
      print('Unexpected error during Apple Sign-In: $e');
    }
    return;
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }
}
