import 'dart:developer';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'auth_service.dart';
import '../select_chapter/chapter_select.dart';

// import 'package:fluttertoast/fluttertoast.dart';
import 'package:simplex_chapter_x/app_info.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:simplex_chapter_x/backend/models.dart';
// import 'package:simplex_chapter_x/frontend/login/auth_service.dart';
import 'package:simplex_chapter_x/frontend/login/login_page.dart';
// import 'package:simplex_chapter_x/frontend/select_chapter/chapter_select.dart';

import 'package:simplex_chapter_x/frontend/toast.dart';
import 'package:url_launcher/url_launcher.dart';

class CreateAccountWidget extends StatefulWidget {
  const CreateAccountWidget({super.key});

  @override
  State<CreateAccountWidget> createState() => _CreateAccountWidgetState();
}

class _CreateAccountWidgetState extends State<CreateAccountWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final AuthService _authService = AuthService();
  late TextEditingController firstName;
  late TextEditingController lastName;
  late TextEditingController email;
  late TextEditingController password;
  late TextEditingController confirmPassword;
  bool agreedTOS = false;
  bool agreedPrivacy = false;
  bool showPassword = false;
  bool showConfirmPassword = false;
  final _auth = FirebaseAuth.instance;
  final emailRegExp =
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

  @override
  void initState() {
    super.initState();
    firstName = TextEditingController();
    lastName = TextEditingController();
    email = TextEditingController();
    password = TextEditingController();
    confirmPassword = TextEditingController();
  }

  @override
  void dispose() {
    firstName.dispose();
    lastName.dispose();
    email.dispose();
    password.dispose();
    confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: const Color(0xFFF5F6F7),
      body: Container(
        constraints: BoxConstraints(
          minHeight: MediaQuery.sizeOf(context).height * 1,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFFF5F6F7),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Stack(
                children: [
                  Align(
                    alignment: const AlignmentDirectional(0, 0),
                    child: Container(
                      width: MediaQuery.sizeOf(context).width,
                      height: 266,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        image: DecorationImage(
                          fit: BoxFit.cover,
                          image: Image.asset(
                            'assets/images/login_bg.png',
                          ).image,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                            24, 65, 24, 40),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  0, 42, 0, 0),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(0),
                                    child: Image.asset(
                                      // REPLACE WITH SIELIFY CHAPTER LOGO
                                      'assets/images/appicon_trans.png',
                                      height: 40,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Padding(
                              padding:
                                  EdgeInsetsDirectional.fromSTEB(0, 8, 0, 0),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  AutoSizeText(
                                    'Simplex Chapter',
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontFamily: 'Google Sans',
                                      color: Colors.white,
                                      fontSize: 30,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(0, 251, 0, 0),
                    child: Container(
                      width: MediaQuery.sizeOf(context).width,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF5F6F7),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(0),
                          bottomRight: Radius.circular(0),
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Padding(
                        padding:
                            const EdgeInsetsDirectional.fromSTEB(0, 31, 0, 50),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  18, 0, 24, 0),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Opacity(
                                    opacity: 0.4,
                                    child: Padding(
                                      padding:
                                          const EdgeInsetsDirectional.fromSTEB(
                                              0, 0, 0, 1),
                                      child: IconButton(
                                        icon: const Icon(
                                            Icons.chevron_left_sharp,
                                            color: Color(0xFF454545),
                                            size: 24),
                                        onPressed: () {
                                          Navigator.pushAndRemoveUntil(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    const LoginWidget()),
                                            (route) =>
                                                false, // This condition removes all previous routes
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      Navigator.of(context).pushAndRemoveUntil(
                                        PageRouteBuilder(
                                          transitionDuration:
                                              const Duration(milliseconds: 200),
                                          reverseTransitionDuration:
                                              const Duration(milliseconds: 200),
                                          pageBuilder: (context, animation,
                                                  secondaryAnimation) =>
                                              const LoginWidget(),
                                          transitionsBuilder: (context,
                                              animation,
                                              secondaryAnimation,
                                              child) {
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
                                    },
                                    child: const Opacity(
                                      opacity: 0.4,
                                      child: Text(
                                        'Back',
                                        style: TextStyle(
                                          fontFamily: 'Google Sans',
                                          color: Color(0xFF454545),
                                          fontSize: 18,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Padding(
                              padding:
                                  EdgeInsetsDirectional.fromSTEB(24, 20, 24, 0),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Text(
                                    'Create an Account',
                                    style: TextStyle(
                                      fontFamily: 'Google Sans',
                                      color: Color(0xFF3B58F4),
                                      fontSize: 24,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  24, 10, 24, 0),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Flexible(
                                    child: RichText(
                                      textScaler:
                                          MediaQuery.of(context).textScaler,
                                      text: const TextSpan(
                                        children: [
                                          TextSpan(
                                            text:
                                                'By creating an account with Google or Apple, you accept our ',
                                            style: TextStyle(),
                                          ),
                                          TextSpan(
                                            text: 'Terms of Service',
                                            style: TextStyle(
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                          ),
                                          TextSpan(
                                            text: ' and ',
                                            style: TextStyle(),
                                          ),
                                          TextSpan(
                                            text: 'Privacy Policy',
                                            style: TextStyle(
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                          ),
                                          TextSpan(
                                            text: '.',
                                            style: TextStyle(),
                                          )
                                        ],
                                        style: TextStyle(
                                          fontFamily: 'Google Sans',
                                          color: Color(0xFF333333),
                                          fontSize: 15,
                                          letterSpacing: 0.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  24, 15, 24, 0),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () async {
                                        await _authService
                                            .signInWithGoogle(context);
                                        if (AuthService.userCredential !=
                                            null) {
                                          try {
                                            Navigator.pushAndRemoveUntil(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      const ChapterSelectWidget()),
                                              (route) =>
                                                  false, // This condition removes all previous routes
                                            );
                                          } catch (e) {
                                            log(e.toString());
                                          }
                                        }
                                      },
                                      child: Container(
                                        width: 100,
                                        height: 54,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: const Color(0xFFE0E0E0),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.max,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Align(
                                              alignment:
                                                  const AlignmentDirectional(
                                                      0, 0),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsetsDirectional
                                                        .fromSTEB(0, 0, 10, 0),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(0),
                                                  child: Image.asset(
                                                    'assets/images/google_logo.png',
                                                    width: 23,
                                                    height: 23,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const Align(
                                              alignment:
                                                  AlignmentDirectional(0, 0),
                                              child: Text(
                                                'Sign in with Google',
                                                style: TextStyle(
                                                  fontFamily: 'Google Sans',
                                                  color: Color(0xFF333333),
                                                  fontSize: 18,
                                                  letterSpacing: 0.0,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  24, 12, 24, 0),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () async {
                                        await _authService
                                            .signInWithApple(context);
                                        if (AuthService.userCredential !=
                                            null) {
                                          Navigator.pushAndRemoveUntil(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    const ChapterSelectWidget()),
                                            (route) =>
                                                false, // This condition removes all previous routes
                                          );
                                        }
                                      },
                                      child: Container(
                                        width: 100,
                                        height: 54,
                                        decoration: BoxDecoration(
                                          color: Colors.black,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: const Color(0xFFE0E0E0),
                                            width: 0,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.max,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Align(
                                              alignment:
                                                  const AlignmentDirectional(
                                                      0, 0),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsetsDirectional
                                                        .fromSTEB(0, 0, 10, 3),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(0),
                                                  child: Image.asset(
                                                    'assets/images/apple_logo.png',
                                                    width: 23,
                                                    height: 23,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const Align(
                                              alignment:
                                                  AlignmentDirectional(0, 0),
                                              child: Text(
                                                'Sign in with Apple',
                                                style: TextStyle(
                                                  fontFamily: 'Google Sans',
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  letterSpacing: 0.0,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  0, 30, 0, 0),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Opacity(
                                      opacity: 0.2,
                                      child: Container(
                                        width: 100,
                                        height: 2,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFCFCFCF),
                                          borderRadius:
                                              BorderRadius.circular(3),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        12, 0, 12, 0),
                                    child: Text(
                                      'Or create with',
                                      style: TextStyle(
                                        fontFamily: 'Google Sans',
                                        color: Color(0xFF333333),
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Opacity(
                                      opacity: 0.2,
                                      child: Container(
                                        width: 100,
                                        height: 2,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFCFCFCF),
                                          borderRadius:
                                              BorderRadius.circular(3),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Padding(
                              padding:
                                  EdgeInsetsDirectional.fromSTEB(28, 15, 24, 0),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Text(
                                    'Name',
                                    style: TextStyle(
                                      fontFamily: 'Google Sans',
                                      color: Color(0xFF333333),
                                      fontSize: 18,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  0, 10, 0, 0),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding:
                                          const EdgeInsetsDirectional.fromSTEB(
                                              24, 0, 24, 0),
                                      child: TextFormField(
                                        controller: firstName,
                                        autofocus: false,
                                        obscureText: false,
                                        decoration: InputDecoration(
                                          isDense: true,
                                          hintText: 'First Name',
                                          hintStyle: const TextStyle(
                                            fontFamily: 'Google Sans',
                                            color: Color(0xFFC7C7C7),
                                            fontSize: 18,
                                            letterSpacing: 0.0,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: Color(0xFFEEEEEF),
                                              width: 0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: Color(0xFFEEEEEF),
                                              width: 0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          errorBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: Color(0xFFEEEEEF),
                                              width: 0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          focusedErrorBorder:
                                              OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: Color(0xFFEEEEEF),
                                              width: 0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          filled: true,
                                          fillColor: const Color(0xFFEEEEEF),
                                          contentPadding:
                                              const EdgeInsetsDirectional
                                                  .fromSTEB(18, 15, 18, 15),
                                        ),
                                        style: const TextStyle(
                                          fontFamily: 'Google Sans',
                                          color: Color(0xFF333333),
                                          fontSize: 18,
                                          letterSpacing: 0.0,
                                        ),
                                        cursorColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  0, 10, 0, 0),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding:
                                          const EdgeInsetsDirectional.fromSTEB(
                                              24, 0, 24, 0),
                                      child: TextFormField(
                                        controller: lastName,
                                        autofocus: false,
                                        obscureText: false,
                                        decoration: InputDecoration(
                                          isDense: true,
                                          hintText: 'Last Name',
                                          hintStyle: const TextStyle(
                                            fontFamily: 'Google Sans',
                                            color: Color(0xFFC7C7C7),
                                            fontSize: 18,
                                            letterSpacing: 0.0,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: Color(0xFFEEEEEF),
                                              width: 0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: Color(0xFFEEEEEF),
                                              width: 0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          errorBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: Color(0xFFEEEEEF),
                                              width: 0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          focusedErrorBorder:
                                              OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: Color(0xFFEEEEEF),
                                              width: 0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          filled: true,
                                          fillColor: const Color(0xFFEEEEEF),
                                          contentPadding:
                                              const EdgeInsetsDirectional
                                                  .fromSTEB(18, 15, 18, 15),
                                        ),
                                        style: const TextStyle(
                                          fontFamily: 'Google Sans',
                                          color: Color(0xFF333333),
                                          fontSize: 18,
                                          letterSpacing: 0.0,
                                        ),
                                        cursorColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Padding(
                              padding:
                                  EdgeInsetsDirectional.fromSTEB(28, 30, 24, 0),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Text(
                                    'Account Information',
                                    style: TextStyle(
                                      fontFamily: 'Google Sans',
                                      color: Color(0xFF333333),
                                      fontSize: 18,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  0, 10, 0, 0),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding:
                                          const EdgeInsetsDirectional.fromSTEB(
                                              24, 0, 24, 0),
                                      child: TextFormField(
                                        controller: email,
                                        autofocus: false,
                                        obscureText: false,
                                        decoration: InputDecoration(
                                          isDense: true,
                                          hintText: 'Email',
                                          hintStyle: const TextStyle(
                                            fontFamily: 'Google Sans',
                                            color: Color(0xFFC7C7C7),
                                            fontSize: 18,
                                            letterSpacing: 0.0,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: Color(0xFFEEEEEF),
                                              width: 0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: Color(0xFFEEEEEF),
                                              width: 0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          errorBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: Color(0xFFEEEEEF),
                                              width: 0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          focusedErrorBorder:
                                              OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: Color(0xFFEEEEEF),
                                              width: 0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          filled: true,
                                          fillColor: const Color(0xFFEEEEEF),
                                          contentPadding:
                                              const EdgeInsetsDirectional
                                                  .fromSTEB(18, 15, 18, 15),
                                        ),
                                        style: const TextStyle(
                                          fontFamily: 'Google Sans',
                                          color: Color(0xFF333333),
                                          fontSize: 18,
                                          letterSpacing: 0.0,
                                        ),
                                        cursorColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  0, 12, 0, 0),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding:
                                          const EdgeInsetsDirectional.fromSTEB(
                                              24, 0, 24, 0),
                                      child: TextFormField(
                                        controller: password,
                                        autofocus: false,
                                        obscureText: !showPassword,
                                        decoration: InputDecoration(
                                          isDense: true,
                                          hintText: 'Password',
                                          hintStyle: const TextStyle(
                                            fontFamily: 'Google Sans',
                                            color: Color(0xFFC7C7C7),
                                            fontSize: 18,
                                            letterSpacing: 0.0,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: Color(0xFFEEEEEF),
                                              width: 0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: Color(0xFFEEEEEF),
                                              width: 0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          errorBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: Color(0xFFEEEEEF),
                                              width: 0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          focusedErrorBorder:
                                              OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: Color(0xFFEEEEEF),
                                              width: 0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          filled: true,
                                          fillColor: const Color(0xFFEEEEEF),
                                          contentPadding:
                                              const EdgeInsetsDirectional
                                                  .fromSTEB(18, 15, 18, 15),
                                          suffixIcon: InkWell(
                                            onTap: () => setState(() {
                                              showPassword = !showPassword;
                                            }),
                                            child: Icon(
                                              showPassword
                                                  ? Icons.visibility_outlined
                                                  : Icons
                                                      .visibility_off_outlined,
                                              color: const Color(0xFFC7C7C7),
                                              size: 24,
                                            ),
                                          ),
                                        ),
                                        style: const TextStyle(
                                          fontFamily: 'Google Sans',
                                          color: Color(0xFF333333),
                                          fontSize: 18,
                                          letterSpacing: 0.0,
                                        ),
                                        cursorColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  0, 12, 0, 0),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding:
                                          const EdgeInsetsDirectional.fromSTEB(
                                              24, 0, 24, 0),
                                      child: TextFormField(
                                        controller: confirmPassword,
                                        autofocus: false,
                                        obscureText: !showConfirmPassword,
                                        decoration: InputDecoration(
                                          isDense: true,
                                          hintText: 'Confirm Password',
                                          hintStyle: const TextStyle(
                                            fontFamily: 'Google Sans',
                                            color: Color(0xFFC7C7C7),
                                            fontSize: 18,
                                            letterSpacing: 0.0,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: Color(0xFFEEEEEF),
                                              width: 0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: Color(0xFFEEEEEF),
                                              width: 0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          errorBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: Color(0xFFEEEEEF),
                                              width: 0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          focusedErrorBorder:
                                              OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: Color(0xFFEEEEEF),
                                              width: 0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          filled: true,
                                          fillColor: const Color(0xFFEEEEEF),
                                          contentPadding:
                                              const EdgeInsetsDirectional
                                                  .fromSTEB(18, 15, 18, 15),
                                          suffixIcon: InkWell(
                                            onTap: () => setState(() {
                                              showConfirmPassword =
                                                  !showConfirmPassword;
                                            }),
                                            child: Icon(
                                              showConfirmPassword
                                                  ? Icons.visibility_outlined
                                                  : Icons
                                                      .visibility_off_outlined,
                                              color: const Color(0xFFC7C7C7),
                                              size: 24,
                                            ),
                                          ),
                                        ),
                                        style: const TextStyle(
                                          fontFamily: 'Google Sans',
                                          color: Color(0xFF333333),
                                          fontSize: 18,
                                          letterSpacing: 0.0,
                                        ),
                                        cursorColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  30, 18, 25, 0),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Container(
                                    width: 17,
                                    height: 17,
                                    decoration: BoxDecoration(
                                      color: agreedTOS
                                          ? const Color(0xFF3B58F4)
                                          : Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF8B8B8B),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Align(
                                      alignment:
                                          const AlignmentDirectional(0, 0),
                                      child: IconButton(
                                        icon: Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: agreedTOS ? 12 : 0,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            agreedTOS = !agreedTOS;
                                          });
                                        },
                                        padding: const EdgeInsetsDirectional
                                            .fromSTEB(0, 0, 0, 0),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding:
                                        const EdgeInsetsDirectional.fromSTEB(
                                            8, 0, 0, 0),
                                    child: RichText(
                                      textScaler:
                                          MediaQuery.of(context).textScaler,
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: 'I accept the ',
                                            style: const TextStyle(
                                              fontFamily: 'Google Sans',
                                            ),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () {
                                                setState(() {
                                                  agreedTOS = !agreedTOS;
                                                });
                                              },
                                          ),
                                          TextSpan(
                                            text: 'Terms of Service',
                                            style: const TextStyle(
                                              fontFamily: 'Google Sans',
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () {
                                                _launchURL(
                                                    'https://sites.google.com/wesimplex.com/hello/terms-of-service?authuser=1');
                                              },
                                          )
                                        ],
                                        style: const TextStyle(
                                          fontFamily: 'Google Sans',
                                          color: Color(0xFF8B8B8B),
                                          fontWeight: FontWeight.normal,
                                          fontSize: 18,
                                        ),
                                      ),
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  30, 8, 25, 0),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Container(
                                    width: 17,
                                    height: 17,
                                    decoration: BoxDecoration(
                                      color: agreedPrivacy
                                          ? const Color(0xFF3B58F4)
                                          : Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF8B8B8B),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Align(
                                      alignment:
                                          const AlignmentDirectional(0, 0),
                                      child: IconButton(
                                        icon: Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: agreedPrivacy ? 12 : 0,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            agreedPrivacy = !agreedPrivacy;
                                          });
                                        },
                                        padding: const EdgeInsetsDirectional
                                            .fromSTEB(0, 0, 0, 0),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding:
                                        const EdgeInsetsDirectional.fromSTEB(
                                            8, 0, 0, 0),
                                    child: RichText(
                                      textScaler:
                                          MediaQuery.of(context).textScaler,
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: 'I accept the ',
                                            style: const TextStyle(
                                              fontFamily: 'Google Sans',
                                            ),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () {
                                                setState(() {
                                                  agreedPrivacy =
                                                      !agreedPrivacy;
                                                });
                                              },
                                          ),
                                          TextSpan(
                                            text: 'Privacy Policy',
                                            style: const TextStyle(
                                              fontFamily: 'Google Sans',
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () {
                                                _launchURL(
                                                    'https://sites.google.com/wesimplex.com/hello/privacy-policy?authuser=1');
                                              },
                                          )
                                        ],
                                        style: const TextStyle(
                                          fontFamily: 'Google Sans',
                                          color: Color(0xFF8B8B8B),
                                          fontWeight: FontWeight.normal,
                                          fontSize: 18,
                                        ),
                                      ),
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  24, 24, 24, 0),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () async {
                                        if (password.text !=
                                            confirmPassword.text) {
                                          Toasts.toast(
                                              "Passwords Do Not Match", true);
                                        } else if ([
                                          firstName.text,
                                          lastName.text,
                                          email.text,
                                          password.text
                                        ].contains("")) {
                                          Toasts.toast(
                                              "Please Fill Out All Fields",
                                              true);
                                        } else if (!emailRegExp
                                            .hasMatch(email.text)) {
                                          Toasts.toast("Email Invalid", true);
                                        } else if (!agreedPrivacy ||
                                            !agreedTOS) {
                                          Toasts.toast(
                                              "Please Agree to the TOS and Privacy Policy",
                                              true);
                                        } else if (password.text.length < 6) {
                                          Toasts.toast(
                                              "Password should be at least 6 characters",
                                              true);
                                        } else {
                                          try {
                                            await _auth
                                                .createUserWithEmailAndPassword(
                                                    email: email.text,
                                                    password: password.text);

                                            await _auth
                                                .signInWithEmailAndPassword(
                                                    email: email.text,
                                                    password: password.text);

                                            String id = _auth.currentUser!.uid;
                                            UserModel user = UserModel(
                                                id: id,
                                                email: email.text,
                                                profilePic: "",
                                                name: firstName.text +
                                                    " " +
                                                    lastName.text,
                                                pastEvents: [],
                                                compEvents: [],
                                                grade: 12,
                                                isExec: false,
                                                approved: true,
                                                openedAppSinceApproved: false,
                                                chapters: [],
                                                currentChapter: "",
                                                topicsSubscribed: []);

                                            UserModel.writeUser(user);
                                            AppInfo.currentUser = user;

                                            AppInfo.loadData();

                                            Navigator.pushAndRemoveUntil(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      const ChapterSelectWidget()),
                                              (route) =>
                                                  false, // This condition removes all previous routes
                                            );
                                          } on FirebaseAuthException catch (e) {
                                            if (e.code ==
                                                'email-already-in-use') {
                                              Toasts.toast(
                                                  'The email address is already in use.',
                                                  true);
                                            } else if (e.code ==
                                                'invalid-email') {
                                              Toasts.toast(
                                                  'Invalid email format.',
                                                  true);
                                            } else {
                                              Toasts.toast(
                                                  'Unexpected error: ${e.code}',
                                                  true);
                                            }
                                          }
                                        }
                                      },
                                      child: Container(
                                        width: 100,
                                        height: 46,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF3B58F4),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Align(
                                          alignment: AlignmentDirectional(0, 0),
                                          child: Text(
                                            'Done',
                                            style: TextStyle(
                                              fontFamily: 'Google Sans',
                                              color: Colors.white,
                                              fontSize: 20,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }
}
