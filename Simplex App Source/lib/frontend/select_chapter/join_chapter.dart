// import 'dart:developer';

import 'package:auto_size_text/auto_size_text.dart';
// import 'package:simplex_chapter_x/create_chapter.dart';

// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_core/firebase_core.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:simplex_chapter_x/app_info.dart';
import 'package:simplex_chapter_x/backend/models.dart';
import 'package:simplex_chapter_x/frontend/select_chapter/chapter_select.dart';
import 'package:simplex_chapter_x/frontend/toast.dart';

import '../nav/navigation.dart';

class JoinChapterWidget extends StatefulWidget {
  const JoinChapterWidget({super.key});

  @override
  State<JoinChapterWidget> createState() => _JoinChapterWidgetState();
}

class _JoinChapterWidgetState extends State<JoinChapterWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late TextEditingController pin;
  String enteredPin = '';
  bool joined = false;

  @override
  void initState() {
    super.initState();
    pin = TextEditingController();
  }

  @override
  void dispose() {
    // pin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      body: Container(
        width: MediaQuery.sizeOf(context).width,
        height: MediaQuery.sizeOf(context).height * 1,
        decoration: BoxDecoration(
          image: DecorationImage(
            fit: BoxFit.cover,
            image: Image.asset(
              'assets/images/join_chapter_bg.png',
            ).image,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(24, 65, 24, 0),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  InkWell(
                    onTap: () {
                      if (!joined) {
                        Navigator.pop(context);
                      } else {
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
                      width: 37,
                      height: 37,
                      decoration: const BoxDecoration(
                        color: Color(0x59000000),
                        shape: BoxShape.circle,
                      ),
                      child: const Align(
                        alignment: AlignmentDirectional(0, 0),
                        child: Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(40, 4, 40, 0),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  const Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      AutoSizeText(
                        'Enter join code:',
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
                  Padding(
                    padding: const EdgeInsets.only(right: 30),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          width: 250,
                          child: PinCodeTextField(
                            onChanged: (value) {
                              enteredPin =
                                  value; // Update the variable with the new value
                              // Perform any additional actions here, such as validation or updating UI
                            },
                            pinTheme: PinTheme(
                              shape: PinCodeFieldShape.underline,
                              activeColor: Colors.white,
                              inactiveColor:
                                  const Color.fromARGB(102, 255, 255, 255),
                              fieldWidth: 38,
                              borderWidth: 1,
                            ),
                            textStyle: const TextStyle(
                              fontFamily: 'Google Sans',
                              color: Colors.white,
                              fontSize: 44,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.w700,
                            ),
                            controller: pin,
                            cursorWidth: 1.5,
                            cursorColor: Colors.white,
                            showCursor: true,
                            appContext: context,
                            backgroundColor: Colors.transparent,
                            length: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 30, 40),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Material(
                    color: Colors.transparent,
                    elevation: 3,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: () async {
                        _joinChapter();
                      },
                      child: Container(
                        width: 58,
                        height: 58,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Align(
                          alignment: AlignmentDirectional(0, 0),
                          child: Icon(
                            Icons.arrow_forward,
                            color: Color(0xFF3B58F4),
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // ElevatedButton(
                  //   onPressed: () {
                  //     Navigator.pushReplacement(
                  //       context,
                  //       MaterialPageRoute(
                  //           builder: (context) => const CreateChapterPage()),
                  //     );
                  //   },
                  //   style: ElevatedButton.styleFrom(
                  //     minimumSize: const Size(50, 50),
                  //     shape: RoundedRectangleBorder(
                  //       borderRadius: BorderRadius.circular(25),
                  //     ),
                  //   ),
                  //   child: const Text(
                  //     'Create a Chapter Instead',
                  //     style: TextStyle(
                  //       fontFamily: 'Google Sans',
                  //       fontSize: 16,
                  //       fontWeight: FontWeight.w500,
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _joinChapter() async {
    try {
      DocumentSnapshot codeDoc =
          await AppInfo.database.collection('codes').doc('codes').get();
      Map<String, String> codes =
          (codeDoc.get("codes") as Map).cast<String, String>();
      if (!codes.containsKey(enteredPin)) {
        Fluttertoast.showToast(
          msg: "Code Does Not Exist",
          toastLength: Toast.LENGTH_SHORT,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      } else {
        String chapterID = codes[enteredPin] as String;

        DocumentSnapshot chapter =
            await AppInfo.database.collection('chapters').doc(chapterID).get();
        if ((chapter.get("users") as List<dynamic>)
            .contains(AppInfo.currentUser.id)) {
          Toasts.toast("Already Member of Chapter", true);
        } else {
          ChapterModel.joinChapter(chapterID);
          AppInfo.currentUser.currentChapter = chapterID;
          FirebaseMessaging.instance.subscribeToTopic(chapterID);

          await FirebaseFirestore.instance
              .collection('users')
              .doc(AppInfo.currentUser.id)
              .update({
            'currentChapter': chapterID,
          });

          await AppInfo.loadData();

          Fluttertoast.showToast(
            msg: "Chapter Joined!",
            toastLength: Toast.LENGTH_SHORT,
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 16.0,
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const Navigation(pIndex: 0),
            ),
          );

          joined = true;
        }
      }
    } catch (e) {
      print("Error: " + e.toString());
      Fluttertoast.showToast(
        msg: "Error",
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }
}
