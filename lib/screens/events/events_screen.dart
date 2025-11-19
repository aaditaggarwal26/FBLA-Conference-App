import 'package:flutter/material.dart';
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
  late TabController _tabController;
  String _selectedCategory = 'All';

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
                      Tab(text: 'FBLA'),
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
                _buildFBLAEventsTab(isDark),
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
                    final schoolEvents = snapshot.data ?? [];

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

  Widget _buildFBLAEventsTab(bool isDark) {
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
                            : (isDark ? AppTheme.darkSurface : Colors.white),
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

        // Events List
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

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_busy_rounded,
                        size: 64,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.3)
                            : Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No events found',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.6)
                              : Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: EventCard(event: snapshot.data![index]),
                  ),
                  childCount: snapshot.data!.length,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSchoolEventsTab(bool isDark) {
    return FutureBuilder<UserModel?>(
      future: _authService.getUserData(
        FirebaseAuth.instance.currentUser?.uid ?? '',
      ),
      builder: (context, userSnapshot) {
        final schoolIds = userSnapshot.data?.schoolIds ?? [];

        if (schoolIds.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.school_outlined,
                  size: 64,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.3)
                      : Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  'No school events',
                  style: TextStyle(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.6)
                        : Colors.grey,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Join a school to see school events',
                  style: TextStyle(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.4)
                        : Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return CustomScrollView(
          slivers: schoolIds.map((schoolId) {
            return StreamBuilder<List<SchoolEventModel>>(
              stream: _schoolService.getSchoolEvents(schoolId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final events = snapshot.data ?? [];

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
}
