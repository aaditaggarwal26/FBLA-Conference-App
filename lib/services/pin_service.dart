import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pin_model.dart';

class PinService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new pin listing
  Future<String> createPin(PinModel pin) async {
    final docRef = await _firestore.collection('pins').add(pin.toFirestore());
    return docRef.id;
  }

  // Get all available pins
  Stream<List<PinModel>> getAllPins() {
    return _firestore
        .collection('pins')
        .where('isAvailable', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => PinModel.fromFirestore(doc)).toList(),
        );
  }

  // Get pins by user
  Stream<List<PinModel>> getUserPins(String userId) {
    return _firestore
        .collection('pins')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => PinModel.fromFirestore(doc)).toList(),
        );
  }

  // Search pins
  Future<List<PinModel>> searchPins(String query) async {
    final snapshot = await _firestore
        .collection('pins')
        .where('isAvailable', isEqualTo: true)
        .get();

    return snapshot.docs
        .map((doc) => PinModel.fromFirestore(doc))
        .where(
          (pin) =>
              pin.pinName.toLowerCase().contains(query.toLowerCase()) ||
              pin.description.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }

  // Update pin
  Future<void> updatePin(String pinId, Map<String, dynamic> data) async {
    await _firestore.collection('pins').doc(pinId).update(data);
  }

  // Delete pin
  Future<void> deletePin(String pinId) async {
    await _firestore.collection('pins').doc(pinId).delete();
  }

  // Mark pin as traded
  Future<void> markAsTraded(String pinId) async {
    await _firestore.collection('pins').doc(pinId).update({
      'isAvailable': false,
    });
  }

  // Get pin by ID
  Future<PinModel?> getPinById(String pinId) async {
    final doc = await _firestore.collection('pins').doc(pinId).get();
    if (doc.exists) {
      return PinModel.fromFirestore(doc);
    }
    return null;
  }

  // Update all pins for a user (useful when profile picture or name changes)
  Future<void> updateUserPins(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    final snapshot = await _firestore
        .collection('pins')
        .where('userId', isEqualTo: userId)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, updates);
    }

    if (snapshot.docs.isNotEmpty) {
      await batch.commit();
    }
  }
}
