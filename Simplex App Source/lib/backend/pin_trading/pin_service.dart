import 'package:cloud_firestore/cloud_firestore.dart';
import 'pin_model.dart';

class PinService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> createPin(PinModel pin) async {
    final docRef = await _firestore.collection('pins').add(pin.toFirestore());
    return docRef.id;
  }

  Stream<List<PinModel>> getAllPins() {
    return _firestore
        .collection('pins')
        .where('isAvailable', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PinModel.fromFirestore(doc)).toList());
  }

  Stream<List<PinModel>> getUserPins(String userId) {
    return _firestore
        .collection('pins')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PinModel.fromFirestore(doc)).toList());
  }

  Future<List<PinModel>> searchPins(String query) async {
    final snapshot = await _firestore
        .collection('pins')
        .where('isAvailable', isEqualTo: true)
        .get();

    return snapshot.docs
        .map((doc) => PinModel.fromFirestore(doc))
        .where((pin) =>
            pin.pinName.toLowerCase().contains(query.toLowerCase()) ||
            pin.description.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  Future<void> updatePin(String pinId, Map<String, dynamic> data) async {
    await _firestore.collection('pins').doc(pinId).update(data);
  }

  Future<void> deletePin(String pinId) async {
    await _firestore.collection('pins').doc(pinId).delete();
  }

  Future<void> markAsTraded(String pinId) async {
    await _firestore.collection('pins').doc(pinId).update({
      'isAvailable': false,
    });
  }

  Future<PinModel?> getPinById(String pinId) async {
    final doc = await _firestore.collection('pins').doc(pinId).get();
    if (doc.exists) {
      return PinModel.fromFirestore(doc);
    }
    return null;
  }
}
