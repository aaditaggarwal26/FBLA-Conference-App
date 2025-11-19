import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/school_service.dart';
import '../../services/auth_service.dart';
import '../../models/school_model.dart';
import '../../models/school_join_request_model.dart';
import '../../theme/app_theme.dart';
import 'school_broadcast_screen.dart';
import 'create_school_resource_screen.dart';
import 'create_school_event_screen.dart';
import 'school_calendar_screen.dart';
import 'social_media_management_screen.dart';
import '../../models/school_resource_model.dart';
import '../../models/school_announcement_model.dart';
import '../../models/school_event_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class SchoolDashboardScreen extends StatefulWidget {
  final String schoolId;

  const SchoolDashboardScreen({super.key, required this.schoolId});

  @override
  State<SchoolDashboardScreen> createState() => _SchoolDashboardScreenState();
}

class _SchoolDashboardScreenState extends State<SchoolDashboardScreen>
    with SingleTickerProviderStateMixin {
  final SchoolService _schoolService = SchoolService();
  late TabController _tabController;
  bool _isGeneratingCode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _checkAndGenerateJoinCode();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkAndGenerateJoinCode() async {
    try {
      final schoolDoc = await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .get();

      if (schoolDoc.exists) {
        final data = schoolDoc.data();
        final joinCode = data?['joinCode'] as String?;

        if (joinCode == null || joinCode.isEmpty) {
          setState(() => _isGeneratingCode = true);
          final newCode = _generateJoinCode();
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(widget.schoolId)
              .update({'joinCode': newCode});
          setState(() => _isGeneratingCode = false);
        }
      }
    } catch (e) {
      print('Error checking join code: $e');
      setState(() => _isGeneratingCode = false);
    }
  }

  String _generateJoinCode() {
    final random = Random();
    return List.generate(6, (_) => random.nextInt(10)).join();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<SchoolModel?>(
      stream: _getSchoolStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: isDark
                ? AppTheme.darkBackground
                : AppTheme.background,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final school = snapshot.data;
        if (school == null) {
          return Scaffold(
            backgroundColor: isDark
                ? AppTheme.darkBackground
                : AppTheme.background,
            appBar: AppBar(
              title: const Text('Error'),
              backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
            ),
            body: const Center(child: Text('School not found')),
          );
        }

        final isOwner = school.isOwner(currentUserId ?? '');
        final isAdmin = school.isAdmin(currentUserId ?? '');

        return Scaffold(
          backgroundColor: isDark
              ? AppTheme.darkBackground
              : AppTheme.background,
          body: Column(
            children: [
              // Header with tabs (for admins)
              if (isAdmin)
                Container(
                  color: isDark ? AppTheme.darkBackground : AppTheme.background,
                  child: Column(
                    children: [
                      // AppBar
                      AppBar(
                        elevation: 0,
                        backgroundColor: isDark
                            ? AppTheme.darkBackground
                            : AppTheme.background,
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              school.name,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppTheme.black,
                              ),
                            ),
                            Text(
                              isOwner ? 'Owner' : 'Administrator',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.mediumGray,
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          IconButton(
                            icon: const Icon(Icons.notifications_outlined),
                            onPressed: () {},
                          ),
                        ],
                      ),
                      // Tabs
                      Container(
                        color: isDark ? AppTheme.darkSurface : Colors.white,
                        child: TabBar(
                          controller: _tabController,
                          indicatorColor: AppTheme.primaryBlue,
                          labelColor: AppTheme.primaryBlue,
                          unselectedLabelColor: isDark
                              ? Colors.white.withValues(alpha: 0.6)
                              : AppTheme.darkGray,
                          labelStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          tabs: const [
                            Tab(text: 'Overview'),
                            Tab(text: 'Members'),
                            Tab(text: 'Requests'),
                            Tab(text: 'Settings'),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                // Regular user header
                AppBar(
                  elevation: 0,
                  backgroundColor: isDark
                      ? AppTheme.darkBackground
                      : AppTheme.background,
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        school.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppTheme.black,
                        ),
                      ),
                      Text(
                        'Member',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.mediumGray,
                        ),
                      ),
                    ],
                  ),
                ),
              // Tab content
              Expanded(
                child: isAdmin
                    ? TabBarView(
                        controller: _tabController,
                        children: [
                          _buildOverview(school, isDark),
                          _buildMembers(school, isOwner, isDark),
                          _buildRequests(school, isDark),
                          _buildSettings(school, isDark),
                        ],
                      )
                    : _buildOverview(school, isDark),
              ),
            ],
          ),
        );
      },
    );
  }

  Stream<SchoolModel?> _getSchoolStream() {
    return FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .snapshots()
        .map((doc) => doc.exists ? SchoolModel.fromFirestore(doc) : null);
  }

  Widget _buildOverview(SchoolModel school, bool isDark) {
    final isAdmin = school.isAdmin(
      FirebaseAuth.instance.currentUser?.uid ?? '',
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Join Code Card (only for admins)
          if (isAdmin) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkPrimary : AppTheme.primaryBlue,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color:
                        (isDark ? AppTheme.darkPrimary : AppTheme.primaryBlue)
                            .withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Join Code',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _isGeneratingCode
                            ? const SizedBox(
                                height: 42,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                ),
                              )
                            : FittedBox(
                                alignment: Alignment.centerLeft,
                                fit: BoxFit.scaleDown,
                                child: SelectableText(
                                  school.joinCode.isNotEmpty
                                      ? school.joinCode.toUpperCase()
                                      : 'GENERATING...',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 42,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 6,
                                    height: 1.1,
                                    shadows: [
                                      Shadow(
                                        offset: Offset(0, 3),
                                        blurRadius: 6,
                                        color: Colors.black45,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                      IconButton(
                        onPressed: () => _copyJoinCode(school.joinCode),
                        icon: const Icon(
                          Icons.copy_rounded,
                          color: Colors.white,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Share this code with students to join your school',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],

          // Stats Grid (only for admins)
          if (isAdmin) ...[
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Members',
                    school.memberIds.length.toString(),
                    Icons.people_rounded,
                    AppTheme.success,
                    isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Admins',
                    school.adminIds.length.toString(),
                    Icons.admin_panel_settings_rounded,
                    AppTheme.warning,
                    isDark,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Quick Actions (only for admins)
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.black,
              ),
            ),
            const SizedBox(height: 16),

            _buildActionButton(
              'Send Announcement',
              'Broadcast a message to all members',
              Icons.campaign_rounded,
              AppTheme.primaryBlue,
              isDark,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SchoolBroadcastScreen(schoolId: school.id),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              'View Members',
              'Manage school members and admins',
              Icons.people_rounded,
              AppTheme.success,
              isDark,
              () => _tabController.animateTo(1),
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              'Review Requests',
              'Approve or deny join requests',
              Icons.inbox_rounded,
              AppTheme.warning,
              isDark,
              () => _tabController.animateTo(2),
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              'Add Resource',
              'Upload files and links for members',
              Icons.folder_rounded,
              AppTheme.primaryBlue,
              isDark,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CreateSchoolResourceScreen(schoolId: school.id),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              'Create Event',
              'Schedule events for your school',
              Icons.event_rounded,
              AppTheme.warning,
              isDark,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CreateSchoolEventScreen(schoolId: school.id),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              'View Calendar',
              'See all upcoming school events',
              Icons.calendar_month_rounded,
              AppTheme.success,
              isDark,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SchoolCalendarScreen(schoolId: school.id),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),
          ],

          // School Info
          Text(
            'School Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.black,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildInfoRow(
                  Icons.location_on_outlined,
                  '${school.city}, ${school.state}',
                  isDark,
                ),
                if (school.description != null &&
                    school.description!.isNotEmpty) ...[
                  const Divider(height: 32),
                  _buildInfoRow(
                    Icons.description_outlined,
                    school.description!,
                    isDark,
                  ),
                ],
                if (school.socialMediaLinks.isNotEmpty) ...[
                  const Divider(height: 32),
                  _buildSocialMediaSection(school, isDark),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Stats for regular users
          if (!isAdmin) ...[
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Members',
                    school.memberIds.length.toString(),
                    Icons.people_rounded,
                    AppTheme.success,
                    isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StreamBuilder<List<SchoolResourceModel>>(
                    stream: _schoolService.getSchoolResources(school.id),
                    builder: (context, snapshot) {
                      final resourceCount = snapshot.data?.length ?? 0;
                      return _buildStatCard(
                        'Resources',
                        resourceCount.toString(),
                        Icons.folder_rounded,
                        AppTheme.primaryBlue,
                        isDark,
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Announcements Section
            Text(
              'Recent Announcements',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.black,
              ),
            ),
            const SizedBox(height: 16),
            _buildAnnouncementsSection(school.id, isDark),

            const SizedBox(height: 24),

            // Upcoming Events
            Text(
              'Upcoming Events',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.black,
              ),
            ),
            const SizedBox(height: 16),
            _buildUpcomingEventsSection(school.id, isDark),

            const SizedBox(height: 24),
          ],

          // Resources Section
          Text(
            'Resources & Documents',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.black,
            ),
          ),
          const SizedBox(height: 16),
          _buildResourcesSection(school.id, isDark),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsSection(String schoolId, bool isDark) {
    return StreamBuilder<List<SchoolAnnouncementModel>>(
      stream: _schoolService.getSchoolAnnouncements(schoolId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          print('Error loading announcements: ${snapshot.error}');
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: AppTheme.error,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Error loading announcements',
                    style: TextStyle(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.6)
                          : AppTheme.darkGray,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final announcements = snapshot.data ?? [];

        print(
          'Announcements loaded: ${announcements.length} for school $schoolId',
        );

        if (announcements.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.campaign_outlined,
                    size: 48,
                    color: AppTheme.mediumGray,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No announcements yet',
                    style: TextStyle(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.6)
                          : AppTheme.darkGray,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: announcements.take(3).map((announcement) {
            return _buildAnnouncementCard(announcement, isDark);
          }).toList(),
        );
      },
    );
  }

  Widget _buildUpcomingEventsSection(String schoolId, bool isDark) {
    return StreamBuilder<List<SchoolEventModel>>(
      stream: _schoolService.getSchoolEvents(schoolId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final allEvents = snapshot.data ?? [];
        final now = DateTime.now();
        final upcomingEvents =
            allEvents.where((event) => event.startTime.isAfter(now)).toList()
              ..sort((a, b) => a.startTime.compareTo(b.startTime));

        if (upcomingEvents.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.event_busy_rounded,
                    size: 48,
                    color: AppTheme.mediumGray,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No upcoming events',
                    style: TextStyle(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.6)
                          : AppTheme.darkGray,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: upcomingEvents.take(3).map((event) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppTheme.darkCard : AppTheme.lightGray,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          DateFormat('MMM').format(event.startTime),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.success,
                          ),
                        ),
                        Text(
                          DateFormat('d').format(event.startTime),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppTheme.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: AppTheme.mediumGray,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              event.isAllDay
                                  ? 'All Day'
                                  : DateFormat(
                                      'h:mm a',
                                    ).format(event.startTime),
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.mediumGray,
                              ),
                            ),
                            const SizedBox(width: 12),
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
                                  fontSize: 12,
                                  color: AppTheme.mediumGray,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildAnnouncementCard(
    SchoolAnnouncementModel announcement,
    bool isDark,
  ) {
    return _AnnouncementCard(
      announcement: announcement,
      isDark: isDark,
      formatDate: _formatDate,
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }

  Widget _buildResourcesSection(String schoolId, bool isDark) {
    return StreamBuilder<List<SchoolResourceModel>>(
      stream: _schoolService.getSchoolResources(schoolId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          print('Error loading resources: ${snapshot.error}');
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: AppTheme.error,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Error loading resources',
                    style: TextStyle(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.6)
                          : AppTheme.darkGray,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(fontSize: 12, color: AppTheme.error),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final resources = snapshot.data ?? [];

        print('Resources loaded: ${resources.length} for school $schoolId');

        if (resources.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.folder_open_rounded,
                    size: 48,
                    color: AppTheme.mediumGray,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No resources yet',
                    style: TextStyle(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.6)
                          : AppTheme.darkGray,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: resources.take(5).map((resource) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppTheme.darkCard : AppTheme.lightGray,
                ),
              ),
              child: InkWell(
                onTap: () => _launchResourceUrl(resource.url),
                borderRadius: BorderRadius.circular(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getResourceColor(
                          resource.type,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getResourceIcon(resource.type),
                        color: _getResourceColor(resource.type),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            resource.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : AppTheme.black,
                            ),
                          ),
                          if (resource.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              resource.description,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.7)
                                    : AppTheme.darkGray,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      Icons.open_in_new_rounded,
                      size: 20,
                      color: AppTheme.mediumGray,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  IconData _getResourceIcon(String type) {
    switch (type.toLowerCase()) {
      case 'document':
        return Icons.description_rounded;
      case 'video':
        return Icons.video_library_rounded;
      case 'file':
        return Icons.attach_file_rounded;
      case 'link':
        return Icons.link_rounded;
      default:
        return Icons.folder_rounded;
    }
  }

  Color _getResourceColor(String type) {
    switch (type.toLowerCase()) {
      case 'document':
        return AppTheme.primaryBlue;
      case 'video':
        return AppTheme.error;
      case 'file':
        return AppTheme.warning;
      case 'link':
        return AppTheme.success;
      default:
        return AppTheme.mediumGray;
    }
  }

  Future<void> _launchResourceUrl(String urlString) async {
    try {
      final Uri url = Uri.parse(urlString);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open resource'),
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

  Widget _buildMembers(SchoolModel school, bool isOwner, bool isDark) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getMembersWithDetails(school),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final members = snapshot.data ?? [];

        return Column(
          children: [
            // Header with search
            Container(
              padding: const EdgeInsets.all(16),
              color: isDark ? AppTheme.darkSurface : Colors.white,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${members.length} Member${members.length != 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppTheme.black,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${school.adminIds.length} Admin${school.adminIds.length != 1 ? 's' : ''}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Members list
            Expanded(
              child: members.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: AppTheme.mediumGray,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No members yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark ? Colors.white : AppTheme.black,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: members.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final member = members[index];
                        final userId = member['id'] as String;
                        final isAdmin = school.adminIds.contains(userId);
                        final isMemberOwner = school.ownerId == userId;

                        final currentUserId =
                            FirebaseAuth.instance.currentUser?.uid ?? '';
                        final isCurrentUserAdmin = school.isAdmin(
                          currentUserId,
                        );

                        return _buildMemberCard(
                          member,
                          isAdmin,
                          isMemberOwner,
                          isOwner && isCurrentUserAdmin,
                          school.id,
                          isDark,
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRequests(SchoolModel school, bool isDark) {
    return StreamBuilder<List<SchoolJoinRequestModel>>(
      stream: _schoolService.getPendingJoinRequests(school.id),
      builder: (context, snapshot) {
        print(
          '📥 Join requests stream - Connection: ${snapshot.connectionState}',
        );
        print('📥 Join requests stream - Has data: ${snapshot.hasData}');
        print('📥 Join requests stream - Count: ${snapshot.data?.length ?? 0}');
        if (snapshot.hasError) {
          print('📥 Join requests stream - Error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data ?? [];

        return Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              color: isDark ? AppTheme.darkSurface : Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Join Requests',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.black,
                      ),
                    ),
                  ),
                  if (requests.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${requests.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.warning,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Requests list
            Expanded(
              child: requests.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            size: 64,
                            color: AppTheme.success,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'All caught up!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppTheme.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'No pending join requests',
                            style: TextStyle(color: AppTheme.mediumGray),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: requests.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildRequestCard(requests[index], isDark);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSettings(SchoolModel school, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'School Settings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.black,
            ),
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.approval_rounded,
                    color: AppTheme.primaryBlue,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Require Approval',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppTheme.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Review join requests before adding members',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.mediumGray,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: school.requireApproval,
                  onChanged: (value) async {
                    try {
                      await _schoolService.updateSchool(widget.schoolId, {
                        'requireApproval': value,
                      });
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              value
                                  ? 'Join approval now required'
                                  : 'Students can join automatically',
                            ),
                            backgroundColor: AppTheme.success,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: AppTheme.error,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                  activeColor: AppTheme.success,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SocialMediaManagementScreen(schoolId: school.id),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.share_rounded,
                      color: AppTheme.primaryBlue,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Manage Social Media',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppTheme.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Add and update your chapter\'s social media links',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.mediumGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: AppTheme.mediumGray,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppTheme.mediumGray),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    bool isDark,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppTheme.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.mediumGray,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppTheme.mediumGray,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.mediumGray),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white : AppTheme.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialMediaSection(SchoolModel school, bool isDark) {
    final socialMediaIcons = {
      'instagram': Icons.camera_alt_rounded,
      'twitter': Icons.alternate_email_rounded,
      'facebook': Icons.facebook_rounded,
      'linkedin': Icons.business_rounded,
      'youtube': Icons.play_circle_filled_rounded,
      'tiktok': Icons.music_note_rounded,
      'snapchat': Icons.camera_alt_outlined,
    };

    final socialMediaLabels = {
      'instagram': 'Instagram',
      'twitter': 'Twitter',
      'facebook': 'Facebook',
      'linkedin': 'LinkedIn',
      'youtube': 'YouTube',
      'tiktok': 'TikTok',
      'snapchat': 'Snapchat',
    };

    final socialMediaColors = {
      'instagram': const Color(0xFFE4405F),
      'twitter': const Color(0xFF1DA1F2),
      'facebook': const Color(0xFF1877F2),
      'linkedin': const Color(0xFF0077B5),
      'youtube': const Color(0xFFFF0000),
      'tiktok': const Color(0xFF000000),
      'snapchat': const Color(0xFFFFFC00),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.share_rounded, size: 20, color: AppTheme.mediumGray),
            const SizedBox(width: 12),
            Text(
              'Social Media',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppTheme.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: school.socialMediaLinks.entries.map((entry) {
            final platform = entry.key;
            final url = entry.value;
            final icon = socialMediaIcons[platform] ?? Icons.link_rounded;
            final label = socialMediaLabels[platform] ?? platform;
            final color = socialMediaColors[platform] ?? AppTheme.primaryBlue;

            return InkWell(
              onTap: () => _launchSocialMediaUrl(url, platform),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 18, color: color),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _launchSocialMediaUrl(String url, String platform) async {
    try {
      Uri uri;
      if (platform == 'snapchat') {
        // For Snapchat, if it's just a username, construct the URL
        if (!url.startsWith('http://') && !url.startsWith('https://')) {
          uri = Uri.parse('https://snapchat.com/add/$url');
        } else {
          uri = Uri.parse(url);
        }
      } else {
        uri = Uri.parse(url);
      }

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open link'),
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

  Widget _buildMemberCard(
    Map<String, dynamic> member,
    bool isAdmin,
    bool isMemberOwner,
    bool isCurrentUserOwner,
    String schoolId,
    bool isDark,
  ) {
    final userId = member['id'] as String;
    final name = member['name'] as String? ?? 'Unknown';
    final email = member['email'] as String? ?? '';
    final photoUrl = member['photoUrl'] as String?;

    final showActions = !isMemberOwner && isCurrentUserOwner;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMemberOwner
              ? AppTheme.gold.withValues(alpha: 0.3)
              : (isAdmin
                    ? AppTheme.primaryBlue.withValues(alpha: 0.3)
                    : (isDark ? AppTheme.darkCard : AppTheme.lightGray)),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: isDark
                    ? AppTheme.darkCard
                    : AppTheme.lightGray,
                backgroundImage: photoUrl != null
                    ? NetworkImage(photoUrl)
                    : null,
                child: photoUrl == null
                    ? Icon(
                        Icons.person,
                        color: isDark ? Colors.white : AppTheme.darkGray,
                        size: 28,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : AppTheme.black,
                            ),
                          ),
                        ),
                        if (isMemberOwner) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.gold.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppTheme.gold),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified_rounded,
                                  size: 12,
                                  color: AppTheme.gold,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'OWNER',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.gold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else if (isAdmin) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withValues(
                                alpha: 0.2,
                              ),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppTheme.primaryBlue),
                            ),
                            child: const Text(
                              'ADMIN',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.mediumGray,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (showActions) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                if (isAdmin)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _demoteAdmin(schoolId, userId, name),
                      icon: const Icon(
                        Icons.remove_moderator_rounded,
                        size: 18,
                      ),
                      label: const Text('Remove Admin'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.warning,
                        side: const BorderSide(color: AppTheme.warning),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _promoteToAdmin(schoolId, userId, name),
                      icon: const Icon(
                        Icons.admin_panel_settings_rounded,
                        size: 18,
                      ),
                      label: const Text('Make Admin'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryBlue,
                        side: const BorderSide(color: AppTheme.primaryBlue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _removeMember(schoolId, userId, name),
                    icon: const Icon(Icons.person_remove_rounded, size: 18),
                    label: const Text('Remove'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: const BorderSide(color: AppTheme.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRequestCard(SchoolJoinRequestModel request, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: isDark
                    ? AppTheme.darkCard
                    : AppTheme.lightGray,
                backgroundImage: request.userPhotoUrl != null
                    ? NetworkImage(request.userPhotoUrl!)
                    : null,
                child: request.userPhotoUrl == null
                    ? Icon(
                        Icons.person,
                        color: isDark ? Colors.white : AppTheme.darkGray,
                        size: 28,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.userName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppTheme.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      request.userEmail,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.mediumGray,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _approveRequest(request.id),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _rejectRequest(request.id),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    side: const BorderSide(color: AppTheme.error),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getMembersWithDetails(
    SchoolModel school,
  ) async {
    final members = <Map<String, dynamic>>[];
    final authService = AuthService();

    for (final memberId in school.memberIds) {
      try {
        final userData = await authService.getUserData(memberId);
        if (userData != null) {
          final isSuperAdmin = await _isSuperAdmin(memberId);
          if (!isSuperAdmin) {
            members.add({
              'id': memberId,
              'name': userData.name,
              'email': userData.email,
              'photoUrl': userData.photoUrl,
            });
          }
        }
      } catch (e) {
        print('Error fetching member $memberId: $e');
      }
    }

    members.sort((a, b) {
      final aId = a['id'] as String;
      final bId = b['id'] as String;

      if (school.ownerId == aId) return -1;
      if (school.ownerId == bId) return 1;

      final aIsAdmin = school.adminIds.contains(aId);
      final bIsAdmin = school.adminIds.contains(bId);

      if (aIsAdmin && !bIsAdmin) return -1;
      if (!aIsAdmin && bIsAdmin) return 1;

      return 0;
    });

    return members;
  }

  Future<bool> _isSuperAdmin(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(userId)
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  void _copyJoinCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text('Join code "$code" copied!'),
          ],
        ),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _promoteToAdmin(
    String schoolId,
    String userId,
    String userName,
  ) async {
    try {
      await _schoolService.addAdmin(schoolId, userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$userName is now an admin'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _demoteAdmin(
    String schoolId,
    String userId,
    String userName,
  ) async {
    try {
      await _schoolService.removeAdmin(schoolId, userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$userName is no longer an admin'),
            backgroundColor: AppTheme.warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _removeMember(
    String schoolId,
    String userId,
    String userName,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text(
          'Remove $userName from the school? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _schoolService.removeMember(schoolId, userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$userName removed from school'),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _approveRequest(String requestId) async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;

      await _schoolService.approveJoinRequest(requestId, currentUserId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Request approved!'),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;

      await _schoolService.rejectJoinRequest(requestId, currentUserId, null);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.info, color: Colors.white),
                SizedBox(width: 8),
                Text('Request rejected'),
              ],
            ),
            backgroundColor: AppTheme.warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

class _AnnouncementCard extends StatefulWidget {
  final SchoolAnnouncementModel announcement;
  final bool isDark;
  final String Function(DateTime) formatDate;

  const _AnnouncementCard({
    required this.announcement,
    required this.isDark,
    required this.formatDate,
  });

  @override
  State<_AnnouncementCard> createState() => _AnnouncementCardState();
}

class _AnnouncementCardState extends State<_AnnouncementCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final announcement = widget.announcement;
    final isDark = widget.isDark;
    final content = announcement.content;
    final shouldShowExpand = content.length > 150;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.darkCard : AppTheme.lightGray,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.campaign_rounded,
                  color: AppTheme.primaryBlue,
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
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppTheme.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'By ${announcement.authorName} • ${widget.formatDate(announcement.createdAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.mediumGray,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (content.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              content,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.8)
                    : AppTheme.darkGray,
              ),
              maxLines: _isExpanded ? null : 3,
              overflow: _isExpanded ? null : TextOverflow.ellipsis,
            ),
            if (shouldShowExpand) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Text(
                  _isExpanded ? 'Show less' : 'Show more',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
