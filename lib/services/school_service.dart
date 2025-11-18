import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/school_model.dart';
import '../models/school_announcement_model.dart';
import '../models/school_resource_model.dart';
import '../models/school_join_request_model.dart';
import 'auth_service.dart';

class SchoolService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new school
  Future<String> createSchool(SchoolModel school) async {
    final doc = await _firestore.collection('schools').add(school.toFirestore());
    
    // Add creator as admin and member
    await _firestore.collection('schools').doc(doc.id).update({
      'adminIds': [school.ownerId],
      'memberIds': [school.ownerId],
    });

    // Update user's profile with school info and role
    final authService = AuthService();
    await authService.updateUserSchoolInfo(
      school.ownerId,
      doc.id,
      isOwner: true,
      isAdmin: true,
    );

    return doc.id;
  }

  // Get school by ID
  Future<SchoolModel?> getSchool(String schoolId) async {
    final doc = await _firestore.collection('schools').doc(schoolId).get();
    if (doc.exists) {
      return SchoolModel.fromFirestore(doc);
    }
    return null;
  }

  // Get schools owned by user
  Stream<List<SchoolModel>> getMySchools(String userId) {
    return _firestore
        .collection('schools')
        .where('ownerId', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SchoolModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Get schools user is a member of
  Stream<List<SchoolModel>> getJoinedSchools(String userId) {
    return _firestore
        .collection('schools')
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SchoolModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Join a school
  Future<void> joinSchool(String schoolId, String userId) async {
    await _firestore.collection('schools').doc(schoolId).update({
      'memberIds': FieldValue.arrayUnion([userId]),
    });

    // Update user profile with student role
    final authService = AuthService();
    await authService.updateUserSchoolInfo(
      userId,
      schoolId,
      isOwner: false,
      isAdmin: false,
    );
  }

  // Leave a school
  Future<void> leaveSchool(String schoolId, String userId) async {
    final school = await getSchool(schoolId);
    if (school == null || school.ownerId == userId) {
      throw Exception('Cannot leave school you own. Transfer ownership first.');
    }

    // Remove from school
    await _firestore.collection('schools').doc(schoolId).update({
      'memberIds': FieldValue.arrayRemove([userId]),
      'adminIds': FieldValue.arrayRemove([userId]),
    });

    // Clear school info from user profile
    await _firestore.collection('users').doc(userId).update({
      'schoolId': null,
      'schoolRole': 'student',
      'isSchoolOwner': false,
    });
  }

  // Add admin to school
  Future<void> addAdmin(String schoolId, String userId) async {
    await _firestore.collection('schools').doc(schoolId).update({
      'adminIds': FieldValue.arrayUnion([userId]),
      'memberIds': FieldValue.arrayUnion([userId]), // Ensure they're also a member
    });

    // Update user role to admin
    final authService = AuthService();
    await authService.updateUserSchoolInfo(
      userId,
      schoolId,
      isOwner: false,
      isAdmin: true,
    );
  }

  // Remove admin from school
  Future<void> removeAdmin(String schoolId, String userId) async {
    final school = await getSchool(schoolId);
    if (school == null || school.ownerId == userId) {
      throw Exception('Cannot remove school owner as admin');
    }

    await _firestore.collection('schools').doc(schoolId).update({
      'adminIds': FieldValue.arrayRemove([userId]),
    });

    // Update user role back to student (keep them in school)
    await _firestore.collection('users').doc(userId).update({
      'schoolRole': 'student',
    });
  }

  // Remove member from school
  Future<void> removeMember(String schoolId, String userId) async {
    final school = await getSchool(schoolId);
    if (school == null || school.ownerId == userId) {
      throw Exception('Cannot remove school owner');
    }

    await _firestore.collection('schools').doc(schoolId).update({
      'memberIds': FieldValue.arrayRemove([userId]),
      'adminIds': FieldValue.arrayRemove([userId]),
    });

    // Clear school info from user
    await _firestore.collection('users').doc(userId).update({
      'schoolId': null,
      'schoolRole': 'student',
      'isSchoolOwner': false,
    });
  }

  // Create announcement
  Future<void> createAnnouncement(SchoolAnnouncementModel announcement) async {
    await _firestore
        .collection('school_announcements')
        .add(announcement.toFirestore());
  }

  // Get announcements for a school
  Stream<List<SchoolAnnouncementModel>> getSchoolAnnouncements(
    String schoolId,
  ) {
    return _firestore
        .collection('school_announcements')
        .where('schoolId', isEqualTo: schoolId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SchoolAnnouncementModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Delete announcement
  Future<void> deleteAnnouncement(String announcementId) async {
    await _firestore.collection('school_announcements').doc(announcementId).delete();
  }

  // Create resource
  Future<void> createResource(SchoolResourceModel resource) async {
    await _firestore.collection('school_resources').add(resource.toFirestore());
  }

  // Get resources for a school
  Stream<List<SchoolResourceModel>> getSchoolResources(String schoolId) {
    return _firestore
        .collection('school_resources')
        .where('schoolId', isEqualTo: schoolId)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SchoolResourceModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Delete resource
  Future<void> deleteResource(String resourceId) async {
    await _firestore.collection('school_resources').doc(resourceId).delete();
  }

  // Update school info
  Future<void> updateSchool(String schoolId, Map<String, dynamic> updates) async {
    await _firestore.collection('schools').doc(schoolId).update(updates);
  }

  // Search schools
  Future<List<SchoolModel>> searchSchools(String query) async {
    final snapshot = await _firestore
        .collection('schools')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .limit(20)
        .get();

    return snapshot.docs
        .map((doc) => SchoolModel.fromFirestore(doc))
        .toList();
  }

  // Get school by join code
  Future<SchoolModel?> getSchoolByJoinCode(String joinCode) async {
    final snapshot = await _firestore
        .collection('schools')
        .where('joinCode', isEqualTo: joinCode)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return SchoolModel.fromFirestore(snapshot.docs.first);
  }

  // Create join request
  Future<String> createJoinRequest(SchoolJoinRequestModel request) async {
    final doc = await _firestore
        .collection('school_join_requests')
        .add(request.toFirestore());
    return doc.id;
  }

  // Get pending join requests for a school
  Stream<List<SchoolJoinRequestModel>> getPendingJoinRequests(String schoolId) {
    return _firestore
        .collection('school_join_requests')
        .where('schoolId', isEqualTo: schoolId)
        .where('status', isEqualTo: JoinRequestStatus.pending.name)
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SchoolJoinRequestModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Approve join request
  Future<void> approveJoinRequest(String requestId, String adminId) async {
    final request = await _firestore
        .collection('school_join_requests')
        .doc(requestId)
        .get();

    if (!request.exists) throw Exception('Request not found');

    final data = request.data() as Map<String, dynamic>;
    final userId = data['userId'];
    final schoolId = data['schoolId'];

    // Add user to school
    await joinSchool(schoolId, userId);

    // Update request status
    await _firestore.collection('school_join_requests').doc(requestId).update({
      'status': JoinRequestStatus.approved.name,
      'reviewedBy': adminId,
      'reviewedAt': Timestamp.now(),
    });
  }

  // Reject join request
  Future<void> rejectJoinRequest(
    String requestId,
    String adminId,
    String? reason,
  ) async {
    await _firestore.collection('school_join_requests').doc(requestId).update({
      'status': JoinRequestStatus.rejected.name,
      'reviewedBy': adminId,
      'reviewedAt': Timestamp.now(),
      'rejectionReason': reason,
    });
  }

  // Check if user has pending request for school
  Future<bool> hasPendingRequest(String schoolId, String userId) async {
    final snapshot = await _firestore
        .collection('school_join_requests')
        .where('schoolId', isEqualTo: schoolId)
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: JoinRequestStatus.pending.name)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }
}
