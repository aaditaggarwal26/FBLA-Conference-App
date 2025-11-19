import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/announcement_model.dart';

class AnnouncementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all announcements
  Stream<List<AnnouncementModel>> getAnnouncements() {
    // Query without orderBy to avoid index requirement, sort in memory instead
    return _firestore
        .collection('announcements')
        .snapshots()
        .map(
          (snapshot) {
            final announcements = snapshot.docs
                .map((doc) {
                  try {
                    return AnnouncementModel.fromFirestore(doc);
                  } catch (e) {
                    print('Error parsing announcement ${doc.id}: $e');
                    print('Document data: ${doc.data()}');
                    return null;
                  }
                })
                .whereType<AnnouncementModel>()
                .toList();
            // Sort: pinned first, then by postedAt descending (newest first)
            announcements.sort((a, b) {
              if (a.isPinned && !b.isPinned) return -1;
              if (!a.isPinned && b.isPinned) return 1;
              return b.postedAt.compareTo(a.postedAt);
            });
            return announcements;
          },
        );
  }

  // Get pinned announcements
  Stream<List<AnnouncementModel>> getPinnedAnnouncements() {
    // Query without orderBy to avoid index requirement, sort in memory instead
    return _firestore
        .collection('announcements')
        .where('isPinned', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) {
            final announcements = snapshot.docs
                .map((doc) {
                  try {
                    return AnnouncementModel.fromFirestore(doc);
                  } catch (e) {
                    print('Error parsing announcement ${doc.id}: $e');
                    print('Document data: ${doc.data()}');
                    return null;
                  }
                })
                .whereType<AnnouncementModel>()
                .toList();
            // Sort by postedAt descending (newest first)
            announcements.sort((a, b) => b.postedAt.compareTo(a.postedAt));
            return announcements;
          },
        );
  }

  // Create announcement (admin only)
  Future<void> createAnnouncement(AnnouncementModel announcement) async {
    await _firestore
        .collection('announcements')
        .add(announcement.toFirestore());
  }

  // Delete announcement (admin only)
  Future<void> deleteAnnouncement(String announcementId) async {
    await _firestore.collection('announcements').doc(announcementId).delete();
  }
}
