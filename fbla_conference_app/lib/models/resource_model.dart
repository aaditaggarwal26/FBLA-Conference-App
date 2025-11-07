import 'package:cloud_firestore/cloud_firestore.dart';

class ResourceModel {
  final String id;
  final String title;
  final String description;
  final String url;
  final String category;
  final String? imageUrl;
  final DateTime uploadedAt;
  final String uploadedBy;

  ResourceModel({
    required this.id,
    required this.title,
    required this.description,
    required this.url,
    required this.category,
    this.imageUrl,
    required this.uploadedAt,
    required this.uploadedBy,
  });

  factory ResourceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ResourceModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      url: data['url'] ?? '',
      category: data['category'] ?? 'General',
      imageUrl: data['imageUrl'],
      uploadedAt: (data['uploadedAt'] as Timestamp).toDate(),
      uploadedBy: data['uploadedBy'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'url': url,
      'category': category,
      'imageUrl': imageUrl,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'uploadedBy': uploadedBy,
    };
  }
}
