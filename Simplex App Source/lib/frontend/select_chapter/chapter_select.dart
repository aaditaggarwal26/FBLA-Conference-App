import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../../backend/models.dart';
import '../nav/navigation.dart';
import '../profile/profile_page.dart';
import 'chapter_card.dart';
import 'join_chapter.dart';
import '../../app_info.dart';

// import '../../backend/models.dart';

class ChapterSelectWidget extends StatefulWidget {
  const ChapterSelectWidget({super.key});

  @override
  State<ChapterSelectWidget> createState() => _ChapterSelectWidgetState();
}

class _ChapterSelectWidgetState extends State<ChapterSelectWidget> {
  List<ChapterCard> chapterCards = [];
  bool cardsLoaded = false;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<String> firstLast = AppInfo.currentUser.name.split(' ');

  @override
  void initState() {
    loadCards();
    AnnouncementModel.configureFirebaseMessaging();
    super.initState();
  }

  Future<void> _selectChapter(String chapterId) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String userId = user.uid;

      FirebaseMessaging.instance.subscribeToTopic(chapterId);

      await _firestore.collection('users').doc(userId).update({
        'currentChapter': chapterId,
      });
      AppInfo.currentUser.currentChapter = chapterId;

      await AppInfo.loadData();
    } else {
      print("No user is currently logged in.");
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> loadCards() async {
    chapterCards = await ChapterCard.getCards();
    setState(() {
      cardsLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: const Color(0xFFF5F6F7),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const JoinChapterWidget()),
          );
        },
        backgroundColor: const Color(0xFF3B58F4),
        elevation: 8,
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 32,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              width: MediaQuery.sizeOf(context).width,
              height: 200,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0x14556EF4), Color(0x7EF5F6F7)],
                  stops: [0, 1],
                  begin: AlignmentDirectional(0, -1),
                  end: AlignmentDirectional(0, 1),
                ),
              ),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(24, 65, 24, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            // REPLACE WITH SIMPLEX CHAPTER LOGO
                            Container(
                              width: 24,
                              height: 24,
                              clipBehavior: Clip.antiAlias,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                              ),
                              child: Image.asset(
                                'assets/images/appicon.png',
                                fit: BoxFit.cover,
                              ),
                            ),

                            const Padding(
                              padding:
                                  EdgeInsetsDirectional.fromSTEB(6, 0, 0, 0),
                              child: Text(
                                'Simplex Chapter',
                                style: TextStyle(
                                  fontFamily: 'Google Sans',
                                  color: Colors.black,
                                  fontSize: 15,
                                  letterSpacing: 0.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          width: 46,
                          height: 46,
                          child: Stack(
                            children: [
                              Align(
                                alignment: const AlignmentDirectional(-1, -1),
                                child: InkWell(
                                  onTap: () {
                                    Profile.showProfilePage(context);
                                  },
                                  child: Container(
                                    width: 43,
                                    height: 43,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF526BF4),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF051989),
                                        width: 1,
                                      ),
                                    ),
                                    child: Align(
                                      alignment:
                                          const AlignmentDirectional(0, 0),
                                      child: Text(
                                        firstLast[0][0] + firstLast[1][0],
                                        style: const TextStyle(
                                          fontFamily: 'Google Sans',
                                          color: Colors.white,
                                          fontSize: 15,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Align(
                                  alignment: const AlignmentDirectional(1, 1),
                                  child: GestureDetector(
                                    onTap: () {
                                      Profile.showProfilePage(context);
                                    },
                                    child: Container(
                                      width: 19,
                                      height: 19,
                                      decoration: const BoxDecoration(
                                        color: Color(0x99000000),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Align(
                                        alignment: AlignmentDirectional(0, 0),
                                        child: Icon(
                                          Icons.more_vert,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                  )),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Flexible(
                              child: AutoSizeText(
                                'Hi ${firstLast[0]}!',
                                maxLines: 1,
                                style: const TextStyle(
                                  fontFamily: 'Google Sans',
                                  color: Colors.black,
                                  fontSize: 35,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Text(
                              '👋 Welcome Back',
                              style: TextStyle(
                                fontFamily: 'Google Sans',
                                color: Colors.black,
                                fontSize: 13,
                                letterSpacing: 0.0,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(24, 30, 24, 0),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Padding(
                        padding:
                            const EdgeInsetsDirectional.fromSTEB(8, 0, 0, 0),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            const Text(
                              'YOUR GROUPS',
                              style: TextStyle(
                                fontFamily: 'Google Sans',
                                color: Colors.black,
                                fontSize: 20,
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  12, 0, 0, 0),
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFD90000),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (cardsLoaded && chapterCards.isNotEmpty)
                        ...chapterCards.map((card) => GestureDetector(
                              onTap: () async {
                                await _selectChapter(card.clubID);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const Navigation(pIndex: 0),
                                  ),
                                );
                              },
                              child: card,
                            ))
                      else if (cardsLoaded && chapterCards.isEmpty)
                        const Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(0, 20, 0, 0),
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Text(
                                'You haven\'t joined any chapters yet.',
                                style: TextStyle(
                                  fontFamily: 'Google Sans',
                                  color: Colors.black,
                                  fontSize: 16,
                                  letterSpacing: 0.0,
                                ),
                              ),
                              SizedBox(height: 10),
                            ],
                          ),
                        )
                      else
                        const CircularProgressIndicator(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
