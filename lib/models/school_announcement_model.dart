import 'package:cloud_firestore/cloud_firestore.dart';

class SchoolAnnouncementModel {
  final String id;
  final String schoolId;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final bool isPinned;
  final List<String> attachments;

  SchoolAnnouncementModel({
    required this.id,
    required this.schoolId,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    this.isPinned = false,
    this.attachments = const [],
  });

  factory SchoolAnnouncementModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SchoolAnnouncementModel(
      id: doc.id,
      schoolId: data['schoolId'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Anonymous',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isPinned: data['isPinned'] ?? false,
      attachments: List<String>.from(data['attachments'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'schoolId': schoolId,
      'title': title,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': Timestamp.fromDate(createdAt),
      'isPinned': isPinned,
      'attachments': attachments,
    };
  }
}
