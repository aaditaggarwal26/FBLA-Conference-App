import 'package:cloud_firestore/cloud_firestore.dart';

class SchoolEventModel {
  final String id;
  final String schoolId;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;
  final String? imageUrl;
  final String createdBy;
  final DateTime createdAt;
  final List<String> attendees;
  final bool isPublic;

  SchoolEventModel({
    required this.id,
    required this.schoolId,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    this.location,
    this.imageUrl,
    required this.createdBy,
    required this.createdAt,
    required this.attendees,
    this.isPublic = true,
  });

  factory SchoolEventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SchoolEventModel(
      id: doc.id,
      schoolId: data['schoolId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      location: data['location'],
      imageUrl: data['imageUrl'],
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      attendees: List<String>.from(data['attendees'] ?? []),
      isPublic: data['isPublic'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'schoolId': schoolId,
      'title': title,
      'description': description,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'location': location,
      'imageUrl': imageUrl,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'attendees': attendees,
      'isPublic': isPublic,
    };
  }
}
