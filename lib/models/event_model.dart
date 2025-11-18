import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String location;
  final String? imageUrl;
  final String category;
  final List<String> speakers;
  final List<String> attendeeIds;
  final int capacity;

  // Aliases for backwards compatibility
  List<String> get registeredUsers => attendeeIds;
  int get maxCapacity => capacity;
  final String organizerId;
  final String? qrCode;
  final bool isRequired;
  final Map<String, dynamic>? metadata;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.location,
    this.imageUrl,
    this.category = 'General',
    this.speakers = const [],
    this.attendeeIds = const [],
    this.capacity = 100,
    required this.organizerId,
    this.qrCode,
    this.isRequired = false,
    this.metadata,
  });

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      startTime: (data['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (data['endTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      location: data['location'] ?? '',
      imageUrl: data['imageUrl'],
      category: data['category'] ?? 'General',
      speakers: List<String>.from(data['speakers'] ?? []),
      attendeeIds: List<String>.from(data['attendeeIds'] ?? []),
      capacity: data['capacity'] ?? 100,
      organizerId: data['organizerId'] ?? '',
      qrCode: data['qrCode'],
      isRequired: data['isRequired'] ?? false,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'location': location,
      'imageUrl': imageUrl,
      'category': category,
      'speakers': speakers,
      'attendeeIds': attendeeIds,
      'capacity': capacity,
      'organizerId': organizerId,
      'qrCode': qrCode,
      'isRequired': isRequired,
      'metadata': metadata,
    };
  }

  bool get isFull => attendeeIds.length >= capacity;
  bool get isUpcoming => startTime.isAfter(DateTime.now());
  bool get isOngoing => 
      DateTime.now().isAfter(startTime) && 
      DateTime.now().isBefore(endTime);
  bool get isPast => endTime.isBefore(DateTime.now());

  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    String? imageUrl,
    String? category,
    List<String>? speakers,
    List<String>? attendeeIds,
    int? capacity,
    String? organizerId,
    String? qrCode,
    bool? isRequired,
    Map<String, dynamic>? metadata,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      speakers: speakers ?? this.speakers,
      attendeeIds: attendeeIds ?? this.attendeeIds,
      capacity: capacity ?? this.capacity,
      organizerId: organizerId ?? this.organizerId,
      qrCode: qrCode ?? this.qrCode,
      isRequired: isRequired ?? this.isRequired,
      metadata: metadata ?? this.metadata,
    );
  }
}
