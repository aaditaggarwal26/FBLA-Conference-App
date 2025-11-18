import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pin_model.dart';

class PinService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createPin(PinModel pin) async {
    await _firestore.collection('pins').doc(pin.id).set(pin.toFirestore());
  }

  Future<PinModel?> getPin(String pinId) async {
    final doc = await _firestore.collection('pins').doc(pinId).get();
    if (!doc.exists) return null;
    return PinModel.fromFirestore(doc);
  }

  Stream<List<PinModel>> getUserPinsStream(String userId) {
    return _firestore
        .collection('pins')
        .where('ownerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PinModel.fromFirestore(doc)).toList());
  }

  Stream<List<PinModel>> getAvailablePinsStream() {
    return _firestore
        .collection('pins')
        .where('isAvailableForTrade', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PinModel.fromFirestore(doc)).toList());
  }

  Stream<List<PinModel>> getAllPins() {
    return _firestore
        .collection('pins')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PinModel.fromFirestore(doc)).toList());
  }

  Future<void> updatePin(String pinId, Map<String, dynamic> updates) async {
    await _firestore.collection('pins').doc(pinId).update(updates);
  }

  Future<void> updateUserPins(String userId, Map<String, dynamic> updates) async {
    final pinsSnapshot = await _firestore
        .collection('pins')
        .where('userId', isEqualTo: userId)
        .get();

    final batch = _firestore.batch();
    for (var doc in pinsSnapshot.docs) {
      batch.update(doc.reference, updates);
    }
    await batch.commit();
  }

  Future<void> deletePin(String pinId) async {
    await _firestore.collection('pins').doc(pinId).delete();
  }

  Future<void> toggleTradeAvailability(String pinId, bool isAvailable) async {
    await updatePin(pinId, {'isAvailableForTrade': isAvailable});
  }

  Future<void> addInterest(String pinId, String userId) async {
    await _firestore.collection('pins').doc(pinId).update({
      'interestedUserIds': FieldValue.arrayUnion([userId]),
    });
  }

  Future<void> removeInterest(String pinId, String userId) async {
    await _firestore.collection('pins').doc(pinId).update({
      'interestedUserIds': FieldValue.arrayRemove([userId]),
    });
  }
}
