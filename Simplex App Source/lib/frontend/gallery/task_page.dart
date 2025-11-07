import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../backend/models.dart';
import '../tasks/task_landing_page.dart';
import '../../app_info.dart';
import '../flutter_flow/flutter_flow_theme.dart';
import 'package:flutter/material.dart';

class TaskPage extends StatefulWidget {
  const TaskPage({super.key});

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  List<TaskModel> tasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Future<void> _loadTasks() async {
    String currentChapter = AppInfo.currentUser.currentChapter;

    QuerySnapshot eventQuery = await AppInfo.database
        .collection("chapters")
        .doc(currentChapter)
        .collection('timedObjects')
        .get();

    List<TaskModel> tasks2 = [];
    for (QueryDocumentSnapshot d in eventQuery.docs) {
      if (d.get('type') == 'task') {
        tasks2.add(TaskModel.fromDocumentSnapshot(d));
      }
    }

    final now = DateTime.now().toLocal();
    final today = DateTime(now.year, now.month, now.day);

    final filteredTasks =
        tasks2.where((task) => task.dueDate.isAfter(today)).toList();

    filteredTasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    setState(() {
      tasks = filteredTasks;
    });
  }

  Widget _buildTaskSection() {
    if (tasks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(22),
        child: Center(
          child: Text(
            'No upcoming tasks',
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

    final Map<DateTime, List<TaskModel>> groupedTasks = {};
    for (var task in tasks) {
      final taskDate =
          DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
      groupedTasks.putIfAbsent(taskDate, () => []).add(task);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groupedTasks.entries.map((entry) {
        final date = entry.key;
        final tasksOnDate = entry.value;

        String dateHeader;
        final now = DateTime.now();
        if (isSameDay(date, now)) {
          dateHeader = 'Today';
        } else if (isSameDay(date, now.add(const Duration(days: 1)))) {
          dateHeader = 'Tomorrow';
        } else {
          dateHeader = DateFormat('EEEE, MMMM d').format(date);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 10),
              child: Text(
                dateHeader,
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontFamily: 'Google Sans',
                      color: const Color(0xFF333333),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.0,
                      useGoogleFonts: false,
                    ),
              ),
            ),
            ...tasksOnDate.map(_buildTaskItem),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildTaskItem(TaskModel task) {
    final isCompleted =
        task.usersSubmitted.contains(FirebaseAuth.instance.currentUser?.uid);

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 12),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //     builder: (context) => TaskLandingPageWidget(
              //       task: task,
              //       chapterId: task.chapterId,
              //     ),
              //   ),
              // );

              showModalBottomSheet(
                  isScrollControlled: true,
                  context: context,
                  builder: (context) => TaskLandingPageWidget(
                      task: task, chapterId: task.chapterId));
            },
            child: Container(
              width: MediaQuery.of(context).size.width * 0.905,
              decoration: BoxDecoration(
                color: isCompleted
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFD0D6F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 15, 20, 15),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TASK',
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    fontFamily: 'Google Sans',
                                    color: isCompleted
                                        ? const Color(0xFF4CAF50)
                                        : const Color(0xFF3B58F4),
                                    fontSize: 12,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.bold,
                                    useGoogleFonts: false,
                                  ),
                        ),
                        Text(
                          DateFormat('h.mma')
                              .format(task.dueDate.toLocal())
                              .toLowerCase(),
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    fontFamily: 'Google Sans',
                                    color: isCompleted
                                        ? const Color(0xFF4CAF50)
                                        : const Color(0xFF3B58F4),
                                    fontSize: 13,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.bold,
                                    useGoogleFonts: false,
                                  ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(0, 6, 0, 0),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              task.title,
                              maxLines: 1,
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    fontFamily: 'Google Sans',
                                    color: isCompleted
                                        ? const Color(0xFF4CAF50)
                                        : const Color(0xFF333333),
                                    fontSize: 15,
                                    letterSpacing: 0.0,
                                    decoration: isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                    useGoogleFonts: false,
                                  ),
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
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: const Color(0xFFF5F6F7),
      body: Container(
        width: MediaQuery.of(context).size.width,
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 1,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFFF5F6F7),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                width: MediaQuery.of(context).size.width,
                height: 251,
                child: Stack(
                  children: [
                    Align(
                      alignment: const AlignmentDirectional(0, 0),
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        height: 251,
                        decoration: BoxDecoration(
                          color:
                              FlutterFlowTheme.of(context).secondaryBackground,
                          image: DecorationImage(
                            fit: BoxFit.cover,
                            image: Image.asset(
                              'assets/images/tasksbg.png',
                            ).image,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              blurRadius: 3,
                              color: Color(0x16000000),
                              offset: Offset(0, 3),
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
                        width: MediaQuery.of(context).size.width,
                        height: 251,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0x004C3339), Color(0xFF9F9268)],
                            stops: [0, 1],
                            begin: AlignmentDirectional(0, -1),
                            end: AlignmentDirectional(0, 1),
                          ),
                          borderRadius: BorderRadius.circular(0),
                          border: Border.all(width: 0),
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
                                        'Tasks',
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
                                          'Complete and keep track of tasks!',
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
                padding: const EdgeInsetsDirectional.fromSTEB(0, 12, 0, 0),
                child: _buildTaskSection(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
