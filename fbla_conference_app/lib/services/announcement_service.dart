import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/announcement_model.dart';

class AnnouncementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all announcements
  Stream<List<AnnouncementModel>> getAnnouncements() {
    return _firestore
        .collection('announcements')
        .orderBy('isPinned', descending: true)
        .orderBy('postedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AnnouncementModel.fromFirestore(doc))
            .toList());
  }

  // Get pinned announcements
  Stream<List<AnnouncementModel>> getPinnedAnnouncements() {
    return _firestore
        .collection('announcements')
        .where('isPinned', isEqualTo: true)
        .orderBy('postedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AnnouncementModel.fromFirestore(doc))
            .toList());
  }

  // Create announcement (admin only)
  Future<void> createAnnouncement(AnnouncementModel announcement) async {
    await _firestore.collection('announcements').add(announcement.toFirestore());
  }

  // Delete announcement (admin only)
  Future<void> deleteAnnouncement(String announcementId) async {
    await _firestore.collection('announcements').doc(announcementId).delete();
  }
}
