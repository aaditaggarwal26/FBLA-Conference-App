import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/speaker_model.dart';

class SpeakerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all speakers
  Stream<List<SpeakerModel>> getSpeakers() {
    return _firestore
        .collection('speakers')
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SpeakerModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Get speaker by ID
  Future<SpeakerModel?> getSpeakerById(String id) async {
    try {
      final doc = await _firestore.collection('speakers').doc(id).get();
      if (doc.exists) {
        return SpeakerModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Create speaker
  Future<void> createSpeaker(SpeakerModel speaker) async {
    await _firestore.collection('speakers').add(speaker.toFirestore());
  }

  // Update speaker
  Future<void> updateSpeaker(String id, Map<String, dynamic> updates) async {
    await _firestore.collection('speakers').doc(id).update(updates);
  }

  // Delete speaker
  Future<void> deleteSpeaker(String id) async {
    await _firestore.collection('speakers').doc(id).delete();
  }
}
