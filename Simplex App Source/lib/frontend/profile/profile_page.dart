import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:simplex_chapter_x/frontend/flutter_flow/flutter_flow_theme.dart';
import 'package:simplex_chapter_x/frontend/login/auth_service.dart';
import 'package:simplex_chapter_x/frontend/login/login_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../app_info.dart';
import '../../backend/models.dart';

class Profile {
  static bool isSigningOut = false;
  static bool isDeleting = false;

  static void showProfilePage(BuildContext context) {
    showModalBottomSheet(
        context: context,
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        // backgroundColor: const Color(0xFFFFFFFF),
        builder: (context) {
          return Padding(
              padding: const EdgeInsets.all(35),
              child: Column(
                children: [
                  Padding(
                      padding: EdgeInsets.zero,
                      child: Row(
                        children: [
                          InkWell(
                              onTap: () => _openUrl(
                                  'https://sites.google.com/wesimplex.com/home/terms-of-service'),
                              child: Text(
                                'Terms and Conditions',
                                style: FlutterFlowTheme.of(context)
                                    .bodyLarge
                                    .override(
                                        // color: const Color(0xFF3B58F4),
                                        decoration: TextDecoration.underline),
                              ))
                        ],
                      )),
                  Padding(
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(0, 12, 0, 0),
                      child: Row(
                        children: [
                          InkWell(
                              onTap: () => _openUrl(
                                  'https://sites.google.com/wesimplex.com/home/privacy-policy'),
                              child: Text(
                                'Privacy Policy',
                                style: FlutterFlowTheme.of(context)
                                    .bodyLarge
                                    .override(
                                        // color: const Color(0xFF3B58F4),
                                        decoration: TextDecoration.underline),
                              ))
                        ],
                      )),
                  Padding(
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(0, 12, 0, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: RichText(
                              text: TextSpan(children: [
                                const TextSpan(
                                  text: 'Email ',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontFamily: 'Google Sans',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                TextSpan(
                                  text: 'hello@wesimplex.com',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontFamily: 'Google Sans',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () async {
                                      Uri params = Uri.parse(
                                          "mailto:hello@wesimplex.com?subject=[Subject]&body=[Body]");

                                      await launchUrl(params);
                                    },
                                ),
                                const TextSpan(
                                  text: ' if you have any questions or issues with this application.',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontFamily: 'Google Sans',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ]),
                            ),
                          )
                        ],
                      )),
                  Padding(
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(0, 24, 0, 0),
                      child: Row(
                        children: [
                          InkWell(
                              onTap: () => _signOut(context),
                              child: Text(
                                'Sign out',
                                style: FlutterFlowTheme.of(context)
                                    .bodyLarge
                                    .override(
                                        // color: const Color(0xFF3B58F4),
                                        decoration: TextDecoration.underline,
                                        fontWeight: FontWeight.bold),
                              ))
                        ],
                      )),
                  Padding(
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(0, 24, 0, 0),
                      child: Row(
                        children: [
                          InkWell(
                              onTap: () async {
                                await _deleteDialog(context);
                                if (isDeleting) {
                                  await UserModel.deleteUserById(
                                      AppInfo.currentUser.id);
                                  AppInfo.currentUser.currentChapter = "";

                                  AppInfo.isAdmin = false;
                                  AppInfo.isOwner = false;
                                  _signOut(context);
                                  Navigator.of(context).pushAndRemoveUntil(
                                    PageRouteBuilder(
                                      transitionDuration:
                                          const Duration(milliseconds: 200),
                                      reverseTransitionDuration:
                                          const Duration(milliseconds: 200),
                                      pageBuilder: (context, animation,
                                              secondaryAnimation) =>
                                          const LoginWidget(),
                                      transitionsBuilder: (context, animation,
                                          secondaryAnimation, child) {
                                        const begin = Offset(-1.0, 0.0);
                                        const end = Offset.zero;
                                        final tween =
                                            Tween(begin: begin, end: end);
                                        final offsetAnimation =
                                            animation.drive(tween);

                                        return SlideTransition(
                                          position: offsetAnimation,
                                          child: child,
                                        );
                                      },
                                    ),
                                    (route) => false,
                                  );
                                  isDeleting = false;
                                }
                              },
                              child: Text(
                                'Delete Account',
                                style: FlutterFlowTheme.of(context)
                                    .bodyLarge
                                    .override(
                                        color: const Color(0xFFDA0000),
                                        // decoration: TextDecoration.underline,
                                        fontWeight: FontWeight.bold),
                              ))
                        ],
                      ))
                ],
              ));
        });
  }



    static Future<bool> _deleteDialog(BuildContext context) async {
    bool okPressed = false;
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: const Color(0xFFFFFFFF),
            // title: const Text(
            //   'New Account',
            //   style: TextStyle(
            //     fontSize: 20,
            //     color: Color.fromARGB(255, 0, 0, 0),
            //     fontFamily: 'ClashGrotesk',
            //     fontWeight: FontWeight.w500,
            //   ),
            // ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * .9,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(0, 10, 0, 0),
                    child: Text(
                        "Are you sure you want to delete your account? This action cannot be reversed.",
                        style: TextStyle(
                          color: Colors.black,
                          fontFamily: 'ClashGrotesk',
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        )),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
            actions: <Widget>[
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black,
                        backgroundColor: Color(0xFF92190C),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          // side: BorderSide(
                          //   color: Color(0xFFEFEFEF), // Border color
                          //   width: 2, // Border width
                          // ),
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 6, 16, 6),
                        child: Text(
                          "Yes, delete my account.",
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'ClashGrotesk',
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      onPressed: () {
                        isDeleting = true;
                        Navigator.pop(context);
                      },
                    ),
                    SizedBox(height: 15),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black,
                        backgroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Color(0xFFEFEFEF), // Border color
                            width: 2, // Border width
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 6, 16, 6),
                        child: Text(
                          "No, go back.",
                          style: TextStyle(
                            color: Colors.black,
                            fontFamily: 'ClashGrotesk',
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      onPressed: () {
                        okPressed = true;
                        isDeleting = false;
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        }).then((val) async {
      if (!okPressed) {
        return false;
      }
      isDeleting = false;

      return true;
    });
  }

  // Maybe make this public in the future if needed
  static _signOut(BuildContext context) async {
    if (!isSigningOut) {
      isSigningOut = true;
      AppInfo.isAdmin = false;
      AppInfo.isOwner = false;
      AuthService.userCredential = null;
      try {
        await FirebaseAuth.instance.signOut();
        if (!kIsWeb) {
          await GoogleSignIn().signOut();
        }
      } catch (e) {
        print(e);
      }

      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginWidget()),
          (route) => false);
      isSigningOut = false;
    }
  }

  // You should probably only use this for trusted links
  static _openUrl(String url) async {
    await launchUrlString(
      url,
      // mode: LaunchMode.externalApplication
    );
  }
}
