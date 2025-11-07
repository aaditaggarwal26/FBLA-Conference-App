// ignore_for_file: dead_code

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:simplex_chapter_x/backend/models.dart';
import 'package:simplex_chapter_x/frontend/events/event_landing_page.dart';
import 'package:simplex_chapter_x/frontend/tasks/task_landing_page.dart';

class ShowEvents extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;

  const ShowEvents({required this.startDate, required this.endDate, super.key});

  @override
  _ShowEventsState createState() => _ShowEventsState();
}

class _ShowEventsState extends State<ShowEvents> {
  String? _currentChapter;

  @override
  void initState() {
    super.initState();
    _loadCurrentChapter();
  }

  void _loadCurrentChapter() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        _currentChapter = userDoc.data()?['currentChapter'];
      });
    }
  }

  bool dateRangesOverlap(DateTime startDate1, DateTime endDate1,
      DateTime startDate2, DateTime endDate2) {
    bool overlap = false;

    if (startDate1.compareTo(startDate2) >= 0 &&
        startDate1.compareTo(endDate2) <= 0) {
      overlap = true;
    } else if (endDate1.compareTo(startDate2) >= 0 &&
        endDate1.compareTo(endDate2) <= 0) {
      overlap = true;
    } else if (startDate1.compareTo(startDate2) <= 0 &&
        endDate1.compareTo(endDate2) >= 0) {
      overlap = true;
    }

    return overlap;
  }

  int compareDates(dynamic a, dynamic b) {
    DateTime timeA = a is EventModel ? a.startDate : a.dueDate;
    DateTime timeB = b is EventModel ? b.startDate : b.dueDate;

    return timeA.compareTo(timeB);
  }

  List<dynamic> _filterObjects(
      List<dynamic> allEvents, DateTime startDate, DateTime endDate) {
    // final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    // final now = DateTime.now();

    // Sort events by startt date
    allEvents.sort((a, b) => compareDates(a, b));

    // Filter so that all events occur after or during startDate
    final filteredEvents = allEvents
        // .where((event) => dateRangesOverlap(
        //     event.startDate, event.endDate, startDate, endDate))
        .where((object) => checkDate(object, startDate, endDate))
        .toList();

    // if (filteredEvents.length >= 2) {
    //   // Return the three soonest events
    //   return filteredEvents.take(3).toList();
    // } else
    if (filteredEvents.isNotEmpty) {
      // Return all events in that range
      return filteredEvents;
    } else {
      return [];
    }
  }

  bool checkDate(dynamic object, startDate, endDate) {
    if (object is TaskModel) {
      return object.dueDate.isBefore(endDate) &&
          object.dueDate.isAfter(startDate);
    } else {
      return dateRangesOverlap(
          object.startDate, object.endDate, startDate, endDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentChapter == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Stream<QuerySnapshot<Map<String, dynamic>>> stream1 = FirebaseFirestore.instance
    //       .collection('chapters')
    //       .doc(_currentChapter)
    //       .collection('events')
    //       .snapshots();

    // Stream<QuerySnapshot<Map<String, dynamic>>> stream2 = FirebaseFirestore.instance
    //     .collection('chapters')
    //     .doc(_currentChapter)
    //     .collection('tasks')
    //     .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chapters')
          .doc(_currentChapter)
          .collection('timedObjects')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        final allEvents = (docs as List<dynamic>?)
                ?.where((event) => (event.data() as Map<String, dynamic>)
                    .containsKey("description"))
                .map((event) => timeEventsFromSnapshot(event))
                .toList() ??
            [];

        final eventsToDisplay =
            _filterObjects(allEvents, widget.startDate, widget.endDate);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            eventsToDisplay.isEmpty
                ? const Center(child: Text('No events available'))
                : Column(
                    children: eventsToDisplay
                        .map((event) => event is EventModel
                            ? _buildEventItem(event)
                            : _buildTaskItem(event))
                        .toList(),
                  ),
          ],
        );
      },
    );
  }

  dynamic timeEventsFromSnapshot(DocumentSnapshot doc) {
    if ((doc.data() as Map<String, dynamic>)['type'].toString().toLowerCase() ==
        'task') {
      return TaskModel.fromDocumentSnapshot(doc);
    } else {
      return EventModel.fromDocumentSnapshot(doc);
    }
  }

  // Stream<List<dynamic>> combineStreams(
  //   Stream<QuerySnapshot<Map<String, dynamic>>> eventStream,
  //   Stream<QuerySnapshot<Map<String, dynamic>>> taskStream,
  // ) {
  //   Stream<List<TaskModel>> processedTaskStream = taskStream.map((snapshot) =>
  //     snapshot.docs.map((doc) => TaskModel.fromDocumentSnapshot(doc)).toList());

  //   Stream<List<EventModel>> processedEventStream = eventStream.map((snapshot) =>
  //     snapshot.docs.map((doc) => EventModel.fromDocumentSnapshot(doc)).toList());

  //   Stream<List<dynamic>> combinedStream = StreamZip([processedTaskStream, processedEventStream]);

  //   return combinedStream;

  //   // await for (var snapshot2 in taskStream) {
  //   //   yield snapshot2.docs.map((doc) => TaskModel.fromDocumentSnapshot(doc)).toList();
  //   // }

  //   // print('yo');

  //   // await for (var snapshot1 in eventStream) {
  //   //   yield snapshot1.docs.map((doc) => EventModel.fromDocumentSnapshot(doc)).toList();
  //   // }

  // }

  Widget _buildEventItem(EventModel event) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    // final isUpcoming = event.startDate.isAfter(now);
    final isOngoing = event.startDate.isBefore(now) && event.endDate.isAfter(now);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () {
          showModalBottomSheet(
            isScrollControlled: true,
            context: context,
            backgroundColor: Colors.transparent,
            builder: (context) => EventLandingPageWidget(
              event: event,
              chapterId: _currentChapter!,
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isOngoing
                  ? (isDark
                      ? [const Color(0xFF1E40AF), const Color(0xFF3B82F6)]
                      : [const Color(0xFF4F46E5), const Color(0xFF7C3AED)])
                  : (isDark
                      ? [const Color(0xFF1F2937), const Color(0xFF374151)]
                      : [Colors.white, const Color(0xFFF9FAFB)]),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (isOngoing
                        ? const Color(0xFF4F46E5)
                        : Colors.black)
                    .withValues(alpha: isDark ? 0.3 : 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon container
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isOngoing
                          ? [const Color(0xFF8B5CF6), const Color(0xFFEC4899)]
                          : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.event_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                // Event details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Event type badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isOngoing
                              ? Colors.white.withValues(alpha: 0.25)
                              : (isDark
                                  ? const Color(0xFF374151)
                                  : const Color(0xFFE0E7FF)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          event.eventType.toUpperCase(),
                          style: TextStyle(
                            fontFamily: 'Google Sans',
                            color: isOngoing
                                ? Colors.white
                                : (isDark
                                    ? const Color(0xFF93C5FD)
                                    : const Color(0xFF4F46E5)),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Event name
                      Text(
                        event.name,
                        style: TextStyle(
                          fontFamily: 'Google Sans',
                          color: isOngoing
                              ? Colors.white
                              : (isDark ? Colors.white : const Color(0xFF0F1113)),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Date and time
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: isOngoing
                                ? Colors.white.withValues(alpha: 0.9)
                                : (isDark
                                    ? const Color(0xFF9CA3AF)
                                    : const Color(0xFF6B7280)),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              DateFormat('MMM d, h:mm a').format(event.startDate),
                              style: TextStyle(
                                fontFamily: 'Google Sans',
                                color: isOngoing
                                    ? Colors.white.withValues(alpha: 0.9)
                                    : (isDark
                                        ? const Color(0xFF9CA3AF)
                                        : const Color(0xFF6B7280)),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (event.location.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 14,
                              color: isOngoing
                                  ? Colors.white.withValues(alpha: 0.9)
                                  : (isDark
                                      ? const Color(0xFF9CA3AF)
                                      : const Color(0xFF6B7280)),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                event.location,
                                style: TextStyle(
                                  fontFamily: 'Google Sans',
                                  color: isOngoing
                                      ? Colors.white.withValues(alpha: 0.9)
                                      : (isDark
                                          ? const Color(0xFF9CA3AF)
                                          : const Color(0xFF6B7280)),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Arrow indicator
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: isOngoing
                      ? Colors.white.withValues(alpha: 0.7)
                      : (isDark
                          ? const Color(0xFF6B7280)
                          : const Color(0xFFD1D5DB)),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskItem(TaskModel task) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompleted =
        task.usersSubmitted.contains(FirebaseAuth.instance.currentUser?.uid);
    final isOverdue = task.dueDate.isBefore(DateTime.now()) && !isCompleted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () {
          showModalBottomSheet(
            isScrollControlled: true,
            context: context,
            backgroundColor: Colors.transparent,
            builder: (context) => TaskLandingPageWidget(
              task: task,
              chapterId: _currentChapter!,
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isCompleted
                  ? (isDark
                      ? [const Color(0xFF065F46), const Color(0xFF059669)]
                      : [const Color(0xFFDEF3DD), const Color(0xFFD1FAE5)])
                  : isOverdue
                      ? (isDark
                          ? [const Color(0xFF991B1B), const Color(0xFFDC2626)]
                          : [const Color(0xFFFFE5E5), const Color(0xFFFEE2E2)])
                      : (isDark
                          ? [const Color(0xFF1F2937), const Color(0xFF374151)]
                          : [Colors.white, const Color(0xFFF9FAFB)]),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (isOverdue
                        ? const Color(0xFFDC2626)
                        : isCompleted
                            ? const Color(0xFF059669)
                            : Colors.black)
                    .withValues(alpha: isDark ? 0.3 : 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon container
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isCompleted
                          ? [const Color(0xFF10B981), const Color(0xFF059669)]
                          : isOverdue
                              ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                              : [const Color(0xFFF59E0B), const Color(0xFFEF4444)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: (isCompleted
                                ? const Color(0xFF10B981)
                                : isOverdue
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFFF59E0B))
                            .withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    isCompleted
                        ? Icons.check_circle_rounded
                        : isOverdue
                            ? Icons.warning_rounded
                            : Icons.assignment_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                // Task details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Task status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? (isDark
                                  ? Colors.white.withValues(alpha: 0.25)
                                  : const Color(0xFFD1FAE5))
                              : isOverdue
                                  ? (isDark
                                      ? Colors.white.withValues(alpha: 0.25)
                                      : const Color(0xFFFEE2E2))
                                  : (isDark
                                      ? const Color(0xFF374151)
                                      : const Color(0xFFFEF3C7)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isCompleted
                              ? 'COMPLETED'
                              : isOverdue
                                  ? 'OVERDUE'
                                  : 'TASK',
                          style: TextStyle(
                            fontFamily: 'Google Sans',
                            color: isCompleted
                                ? (isDark ? Colors.white : const Color(0xFF059669))
                                : isOverdue
                                    ? (isDark ? Colors.white : const Color(0xFFDC2626))
                                    : (isDark
                                        ? const Color(0xFFFBBF24)
                                        : const Color(0xFFD97706)),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Task title
                      Text(
                        task.title,
                        style: TextStyle(
                          fontFamily: 'Google Sans',
                          color: isCompleted || isOverdue
                              ? (isDark ? Colors.white : const Color(0xFF0F1113))
                              : (isDark ? Colors.white : const Color(0xFF0F1113)),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Due date
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: isCompleted || isOverdue
                                ? (isDark
                                    ? Colors.white.withValues(alpha: 0.9)
                                    : const Color(0xFF6B7280))
                                : (isDark
                                    ? const Color(0xFF9CA3AF)
                                    : const Color(0xFF6B7280)),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Due ${DateFormat('MMM d, h:mm a').format(task.dueDate)}',
                            style: TextStyle(
                              fontFamily: 'Google Sans',
                              color: isCompleted || isOverdue
                                  ? (isDark
                                      ? Colors.white.withValues(alpha: 0.9)
                                      : const Color(0xFF6B7280))
                                  : (isDark
                                      ? const Color(0xFF9CA3AF)
                                      : const Color(0xFF6B7280)),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Arrow indicator
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: isCompleted || isOverdue
                      ? (isDark
                          ? Colors.white.withValues(alpha: 0.7)
                          : const Color(0xFF6B7280))
                      : (isDark
                          ? const Color(0xFF6B7280)
                          : const Color(0xFFD1D5DB)),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
