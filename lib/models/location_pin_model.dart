import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' show sin, cos, sqrt, asin, pi;

class LocationPinModel {
  final String id;
  final String schoolId;
  final String name;
  final String? description;
  final double latitude;
  final double longitude;
  final int floorLevel; // 0 for ground floor, 1 for first floor, etc.
  final String? buildingName;
  final String? imageUrl; // Optional image of the location
  final String? arReferenceImageUrl; // Optional AR reference image
  final DateTime createdAt;
  final String createdBy; // Admin who created this pin
  final Map<String, dynamic>? metadata; // Additional data like room number, etc.

  LocationPinModel({
    required this.id,
    required this.schoolId,
    required this.name,
    this.description,
    required this.latitude,
    required this.longitude,
    required this.floorLevel,
    this.buildingName,
    this.imageUrl,
    this.arReferenceImageUrl,
    required this.createdAt,
    required this.createdBy,
    this.metadata,
  });

  factory LocationPinModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LocationPinModel(
      id: doc.id,
      schoolId: data['schoolId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'],
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      floorLevel: data['floorLevel'] ?? 0,
      buildingName: data['buildingName'],
      imageUrl: data['imageUrl'],
      arReferenceImageUrl: data['arReferenceImageUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'schoolId': schoolId,
      'name': name,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'floorLevel': floorLevel,
      'buildingName': buildingName,
      'imageUrl': imageUrl,
      'arReferenceImageUrl': arReferenceImageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'metadata': metadata,
    };
  }

  // Calculate distance to another location in meters
  double distanceTo(double otherLat, double otherLong) {
    const double earthRadius = 6371000; // meters
    final dLat = _toRadians(otherLat - latitude);
    final dLon = _toRadians(otherLong - longitude);
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(latitude)) *
            cos(_toRadians(otherLat)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    
    final c = 2 * asin(sqrt(a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (pi / 180.0);
  }

  LocationPinModel copyWith({
    String? id,
    String? schoolId,
    String? name,
    String? description,
    double? latitude,
    double? longitude,
    int? floorLevel,
    String? buildingName,
    String? imageUrl,
    String? arReferenceImageUrl,
    DateTime? createdAt,
    String? createdBy,
    Map<String, dynamic>? metadata,
  }) {
    return LocationPinModel(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      name: name ?? this.name,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      floorLevel: floorLevel ?? this.floorLevel,
      buildingName: buildingName ?? this.buildingName,
      imageUrl: imageUrl ?? this.imageUrl,
      arReferenceImageUrl: arReferenceImageUrl ?? this.arReferenceImageUrl,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      metadata: metadata ?? this.metadata,
    );
  }
}
