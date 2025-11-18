import 'package:cloud_firestore/cloud_firestore.dart';

class SchoolResourceModel {
  final String id;
  final String schoolId;
  final String title;
  final String description;
  final String url;
  final String type; // 'document', 'link', 'video', 'file'
  final String uploadedBy;
  final String uploaderName;
  final DateTime uploadedAt;

  SchoolResourceModel({
    required this.id,
    required this.schoolId,
    required this.title,
    required this.description,
    required this.url,
    required this.type,
    required this.uploadedBy,
    required this.uploaderName,
    required this.uploadedAt,
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
      uploadedBy: data['uploadedBy'] ?? '',
      uploaderName: data['uploaderName'] ?? 'Anonymous',
      uploadedAt: (data['uploadedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'schoolId': schoolId,
      'title': title,
      'description': description,
      'url': url,
      'type': type,
      'uploadedBy': uploadedBy,
      'uploaderName': uploaderName,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
    };
  }
}
