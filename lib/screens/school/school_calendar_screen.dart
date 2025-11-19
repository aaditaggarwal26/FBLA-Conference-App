import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../services/school_service.dart';
import '../../models/school_event_model.dart';
import '../../theme/app_theme.dart';
import 'create_school_event_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class SchoolCalendarScreen extends StatefulWidget {
  final String schoolId;

  const SchoolCalendarScreen({super.key, required this.schoolId});

  @override
  State<SchoolCalendarScreen> createState() => _SchoolCalendarScreenState();
}

class _SchoolCalendarScreenState extends State<SchoolCalendarScreen> {
  final SchoolService _schoolService = SchoolService();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<SchoolEventModel>> _events = {};
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;

      final schoolDoc = await _schoolService.getSchool(widget.schoolId);
      if (schoolDoc != null) {
        setState(() {
          _isAdmin = schoolDoc.isAdmin(currentUserId);
        });
      }
    } catch (e) {
      print('Error checking admin status: $e');
    }
  }

  List<SchoolEventModel> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  void _organizeEvents(List<SchoolEventModel> events) {
    if (!mounted) return;

    final Map<DateTime, List<SchoolEventModel>> eventMap = {};

    for (final event in events) {
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

    if (mounted) {
      setState(() {
        _events = eventMap;
      });
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

  Future<void> _deleteEvent(String eventId) async {
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

  Future<void> _registerForEvent(SchoolEventModel event) async {
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        title: const Text('School Calendar'),
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CreateSchoolEventScreen(schoolId: widget.schoolId),
                  ),
                );
              },
            ),
        ],
      ),
      body: StreamBuilder<List<SchoolEventModel>>(
        stream: _schoolService.getSchoolEvents(widget.schoolId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final events = snapshot.data ?? [];

          // Organize events only when data changes
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _organizeEvents(events);
          });

          return Column(
            children: [
              // Calendar
              Container(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                child: TableCalendar(
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
                      color: isDark
                          ? AppTheme.darkPrimary
                          : AppTheme.primaryBlue,
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
                    _focusedDay = focusedDay;
                  },
                ),
              ),

              const SizedBox(height: 8),

              // Events for selected day
              Expanded(
                child: _selectedDay == null
                    ? const Center(child: Text('Select a day to see events'))
                    : _buildEventsList(
                        _getEventsForDay(_selectedDay!),
                        isDark,
                        currentUserId,
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEventsList(
    List<SchoolEventModel> events,
    bool isDark,
    String currentUserId,
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
                  if (_isAdmin)
                    IconButton(
                      icon: const Icon(
                        Icons.delete_rounded,
                        color: AppTheme.error,
                      ),
                      onPressed: () => _deleteEvent(event.id),
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
                      onPressed: () => _registerForEvent(event),
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
      },
    );
  }
}
