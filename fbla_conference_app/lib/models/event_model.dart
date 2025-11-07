import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final String description;
  final String location;
  final String? imageUrl;
  final DateTime startTime;
  final DateTime endTime;
  final String category;
  final List<String> speakers;
  final int maxCapacity;
  final List<String> registeredUsers;
  final bool isFeatured;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    this.imageUrl,
    required this.startTime,
    required this.endTime,
    required this.category,
    required this.speakers,
    required this.maxCapacity,
    required this.registeredUsers,
    this.isFeatured = false,
  });

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      location: data['location'] ?? '',
      imageUrl: data['imageUrl'],
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      category: data['category'] ?? 'General',
      speakers: List<String>.from(data['speakers'] ?? []),
      maxCapacity: data['maxCapacity'] ?? 0,
      registeredUsers: List<String>.from(data['registeredUsers'] ?? []),
      isFeatured: data['isFeatured'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'location': location,
      'imageUrl': imageUrl,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'category': category,
      'speakers': speakers,
      'maxCapacity': maxCapacity,
      'registeredUsers': registeredUsers,
      'isFeatured': isFeatured,
    };
  }

  bool get isFull => registeredUsers.length >= maxCapacity;
  
  int get availableSpots => maxCapacity - registeredUsers.length;
}
