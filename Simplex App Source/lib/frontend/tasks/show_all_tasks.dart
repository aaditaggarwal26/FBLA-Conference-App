import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../backend/models.dart';
import 'task_landing_page.dart';
import '../flutter_flow/flutter_flow_theme.dart';

class ShowAllTasksWidget extends StatelessWidget {
  final String chapterId;

  const ShowAllTasksWidget({super.key, required this.chapterId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('All Tasks'),
        backgroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chapters')
            .doc(chapterId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final chapterData = snapshot.data!.data() as Map<String, dynamic>?;
          final tasks = (chapterData?['tasks'] as List<dynamic>?)
                  ?.map((task) => TaskModel.fromMap(task))
                  .where((task) => !task.dueDate.isBefore(DateTime.now()))
                  .toList() ??
              [];

          tasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));

          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              return _buildTaskItem(context, tasks[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildTaskItem(BuildContext context, TaskModel task) {
    final isCompleted =
        task.usersSubmitted.contains(FirebaseAuth.instance.currentUser?.uid);
    final isOverdue = task.dueDate.isBefore(DateTime.now()) && !isCompleted;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 8),
      child: GestureDetector(
        onTap: () {
          showModalBottomSheet(
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25.0),
                    topRight: Radius.circular(25.0)),
              ),
              backgroundColor: const Color(0xFFF5F6F7),
              context: context,
              builder: (context) {
                return TaskLandingPageWidget(
                  task: task,
                  chapterId: chapterId,
                );
              });
          // Navigator.of(context).push(MaterialPageRoute(
          //   builder: (context) => TaskLandingPageWidget(
          //     task: task,
          //     chapterId: chapterId,
          //   ),
          // ));
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
                              const SizedBox(height: 3),
                              Text(
                                'Due: ${_formatDate(task.dueDate)}',
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: 'Google Sans',
                                      color: isOverdue
                                          ? const Color(0xFFFF6B6B)
                                          : const Color(0xFF666666),
                                      fontSize: 12,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.normal,
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

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
