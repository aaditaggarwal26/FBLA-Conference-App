import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/admin_model.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Check if current user is admin
  Future<bool> isAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final doc = await _firestore.collection('admins').doc(user.uid).get();
      return doc.exists;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  // Get admin model for current user
  Future<AdminModel?> getAdminModel() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('admins').doc(user.uid).get();
      if (doc.exists) {
        return AdminModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting admin model: $e');
      return null;
    }
  }

  // Check if user has specific permission
  Future<bool> hasPermission(String permission) async {
    final admin = await getAdminModel();
    return admin?.hasPermission(permission) ?? false;
  }

  // Grant admin access (super admin only)
  Future<void> grantAdminAccess({
    required String uid,
    required String email,
    required String role,
    required List<String> permissions,
  }) async {
    final admin = AdminModel(
      uid: uid,
      email: email,
      role: role,
      permissions: permissions,
      grantedAt: DateTime.now(),
    );

    await _firestore.collection('admins').doc(uid).set(admin.toFirestore());
  }

  // Revoke admin access
  Future<void> revokeAdminAccess(String uid) async {
    await _firestore.collection('admins').doc(uid).delete();
  }

  // Get all admins
  Stream<List<AdminModel>> getAllAdmins() {
    return _firestore
        .collection('admins')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AdminModel.fromFirestore(doc))
              .toList(),
        );
  }
}
