import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:simplex_chapter_x/frontend/chats/chats_card.dart';

import '../../app_info.dart';
import '../../backend/models.dart';
import '../flutter_flow/flutter_flow_theme.dart';

import 'package:flutter/material.dart';

import '../nav/navigation.dart';
import '../toast.dart';

class JoinChatsWidget extends StatefulWidget {
  const JoinChatsWidget({super.key});

  @override
  State<JoinChatsWidget> createState() => _JoinChatsWidgetState();
}

class _JoinChatsWidgetState extends State<JoinChatsWidget> {
  List<String> firstLast = AppInfo.currentUser.name.split(' ');
  final scaffoldKey = GlobalKey<ScaffoldState>();

  bool dataLoaded = false;
  List<AnnouncementModel> groups = [];
  StreamSubscription<DocumentSnapshot>? _streamSubscription;
  List<Widget> subscribedChats = [];
  List<Widget> unsubscribedChats = [];

  _JoinChatsWidgetState() {
    _setupMessageListener();
  }

  @override
  void initState() {
    super.initState();
    log(AppInfo.currentUser.isExec.toString());
  }

  void updateCards() {
    setState(() {});
  }

  void _setupMessageListener() {
    _streamSubscription = FirebaseFirestore.instance
        .collection('chapters')
        .doc(AppInfo.currentUser.currentChapter)
        .snapshots()
        .listen((documentSnapshot) {
      if (documentSnapshot.exists) {
        dataLoaded = false;
        setState(() {});
        AnnouncementModel.getAnnouncements(AppInfo.currentUser.currentChapter)
            .then(
          (value) {
            groups = value;
            groups.sort(
              (a, b) {
                if (a.msgs.isEmpty && b.msgs.isEmpty) {
                  return a.name.compareTo(b.name);
                } else if (a.msgs.isEmpty) {
                  return 1;
                } else if (b.msgs.isEmpty) {
                  return -1;
                } else {
                  String timestamp1 = a.msgs.last['timestamp']!;
                  String timestamp2 = b.msgs.last['timestamp']!;
                  return DateTime.parse(timestamp2)
                      .compareTo(DateTime.parse(timestamp1));
                }
              },
            );
            dataLoaded = true;
            setState(() {});
          },
        );
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _streamSubscription!.cancel();
  }

  @override
  Widget build(BuildContext context) {
    unsubscribedChats = [];
    for (AnnouncementModel a in groups) {
      if (!AppInfo.currentUser.topicsSubscribed.contains(a.id) &&
          AppInfo.currentUser.currentChapter != a.id) {
        unsubscribedChats.add(ChatsCard(
          a: a,
          onPress: updateCards,
          onTap: () {
            if (AppInfo.currentUser.topicsSubscribed.contains(a.id)) {
              AppInfo.currentUser.removeSubscribedTopic(a.id);
              a.unsubscribeNotif();
            } else {
              AppInfo.currentUser.addSubscribedTopic(a.id);
              a.subscribeNotif();
            }

            Toasts.toast('Joined Channel!', false);
            updateCards();
          },
        ));
      }
    }
    List<Widget> otherItems = unsubscribedChats;
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
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(24, 65, 24, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 4, 0),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                0, 6, 0, 0),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Available Channels',
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        fontFamily: 'Google Sans',
                                        color: const Color(0xFF333333),
                                        fontSize: 28,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.w500,
                                        useGoogleFonts: false,
                                      ),
                                ),
                                // const Padding(
                                //   padding: EdgeInsetsDirectional.fromSTEB(
                                //       15, 0, 0, 0),
                                //   child: Icon(
                                //     Icons.help_outline,
                                //     color: Color(0xFF98989D),
                                //     size: 17,
                                //   ),
                                // ),
                              ],
                            ),
                          ),
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
                                  transitionsBuilder: (context, animation,
                                      secondaryAnimation, child) {
                                    const begin = Offset(-1.0, 0.0);
                                    const end = Offset.zero;
                                    final tween = Tween(begin: begin, end: end);
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
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                color: Color(0x59000000),
                                shape: BoxShape.circle,
                              ),
                              child: const Align(
                                alignment: AlignmentDirectional(0, 0),
                                child: Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
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
              Padding(
                  padding: const EdgeInsets.only(top: 15, left: 24, right: 24),
                  child: Column(
                    children: otherItems,
                  )),
              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
    );
  }
}
