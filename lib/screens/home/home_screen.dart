import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/event_service.dart';
import '../../services/announcement_service.dart';
import '../../services/auth_service.dart';
import '../../models/event_model.dart';
import '../../models/announcement_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/event_card.dart';
import '../../widgets/announcement_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final EventService _eventService = EventService();
  final AnnouncementService _announcementService = AnnouncementService();
  final AuthService _authService = AuthService();
  late Future<String> _firstNameFuture;

  @override
  void initState() {
    super.initState();
    _firstNameFuture = _getFirstName();
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
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryBlue, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppTheme.black,
            letterSpacing: 0.3,
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
}
