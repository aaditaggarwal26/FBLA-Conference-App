import 'package:cloud_firestore/cloud_firestore.dart';

class ParsedEventModel {
  final String id;
  final String schoolId;
  final String eventName;
  final String location; // Location code like "2233", "2208", etc.
  final DateTime startTime;
  final DateTime endTime;
  final List<String> participants; // List of participant names
  final String? performLocation;
  final String? prepLocation;
  final String? locationPinId; // Reference to LocationPinModel
  final Map<String, dynamic>? metadata; // Additional data like section, final/prelim, etc.

  ParsedEventModel({
    required this.id,
    required this.schoolId,
    required this.eventName,
    required this.location,
    required this.startTime,
    required this.endTime,
    required this.participants,
    this.performLocation,
    this.prepLocation,
    this.locationPinId,
    this.metadata,
  });

  factory ParsedEventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ParsedEventModel(
      id: doc.id,
      schoolId: data['schoolId'] ?? '',
      eventName: data['eventName'] ?? '',
      location: data['location'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      participants: List<String>.from(data['participants'] ?? []),
      performLocation: data['performLocation'],
      prepLocation: data['prepLocation'],
      locationPinId: data['locationPinId'],
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'schoolId': schoolId,
      'eventName': eventName,
      'location': location,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'participants': participants,
      'performLocation': performLocation,
      'prepLocation': prepLocation,
      'locationPinId': locationPinId,
      'metadata': metadata,
    };
  }

  bool hasLocationPin() => locationPinId != null && locationPinId!.isNotEmpty;

  ParsedEventModel copyWith({
    String? id,
    String? schoolId,
    String? eventName,
    String? location,
    DateTime? startTime,
    DateTime? endTime,
    List<String>? participants,
    String? performLocation,
    String? prepLocation,
    String? locationPinId,
    Map<String, dynamic>? metadata,
  }) {
    return ParsedEventModel(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      eventName: eventName ?? this.eventName,
      location: location ?? this.location,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      participants: participants ?? this.participants,
      performLocation: performLocation ?? this.performLocation,
      prepLocation: prepLocation ?? this.prepLocation,
      locationPinId: locationPinId ?? this.locationPinId,
      metadata: metadata ?? this.metadata,
    );
  }
}
