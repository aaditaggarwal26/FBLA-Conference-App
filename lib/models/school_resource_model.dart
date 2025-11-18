import 'package:cloud_firestore/cloud_firestore.dart';

class SchoolResourceModel {
  final String id;
  final String schoolId;
  final String title;
  final String description;
  final String url;
  final String type; // 'link', 'document', 'video', etc.
  final String? iconUrl;
  final String createdBy;
  final DateTime createdAt;
  final int priority; // For ordering
  final bool isVisible;

  SchoolResourceModel({
    required this.id,
    required this.schoolId,
    required this.title,
    required this.description,
    required this.url,
    required this.type,
    this.iconUrl,
    required this.createdBy,
    required this.createdAt,
    this.priority = 0,
    this.isVisible = true,
  });

  factory SchoolResourceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SchoolResourceModel(
      id: doc.id,
      schoolId: data['schoolId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      url: data['url'] ?? '',
      type: data['type'] ?? 'link',
      iconUrl: data['iconUrl'],
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      priority: data['priority'] ?? 0,
      isVisible: data['isVisible'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'schoolId': schoolId,
      'title': title,
      'description': description,
      'url': url,
      'type': type,
      'iconUrl': iconUrl,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'priority': priority,
      'isVisible': isVisible,
    };
  }
}
