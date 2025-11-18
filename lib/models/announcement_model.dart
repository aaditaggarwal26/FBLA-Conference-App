import 'package:cloud_firestore/cloud_firestore.dart';

enum AnnouncementType {
  national, // From FBLA nationals
  school, // From specific school
}

class AnnouncementModel {
  final String id;
  final String title;
  final String content;
  final String? imageUrl;
  final DateTime postedAt;
  final String postedBy;
  final bool isPinned;
  final String category;
  final AnnouncementType type;
  final String? schoolId; // Only set if type is school

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.postedAt,
    required this.postedBy,
    this.isPinned = false,
    required this.category,
    this.type = AnnouncementType.national,
    this.schoolId,
  });

  factory AnnouncementModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AnnouncementModel(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'],
      postedAt: (data['postedAt'] as Timestamp).toDate(),
      postedBy: data['postedBy'] ?? '',
      isPinned: data['isPinned'] ?? false,
      category: data['category'] ?? 'General',
      type: data['type'] == 'school' ? AnnouncementType.school : AnnouncementType.national,
      schoolId: data['schoolId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'postedAt': Timestamp.fromDate(postedAt),
      'postedBy': postedBy,
      'isPinned': isPinned,
      'category': category,
      'type': type == AnnouncementType.school ? 'school' : 'national',
      'schoolId': schoolId,
    };
  }

  bool get isNational => type == AnnouncementType.national;
  bool get isSchool => type == AnnouncementType.school;
}
