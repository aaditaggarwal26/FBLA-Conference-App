import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/event_service.dart';
import '../../services/announcement_service.dart';
import '../../services/school_service.dart';
import '../../services/auth_service.dart';
import '../../models/event_model.dart';
import '../../models/announcement_model.dart';
import '../../models/school_announcement_model.dart';
import '../../models/school_event_model.dart';
import '../../models/school_model.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/event_card.dart';
import '../../widgets/announcement_card.dart';
import '../practice_tests/practice_tests_screen.dart';
import '../school/school_calendar_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final EventService _eventService = EventService();
  final AnnouncementService _announcementService = AnnouncementService();
  final SchoolService _schoolService = SchoolService();
  final AuthService _authService = AuthService();
  late Future<String> _firstNameFuture;
  late Future<UserModel?> _userDataFuture;

  @override
  void initState() {
    super.initState();
    _firstNameFuture = _getFirstName();
    _userDataFuture = _fetchUserData();
  }

  Future<UserModel?> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    try {
      return await _authService.getUserData(user.uid);
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      return null;
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Future<String> _getFirstName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'Friend';

    try {
      final userData = await _authService.getUserData(user.uid);
      if (userData != null && userData.name.isNotEmpty) {
        return userData.name.split(' ').first;
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }

    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!.split(' ').first;
    }
    if (user.email != null) {
      final emailName = user.email!.split('@').first.split('.').first;
      return emailName.isNotEmpty
          ? '${emailName[0].toUpperCase()}${emailName.substring(1)}'
          : 'Friend';
    }
    return 'Friend';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // Elegant Minimal Header
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            stretch: true,
            elevation: 0,
            backgroundColor: isDark
                ? AppTheme.darkBackground
                : AppTheme.background,
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                // Calculate if we're collapsed
                final isCollapsed =
                    constraints.biggest.height <=
                    kToolbarHeight + MediaQuery.of(context).padding.top + 20;

                return FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: EdgeInsets.only(
                    left: 24,
                    bottom: isCollapsed ? 16 : 20,
                    right: 24,
                  ),
                  title: isCollapsed
                      ? Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                'assets/logo.png',
                                height: 28,
                                width: 28,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'FBLA Conference',
                              style: TextStyle(
                                color: isDark ? Colors.white : AppTheme.black,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        )
                      : null,
                  background: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Logo with rounded corners
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              'assets/logo.png',
                              height: 32,
                              width: 32,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Greeting
                          Text(
                            '${_getGreeting()},',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.6)
                                  : AppTheme.mediumGray,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          FutureBuilder<String>(
                            future: _firstNameFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Text(
                                  'Friend',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : AppTheme.black,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    height: 1.2,
                                    letterSpacing: -0.5,
                                  ),
                                );
                              }
                              return Text(
                                snapshot.data ?? 'Friend',
                                style: TextStyle(
                                  color: isDark ? Colors.white : AppTheme.black,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                  letterSpacing: -0.5,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          // Date with subtle background
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppTheme.darkSurface.withValues(alpha: 0.5)
                                  : Colors.white.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color:
                                    (isDark
                                            ? AppTheme.darkCard
                                            : AppTheme.lightGray)
                                        .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 13,
                                  color: isDark
                                      ? AppTheme.darkSecondary
                                      : AppTheme.primaryBlue,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  DateFormat(
                                    'EEEE, MMMM d',
                                  ).format(DateTime.now()),
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.8)
                                        : AppTheme.darkGray,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Announcements Section
                _buildSectionHeader(
                  'Latest Announcements',
                  Icons.campaign_rounded,
                  isDark,
                ),
                const SizedBox(height: 16),

                // School Announcements (if user is in a school)
                FutureBuilder<UserModel?>(
                  future: _userDataFuture,
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return _buildLoadingShimmer(isDark);
                    }

                    if (userSnapshot.hasError) {
                      return _buildEmptyState(
                        'Unable to load school info',
                        'Please try again later',
                        Icons.error_outline,
                        isDark,
                      );
                    }

                    if (!userSnapshot.hasData) {
                      return const SizedBox.shrink();
                    }

                    final userData = userSnapshot.data!;
                    final schoolIds = userData.schoolIds;

                    if (schoolIds.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    // Show announcements from all schools
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: schoolIds.map((schoolId) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // School announcements header
                            FutureBuilder<SchoolModel?>(
                              future: _schoolService.getSchool(schoolId),
                              builder: (context, schoolSnapshot) {
                                final schoolName =
                                    schoolSnapshot.data?.name ?? 'Your School';
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.success.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppTheme.success.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.school_rounded,
                                        size: 16,
                                        color: AppTheme.success,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        schoolName,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.success,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            StreamBuilder<List<SchoolAnnouncementModel>>(
                              stream: _schoolService.getSchoolAnnouncements(
                                schoolId,
                              ),
                              builder: (context, schoolSnapshot) {
                                // Only show loading on initial wait
                                if (schoolSnapshot.connectionState ==
                                        ConnectionState.waiting &&
                                    !schoolSnapshot.hasData) {
                                  return _buildLoadingShimmer(isDark);
                                }

                                if (!schoolSnapshot.hasData ||
                                    schoolSnapshot.data!.isEmpty) {
                                  return Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppTheme.darkSurface
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppTheme.success.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.school_rounded,
                                          color: AppTheme.success.withValues(
                                            alpha: 0.5,
                                          ),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'No school announcements yet',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: isDark
                                                  ? AppTheme.mediumGray
                                                  : AppTheme.darkGray,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                return Column(
                                  children: schoolSnapshot.data!
                                      .take(3)
                                      .map(
                                        (announcement) => Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          child: _buildSchoolAnnouncementCard(
                                            announcement,
                                            isDark,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                          ],
                        );
                      }).toList(),
                    );
                  },
                ),

                // FBLA announcements header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.account_balance_rounded,
                        size: 16,
                        color: AppTheme.primaryBlue,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'FBLA Conference',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // FBLA Announcements
                StreamBuilder<List<AnnouncementModel>>(
                  stream: _announcementService.getAnnouncements(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildLoadingShimmer(isDark);
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return _buildEmptyState(
                        'No announcements yet',
                        'Check back later for updates',
                        Icons.campaign_rounded,
                        isDark,
                      );
                    }

                    return Column(
                      children: snapshot.data!
                          .take(3)
                          .map(
                            (announcement) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: AnnouncementCard(
                                announcement: announcement,
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Practice Tests Section
                _buildSectionHeader(
                  'Practice Tests',
                  Icons.quiz_rounded,
                  isDark,
                ),
                const SizedBox(height: 16),
                _buildPracticeTestsCard(isDark),

                const SizedBox(height: 32),

                // School Calendar Section (if user is in a school)
                FutureBuilder<UserModel?>(
                  future: _userDataFuture,
                  builder: (context, userSnapshot) {
                    if (!userSnapshot.hasData) {
                      return const SizedBox.shrink();
                    }

                    final userData = userSnapshot.data!;
                    final schoolId = userData.schoolId;

                    if (schoolId == null || schoolId.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildSectionHeader(
                                'Upcoming Events',
                                Icons.event_rounded,
                                isDark,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SchoolCalendarScreen(
                                      schoolId: schoolId,
                                    ),
                                  ),
                                );
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'View Calendar',
                                    style: TextStyle(
                                      color: isDark
                                          ? AppTheme.darkPrimary
                                          : AppTheme.primaryBlue,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 16,
                                    color: isDark
                                        ? AppTheme.darkPrimary
                                        : AppTheme.primaryBlue,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildUpcomingEvents(schoolId, isDark),
                        const SizedBox(height: 32),
                      ],
                    );
                  },
                ),

                // Featured Events Section
                _buildSectionHeader(
                  'Featured Events',
                  Icons.star_rounded,
                  isDark,
                ),
                const SizedBox(height: 16),
                StreamBuilder<List<EventModel>>(
                  stream: _eventService.getFeaturedEvents(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildLoadingShimmer(isDark);
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return _buildEmptyState(
                        'No featured events',
                        'Stay tuned for upcoming events',
                        Icons.event_rounded,
                        isDark,
                      );
                    }

                    return SizedBox(
                      height: 220,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          return Container(
                            width: 320,
                            margin: EdgeInsets.only(
                              right: index != snapshot.data!.length - 1
                                  ? 16
                                  : 0,
                            ),
                            child: EventCard(
                              event: snapshot.data![index],
                              isFeatured: true,
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryBlue, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.black,
              letterSpacing: 0.3,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingShimmer(bool isDark) {
    return Column(
      children: List.generate(
        2,
        (index) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 100,
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : AppTheme.lightGray,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    String title,
    String subtitle,
    IconData icon,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? AppTheme.darkCard : AppTheme.lightGray).withValues(
            alpha: 0.5,
          ),
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: AppTheme.primaryBlue.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppTheme.black,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                color: isDark ? AppTheme.mediumGray : AppTheme.darkGray,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPracticeTestsCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? AppTheme.darkCard : AppTheme.lightGray).withValues(
            alpha: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PracticeTestsScreen(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.quiz_rounded,
                    color: AppTheme.primaryBlue,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Objective Test Practice',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppTheme.black,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Practice tests for all FBLA objective test events',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.7)
                              : AppTheme.darkGray,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 20,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.5)
                      : AppTheme.mediumGray,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSchoolAnnouncementCard(
    SchoolAnnouncementModel announcement,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.success.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.success.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.school_rounded,
                  color: AppTheme.success,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      announcement.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'By ${announcement.authorName}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (announcement.isPinned)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.push_pin, size: 12, color: AppTheme.success),
                      SizedBox(width: 4),
                      Text(
                        'Pinned',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.success,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            announcement.content,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppTheme.mediumGray : AppTheme.darkGray,
              height: 1.5,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 14,
                color: isDark ? AppTheme.mediumGray : AppTheme.darkGray,
              ),
              const SizedBox(width: 6),
              Text(
                DateFormat('MMM d, y • h:mm a').format(announcement.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppTheme.mediumGray : AppTheme.darkGray,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingEvents(String schoolId, bool isDark) {
    return StreamBuilder<List<SchoolEventModel>>(
      stream: _schoolService.getSchoolEvents(schoolId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return _buildLoadingShimmer(isDark);
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (isDark ? AppTheme.darkCard : AppTheme.lightGray),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.event_available_rounded,
                  color: AppTheme.mediumGray.withValues(alpha: 0.5),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No upcoming events',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppTheme.mediumGray : AppTheme.darkGray,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // Get upcoming events (future events sorted by start time)
        final now = DateTime.now();
        final upcomingEvents =
            snapshot.data!
                .where((event) => event.startTime.isAfter(now))
                .toList()
              ..sort((a, b) => a.startTime.compareTo(b.startTime));

        if (upcomingEvents.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (isDark ? AppTheme.darkCard : AppTheme.lightGray),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.event_available_rounded,
                  color: AppTheme.mediumGray.withValues(alpha: 0.5),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No upcoming events',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppTheme.mediumGray : AppTheme.darkGray,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: upcomingEvents.take(3).map((event) {
            final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
            final isRegistered = event.isUserRegistered(currentUserId);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isRegistered
                      ? AppTheme.success
                      : (isDark ? AppTheme.darkCard : AppTheme.lightGray),
                  width: isRegistered ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.event_rounded,
                          color: AppTheme.primaryBlue,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppTheme.black,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 10,
                                  color: AppTheme.mediumGray,
                                ),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: Text(
                                    event.isAllDay
                                        ? DateFormat(
                                            'MMM d',
                                          ).format(event.startTime)
                                        : DateFormat(
                                            'MMM d h:mm a',
                                          ).format(event.startTime),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.mediumGray,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (isRegistered)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.check_circle_rounded,
                            size: 12,
                            color: AppTheme.success,
                          ),
                        ),
                    ],
                  ),
                  if (event.location.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: AppTheme.mediumGray,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.location,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppTheme.mediumGray
                                  : AppTheme.darkGray,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (event.maxAttendees != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.people_rounded,
                          size: 14,
                          color: AppTheme.mediumGray,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${event.attendeeIds.length}/${event.maxAttendees} registered',
                          style: TextStyle(
                            fontSize: 12,
                            color: event.isFull()
                                ? AppTheme.error
                                : AppTheme.mediumGray,
                            fontWeight: event.isFull()
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
