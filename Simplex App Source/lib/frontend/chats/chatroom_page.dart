// ignore_for_file: must_be_immutable, no_logic_in_create_state

import 'dart:async';

// import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:simplex_chapter_x/frontend/toast.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app_info.dart';
import '../../backend/models.dart';
import '../flutter_flow/flutter_flow_theme.dart';
import '../nav/navigation.dart';
import '../select_chapter/chapter_card.dart';

class ChatroomWidget extends StatefulWidget {
  AnnouncementModel a;
  ChatroomWidget({super.key, required this.a});

  @override
  State<ChatroomWidget> createState() => _ChatroomWidgetState(a);
}

class _ChatroomWidgetState extends State<ChatroomWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late TextEditingController text;
  late FocusNode focus;
  StreamSubscription<DocumentSnapshot>? _streamSubscription;
  List<Widget> announcementWidgets = [];
  Timer? timer;
  bool dataLoaded = false;
  List<Widget> items = [];
  AnnouncementModel a;
  _ChatroomWidgetState(this.a) {
    _setupMessageListener();
  }

  @override
  void initState() {
    super.initState();
    text = TextEditingController();
    focus = FocusNode();
  }

  @override
  void dispose() {
    super.dispose();
    _streamSubscription!.cancel();
    text.dispose();
    focus.dispose();
  }

  Future<void> getMessages() async {
    bool todayFound = false;
    bool yesterdayFound = false;
    items = [const SizedBox(height: 25)];

    if (a.msgs.isEmpty) {
      items.add(Padding(
        padding: const EdgeInsets.only(top: 100),
        child: Text(
          'No messages yet',
          style: FlutterFlowTheme.of(context).bodyMedium.override(
                fontFamily: 'Google Sans',
                color: Colors.grey,
                fontSize: 16,
                letterSpacing: 0.0,
                fontWeight: FontWeight.w500,
                useGoogleFonts: false,
              ),
          textAlign: TextAlign.center,
        ),
      ));
      items.add(const SizedBox(height: 100));
      return;
    }

    for (int i = 0; i < a.msgs.length; i++) {
      Map<String, String> m = a.msgs[i];

      // Extracting message details
      String senderName = m['senderName']!;
      String text = m['text']!;
      String timestampString = m['timestamp']!;

      // Parse the timestamp and convert to local time
      DateTime timestamp = DateTime.parse(timestampString).toLocal();
      DateTime now = DateTime.now();

      // Create initials from senderName
      List<String> nameParts = senderName.split(' ');
      String initials = '';
      if (nameParts.length >= 2) {
        initials = nameParts[0][0] + nameParts[1][0]; // First and last initials
      } else if (nameParts.isNotEmpty) {
        initials = nameParts[0][0]; // In case there's only one name
      }

      // Check if timestamp is today, yesterday, or before
      if (isSameDay(timestamp, now) && !todayFound) {
        todayFound = true;
        // It's today
        items.add(buildDateLabel(context, 'Today'));
      } else if (isSameDay(timestamp, now.subtract(const Duration(days: 1))) &&
          !yesterdayFound) {
        yesterdayFound = true;
        // It's yesterday
        items.add(buildDateLabel(context, 'Yesterday'));
      }

      // Format timestamp
      String formattedTime;
      if (isSameDay(timestamp, now) ||
          isSameDay(timestamp, now.subtract(const Duration(days: 1)))) {
        formattedTime = DateFormat.jm()
            .format(timestamp); // Only show time for today and yesterday
      } else {
        formattedTime = DateFormat('M/d/yy, h:mm a')
            .format(timestamp); // Show full date and time for older messages
      }

      List<TextSpan> msgText = [];

      // Use RegExp to match any sequence of words, spaces, newlines, and tabs
      RegExp exp = RegExp(r'(\s+|https:\/\/[^\s]+|\S+)', multiLine: true);
      Iterable<RegExpMatch> matches = exp.allMatches(text);

      for (final match in matches) {
        String token = match.group(0)!; // Get the matched token

        // Check if the token starts with 'https://'
        if (token.startsWith('https://')) {
          bool canlaunch;
          try {
            final Uri? uri = Uri.tryParse(token); // Attempt to parse the URL

            if (uri != null &&
                (uri.isScheme('https') || uri.isScheme('http'))) {
              canlaunch = true;
            } else {
              canlaunch = false;
            }
          } catch (e) {
            canlaunch = false;
          }
          if (canlaunch) {
            msgText.add(
              TextSpan(
                text: token,
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontFamily: 'Google Sans',
                      fontSize: 15,
                      letterSpacing: 0.0,
                      useGoogleFonts: false,
                      color: const Color.fromARGB(255, 41, 41, 255),
                      decoration: TextDecoration.underline,
                    ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () async {
                    final uri = Uri.parse(token);
                    try {
                      await launchUrl(uri);
                      // ignore: empty_catches
                    } catch (e) {}
                  },
              ),
            );
          } else {
            msgText.add(
              TextSpan(
                text: token,
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontFamily: 'Google Sans',
                      fontSize: 15,
                      letterSpacing: 0.0,
                      useGoogleFonts: false,
                    ),
              ),
            );
          }
        } else {
          // Add regular text with the normal style, including whitespace
          msgText.add(
            TextSpan(
              text: token,
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    fontFamily: 'Google Sans',
                    fontSize: 15,
                    letterSpacing: 0.0,
                    useGoogleFonts: false,
                  ),
            ),
          );
        }
      }

      // Add message UI widget for each message
      items.add(Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(24, 12, 24, 0),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: a.color,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initials,
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'Google Sans',
                        color: const Color(0xFFF8FFF1),
                        fontSize: 20,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.bold,
                        useGoogleFonts: false,
                      ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 0, 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsetsDirectional.fromSTEB(16, 15, 16, 14),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          senderName,
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    fontFamily: 'Google Sans',
                                    color: a.color,
                                    fontSize: 15,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.bold,
                                    useGoogleFonts: false,
                                  ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsetsDirectional.fromSTEB(0, 5, 0, 0),
                          child:
                              SelectableText.rich(TextSpan(children: msgText)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ));

      // Add timestamp below the message
      items.add(Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(0, 8, 10, 0),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              formattedTime,
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    fontFamily: 'Google Sans',
                    color: const Color(0x34333333),
                    fontSize: 12,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w500,
                    useGoogleFonts: false,
                  ),
            ),
          ],
        ),
      ));
    }
    items.add(const SizedBox(height: 100));
  }

  void _setupMessageListener() {
    _streamSubscription = FirebaseFirestore.instance
        .collection('chapters')
        .doc(AppInfo.currentUser.currentChapter)
        .collection('announcements')
        .doc(a.id)
        .snapshots()
        .listen((documentSnapshot) {
      if (documentSnapshot.exists) {
        dataLoaded = false;
        setState(() {});
        a = AnnouncementModel.fromDocumentSnapshot(
            documentSnapshot, AppInfo.currentUser.currentChapter);
        getMessages().then(
          (value) {
            dataLoaded = true;
            setState(() {});
          },
        );
      }
    });
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // Build a label for 'Today' or 'Yesterday'
  Padding buildDateLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0, 20, 0, 0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  fontFamily: 'Google Sans',
                  color: const Color(0xFFB0B0B0),
                  fontSize: 15,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.bold,
                  useGoogleFonts: false,
                ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 200),
            reverseTransitionDuration: const Duration(milliseconds: 200),
            pageBuilder: (context, animation, secondaryAnimation) =>
                const Navigation(pIndex: 1),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              const begin = Offset(-1.0, 0.0);
              const end = Offset.zero;
              final tween = Tween(begin: begin, end: end);
              final offsetAnimation = animation.drive(tween);

              return SlideTransition(
                position: offsetAnimation,
                child: child,
              );
            },
          ),
        );
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: const Color(0xFFF5F6F7),
        body: Container(
          width: MediaQuery.sizeOf(context).width,
          height: MediaQuery.sizeOf(context).height * 1,
          decoration: const BoxDecoration(
            color: Color(0xFFF5F6F7),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                width: MediaQuery.sizeOf(context).width,
                height: 144,
                decoration: BoxDecoration(
                  color: a.color,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(20, 0, 30, 20),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  0, 0, 12, 0),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  InkWell(
                                    onTap: () {
                                      Navigator.of(context).pushReplacement(
                                        PageRouteBuilder(
                                          transitionDuration:
                                              const Duration(milliseconds: 200),
                                          reverseTransitionDuration:
                                              const Duration(milliseconds: 200),
                                          pageBuilder: (context, animation,
                                                  secondaryAnimation) =>
                                              const Navigation(pIndex: 1),
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
                                      );
                                    },
                                    child: const Icon(
                                      Icons.arrow_back_ios_rounded,
                                      color: Color(0xafffffff),
                                      size: 24,
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding:
                                          const EdgeInsetsDirectional.fromSTEB(
                                              10, 0, 0, 0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.max,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'BROADCAST CHANNEL',
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  fontFamily: 'Google Sans',
                                                  color:
                                                      const Color(0xafffffff),
                                                  fontSize: 13,
                                                  letterSpacing: 0.0,
                                                  fontWeight: FontWeight.bold,
                                                  useGoogleFonts: false,
                                                ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsetsDirectional
                                                .fromSTEB(0, 5, 0, 0),
                                            child: Text(
                                              a.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: FlutterFlowTheme.of(
                                                      context)
                                                  .bodyMedium
                                                  .override(
                                                    fontFamily: 'Google Sans',
                                                    color: Colors.white,
                                                    fontSize: 25,
                                                    letterSpacing: 0.0,
                                                    fontWeight: FontWeight.bold,
                                                    useGoogleFonts: false,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // !AppInfo.currentUser.topicsSubscribed
                          //             .contains(a.id) &&
                          //         AppInfo.currentUser.currentChapter != a.id
                          //     ? InkWell(
                          //         onTap: () {
                          //           AppInfo.currentUser
                          //               .addSubscribedTopic(a.id);
                          //           a.subscribeNotif();
                          //           setState(() {});
                          //         },
                          //         child: Container(
                          //           width: 36,
                          //           height: 36,
                          //           decoration: const BoxDecoration(
                          //             color: Color(0x4C000000),
                          //             shape: BoxShape.circle,
                          //           ),
                          //           child: const Center(
                          //             child: Icon(
                          //               Icons.add,
                          //               color: Colors.white,
                          //               size: 24,
                          //             ),
                          //           ),
                          //         ),
                          //       )
                          //     : const SizedBox(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Align(
                        alignment: const AlignmentDirectional(0, -1),
                        child: SingleChildScrollView(
                            reverse: true,
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              children: !dataLoaded
                                  ? [
                                      const Padding(
                                          padding: EdgeInsets.only(top: 30),
                                          child: CircularProgressIndicator(
                                              color: Colors.black))
                                    ]
                                  : items,
                            ))),
                    AppInfo.isAdmin
                        ? Align(
                            alignment: const AlignmentDirectional(0, 1),
                            child: Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  24, 0, 24, 40),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Expanded(
                                    child: Align(
                                      alignment:
                                          const AlignmentDirectional(0, 1),
                                      child: TextFormField(
                                        controller: text,
                                        focusNode: focus,
                                        autofocus: false,
                                        obscureText: false,
                                        decoration: InputDecoration(
                                          isDense: true,
                                          hintText: 'Enter text here...',
                                          hintStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .override(
                                                    fontFamily: 'Google Sans',
                                                    color:
                                                        const Color(0xFFA6A6A6),
                                                    letterSpacing: 0.0,
                                                    useGoogleFonts: false,
                                                  ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: Color(0x00000000),
                                              width: 0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(44),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: Color(0x00000000),
                                              width: 0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(44),
                                          ),
                                          errorBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: Color(0x00000000),
                                              width: 0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(44),
                                          ),
                                          focusedErrorBorder:
                                              OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: Color(0x00000000),
                                              width: 0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(44),
                                          ),
                                          filled: true,
                                          fillColor: Colors.white,
                                          contentPadding:
                                              const EdgeInsetsDirectional
                                                  .fromSTEB(15, 8, 15, 8),
                                          prefixIcon: const Icon(
                                            Icons.add,
                                            color: Color(0xFFA6A6A6),
                                            size: 20,
                                          ),
                                          suffixIcon: InkWell(
                                              onTap: () async {
                                                await _sendMessage();
                                              },
                                              child: const Icon(
                                                Icons.send,
                                                color: Color(0xFFA6A6A6),
                                                size: 20,
                                              )),
                                        ),
                                        style: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              fontFamily: 'Google Sans',
                                              color: const Color(0xFF333333),
                                              letterSpacing: 0.0,
                                              useGoogleFonts: false,
                                            ),
                                        maxLines: null,
                                        cursorColor:
                                            FlutterFlowTheme.of(context)
                                                .primaryText,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : const SizedBox(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (text.text.isEmpty) {
      Toasts.toast("Message text is empty.", true);
    } else {
      a.msgs.add({
        'senderName': AppInfo.currentUser.name,
        'timestamp': DateTime.now().toUtc().toString(),
        'text': text.text,
      });

      await AnnouncementModel.updateAnnouncementById(a.chapterid, a.id, a.msgs);
      DocumentSnapshot chapter =
          await AppInfo.database.collection("chapters").doc(a.chapterid).get();
      ChapterCard c = ChapterCard.fromDocumentSnapshot(chapter);
      _sendNotification(text.text, "", a.id, c.name);

      Toasts.toast("Message sent!", false);
      text.text = "";
      setState(() {});
    }
    FocusScope.of(context).unfocus();
  }

  void _sendNotification(String msg, String img, String topic, String title) {
    HttpsCallable callable =
        FirebaseFunctions.instance.httpsCallable('sendNotif');
    callable.call(<String, dynamic>{
      'topic': topic,
      'title': title,
      'body': msg,
      "image": img,
    });
  }
}
