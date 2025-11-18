import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  attendee,
  speaker,
  organizer,
  admin,
  student,
  schoolAdmin,
  superAdmin,
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
  final String? schoolId; // Links user to their school

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
    this.schoolId,
  });

  bool get isAdmin => role == UserRole.admin;
  bool get isSchoolAdmin => role == UserRole.schoolAdmin;
  bool get isSuperAdmin => role == UserRole.superAdmin;
  bool get isStudent => role == UserRole.student;
  bool get isOrganizer => role == UserRole.organizer || role == UserRole.admin || role == UserRole.superAdmin;
  bool get isSpeaker => role == UserRole.speaker || role == UserRole.organizer || role == UserRole.admin || role == UserRole.superAdmin;

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
      schoolId: data['schoolId'],
    );
  }

  static UserRole _roleFromString(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'super_admin':
      case 'superadmin':
        return UserRole.superAdmin;
      case 'school_admin':
      case 'schooladmin':
        return UserRole.schoolAdmin;
      case 'student':
        return UserRole.student;
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
      case UserRole.superAdmin:
        return 'super_admin';
      case UserRole.schoolAdmin:
        return 'school_admin';
      case UserRole.student:
        return 'student';
      case UserRole.organizer:
        return 'organizer';
      case UserRole.speaker:
        return 'speaker';
      default:
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
      'schoolId': schoolId,
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
    String? schoolId,
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
      schoolId: schoolId ?? this.schoolId,
    );
  }
}
