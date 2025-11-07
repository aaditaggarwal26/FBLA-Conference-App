// ignore_for_file: dead_code

import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:simplex_chapter_x/backend/models.dart';
import 'package:simplex_chapter_x/frontend/events/event_landing_page.dart';
import 'package:simplex_chapter_x/frontend/tasks/task_landing_page.dart';

import '../../app_info.dart';
import '../flutter_flow/flutter_flow_theme.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late DateTime selectedDate;
  late DateTime currentMonth;
  List<dynamic> timedObjects = [];
  bool isMonthView = true;
  late DateTime currentWeekStart;
  String? _currentChapter;

  @override
  void initState() {
    super.initState();
    _loadCurrentChapter();

    selectedDate = DateTime.now().toLocal();
    currentMonth = DateTime(selectedDate.year, selectedDate.month);
    currentWeekStart = _findFirstDayOfWeek(selectedDate);
    _loadAllTimedObjects();
    log(timedObjects.toString());
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

  List<dynamic> _getTimedObjectsForDate(DateTime date) {
    return timedObjects.where((timedObject) {
      if (timedObject is EventModel) {
        return timedObject.startDate.year <= date.year &&
            timedObject.startDate.month <= date.month &&
            timedObject.startDate.day <= date.day &&
            timedObject.endDate.year >= date.year &&
            timedObject.endDate.month >= date.month &&
            timedObject.endDate.day >= date.day;
      } else if (timedObject is TaskModel) {
        return timedObject.dueDate.year == date.year &&
            timedObject.dueDate.month == date.month &&
            timedObject.dueDate.day == date.day;
      } else {
        throw Exception("Invalid object");
      }
    }).toList();
  }

  Widget _buildCalendarGrid() {
    final daysInMonth =
        DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
    final firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
    final startingWeekday = firstDayOfMonth.weekday % 7;

    List<Widget> dayWidgets = [];
    final weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    for (var day in weekDays) {
      dayWidgets.add(
        Expanded(
          child: Center(
            child: Text(
              day,
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    fontFamily: 'Google Sans',
                    color: const Color(0xFF676767),
                    fontSize: 13,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w500,
                    useGoogleFonts: false,
                  ),
            ),
          ),
        ),
      );
    }

    List<Widget> rows = [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: dayWidgets,
      ),
    ];

    List<Widget> currentRow = [];

    for (var i = 0; i < startingWeekday; i++) {
      currentRow.add(
        Expanded(
          child: Container(),
        ),
      );
    }

    for (var i = 1; i <= daysInMonth; i++) {
      final currentDate = DateTime(currentMonth.year, currentMonth.month, i);
      final hasTask = _getTimedObjectsForDate(currentDate).isNotEmpty;
      final isSelected = selectedDate.year == currentDate.year &&
          selectedDate.month == currentDate.month &&
          selectedDate.day == currentDate.day;
      final isToday = DateTime.now().toLocal().year == currentDate.year &&
          DateTime.now().toLocal().month == currentDate.month &&
          DateTime.now().toLocal().day == currentDate.day;

      currentRow.add(
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                selectedDate = currentDate;
              });
            },
            child: Container(
              margin: const EdgeInsets.all(2),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF333333)
                    : isToday
                        ? const Color(0xFF226ADD)
                        : hasTask
                            ? const Color(0xFFFFF3CD)
                            : const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  i.toString(),
                  style: TextStyle(
                    color: isSelected || isToday
                        ? Colors.white
                        : const Color(0xFF969696),
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      if ((startingWeekday + i) % 7 == 0 || i == daysInMonth) {
        if (i == daysInMonth && currentRow.length < 7) {
          while (currentRow.length < 7) {
            currentRow.add(
              Expanded(
                child: Container(),
              ),
            );
          }
        }
        rows.add(
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.from(currentRow),
          ),
        );
        currentRow = [];
      }
    }

    return Column(
      children: rows.map((row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: row,
        );
      }).toList(),
    );
  }

  Widget _buildWeekView() {
    final weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: weekDays
              .map((day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              fontFamily: 'Google Sans',
                              color: const Color(0xFF676767),
                              fontSize: 13,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.w500,
                              useGoogleFonts: false,
                            ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(7, (index) {
            final currentDate = currentWeekStart.add(Duration(days: index));
            final hasTask = _getTimedObjectsForDate(currentDate).isNotEmpty;
            final isSelected = selectedDate.year == currentDate.year &&
                selectedDate.month == currentDate.month &&
                selectedDate.day == currentDate.day;
            final isToday = DateTime.now().toLocal().year == currentDate.year &&
                DateTime.now().toLocal().month == currentDate.month &&
                DateTime.now().toLocal().day == currentDate.day;

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    selectedDate = currentDate;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.all(2),
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF333333)
                        : isToday
                            ? const Color(0xFF226ADD)
                            : hasTask
                                ? const Color(0xFFFFF3CD)
                                : const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      currentDate.day.toString(),
                      style: TextStyle(
                        color: isSelected || isToday
                            ? Colors.white
                            : const Color(0xFF969696),
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildTasksList() {
    final tasksForDate = _getTimedObjectsForDate(selectedDate);

    if (tasksForDate.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(22),
        child: Center(
          child: Text(
            'No tasks or events on ${DateFormat('MMMM d, yyyy').format(selectedDate)}',
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  fontFamily: 'Google Sans',
                  color: const Color(0xFF676767),
                  fontSize: 15,
                  letterSpacing: 0.0,
                  useGoogleFonts: false,
                ),
          ),
        ),
      );
    }

    return Column(
      children: tasksForDate.map((task) {
        if (task is EventModel) {
          return _buildEventItem(task);
        } else {
          return _buildTaskItem(task);
        }
      }).toList(),
    );
  }

  Future<void> _loadAllTimedObjects() async {
    String currentChapter = AppInfo.currentUser.currentChapter;
    DateTime currentDate = DateTime.now().toLocal();
    String formattedDate =
        DateFormat('MMMM d, yyyy').format(currentDate.toLocal());
    log(formattedDate);
    QuerySnapshot eventQuery = await AppInfo.database
        .collection("chapters")
        .doc(currentChapter)
        .collection('timedObjects')
        .get();
    List<EventModel> events = [];
    List<TaskModel> tasks = [];
    for (QueryDocumentSnapshot d in eventQuery.docs) {
      if (d.get('type') == 'event') {
        events.add(EventModel.fromDocumentSnapshot(d));
      } else if (d.get('type') == 'task') {
        // if (currentDate.isAfter(TaskModel.fromDocumentSnapshot(d).dueDate)) {
        //   continue;
        // }
        tasks.add(TaskModel.fromDocumentSnapshot(d));
      }
    }

    setState(() {
      timedObjects = [
        ...events,
        ...tasks,
      ];
      log(timedObjects.toString());
    });
  }

  DateTime _findFirstDayOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday % 7));
  }

  void _toggleView() {
    setState(() {
      isMonthView = !isMonthView;
      if (!isMonthView) {
        currentWeekStart = _findFirstDayOfWeek(selectedDate);
      }
    });
  }

  void _previousPeriod() {
    setState(() {
      if (isMonthView) {
        currentMonth = DateTime(currentMonth.year, currentMonth.month - 1);
      } else {
        currentWeekStart = currentWeekStart.subtract(const Duration(days: 7));
      }
    });
  }

  void _nextPeriod() {
    setState(() {
      if (isMonthView) {
        currentMonth = DateTime(currentMonth.year, currentMonth.month + 1);
      } else {
        currentWeekStart = currentWeekStart.add(const Duration(days: 7));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: const Color(0xFFF5F6F7),
      body: Container(
        width: MediaQuery.sizeOf(context).width,
        constraints: BoxConstraints(
          minHeight: MediaQuery.sizeOf(context).height * 1,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFFF5F6F7),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                width: MediaQuery.sizeOf(context).width,
                height: 251,
                child: Stack(
                  children: [
                    Align(
                      alignment: const AlignmentDirectional(0, 0),
                      child: Container(
                        width: MediaQuery.sizeOf(context).width,
                        height: 251,
                        decoration: BoxDecoration(
                          color:
                              FlutterFlowTheme.of(context).secondaryBackground,
                          image: DecorationImage(
                            fit: BoxFit.cover,
                            image: Image.asset(
                              'assets/images/calendarbg.png',
                            ).image,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              blurRadius: 3,
                              color: Color(0x16000000),
                              offset: Offset(
                                0,
                                3,
                              ),
                            )
                          ],
                          borderRadius: BorderRadius.circular(0),
                          border: Border.all(
                            color: const Color(0xFF021633),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: const AlignmentDirectional(0, 0),
                      child: Container(
                        width: MediaQuery.sizeOf(context).width,
                        height: 251,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0x004C3339),
                              Color.fromARGB(255, 159, 133, 104)
                            ],
                            stops: [0, 1],
                            begin: AlignmentDirectional(0, -1),
                            end: AlignmentDirectional(0, 1),
                          ),
                          borderRadius: BorderRadius.circular(0),
                          border: Border.all(
                            width: 0,
                          ),
                        ),
                        child: Padding(
                          padding:
                              const EdgeInsetsDirectional.fromSTEB(22, 0, 0, 0),
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    0, 65, 22, 0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: Container(
                                        width: 30,
                                        height: 30,
                                        decoration: const BoxDecoration(
                                          color: Colors.black,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Align(
                                          alignment: AlignmentDirectional(0, 0),
                                          child: Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Text(
                                        'Calendar',
                                        style: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              fontFamily: 'Google Sans',
                                              color: Colors.white,
                                              fontSize: 35,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.bold,
                                              useGoogleFonts: false,
                                            ),
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding:
                                        const EdgeInsetsDirectional.fromSTEB(
                                            0, 5, 0, 20),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Text(
                                          'Keep track of all upcoming events.',
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                fontFamily: 'Google Sans',
                                                color: const Color(0xFFFDD0B7),
                                                fontSize: 16,
                                                letterSpacing: 0.0,
                                                useGoogleFonts: false,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(0, 30, 0, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: MediaQuery.sizeOf(context).width * 0.905,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFECECED),
                            borderRadius: BorderRadius.circular(75),
                          ),
                          padding: const EdgeInsets.all(3),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    if (isMonthView) _toggleView();
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: !isMonthView
                                          ? const Color(0xFF333333)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(75),
                                    ),
                                    child: Center(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.view_week_outlined,
                                            color: !isMonthView
                                                ? Colors.white
                                                : const Color(0xFF999999),
                                            size: 18,
                                          ),
                                          Padding(
                                            padding: const EdgeInsetsDirectional
                                                .fromSTEB(8, 0, 0, 0),
                                            child: Text(
                                              'Week',
                                              style: FlutterFlowTheme.of(
                                                      context)
                                                  .bodyMedium
                                                  .override(
                                                    fontFamily: 'Google Sans',
                                                    color: !isMonthView
                                                        ? Colors.white
                                                        : const Color(
                                                            0xFF999999),
                                                    fontSize: 13,
                                                    letterSpacing: 0.0,
                                                    fontWeight: FontWeight.w500,
                                                    useGoogleFonts: false,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    if (!isMonthView) _toggleView();
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isMonthView
                                          ? const Color(0xFF333333)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(75),
                                    ),
                                    child: Center(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.calendar_today,
                                            color: isMonthView
                                                ? Colors.white
                                                : const Color(0xFF999999),
                                            size: 18,
                                          ),
                                          Padding(
                                            padding: const EdgeInsetsDirectional
                                                .fromSTEB(8, 0, 0, 0),
                                            child: Text(
                                              'Month',
                                              style: FlutterFlowTheme.of(
                                                      context)
                                                  .bodyMedium
                                                  .override(
                                                    fontFamily: 'Google Sans',
                                                    color: isMonthView
                                                        ? Colors.white
                                                        : const Color(
                                                            0xFF999999),
                                                    fontSize: 13,
                                                    letterSpacing: 0.0,
                                                    fontWeight: FontWeight.w500,
                                                    useGoogleFonts: false,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(22, 20, 0, 0),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              InkWell(
                                onTap: _previousPeriod,
                                child: const Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      0, 0, 10, 0),
                                  child: Icon(
                                    Icons.arrow_back_ios_new,
                                    color: Color(0xFF333333),
                                    size: 15,
                                  ),
                                ),
                              ),
                              Text(
                                isMonthView
                                    ? DateFormat('MMMM yyyy')
                                        .format(currentMonth)
                                    : '${DateFormat('MMM d').format(currentWeekStart)} - ${DateFormat('MMM d').format(currentWeekStart.add(const Duration(days: 6)))}',
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
                              InkWell(
                                onTap: _nextPeriod,
                                child: const Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      10, 0, 0, 0),
                                  child: Icon(
                                    Icons.arrow_forward_ios,
                                    color: Color(0xFF333333),
                                    size: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(
                      thickness: 1,
                      color: Color(0xFFDDDDDD),
                    ),
                    Padding(
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(22, 20, 22, 0),
                      child:
                          isMonthView ? _buildCalendarGrid() : _buildWeekView(),
                    ),
                    Padding(
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(22, 20, 0, 0),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Text(
                            DateFormat('MMM d, yyyy').format(selectedDate),
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  fontFamily: 'Google Sans',
                                  color: const Color(0xFF333333),
                                  fontSize: 18,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.w500,
                                  useGoogleFonts: false,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(0, 20, 0, 20),
                      child: _buildTasksList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
                // Text(
                //   _formatDate(event.startDate),
                //   style: FlutterFlowTheme.of(context).bodyMedium.override(
                //         fontFamily: 'Google Sans',
                //         color: const Color.fromARGB(255, 107, 107, 107),
                //         fontSize: 20,
                //         letterSpacing: 0.0,
                //         fontWeight: FontWeight.bold,
                //         useGoogleFonts: false,
                //       ),
                // ),
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
    // final isOverdue = task.dueDate.isBefore(DateTime.now()) && !isCompleted;

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
                // : isOverdue
                //     ? const Color(0xFFFFE5E5)
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
                              // : isOverdue
                              //     ? const Color(0xFFFF6B6B)
                              : const Color(0xFFC1AD83),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCompleted
                              ? Icons.check
                              // : isOverdue
                              //     ? Icons.warning
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
                                    // : isOverdue
                                    //     ? 'OVERDUE'
                                    : 'TASK',
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: 'Google Sans',
                                      color: isCompleted
                                          ? const Color(0xFF8CBC89)
                                          // : isOverdue
                                          //     ? const Color(0xFFFF6B6B)
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
    return formatter.format(startDate);
  }
}
