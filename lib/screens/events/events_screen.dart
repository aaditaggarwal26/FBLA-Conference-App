import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/event_service.dart';
import '../../services/school_service.dart';
import '../../services/auth_service.dart';
import '../../models/event_model.dart';
import '../../models/school_event_model.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/event_card.dart';
import 'event_qr_scanner_screen.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../school/create_school_event_screen.dart';
import '../school/nccc_event_detail_screen.dart';
import '../../services/event_import_service.dart';
import '../../models/parsed_event_model.dart';
import '../school/event_detail_page.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen>
    with SingleTickerProviderStateMixin {
  final EventService _eventService = EventService();
  final SchoolService _schoolService = SchoolService();
  final AuthService _authService = AuthService();
  final EventImportService _eventImportService = EventImportService();
  late TabController _tabController;
  String _selectedCategory = 'All';
  int _myEventsRefreshKey = 0;

  // Calendar state
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<dynamic>> _calendarEvents = {};
  bool _isAdmin = false;

  final List<String> _categories = [
    'All',
    'General',
    'Workshop',
    'Keynote',
    'Networking',
    'Competition',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _selectedDay = _focusedDay;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.background,
      body: Column(
        children: [
          // Header with tabs
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
                  title: Text(
                    'Events',
                    style: TextStyle(
                      color: isDark ? Colors.white : AppTheme.black,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(
                        Icons.qr_code_scanner_rounded,
                        color: isDark ? Colors.white : AppTheme.black,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EventQRScannerScreen(),
                          ),
                        );
                      },
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
                      Tab(text: 'All Events'),
                      Tab(text: 'My Events'),
                      Tab(text: 'School'),
                      Tab(text: 'Calendar'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllEventsTab(isDark),
                _buildMyEventsTab(isDark),
                _buildSchoolEventsTab(isDark),
                _buildCalendarTab(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllEventsTab(bool isDark) {
    return FutureBuilder<UserModel?>(
      future: _authService.getUserData(
        FirebaseAuth.instance.currentUser?.uid ?? '',
      ),
      builder: (context, userSnapshot) {
        final schoolIds = userSnapshot.data?.schoolIds ?? [];
        final currentUserName = userSnapshot.data?.name ?? '';

        return CustomScrollView(
          slivers: [
            // Category Filter
            SliverToBoxAdapter(
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = _selectedCategory == category;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedCategory = category);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryBlue
                                : (isDark
                                      ? AppTheme.darkSurface
                                      : Colors.white),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryBlue
                                  : (isDark
                                        ? Colors.white.withValues(alpha: 0.1)
                                        : Colors.grey.shade300),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              category,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                          ? Colors.white.withValues(alpha: 0.7)
                                          : Colors.grey.shade700),
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Featured FBLA State block (always visible)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NCCCEventDetailScreen(
                            schoolId: schoolIds.isNotEmpty ? schoolIds.first : '',
                            currentUserName: currentUserName,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF001231), Color(0xFF0A2463)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF001231,
                            ).withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Background pattern
                          Positioned(
                            right: -20,
                            top: -20,
                            child: Icon(
                              Icons.event_rounded,
                              size: 140,
                              color: Colors.white.withValues(alpha: 0.05),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.amber,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.star_rounded,
                                            size: 14,
                                            color: Colors.black,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'FEATURED',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.navigation_rounded,
                                            size: 12,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'AR Nav',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'FBLA State',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'WA SBLC 2026 State Competition',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.calendar_today_rounded,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'April 21–23, 2026',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          'Saturday • Full Day Event',
                                          style: TextStyle(
                                            color: Colors.white60,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.location_on_rounded,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'North Creek High School',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            '208 Competition Events',
                                            style: TextStyle(
                                              color: Colors.white60,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'View My Schedule & Navigate',
                                        style: TextStyle(
                                          color: Color(0xFF001231),
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        color: Color(0xFF001231),
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // FBLA Events Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_balance_rounded,
                      size: 18,
                      color: AppTheme.primaryBlue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'FBLA Conference Events',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppTheme.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            StreamBuilder<List<EventModel>>(
              stream: _selectedCategory == 'All'
                  ? _eventService.getEvents()
                  : _eventService.getEventsByCategory(_selectedCategory),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final fblaEvents = snapshot.data ?? [];

                if (fblaEvents.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkSurface : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'No FBLA events found',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.6)
                                  : AppTheme.darkGray,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: EventCard(event: fblaEvents[index]),
                      ),
                      childCount: fblaEvents.length,
                    ),
                  ),
                );
              },
            ),

            // School Events Section (if user is in schools)
            if (schoolIds.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.school_rounded,
                        size: 18,
                        color: AppTheme.success,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'School Events',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppTheme.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ...schoolIds.map((schoolId) {
                return StreamBuilder<List<SchoolEventModel>>(
                  stream: _schoolService.getSchoolEvents(schoolId),
                  builder: (context, snapshot) {
                    final schoolEvents = (snapshot.data ?? [])
                        .where((event) => !_isNcccSchoolEvent(event))
                        .toList();

                    if (schoolEvents.isEmpty) {
                      return const SliverToBoxAdapter(child: SizedBox.shrink());
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildSchoolEventCard(
                              schoolEvents[index],
                              isDark,
                            ),
                          ),
                          childCount: schoolEvents.length,
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ],
          ],
        );
      },
    );
  }

  Widget _buildMyEventsTab(bool isDark) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _buildSignedOutState(isDark);
    }
    return FutureBuilder<List<ParsedEventModel>>(
      key: ValueKey(_myEventsRefreshKey),
      future: _loadMyEvents(user.uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final myEvents = snap.data ?? [];
        if (myEvents.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border_rounded,
                      size: 72,
                      color: isDark ? const Color(0xFF30363D) : Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('No saved events yet',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppTheme.black)),
                  const SizedBox(height: 8),
                  Text(
                    'Open FBLA State and your events\nwill be automatically detected.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.5)
                            : AppTheme.mediumGray),
                  ),
                ],
              ),
            ),
          );
        }

        // Group by date
        final now = DateTime.now();
        final byDate = <DateTime, List<ParsedEventModel>>{};
        for (final e in myEvents) {
          final day = DateTime(e.startTime.year, e.startTime.month, e.startTime.day);
          byDate.putIfAbsent(day, () => []).add(e);
        }
        final dates = byDate.keys.toList()..sort();

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: dates.length,
          itemBuilder: (context, di) {
            final day = dates[di];
            final events = byDate[day]!..sort((a, b) => a.startTime.compareTo(b.startTime));
            final isPast = day.isBefore(DateTime(now.year, now.month, now.day));
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
                  child: Row(
                    children: [
                      Text(
                        _formatDate(day),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isPast
                              ? (isDark ? Colors.white38 : Colors.grey)
                              : (isDark ? const Color(0xFF58A6FF) : AppTheme.primaryBlue),
                        ),
                      ),
                      if (!isPast) ...[const SizedBox(width: 6), _upcomingBadge(isDark)],
                    ],
                  ),
                ),
                ...events.map((e) => _myEventCard(e, isDark, isPast)),
              ],
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime d) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
  }

  Widget _upcomingBadge(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.green.withValues(alpha: 0.35)),
      ),
      child: Text('Upcoming',
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.green[300] : Colors.green[700])),
    );
  }

  Widget _myEventCard(ParsedEventModel e, bool isDark, bool isPast) {
    final cardBg = isDark ? const Color(0xFF21262D) : Colors.white;
    final border = isDark ? const Color(0xFF30363D) : const Color(0xFFE5E7EB);
    final textPrimary = isDark ? const Color(0xFFE6EDF3) : const Color(0xFF1A1D26);
    final textSec = isDark ? const Color(0xFF8B949E) : const Color(0xFF6B7280);
    final timeColor = isPast ? textSec : (isDark ? const Color(0xFF58A6FF) : AppTheme.primaryBlue);
    final hour = DateFormat('h:mm a').format(e.startTime);
    return Opacity(
      opacity: isPast ? 0.5 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _openEventGroup(e),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    alignment: Alignment.topCenter,
                    child: Text(hour,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: timeColor)),
                  ),
                  Container(
                      width: 1,
                      height: 48,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      color: isDark ? const Color(0xFF30363D) : const Color(0xFFE5E7EB)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.eventName,
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: textPrimary)),
                        const SizedBox(height: 4),
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
                  // Remove button
                  IconButton(
                    icon: Icon(Icons.bookmark_remove_rounded,
                        size: 20,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.35)
                            : Colors.grey[400]),
                    tooltip: 'Remove from My Events',
                    onPressed: () => _removeFromMyEvents(e),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openEventGroup(ParsedEventModel e) async {
    final user = await _authService.getUserData(
        FirebaseAuth.instance.currentUser?.uid ?? '');
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventDetailPage(
          event: e,
          schoolId: user?.schoolIds.firstOrNull ?? '',
          isAdmin: user?.isAdmin ?? false,
        ),
      ),
    ).then((_) {
      // Refresh list in case the user added/removed this event on the detail page
      if (mounted) setState(() => _myEventsRefreshKey++);
    });
  }

  Future<void> _removeFromMyEvents(ParsedEventModel e) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final id = '${e.eventName}::${e.schoolName ?? ""}';
    try {
      final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final doc = await ref.get();
      if (!doc.exists) return;
      final current =
          List<String>.from(doc.data()?['registeredEvents'] ?? []);
      current.remove(id);
      await ref.update({'registeredEvents': current});
      if (mounted) {
        setState(() => _myEventsRefreshKey++);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed "${e.eventName}"'),
            backgroundColor: Colors.orange[700],
            action: SnackBarAction(
              label: 'Undo',
              textColor: Colors.white,
              onPressed: () async {
                await ref.update({'registeredEvents': current..add(id)});
                if (mounted) setState(() => _myEventsRefreshKey++);
              },
            ),
          ),
        );
      }
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $err'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<List<ParsedEventModel>> _loadMyEvents(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (!doc.exists) return [];
    final saved = List<String>.from(doc.data()?['registeredEvents'] ?? []);
    if (saved.isEmpty) return [];
    final allEvents = await _eventImportService.loadSBLCSchedule();
    return allEvents.where((e) {
      final id = '${e.eventName}::${e.schoolName ?? ""}';
      return saved.contains(id);
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  Widget _buildSignedOutState(bool isDark) {
    return Center(
      child: Text('Sign in to see your events',
          style: TextStyle(
              color: isDark ? Colors.white60 : AppTheme.mediumGray)),
    );
  }

  Widget _buildSchoolEventsTab(bool isDark) {
    return FutureBuilder<UserModel?>(
      future: _authService.getUserData(
        FirebaseAuth.instance.currentUser?.uid ?? '',
      ),
      builder: (context, userSnapshot) {
        final schoolIds = userSnapshot.data?.schoolIds ?? [];
        final currentUserName = userSnapshot.data?.name ?? '';

        return CustomScrollView(
          slivers: [
            // FBLA State 2026 Event Card (Featured)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NCCCEventDetailScreen(
                          schoolId: schoolIds.isNotEmpty ? schoolIds.first : '',
                          currentUserName: currentUserName,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF001231), Color(0xFF0A2463)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF001231).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Background pattern
                        Positioned(
                          right: -20,
                          top: -20,
                          child: Icon(
                            Icons.event_rounded,
                            size: 140,
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.star_rounded,
                                          size: 14,
                                          color: Colors.black,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'FEATURED',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.navigation_rounded,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'AR Nav',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'FBLA State',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'WA SBLC 2026 State Competition',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.calendar_today_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'April 21–23, 2026',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        'Tue–Thu • State Competition',
                                        style: TextStyle(
                                          color: Colors.white60,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.location_on_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'North Creek High School',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          '208 Competition Events',
                                          style: TextStyle(
                                            color: Colors.white60,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'View My Schedule & Navigate',
                                      style: TextStyle(
                                        color: Color(0xFF001231),
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Color(0xFF001231),
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Regular school events (excluding NCCC block)
            ...schoolIds.map((schoolId) {
              return StreamBuilder<List<SchoolEventModel>>(
                stream: _schoolService.getSchoolEvents(schoolId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final events = (snapshot.data ?? [])
                      .where((event) => !_isNcccSchoolEvent(event))
                      .toList();

                  if (events.isEmpty) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildSchoolEventCard(events[index], isDark),
                        ),
                        childCount: events.length,
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ],
        );
      },
    );
  }

  void _organizeCalendarEvents(
    List<EventModel> fblaEvents,
    List<SchoolEventModel> schoolEvents,
  ) {
    final Map<DateTime, List<dynamic>> eventMap = {};

    // Add FBLA events
    for (final event in fblaEvents) {
      final eventDate = DateTime(
        event.startTime.year,
        event.startTime.month,
        event.startTime.day,
      );
      if (eventMap[eventDate] == null) {
        eventMap[eventDate] = [];
      }
      eventMap[eventDate]!.add(event);
    }

    // Add school events
    for (final event in schoolEvents) {
      final eventDate = DateTime(
        event.startTime.year,
        event.startTime.month,
        event.startTime.day,
      );
      if (eventMap[eventDate] == null) {
        eventMap[eventDate] = [];
      }
      eventMap[eventDate]!.add(event);
    }

    setState(() {
      _calendarEvents = eventMap;
    });
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _calendarEvents[normalizedDay] ?? [];
  }

  Future<void> _checkAdminStatus(String? schoolId) async {
    if (schoolId == null) {
      setState(() => _isAdmin = false);
      return;
    }
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;

      final schoolDoc = await _schoolService.getSchool(schoolId);
      if (schoolDoc != null) {
        setState(() {
          _isAdmin = schoolDoc.isAdmin(currentUserId);
        });
      }
    } catch (e) {
      print('Error checking admin status: $e');
    }
  }

  Widget _buildCalendarTab(bool isDark) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return FutureBuilder<UserModel?>(
      future: _authService.getUserData(currentUserId),
      builder: (context, userSnapshot) {
        final schoolIds = userSnapshot.data?.schoolIds ?? [];
        final schoolId = schoolIds.isNotEmpty ? schoolIds.first : null;

        // Check admin status
        if (schoolId != null) {
          _checkAdminStatus(schoolId);
        }

        return StreamBuilder<List<EventModel>>(
          stream: _eventService.getEvents(),
          builder: (context, fblaSnapshot) {
            // Get school events if user is in a school
            if (schoolId != null) {
              return StreamBuilder<List<SchoolEventModel>>(
                stream: _schoolService.getSchoolEvents(schoolId),
                builder: (context, schoolSnapshot) {
                  final fblaEvents = fblaSnapshot.data ?? [];
                  final schoolEvents = schoolSnapshot.data ?? [];

                  // Organize events
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _organizeCalendarEvents(fblaEvents, schoolEvents);
                  });

                  return _buildCalendarContent(
                    isDark,
                    currentUserId,
                    schoolId,
                    fblaEvents,
                    schoolEvents,
                  );
                },
              );
            } else {
              // Only FBLA events
              final fblaEvents = fblaSnapshot.data ?? [];
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _organizeCalendarEvents(fblaEvents, []);
              });

              return _buildCalendarContent(
                isDark,
                currentUserId,
                null,
                fblaEvents,
                [],
              );
            }
          },
        );
      },
    );
  }

  Widget _buildCalendarContent(
    bool isDark,
    String currentUserId,
    String? schoolId,
    List<EventModel> fblaEvents,
    List<SchoolEventModel> schoolEvents,
  ) {
    return Column(
      children: [
        // Calendar
        Container(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          child: Column(
            children: [
              // Add Event button for admins
              if (_isAdmin && schoolId != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(Icons.add_rounded),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CreateSchoolEventScreen(schoolId: schoolId),
                          ),
                        );
                      },
                      tooltip: 'Add School Event',
                    ),
                  ),
                ),
              // Calendar widget
              TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                eventLoader: _getEventsForDay,
                startingDayOfWeek: StartingDayOfWeek.sunday,
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color:
                        (isDark ? AppTheme.darkPrimary : AppTheme.primaryBlue)
                            .withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: isDark ? AppTheme.darkPrimary : AppTheme.primaryBlue,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: AppTheme.success,
                    shape: BoxShape.circle,
                  ),
                  outsideDaysVisible: false,
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                  formatButtonDecoration: BoxDecoration(
                    color: isDark ? AppTheme.darkCard : AppTheme.lightGray,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  formatButtonTextStyle: TextStyle(
                    color: isDark ? Colors.white : AppTheme.black,
                  ),
                ),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                onPageChanged: (focusedDay) {
                  setState(() {
                    _focusedDay = focusedDay;
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Events for selected day
        Expanded(
          child: _selectedDay == null
              ? Center(
                  child: Text(
                    'Select a day to see events',
                    style: TextStyle(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.6)
                          : AppTheme.darkGray,
                    ),
                  ),
                )
              : _buildEventsListForDay(
                  _getEventsForDay(_selectedDay!),
                  isDark,
                  currentUserId,
                  schoolId,
                ),
        ),
      ],
    );
  }

  Widget _buildEventsListForDay(
    List<dynamic> events,
    bool isDark,
    String currentUserId,
    String? schoolId,
  ) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_busy_rounded,
              size: 56,
              color: AppTheme.mediumGray,
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'No events on this day',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white : AppTheme.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final event = events[index];
        if (event is EventModel) {
          return EventCard(event: event);
        } else if (event is SchoolEventModel) {
          return _buildSchoolEventCardForCalendar(
            event,
            isDark,
            currentUserId,
            schoolId,
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSchoolEventCardForCalendar(
    SchoolEventModel event,
    bool isDark,
    String currentUserId,
    String? schoolId,
  ) {
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  event.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.black,
                  ),
                ),
              ),
              if (_isAdmin && schoolId != null)
                IconButton(
                  icon: const Icon(Icons.delete_rounded, color: AppTheme.error),
                  onPressed: () => _deleteSchoolEvent(event.id),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 16,
                color: AppTheme.mediumGray,
              ),
              const SizedBox(width: 4),
              Text(
                event.isAllDay
                    ? 'All Day'
                    : '${DateFormat.jm().format(event.startTime)} - ${DateFormat.jm().format(event.endTime)}',
                style: const TextStyle(color: AppTheme.mediumGray),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 16,
                color: AppTheme.mediumGray,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  event.location,
                  style: const TextStyle(color: AppTheme.mediumGray),
                ),
              ),
            ],
          ),
          if (event.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              event.description,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.8)
                    : AppTheme.darkGray,
              ),
            ),
          ],
          if (event.maxAttendees != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.people_rounded,
                  size: 16,
                  color: AppTheme.mediumGray,
                ),
                const SizedBox(width: 4),
                Text(
                  '${event.attendeeIds.length}/${event.maxAttendees} registered',
                  style: TextStyle(
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
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _registerForSchoolEvent(event),
                  icon: Icon(
                    isRegistered
                        ? Icons.check_circle_rounded
                        : Icons.event_available_rounded,
                    size: 18,
                  ),
                  label: Text(isRegistered ? 'Registered' : 'Register'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isRegistered
                        ? AppTheme.success
                        : AppTheme.primaryBlue,
                    side: BorderSide(
                      color: isRegistered
                          ? AppTheme.success
                          : AppTheme.primaryBlue,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _addToGoogleCalendar(event),
                  icon: const Icon(Icons.calendar_today_rounded, size: 18),
                  label: const Text('Add to Google'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.warning,
                    side: const BorderSide(color: AppTheme.warning),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSchoolEvent(String eventId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _schoolService.deleteSchoolEvent(eventId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Event deleted'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _registerForSchoolEvent(SchoolEventModel event) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      if (event.isUserRegistered(currentUserId)) {
        await _schoolService.unregisterFromEvent(event.id, currentUserId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unregistered from event'),
              backgroundColor: AppTheme.warning,
            ),
          );
        }
      } else {
        if (event.isFull()) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Event is full'),
              backgroundColor: AppTheme.error,
            ),
          );
          return;
        }

        await _schoolService.registerForEvent(event.id, currentUserId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registered for event!'),
              backgroundColor: AppTheme.success,
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

  Future<void> _addToGoogleCalendar(SchoolEventModel event) async {
    final startTime = event.startTime.toUtc();
    final endTime = event.endTime.toUtc();

    final startStr = DateFormat("yyyyMMdd'T'HHmmss'Z'").format(startTime);
    final endStr = DateFormat("yyyyMMdd'T'HHmmss'Z'").format(endTime);

    final url = Uri.parse(
      'https://calendar.google.com/calendar/render?action=TEMPLATE'
      '&text=${Uri.encodeComponent(event.title)}'
      '&dates=$startStr/$endStr'
      '&details=${Uri.encodeComponent(event.description)}'
      '&location=${Uri.encodeComponent(event.location)}',
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
              : AppTheme.success.withValues(alpha: 0.3),
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
                      event.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.location,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.mediumGray,
                      ),
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
                    size: 16,
                    color: AppTheme.success,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
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
                    ? DateFormat('MMM d').format(event.startTime)
                    : DateFormat('MMM d, h:mm a').format(event.startTime),
                style: TextStyle(fontSize: 12, color: AppTheme.mediumGray),
              ),
            ],
          ),
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
  }

  bool _isNcccSchoolEvent(SchoolEventModel event) {
    final titleLower = event.title.toLowerCase();
    final tagsLower = event.tags.map((tag) => tag.toLowerCase());
    return titleLower.contains('nccc') ||
        tagsLower.any((tag) => tag.contains('nccc'));
  }

}
