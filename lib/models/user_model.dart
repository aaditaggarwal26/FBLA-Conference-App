import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  attendee,
  speaker,
  organizer,
  admin,
}

enum SchoolRole {
  student,
  teacher,
  schoolAdmin,
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
  final String? schoolId; // Deprecated: kept for backwards compatibility
  final List<String> schoolIds; // New: support multiple schools
  final SchoolRole? schoolRole;
  final bool isSchoolOwner;

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
    List<String>? schoolIds,
    this.schoolRole,
    this.isSchoolOwner = false,
  }) : schoolIds = schoolIds ?? (schoolId != null ? [schoolId] : []);

  bool get isAdmin => role == UserRole.admin;
  bool get isOrganizer => role == UserRole.organizer || role == UserRole.admin;
  bool get isSpeaker => role == UserRole.speaker || role == UserRole.organizer || role == UserRole.admin;
  bool get hasSchool => schoolIds.isNotEmpty;
  bool get canJoinMoreSchools => schoolIds.length < 2;
  bool get isSchoolAdminOrTeacher => schoolRole == SchoolRole.schoolAdmin || schoolRole == SchoolRole.teacher || isSchoolOwner;

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
      schoolIds: data['schoolIds'] != null ? List<String>.from(data['schoolIds']) : null,
      schoolRole: data['schoolRole'] != null ? _schoolRoleFromString(data['schoolRole']) : null,
      isSchoolOwner: data['isSchoolOwner'] ?? false,
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

  static SchoolRole _schoolRoleFromString(String role) {
    switch (role.toLowerCase()) {
      case 'teacher':
        return SchoolRole.teacher;
      case 'schooladmin':
      case 'school_admin':
        return SchoolRole.schoolAdmin;
      default:
        return SchoolRole.student;
    }
  }

  static String _schoolRoleToString(SchoolRole? role) {
    if (role == null) return 'student';
    switch (role) {
      case SchoolRole.teacher:
        return 'teacher';
      case SchoolRole.schoolAdmin:
        return 'schoolAdmin';
      case SchoolRole.student:
        return 'student';
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
      'schoolId': schoolIds.isNotEmpty ? schoolIds.first : null, // Backwards compatibility
      'schoolIds': schoolIds,
      'schoolRole': _schoolRoleToString(schoolRole),
      'isSchoolOwner': isSchoolOwner,
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
    List<String>? schoolIds,
    SchoolRole? schoolRole,
    bool? isSchoolOwner,
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
      schoolIds: schoolIds ?? this.schoolIds,
      schoolRole: schoolRole ?? this.schoolRole,
      isSchoolOwner: isSchoolOwner ?? this.isSchoolOwner,
    );
  }
}
