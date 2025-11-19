import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/school_model.dart';
import '../models/school_announcement_model.dart';
import '../models/school_resource_model.dart';
import '../models/school_join_request_model.dart';
import '../models/school_event_model.dart';
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

    // Update user profile to add school to schoolIds array
    final authService = AuthService();
    final user = await authService.getUserData(userId);
    if (user != null) {
      final updatedSchoolIds = List<String>.from(user.schoolIds);
      if (!updatedSchoolIds.contains(schoolId)) {
        updatedSchoolIds.add(schoolId);
      }
      await _firestore.collection('users').doc(userId).update({
        'schoolIds': updatedSchoolIds,
        'schoolId': updatedSchoolIds.first, // Backwards compatibility
      });
    }
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

    // Update user's schoolIds array
    final authService = AuthService();
    final user = await authService.getUserData(userId);
    if (user != null) {
      final updatedSchoolIds = List<String>.from(user.schoolIds);
      updatedSchoolIds.remove(schoolId);
      
      await _firestore.collection('users').doc(userId).update({
        'schoolIds': updatedSchoolIds,
        'schoolId': updatedSchoolIds.isNotEmpty ? updatedSchoolIds.first : null,
        'schoolRole': updatedSchoolIds.isEmpty ? 'student' : null,
        'isSchoolOwner': false,
      });
    }
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
    // Query without orderBy to avoid index requirement, sort in memory instead
    return _firestore
        .collection('school_announcements')
        .where('schoolId', isEqualTo: schoolId)
        .snapshots()
        .map(
          (snapshot) {
            final announcements = snapshot.docs
                .map((doc) {
                  try {
                    return SchoolAnnouncementModel.fromFirestore(doc);
                  } catch (e) {
                    print('Error parsing announcement ${doc.id}: $e');
                    print('Document data: ${doc.data()}');
                    return null;
                  }
                })
                .whereType<SchoolAnnouncementModel>()
                .toList();
            // Sort by createdAt descending (newest first)
            announcements.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return announcements;
          },
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
    // Query without orderBy to avoid index requirement, sort in memory instead
    return _firestore
        .collection('school_resources')
        .where('schoolId', isEqualTo: schoolId)
        .snapshots()
        .map(
          (snapshot) {
            final resources = snapshot.docs
                .map((doc) {
                  try {
                    return SchoolResourceModel.fromFirestore(doc);
                  } catch (e) {
                    print('Error parsing resource ${doc.id}: $e');
                    print('Document data: ${doc.data()}');
                    return null;
                  }
                })
                .whereType<SchoolResourceModel>()
                .toList();
            // Sort by uploadedAt descending (newest first)
            resources.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
            return resources;
          },
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
    print('🔔 Creating join request for school: ${request.schoolId}');
    print('🔔 User: ${request.userName} (${request.userId})');
    
    final doc = await _firestore
        .collection('school_join_requests')
        .add(request.toFirestore());
    
    print('🔔 Join request created with ID: ${doc.id}');
    return doc.id;
  }

  // Get pending join requests for a school
  Stream<List<SchoolJoinRequestModel>> getPendingJoinRequests(String schoolId) {
    print('🔍 Setting up stream for join requests, schoolId: $schoolId');
    
    return _firestore
        .collection('school_join_requests')
        .where('schoolId', isEqualTo: schoolId)
        .where('status', isEqualTo: JoinRequestStatus.pending.name)
        .snapshots()
        .map(
          (snapshot) {
            print('🔍 Received ${snapshot.docs.length} join request docs');
            final requests = snapshot.docs
                .map((doc) {
                  print('🔍 Request doc: ${doc.id} - ${doc.data()}');
                  return SchoolJoinRequestModel.fromFirestore(doc);
                })
                .toList();
            // Sort in-memory to avoid index requirement
            requests.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
            print('🔍 Returning ${requests.length} processed requests');
            return requests;
          },
        );
  }

  // Approve join request
  Future<void> approveJoinRequest(String requestId, String adminId) async {
    try {
      final request = await _firestore
          .collection('school_join_requests')
          .doc(requestId)
          .get();

      if (!request.exists) throw Exception('Request not found');

      final data = request.data() as Map<String, dynamic>;
      final userId = data['userId'];
      final schoolId = data['schoolId'];

      // Verify admin has permission
      final school = await getSchool(schoolId);
      if (school == null) throw Exception('School not found');
      
      if (!school.isAdmin(adminId) && !school.isOwner(adminId)) {
        throw Exception('You do not have permission to approve this request');
      }

      // Add user to school's member list
      await _firestore.collection('schools').doc(schoolId).update({
        'memberIds': FieldValue.arrayUnion([userId]),
      });

      // Update user's schoolIds array
      await _firestore.collection('users').doc(userId).update({
        'schoolIds': FieldValue.arrayUnion([schoolId]),
        'schoolId': schoolId, // For backwards compatibility
      });

      // Update request status
      await _firestore.collection('school_join_requests').doc(requestId).update({
        'status': JoinRequestStatus.approved.name,
        'reviewedBy': adminId,
        'reviewedAt': Timestamp.now(),
      });

      print('✅ Join request approved successfully');
    } catch (e) {
      print('❌ Error approving join request: $e');
      rethrow;
    }
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

  // Get user's pending join requests
  Stream<List<SchoolJoinRequestModel>> getUserPendingRequests(String userId) {
    return _firestore
        .collection('school_join_requests')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: JoinRequestStatus.pending.name)
        .snapshots()
        .map(
          (snapshot) {
            final requests = snapshot.docs
                .map((doc) => SchoolJoinRequestModel.fromFirestore(doc))
                .toList();
            requests.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
            return requests;
          },
        );
  }

  // Cancel a join request
  Future<void> cancelJoinRequest(String requestId) async {
    await _firestore.collection('school_join_requests').doc(requestId).delete();
  }

  // Get total schools user is in (including pending)
  Future<int> getUserSchoolCount(String userId) async {
    // Get joined schools
    final user = await AuthService().getUserData(userId);
    final joinedCount = user?.schoolIds.length ?? 0;
    
    // Get pending requests
    final pendingSnapshot = await _firestore
        .collection('school_join_requests')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: JoinRequestStatus.pending.name)
        .get();
    
    return joinedCount + pendingSnapshot.docs.length;
  }

  // ==================== SCHOOL EVENTS ====================

  // Create school event
  Future<String> createSchoolEvent(SchoolEventModel event) async {
    final doc = await _firestore.collection('school_events').add(event.toFirestore());
    return doc.id;
  }

  // Get school events
  Stream<List<SchoolEventModel>> getSchoolEvents(String schoolId) {
    return _firestore
        .collection('school_events')
        .where('schoolId', isEqualTo: schoolId)
        .snapshots()
        .map(
          (snapshot) {
            final events = snapshot.docs
                .map((doc) => SchoolEventModel.fromFirestore(doc))
                .toList();
            // Sort in-memory to avoid index requirement
            events.sort((a, b) => a.startTime.compareTo(b.startTime));
            return events;
          },
        );
  }

  // Get upcoming school events
  Stream<List<SchoolEventModel>> getUpcomingSchoolEvents(String schoolId) {
    return _firestore
        .collection('school_events')
        .where('schoolId', isEqualTo: schoolId)
        .where('startTime', isGreaterThanOrEqualTo: Timestamp.now())
        .orderBy('startTime', descending: false)
        .limit(10)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SchoolEventModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Get single event
  Future<SchoolEventModel?> getSchoolEvent(String eventId) async {
    final doc = await _firestore.collection('school_events').doc(eventId).get();
    if (doc.exists) {
      return SchoolEventModel.fromFirestore(doc);
    }
    return null;
  }

  // Update school event
  Future<void> updateSchoolEvent(String eventId, Map<String, dynamic> updates) async {
    await _firestore.collection('school_events').doc(eventId).update(updates);
  }

  // Delete school event
  Future<void> deleteSchoolEvent(String eventId) async {
    await _firestore.collection('school_events').doc(eventId).delete();
  }

  // Register for event
  Future<void> registerForEvent(String eventId, String userId) async {
    await _firestore.collection('school_events').doc(eventId).update({
      'attendeeIds': FieldValue.arrayUnion([userId]),
    });
  }

  // Unregister from event
  Future<void> unregisterFromEvent(String eventId, String userId) async {
    await _firestore.collection('school_events').doc(eventId).update({
      'attendeeIds': FieldValue.arrayRemove([userId]),
    });
  }
}
