import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/announcement_model.dart';

class AnnouncementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createAnnouncement(AnnouncementModel announcement) async {
    await _firestore
        .collection('announcements')
        .doc(announcement.id)
        .set(announcement.toFirestore());
  }

  Future<AnnouncementModel?> getAnnouncement(String announcementId) async {
    final doc =
        await _firestore.collection('announcements').doc(announcementId).get();
    if (!doc.exists) return null;
    return AnnouncementModel.fromFirestore(doc);
  }

  Stream<List<AnnouncementModel>> getAnnouncementsStream() {
    return _firestore
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AnnouncementModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<AnnouncementModel>> getAnnouncements() {
    return getAnnouncementsStream();
  }

  Stream<List<AnnouncementModel>> getNationalAnnouncementsStream() {
    return _firestore
        .collection('announcements')
        .where('type', isEqualTo: 'national')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AnnouncementModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<AnnouncementModel>> getSchoolAnnouncementsStream(
      String schoolId) {
    return _firestore
        .collection('announcements')
        .where('type', isEqualTo: 'school')
        .where('schoolId', isEqualTo: schoolId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AnnouncementModel.fromFirestore(doc))
            .toList());
  }

  Future<void> updateAnnouncement(
      String announcementId, Map<String, dynamic> updates) async {
    await _firestore
        .collection('announcements')
        .doc(announcementId)
        .update(updates);
  }

  Future<void> deleteAnnouncement(String announcementId) async {
    await _firestore.collection('announcements').doc(announcementId).delete();
  }
}
