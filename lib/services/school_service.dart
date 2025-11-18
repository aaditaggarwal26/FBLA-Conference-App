import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/school_model.dart';
import '../models/school_event_model.dart';
import '../models/school_resource_model.dart';
import '../models/announcement_model.dart';
import '../models/user_model.dart';

class SchoolService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generate unique invite code
  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(8, (index) => chars[random.nextInt(chars.length)]).join();
  }

  // Create a new school
  Future<SchoolModel> createSchool({
    required String name,
    required String address,
    required String creatorId,
    String? city,
    String? state,
    String? zipCode,
    String? logoUrl,
    String? bannerUrl,
  }) async {
    final inviteCode = _generateInviteCode();
    
    final school = SchoolModel(
      id: '',
      name: name,
      address: address,
      city: city,
      state: state,
      zipCode: zipCode,
      logoUrl: logoUrl,
      bannerUrl: bannerUrl,
      adminIds: [creatorId],
      memberIds: [creatorId],
      inviteCode: inviteCode,
      createdAt: DateTime.now(),
      socialMediaLinks: {},
      isActive: true,
    );

    final docRef = await _firestore.collection('schools').add(school.toFirestore());
    return school.copyWith(id: docRef.id);
  }

  // Get school by ID
  Future<SchoolModel?> getSchool(String schoolId) async {
    final doc = await _firestore.collection('schools').doc(schoolId).get();
    if (!doc.exists) return null;
    return SchoolModel.fromFirestore(doc);
  }

  // Get school by invite code
  Future<SchoolModel?> getSchoolByInviteCode(String inviteCode) async {
    final query = await _firestore
        .collection('schools')
        .where('inviteCode', isEqualTo: inviteCode.toUpperCase())
        .limit(1)
        .get();
    
    if (query.docs.isEmpty) return null;
    return SchoolModel.fromFirestore(query.docs.first);
  }

  // Stream school data
  Stream<SchoolModel?> getSchoolStream(String schoolId) {
    return _firestore
        .collection('schools')
        .doc(schoolId)
        .snapshots()
        .map((doc) => doc.exists ? SchoolModel.fromFirestore(doc) : null);
  }

  // Get all schools (for super admin)
  Stream<List<SchoolModel>> getAllSchools() {
    return _firestore
        .collection('schools')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SchoolModel.fromFirestore(doc))
            .toList());
  }

  // Update school
  Future<void> updateSchool(String schoolId, Map<String, dynamic> data) async {
    await _firestore.collection('schools').doc(schoolId).update(data);
  }

  // Add admin to school
  Future<void> addAdmin(String schoolId, String userId) async {
    await _firestore.collection('schools').doc(schoolId).update({
      'adminIds': FieldValue.arrayUnion([userId]),
    });

    // Update user role
    await _firestore.collection('users').doc(userId).update({
      'role': 'school_admin',
      'schoolId': schoolId,
    });
  }

  // Remove admin from school
  Future<void> removeAdmin(String schoolId, String userId) async {
    final school = await getSchool(schoolId);
    if (school == null) return;

    // Don't allow removing the last admin
    if (school.adminIds.length <= 1) {
      throw Exception('Cannot remove the last admin');
    }

    await _firestore.collection('schools').doc(schoolId).update({
      'adminIds': FieldValue.arrayRemove([userId]),
    });

    // Update user role to student if they're still a member
    if (school.memberIds.contains(userId)) {
      await _firestore.collection('users').doc(userId).update({
        'role': 'student',
      });
    }
  }

  // Join school with invite code
  Future<void> joinSchool(String userId, String inviteCode) async {
    final school = await getSchoolByInviteCode(inviteCode);
    if (school == null) {
      throw Exception('Invalid invite code');
    }

    if (!school.isActive) {
      throw Exception('This school is no longer active');
    }

    // Add user to school members
    await _firestore.collection('schools').doc(school.id).update({
      'memberIds': FieldValue.arrayUnion([userId]),
    });

    // Update user's school affiliation
    await _firestore.collection('users').doc(userId).update({
      'schoolId': school.id,
      'role': 'student',
    });
  }

  // Leave school
  Future<void> leaveSchool(String userId, String schoolId) async {
    final school = await getSchool(schoolId);
    if (school == null) return;

    // Remove from members
    await _firestore.collection('schools').doc(schoolId).update({
      'memberIds': FieldValue.arrayRemove([userId]),
      'adminIds': FieldValue.arrayRemove([userId]),
    });

    // Update user
    await _firestore.collection('users').doc(userId).update({
      'schoolId': FieldValue.delete(),
      'role': 'attendee',
    });
  }

  // Regenerate invite code
  Future<String> regenerateInviteCode(String schoolId) async {
    final newCode = _generateInviteCode();
    await _firestore.collection('schools').doc(schoolId).update({
      'inviteCode': newCode,
    });
    return newCode;
  }

  // Update social media links
  Future<void> updateSocialMediaLinks(String schoolId, Map<String, String> links) async {
    await _firestore.collection('schools').doc(schoolId).update({
      'socialMediaLinks': links,
    });
  }

  // Get school members
  Stream<List<UserModel>> getSchoolMembers(String schoolId) {
    return _firestore
        .collection('users')
        .where('schoolId', isEqualTo: schoolId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromFirestore(doc))
            .toList());
  }

  // SCHOOL ANNOUNCEMENTS
  Future<String> createSchoolAnnouncement({
    required String schoolId,
    required String title,
    required String content,
    required String postedBy,
    String? imageUrl,
    String category = 'School',
    bool isPinned = false,
  }) async {
    final announcement = AnnouncementModel(
      id: '',
      title: title,
      content: content,
      imageUrl: imageUrl,
      postedAt: DateTime.now(),
      postedBy: postedBy,
      isPinned: isPinned,
      category: category,
      type: AnnouncementType.school,
      schoolId: schoolId,
    );

    final docRef = await _firestore
        .collection('announcements')
        .add(announcement.toFirestore());
    
    return docRef.id;
  }

  Stream<List<AnnouncementModel>> getSchoolAnnouncements(String schoolId) {
    return _firestore
        .collection('announcements')
        .where('schoolId', isEqualTo: schoolId)
        .orderBy('postedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AnnouncementModel.fromFirestore(doc))
            .toList());
  }

  // SCHOOL EVENTS
  Future<String> createSchoolEvent({
    required String schoolId,
    required String title,
    required String description,
    required DateTime startTime,
    required DateTime endTime,
    required String createdBy,
    String? location,
    String? imageUrl,
    bool isPublic = true,
  }) async {
    final event = SchoolEventModel(
      id: '',
      schoolId: schoolId,
      title: title,
      description: description,
      startTime: startTime,
      endTime: endTime,
      location: location,
      imageUrl: imageUrl,
      createdBy: createdBy,
      createdAt: DateTime.now(),
      attendees: [],
      isPublic: isPublic,
    );

    final docRef = await _firestore
        .collection('school_events')
        .add(event.toFirestore());
    
    return docRef.id;
  }

  Stream<List<SchoolEventModel>> getSchoolEvents(String schoolId) {
    return _firestore
        .collection('school_events')
        .where('schoolId', isEqualTo: schoolId)
        .orderBy('startTime', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SchoolEventModel.fromFirestore(doc))
            .toList());
  }

  Future<void> updateSchoolEvent(String eventId, Map<String, dynamic> data) async {
    await _firestore.collection('school_events').doc(eventId).update(data);
  }

  Future<void> deleteSchoolEvent(String eventId) async {
    await _firestore.collection('school_events').doc(eventId).delete();
  }

  // SCHOOL RESOURCES
  Future<String> createSchoolResource({
    required String schoolId,
    required String title,
    required String description,
    required String url,
    required String type,
    required String createdBy,
    String? iconUrl,
    int priority = 0,
  }) async {
    final resource = SchoolResourceModel(
      id: '',
      schoolId: schoolId,
      title: title,
      description: description,
      url: url,
      type: type,
      iconUrl: iconUrl,
      createdBy: createdBy,
      createdAt: DateTime.now(),
      priority: priority,
      isVisible: true,
    );

    final docRef = await _firestore
        .collection('school_resources')
        .add(resource.toFirestore());
    
    return docRef.id;
  }

  Stream<List<SchoolResourceModel>> getSchoolResources(String schoolId) {
    return _firestore
        .collection('school_resources')
        .where('schoolId', isEqualTo: schoolId)
        .where('isVisible', isEqualTo: true)
        .orderBy('priority', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SchoolResourceModel.fromFirestore(doc))
            .toList());
  }

  Future<void> updateSchoolResource(String resourceId, Map<String, dynamic> data) async {
    await _firestore.collection('school_resources').doc(resourceId).update(data);
  }

  Future<void> deleteSchoolResource(String resourceId) async {
    await _firestore.collection('school_resources').doc(resourceId).delete();
  }

  // Delete school (super admin only)
  Future<void> deleteSchool(String schoolId) async {
    // Remove school reference from all members
    final members = await _firestore
        .collection('users')
        .where('schoolId', isEqualTo: schoolId)
        .get();
    
    for (var doc in members.docs) {
      await _firestore.collection('users').doc(doc.id).update({
        'schoolId': FieldValue.delete(),
        'role': 'attendee',
      });
    }

    // Delete school
    await _firestore.collection('schools').doc(schoolId).delete();
  }
}
