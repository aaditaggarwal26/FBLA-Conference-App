import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../app_info.dart';
import '../events/show_events.dart';
import '../profile/profile_page.dart';
import '../select_chapter/chapter_select.dart';

class HomeWidget extends StatefulWidget {
  const HomeWidget({super.key});

  @override
  State<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  List<String> firstLast = AppInfo.currentUser.name.split(' ');
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime startDate = DateTime.now().toLocal();
  DateTime endDate = DateTime.now().toLocal();
  String logo = "";
  String name = "";

  @override
  void initState() {
    // AppInfo.loadData();

    setState(() {
      startDate = DateTime(startDate.year, startDate.month, startDate.day);

      endDate = startDate.add(const Duration(days: 365));

      endDate =
          DateTime(endDate.year, endDate.month, endDate.day + 1, 23, 59, 59);
    });

    AppInfo.database
        .collection('chapters')
        .doc(AppInfo.currentUser.currentChapter)
        .get()
        .then(
      (value) {
        setState(() {
          logo = value.get('logo') as String;
          name = value.get('name') as String;
        });
      },
    );

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Modern gradient header
          SliverAppBar(
            expandedHeight: 240,
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
                        // Top Bar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () async {
                                await _firestore
                                    .collection('users')
                                    .doc(AppInfo.currentUser.id)
                                    .update({'currentChapter': ""});
                                AppInfo.currentUser.currentChapter = "";
                                AppInfo.isAdmin = false;
                                AppInfo.isOwner = false;

                                Navigator.of(context).pushAndRemoveUntil(
                                  PageRouteBuilder(
                                    transitionDuration:
                                        const Duration(milliseconds: 200),
                                    reverseTransitionDuration:
                                        const Duration(milliseconds: 200),
                                    pageBuilder: (context, animation,
                                            secondaryAnimation) =>
                                        const ChapterSelectWidget(),
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
                                  (route) => false,
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.arrow_back_ios_new,
                                        color: Colors.white, size: 14),
                                    SizedBox(width: 4),
                                    Text(
                                      'Exit',
                                      style: TextStyle(
                                        fontFamily: 'Google Sans',
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
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
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF6366F1),
                                      const Color(0xFF8B5CF6)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
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
                        const Spacer(),
                        // Logo
                        if (logo.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: logo,
                                height: 28,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        // Chapter Name
                        Text(
                          name.isEmpty ? 'Loading...' : name,
                          style: const TextStyle(
                            fontFamily: 'Google Sans',
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Welcome back, ${firstLast[0]}!',
                          style: TextStyle(
                            fontFamily: 'Google Sans',
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Content
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 80),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Upcoming Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 24,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [const Color(0xFF3B82F6), const Color(0xFF8B5CF6)]
                                  : [const Color(0xFF4B39EF), const Color(0xFF7C3AED)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Upcoming Events',
                          style: TextStyle(
                            fontFamily: 'Google Sans',
                            color: isDark ? Colors.white : const Color(0xFF0F1113),
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Events List
                ShowEvents(startDate: startDate, endDate: endDate),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
