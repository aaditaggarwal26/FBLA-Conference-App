import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementModel {
  final String id;
  final String title;
  final String content;
  final String? imageUrl;
  final DateTime postedAt;
  final String postedBy;
  final bool isPinned;
  final String category;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.postedAt,
    required this.postedBy,
    this.isPinned = false,
    required this.category,
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
    };
  }
}
