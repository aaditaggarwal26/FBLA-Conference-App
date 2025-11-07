// ignore_for_file: dead_code

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// import 'package:simplex_chapter_x/app_info.dart';
import 'package:simplex_chapter_x/backend/models.dart';
import 'package:simplex_chapter_x/frontend/events/event_landing_page.dart';
import 'package:simplex_chapter_x/frontend/tasks/task_landing_page.dart';

// import 'package:simplex_chapter_x/frontend/tasks/show_all_tasks.dart';
// import 'package:simplex_chapter_x/frontend/tasks/task_landing_page.dart';
import '../flutter_flow/flutter_flow_theme.dart';

class ShowEvents extends StatefulWidget {
  DateTime startDate;
  DateTime endDate;

  ShowEvents({required this.startDate, required this.endDate, super.key});

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
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 10),
      child: GestureDetector(
        onTap: () {
          showModalBottomSheet(
              isScrollControlled: true,
              context: context,
              builder: (context) => EventLandingPageWidget(
                  event: event, chapterId: _currentChapter!));
        },
        child: Container(
          decoration: BoxDecoration(
            // TODO Event types?
            color: true
                ? const Color.fromARGB(255, 208, 242, 255)
                : false
                    ? const Color(0xFFFFE5E5)
                    : const Color(0xFFEEEFEF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(17, 15, 18, 15),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Container(
                        width: 39,
                        height: 39,
                        decoration: const BoxDecoration(
                          // TODO Event colors
                          color: true
                              ? Color.fromARGB(255, 0, 119, 255)
                              : false
                                  ? Color(0xFFFF6B6B)
                                  : Color(0xFFC1AD83),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          // Event icons
                          true
                              ? Icons.calendar_month
                              : false
                                  ? Icons.warning
                                  : Icons.access_time,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding:
                              const EdgeInsetsDirectional.fromSTEB(10, 0, 8, 0),
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                // TODO event type names
                                event.eventType,
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: 'Google Sans',
                                      // TODO event colors
                                      color: true
                                          ? const Color.fromARGB(255, 5, 0, 77)
                                          : false
                                              ? const Color(0xFFFF6B6B)
                                              : const Color(0xFFC1AD83),
                                      fontSize: 12,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.bold,
                                      useGoogleFonts: false,
                                    ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                event.name,
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: 'Google Sans',
                                      color: const Color(0xFF333333),
                                      fontSize: 15,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w500,
                                      useGoogleFonts: false,
                                    ),
                              ),
                              const SizedBox(height: 3),
                              Visibility(
                                visible: !event.allDay,
                                child: Text(
                                  '${_formatTime(event.startDate, event.endDate)}',
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        fontFamily: 'Google Sans',
                                        // TODO color changes?
                                        color: true
                                            ? const Color.fromARGB(
                                                255, 21, 0, 138)
                                            : const Color(0xFF666666),
                                        fontSize: 12,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.normal,
                                        useGoogleFonts: false,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatDate(event.startDate),
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'Google Sans',
                        color: const Color.fromARGB(255, 107, 107, 107),
                        fontSize: 16,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.bold,
                        useGoogleFonts: false,
                      ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFFC8C8C8),
                  size: 12,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskItem(TaskModel task) {
    final isCompleted =
        task.usersSubmitted.contains(FirebaseAuth.instance.currentUser?.uid);
    final isOverdue = task.dueDate.isBefore(DateTime.now()) && !isCompleted;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 10),
      child: GestureDetector(
        onTap: () {
          // Navigator.of(context).push(MaterialPageRoute(
          //   builder: (context) => TaskLandingPageWidget(
          //     task: task,
          //     chapterId: _currentChapter!,
          //   ),
          // ));
          showModalBottomSheet(
              isScrollControlled: true,
              context: context,
              builder: (context) => TaskLandingPageWidget(
                  task: task, chapterId: _currentChapter!));
        },
        child: Container(
          decoration: BoxDecoration(
            color: isCompleted
                ? const Color(0xFFDEF3DD)
                : isOverdue
                    ? const Color(0xFFFFE5E5)
                    : const Color(0xFFEEEFEF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(17, 15, 18, 15),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Container(
                        width: 39,
                        height: 39,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? const Color(0xFF8CBC89)
                              : isOverdue
                                  ? const Color(0xFFFF6B6B)
                                  : const Color(0xFFC1AD83),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCompleted
                              ? Icons.check
                              : isOverdue
                                  ? Icons.warning
                                  : Icons.checklist,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding:
                              const EdgeInsetsDirectional.fromSTEB(10, 0, 8, 0),
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isCompleted
                                    ? 'COMPLETED'
                                    : isOverdue
                                        ? 'OVERDUE'
                                        : 'TASK',
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: 'Google Sans',
                                      color: isCompleted
                                          ? const Color(0xFF8CBC89)
                                          : isOverdue
                                              ? const Color(0xFFFF6B6B)
                                              : const Color(0xFFC1AD83),
                                      fontSize: 12,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.bold,
                                      useGoogleFonts: false,
                                    ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                task.title,
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: 'Google Sans',
                                      color: const Color(0xFF333333),
                                      fontSize: 15,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w500,
                                      useGoogleFonts: false,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatDate(task.dueDate),
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'Google Sans',
                        color: const Color.fromARGB(255, 107, 107, 107),
                        fontSize: 16,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.bold,
                        useGoogleFonts: false,
                      ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFFC8C8C8),
                  size: 12,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime startDate, DateTime endDate) {
    final DateFormat formatter =
        DateFormat('h.mma'); // 12-hour format with AM/PM
    String startTime = formatter
        .format(startDate.toLocal())
        .toLowerCase(); // Format start time
    String endTime =
        formatter.format(endDate.toLocal()).toLowerCase(); // Format end time

    return '$startTime - $endTime';
  }

  String _formatDate(DateTime startDate) {
    DateFormat formatter = DateFormat('MMM dd ');
    return formatter.format(startDate.toLocal());
  }
}
