import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:simplex_chapter_x/frontend/chats/chats_card.dart';
import 'package:simplex_chapter_x/frontend/chats/join_chats.dart';

import '../../app_info.dart';
import '../../backend/models.dart';
import '../flutter_flow/flutter_flow_theme.dart';

import 'package:flutter/material.dart';

import '../profile/profile_page.dart';
import 'chatroom_page.dart';

class ChatsWidget extends StatefulWidget {
  const ChatsWidget({super.key});

  @override
  State<ChatsWidget> createState() => _ChatsWidgetState();
}

class _ChatsWidgetState extends State<ChatsWidget> {
  List<String> firstLast = AppInfo.currentUser.name.split(' ');
  final scaffoldKey = GlobalKey<ScaffoldState>();

  bool dataLoaded = false;
  bool showUnsubscribed = false;
  List<AnnouncementModel> groups = [];
  StreamSubscription<DocumentSnapshot>? _streamSubscription;
  List<Widget> subscribedChats = [];
  List<Widget> unsubscribedChats = [];

  _ChatsWidgetState() {
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
    subscribedChats = [];
    unsubscribedChats = [];
    for (AnnouncementModel a in groups) {
      if (AppInfo.currentUser.topicsSubscribed.contains(a.id) ||
          a.id == AppInfo.currentUser.currentChapter) {
        subscribedChats.add(ChatsCard(
          a: a,
          onPress: updateCards,
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ChatroomWidget(a: a),
              ),
            );
          },
        ));
      } else {
        unsubscribedChats.add(ChatsCard(
          a: a,
          onPress: updateCards,
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ChatroomWidget(a: a),
              ),
            );
          },
        ));
      }
    }

    if (subscribedChats.isEmpty && dataLoaded) {
      subscribedChats.add(
        Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Text(
            'No subscribed channels',
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
        ),
      );
    }
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: Platform.isIOS ? 90 : 80),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const JoinChatsWidget()),
              );
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: const Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
      key: scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Modern gradient header
          SliverAppBar(
            expandedHeight: 180,
            pinned: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E3A8A), const Color(0xFF3B82F6)]
                        : [const Color(0xFF4B39EF), const Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Channels',
                              style: TextStyle(
                                fontFamily: 'Google Sans',
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                Profile.showProfilePage(context);
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    firstLast[0][0] + firstLast[1][0],
                                    style: const TextStyle(
                                      fontFamily: 'Google Sans',
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${subscribedChats.length} active channels',
                          style: TextStyle(
                            fontFamily: 'Google Sans',
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Content
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
            sliver: dataLoaded
                ? (subscribedChats.isEmpty
                    ? SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isDark
                                        ? [const Color(0xFF374151), const Color(0xFF4B5563)]
                                        : [const Color(0xFFE0E7FF), const Color(0xFFDDD6FE)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 60,
                                  color: isDark
                                      ? const Color(0xFF9CA3AF)
                                      : const Color(0xFF6366F1),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'No channels yet',
                                style: TextStyle(
                                  fontFamily: 'Google Sans',
                                  color: isDark ? Colors.white : const Color(0xFF0F1113),
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Tap the + button to join a channel',
                                style: TextStyle(
                                  fontFamily: 'Google Sans',
                                  color: isDark
                                      ? const Color(0xFF9CA3AF)
                                      : const Color(0xFF6B7280),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildListDelegate(subscribedChats),
                      ))
                : SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isDark ? const Color(0xFF6366F1) : const Color(0xFF4B39EF),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Loading channels...',
                            style: TextStyle(
                              fontFamily: 'Google Sans',
                              color: isDark
                                  ? const Color(0xFF9CA3AF)
                                  : const Color(0xFF6B7280),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
