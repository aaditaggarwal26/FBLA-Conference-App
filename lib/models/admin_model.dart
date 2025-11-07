import 'package:cloud_firestore/cloud_firestore.dart';

class AdminModel {
  final String uid;
  final String email;
  final String role; // 'admin' or 'super_admin'
  final List<String> permissions; // ['events', 'announcements', 'users', 'pins']
  final DateTime grantedAt;

  AdminModel({
    required this.uid,
    required this.email,
    required this.role,
    required this.permissions,
    required this.grantedAt,
  });

  factory AdminModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminModel(
      uid: doc.id,
      email: data['email'] ?? '',
      role: data['role'] ?? 'admin',
      permissions: List<String>.from(data['permissions'] ?? []),
      grantedAt: (data['grantedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'role': role,
      'permissions': permissions,
      'grantedAt': Timestamp.fromDate(grantedAt),
    };
  }

  bool hasPermission(String permission) {
    return permissions.contains(permission) || role == 'super_admin';
  }
}
