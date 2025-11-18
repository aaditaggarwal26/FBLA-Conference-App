import 'package:cloud_firestore/cloud_firestore.dart';

class SchoolEventModel {
  final String id;
  final String schoolId;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String location;
  final String? imageUrl;
  final String createdBy; // Admin who created the event
  final String creatorName;
  final DateTime createdAt;
  final bool isAllDay;
  final List<String> attendeeIds; // Students who registered
  final int? maxAttendees;
  final String? meetingLink; // For virtual events
  final List<String> tags; // e.g., ['sports', 'academic', 'club']

  SchoolEventModel({
    required this.id,
    required this.schoolId,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.location,
    this.imageUrl,
    required this.createdBy,
    required this.creatorName,
    required this.createdAt,
    this.isAllDay = false,
    this.attendeeIds = const [],
    this.maxAttendees,
    this.meetingLink,
    this.tags = const [],
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
      location: data['location'] ?? '',
      imageUrl: data['imageUrl'],
      createdBy: data['createdBy'] ?? '',
      creatorName: data['creatorName'] ?? 'Admin',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isAllDay: data['isAllDay'] ?? false,
      attendeeIds: List<String>.from(data['attendeeIds'] ?? []),
      maxAttendees: data['maxAttendees'],
      meetingLink: data['meetingLink'],
      tags: List<String>.from(data['tags'] ?? []),
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
      'creatorName': creatorName,
      'createdAt': Timestamp.fromDate(createdAt),
      'isAllDay': isAllDay,
      'attendeeIds': attendeeIds,
      'maxAttendees': maxAttendees,
      'meetingLink': meetingLink,
      'tags': tags,
    };
  }

  bool isFull() {
    if (maxAttendees == null) return false;
    return attendeeIds.length >= maxAttendees!;
  }

  bool isUserRegistered(String userId) {
    return attendeeIds.contains(userId);
  }

  bool isUpcoming() {
    return startTime.isAfter(DateTime.now());
  }

  bool isOngoing() {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  bool isPast() {
    return endTime.isBefore(DateTime.now());
  }
}
