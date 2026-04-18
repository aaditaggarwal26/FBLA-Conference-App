import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/event_service.dart';
import '../../services/announcement_service.dart';
import '../../services/school_service.dart';
import '../../services/auth_service.dart';
import '../../services/linkedin_service.dart';
import '../../services/event_import_service.dart';
import '../../models/event_model.dart';
import '../../models/announcement_model.dart';
import '../../models/school_announcement_model.dart';
import '../../models/school_event_model.dart';
import '../../models/school_model.dart';
import '../../models/user_model.dart';
import '../../models/parsed_event_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/event_card.dart';
import '../../widgets/announcement_card.dart';
import '../practice_tests/practice_tests_screen.dart';

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
  final LinkedInService _linkedInService = LinkedInService();
  final EventImportService _eventImportService = EventImportService();
  late Future<String> _firstNameFuture;
  late Future<UserModel?> _userDataFuture;
  final Map<String, bool> _expandedAnnouncements = {};
  final Map<String, bool> _sharingToLinkedIn = {};

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
        physics: const ClampingScrollPhysics(),
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
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Adjust sizing based on available space
                          final availableHeight = constraints.maxHeight;
                          final textScaleFactor = MediaQuery.of(context).textScaleFactor;
                          
                          // Scale down elements when text is scaled up or space is limited
                          final shouldCompact = textScaleFactor > 1.1 || availableHeight < 140;
                          final logoSize = shouldCompact ? 24.0 : 32.0;
                          final greetingFontSize = shouldCompact ? 13.0 : 16.0;
                          final nameFontSize = shouldCompact ? 24.0 : 32.0;
                          final dateFontSize = shouldCompact ? 11.0 : 12.0;
                          final iconSize = shouldCompact ? 11.0 : 13.0;
                          final spacing = shouldCompact ? 4.0 : 8.0;
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Logo with rounded corners
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  'assets/logo.png',
                                  height: logoSize,
                                  width: logoSize,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              SizedBox(height: spacing),
                              // Greeting
                              Flexible(
                                child: Text(
                                  '${_getGreeting()},',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.6)
                                        : AppTheme.mediumGray,
                                    fontSize: greetingFontSize,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(height: spacing / 2),
                              FutureBuilder<String>(
                                future: _firstNameFuture,
                                builder: (context, snapshot) {
                                  final name = snapshot.data ?? 'Friend';
                                  return Flexible(
                                    child: Text(
                                      name,
                                      style: TextStyle(
                                        color: isDark ? Colors.white : AppTheme.black,
                                        fontSize: nameFontSize,
                                        fontWeight: FontWeight.w800,
                                        height: 1.2,
                                        letterSpacing: -0.5,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                },
                              ),
                              SizedBox(height: spacing),
                              // Date with subtle background
                              Flexible(
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: shouldCompact ? 8 : 12,
                                    vertical: shouldCompact ? 4 : 6,
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
                                        size: iconSize,
                                        color: isDark
                                            ? AppTheme.darkSecondary
                                            : AppTheme.primaryBlue,
                                      ),
                                      SizedBox(width: shouldCompact ? 4 : 6),
                                      Flexible(
                                        child: Text(
                                          DateFormat(
                                            'EEEE, MMMM d',
                                          ).format(DateTime.now()),
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.white.withValues(alpha: 0.8)
                                                : AppTheme.darkGray,
                                            fontSize: dateFontSize,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.2,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
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
                const SizedBox(height: 20),
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

                // SBLC Upcoming Events Section
                _buildSectionHeader(
                  'Your FBLA State Events',
                  Icons.school_rounded,
                  isDark,
                ),
                const SizedBox(height: 16),
                _buildUpcomingSBLCEvents(isDark),

                const SizedBox(height: 32),

                // Upcoming Events Section (merged: school events + featured FBLA events)
                _buildSectionHeader(
                  'Upcoming Events',
                  Icons.event_rounded,
                  isDark,
                ),
                const SizedBox(height: 16),
                _buildMergedUpcomingEvents(isDark),

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
          color: AppTheme.success.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with icon, title, and pinned badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            announcement.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppTheme.black,
                              height: 1.3,
                            ),
                          ),
                        ),
                        if (announcement.isPinned) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.warning.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppTheme.warning.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.push_pin_rounded,
                                  size: 12,
                                  color: AppTheme.warning,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Pinned',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.warning,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.person_rounded,
                          size: 12,
                          color: AppTheme.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          announcement.authorName,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Content with expand/collapse
          Builder(
            builder: (context) {
              final isExpanded =
                  _expandedAnnouncements[announcement.id] ?? false;
              final shouldShowExpand = announcement.content.length > 150;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    announcement.content,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.7)
                          : AppTheme.darkGray,
                      height: 1.5,
                    ),
                    maxLines: isExpanded ? null : 3,
                    overflow: isExpanded ? null : TextOverflow.ellipsis,
                  ),
                  if (shouldShowExpand) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _expandedAnnouncements[announcement.id] = !isExpanded;
                        });
                      },
                      child: Text(
                        isExpanded ? 'Show less' : 'Show more',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          // Footer with timestamp and share button
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 13,
                color: isDark ? AppTheme.mediumGray : AppTheme.darkGray,
              ),
              const SizedBox(width: 6),
              Text(
                DateFormat('MMM d, y • h:mm a').format(announcement.createdAt),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppTheme.mediumGray : AppTheme.darkGray,
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: (_sharingToLinkedIn[announcement.id] ?? false)
                    ? null
                    : () => _shareSchoolAnnouncementToLinkedIn(announcement),
                icon: (_sharingToLinkedIn[announcement.id] ?? false)
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.business_rounded, size: 16),
                label: const Text('Share'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0077B5),
                  side: const BorderSide(color: Color(0xFF0077B5)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: const Size(0, 32),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _shareSchoolAnnouncementToLinkedIn(
    SchoolAnnouncementModel announcement,
  ) async {
    final isConnected = await _linkedInService.isConnected();

    if (!isConnected) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please connect LinkedIn in Profile settings first'),
            backgroundColor: AppTheme.warning,
          ),
        );
      }
      return;
    }

    setState(() {
      _sharingToLinkedIn[announcement.id] = true;
    });

    try {
      final success = await _linkedInService.shareAnnouncement(
        title: announcement.title,
        content: announcement.content,
        context: context,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Announcement shared on LinkedIn!'
                  : 'Failed to share on LinkedIn',
            ),
            backgroundColor: success ? AppTheme.success : AppTheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing to LinkedIn: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _sharingToLinkedIn[announcement.id] = false;
        });
      }
    }
  }

  Widget _buildUpcomingSBLCEvents(bool isDark) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _buildEmptyState(
        'Sign in to see your schedule',
        'Your FBLA State events will appear here',
        Icons.school_rounded,
        isDark,
      );
    }
    return FutureBuilder<List<ParsedEventModel>>(
      future: _loadUpcomingSBLCEvents(user.uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _buildLoadingShimmer(isDark);
        }
        final events = snap.data ?? [];
        if (events.isEmpty) {
          return _buildEmptyState(
            'No upcoming FBLA State events',
            'Open FBLA State and your events will appear here',
            Icons.school_rounded,
            isDark,
          );
        }
        return Column(
          children: events.map((e) {
            final cardBg = isDark ? const Color(0xFF21262D) : Colors.white;
            final border = isDark ? const Color(0xFF30363D) : const Color(0xFFE5E7EB);
            final textPrimary = isDark ? const Color(0xFFE6EDF3) : const Color(0xFF1A1D26);
            final textSec = isDark ? const Color(0xFF8B949E) : const Color(0xFF6B7280);
            final timeStr = DateFormat('h:mm a').format(e.startTime);
            final dateStr = DateFormat('EEE, MMM d').format(e.startTime);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 52,
                        alignment: Alignment.topCenter,
                        child: Column(
                          children: [
                            Text(timeStr,
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? const Color(0xFF58A6FF)
                                        : AppTheme.primaryBlue)),
                            Text(dateStr,
                                style: TextStyle(
                                    fontSize: 9,
                                    color: textSec),
                                textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                      Container(
                          width: 1,
                          height: 44,
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          color: border),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.eventName,
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: textPrimary),
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 3),
                            if (e.schoolName != null)
                              Text(e.schoolName!,
                                  style: TextStyle(fontSize: 12, color: textSec),
                                  overflow: TextOverflow.ellipsis),
                            if (e.location.isNotEmpty)
                              Text(e.location,
                                  style: TextStyle(fontSize: 11.5, color: textSec),
                                  overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<List<ParsedEventModel>> _loadUpcomingSBLCEvents(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (!doc.exists) return [];
    final saved = List<String>.from(doc.data()?['registeredEvents'] ?? []);
    if (saved.isEmpty) return [];
    final allEvents = await _eventImportService.loadSBLCSchedule();
    final now = DateTime.now();
    final filtered = allEvents.where((e) {
      final id = '${e.eventName}::${e.schoolName ?? ""}';
      return saved.contains(id) && e.startTime.isAfter(now);
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    return filtered.take(5).toList();
  }

  Widget _buildMergedUpcomingEvents(bool isDark) {
    return FutureBuilder<UserModel?>(
      future: _userDataFuture,
      builder: (context, userSnapshot) {
        final schoolId = userSnapshot.data?.schoolId;

        // Get featured FBLA events
        return StreamBuilder<List<EventModel>>(
          stream: _eventService.getFeaturedEvents(),
          builder: (context, fblaSnapshot) {
            // Get school events if user is in a school
            if (schoolId != null && schoolId.isNotEmpty) {
              return StreamBuilder<List<SchoolEventModel>>(
                stream: _schoolService.getSchoolEvents(schoolId),
                builder: (context, schoolSnapshot) {
                  final featuredFBLAEvents = fblaSnapshot.data ?? [];
                  final schoolEvents = schoolSnapshot.data ?? [];

                  // Combine and sort by date
                  final now = DateTime.now();
                  final upcomingSchoolEvents =
                      schoolEvents
                          .where((event) => event.startTime.isAfter(now))
                          .toList()
                        ..sort((a, b) => a.startTime.compareTo(b.startTime));

                  final upcomingFBLAEvents =
                      featuredFBLAEvents
                          .where((event) => event.startTime.isAfter(now))
                          .toList()
                        ..sort((a, b) => a.startTime.compareTo(b.startTime));

                  // Combine all events
                  final allEvents =
                      <dynamic>[
                        ...upcomingSchoolEvents.take(3),
                        ...upcomingFBLAEvents.take(3),
                      ]..sort((a, b) {
                        DateTime aTime, bTime;
                        if (a is SchoolEventModel) {
                          aTime = a.startTime;
                        } else {
                          aTime = (a as EventModel).startTime;
                        }
                        if (b is SchoolEventModel) {
                          bTime = b.startTime;
                        } else {
                          bTime = (b as EventModel).startTime;
                        }
                        return aTime.compareTo(bTime);
                      });

                  if (fblaSnapshot.connectionState == ConnectionState.waiting &&
                      schoolSnapshot.connectionState ==
                          ConnectionState.waiting &&
                      !fblaSnapshot.hasData &&
                      !schoolSnapshot.hasData) {
                    return _buildLoadingShimmer(isDark);
                  }

                  if (allEvents.isEmpty) {
                    return _buildEmptyState(
                      'No upcoming events',
                      'Check back later for new events',
                      Icons.event_rounded,
                      isDark,
                    );
                  }

                  return Column(
                    children: allEvents.take(5).map((event) {
                      if (event is SchoolEventModel) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildSchoolEventCard(event, isDark),
                        );
                      } else {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: EventCard(event: event as EventModel),
                        );
                      }
                    }).toList(),
                  );
                },
              );
            } else {
              // Only FBLA featured events
              final featuredFBLAEvents = fblaSnapshot.data ?? [];
              final now = DateTime.now();
              final upcomingFBLAEvents =
                  featuredFBLAEvents
                      .where((event) => event.startTime.isAfter(now))
                      .toList()
                    ..sort((a, b) => a.startTime.compareTo(b.startTime));

              if (fblaSnapshot.connectionState == ConnectionState.waiting &&
                  !fblaSnapshot.hasData) {
                return _buildLoadingShimmer(isDark);
              }

              if (upcomingFBLAEvents.isEmpty) {
                return _buildEmptyState(
                  'No upcoming events',
                  'Stay tuned for upcoming events',
                  Icons.event_rounded,
                  isDark,
                );
              }

              return Column(
                children: upcomingFBLAEvents.take(5).map((event) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: EventCard(event: event),
                  );
                }).toList(),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildSchoolEventCard(SchoolEventModel event, bool isDark) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isRegistered = event.isUserRegistered(currentUserId);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRegistered
              ? AppTheme.success
              : (isDark ? AppTheme.darkCard : AppTheme.lightGray),
          width: isRegistered ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
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
                  color: AppTheme.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.school_rounded,
                  color: AppTheme.success,
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
                                ? DateFormat('MMM d').format(event.startTime)
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
                      color: isDark ? AppTheme.mediumGray : AppTheme.darkGray,
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
          const SizedBox(height: 12),
          // Add to Google Calendar button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _addToGoogleCalendar(event),
              icon: const Icon(Icons.event_rounded, size: 18),
              label: const Text('Add to Google Calendar'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                side: BorderSide(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addToGoogleCalendar(SchoolEventModel event) async {
    try {
      // Format dates for Google Calendar URL
      final startDate = event.startTime.toUtc();
      final endDate = event.endTime.toUtc();

      // Format as YYYYMMDDTHHMMSSZ
      String formatDate(DateTime date) {
        return DateFormat('yyyyMMdd\'T\'HHmmss\'Z\'').format(date);
      }

      final startStr = formatDate(startDate);
      final endStr = formatDate(endDate);

      // Build Google Calendar URL
      final params = <String, String>{
        'action': 'TEMPLATE',
        'text': event.title,
        'dates': '$startStr/$endStr',
        'location': event.location,
      };

      if (event.description.isNotEmpty) {
        params['details'] = event.description;
      }

      final queryString = params.entries
          .map(
            (e) =>
                '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
          )
          .join('&');

      final url = Uri.parse(
        'https://calendar.google.com/calendar/render?$queryString',
      );

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open Google Calendar'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }
}
