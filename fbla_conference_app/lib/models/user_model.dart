import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  attendee,
  speaker,
  organizer,
  admin,
}

class UserModel {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;
  final String? organization;
  final String? position;
  final List<String> registeredEvents;
  final DateTime createdAt;
  final UserRole role;
  final bool isApproved;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    this.organization,
    this.position,
    required this.registeredEvents,
    required this.createdAt,
    this.role = UserRole.attendee,
    this.isApproved = true,
  });

  bool get isAdmin => role == UserRole.admin;
  bool get isOrganizer => role == UserRole.organizer || role == UserRole.admin;
  bool get isSpeaker => role == UserRole.speaker || role == UserRole.organizer || role == UserRole.admin;

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      photoUrl: data['photoUrl'],
      organization: data['organization'],
      position: data['position'],
      registeredEvents: List<String>.from(data['registeredEvents'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      role: _roleFromString(data['role'] as String? ?? 'attendee'),
      isApproved: data['isApproved'] ?? true,
    );
  }

  static UserRole _roleFromString(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'organizer':
        return UserRole.organizer;
      case 'speaker':
        return UserRole.speaker;
      default:
        return UserRole.attendee;
    }
  }

  static String _roleToString(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'admin';
      case UserRole.organizer:
        return 'organizer';
      case UserRole.speaker:
        return 'speaker';
      case UserRole.attendee:
        return 'attendee';
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'organization': organization,
      'position': position,
      'registeredEvents': registeredEvents,
      'createdAt': Timestamp.fromDate(createdAt),
      'role': _roleToString(role),
      'isApproved': isApproved,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? photoUrl,
    String? organization,
    String? position,
    List<String>? registeredEvents,
    DateTime? createdAt,
    UserRole? role,
    bool? isApproved,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      organization: organization ?? this.organization,
      position: position ?? this.position,
      registeredEvents: registeredEvents ?? this.registeredEvents,
      createdAt: createdAt ?? this.createdAt,
      role: role ?? this.role,
      isApproved: isApproved ?? this.isApproved,
    );
  }
}
