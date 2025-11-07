import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../app_info.dart';
import '../../backend/models.dart';
import 'show_all_tasks.dart';
import 'task_landing_page.dart';
import '../flutter_flow/flutter_flow_theme.dart';

class ShowTasks extends StatefulWidget {
  const ShowTasks({super.key});

  @override
  _ShowTasksState createState() => _ShowTasksState();
}

class _ShowTasksState extends State<ShowTasks> {
  String? _currentChapter;

  @override
  void initState() {
    super.initState();
    _loadCurrentChapter();
  }

  void _loadCurrentChapter() async {
    // final user = FirebaseAuth.instance.currentUser;
    // if (user != null) {
    //   final userDoc = await FirebaseFirestore.instance
    //       .collection('users')
    //       .doc(user.uid)
    //       .get();
    //   setState(() {
    //     _currentChapter = userDoc.data()?['currentChapter'];
    //   });
    // }
    setState(() {
      _currentChapter = AppInfo.currentUser.currentChapter;
    });
  }

  List<TaskModel> _getTasksToDisplay(List<TaskModel> allTasks) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final now = DateTime.now();

    // Sort tasks by due date
    allTasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    // Filter incomplete tasks
    final incompleteTasks = allTasks
        .where((task) => !task.usersSubmitted.contains(currentUserId))
        .toList();

    if (incompleteTasks.length >= 2) {
      // Return the two incomplete tasks with the soonest due dates
      return incompleteTasks.take(2).toList();
    } else if (incompleteTasks.isNotEmpty) {
      // Return all incomplete tasks if there are less than 2
      return incompleteTasks;
    } else {
      // If all tasks are complete, return the two tasks with the closest due dates
      return allTasks
          .where((task) => task.dueDate.isAfter(now))
          .take(2)
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentChapter == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chapters')
          .doc(_currentChapter)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final chapterData = snapshot.data!.data() as Map<String, dynamic>?;
        final allTasks = (chapterData?['tasks'] as List<dynamic>?)
                ?.map((task) => TaskModel.fromMap(task))
                .where((task) => !task.dueDate.isBefore(DateTime.now()))
                .toList() ??
            [];

        final tasksToDisplay = _getTasksToDisplay(allTasks);
        final hasIncompleteTasks = allTasks.any((task) => !task.usersSubmitted
            .contains(FirebaseAuth.instance.currentUser?.uid));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'DASHBOARD',
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            fontFamily: 'Google Sans',
                            color: const Color(0xFF333333),
                            fontSize: 18,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.bold,
                            useGoogleFonts: false,
                          ),
                    ),
                    if (hasIncompleteTasks)
                      Padding(
                        padding:
                            const EdgeInsetsDirectional.fromSTEB(8, 0, 0, 0),
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFFD90000),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) =>
                              ShowAllTasksWidget(chapterId: _currentChapter!),
                        ));
                      },
                      child: Text(
                        'See All',
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              fontFamily: 'Google Sans',
                              color: const Color(0xFF3B58F4),
                              fontSize: 12,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.bold,
                              useGoogleFonts: false,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            tasksToDisplay.isEmpty
                ? const Center(child: Text('No tasks available'))
                : Column(
                    children: tasksToDisplay
                        .map((task) => _buildTaskItem(task))
                        .toList(),
                  ),
          ],
        );
      },
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
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => TaskLandingPageWidget(
              task: task,
              chapterId: _currentChapter!,
            ),
          ));
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
                                isCompleted
                                    ? 'COMPLETED'
                                    : isOverdue
                                        ? 'OVERDUE'
                                        : 'PENDING',
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
}
