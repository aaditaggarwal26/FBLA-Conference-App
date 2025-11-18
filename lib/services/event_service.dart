import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createEvent(EventModel event) async {
    await _firestore.collection('events').doc(event.id).set(event.toFirestore());
  }

  Future<EventModel?> getEvent(String eventId) async {
    final doc = await _firestore.collection('events').doc(eventId).get();
    if (!doc.exists) return null;
    return EventModel.fromFirestore(doc);
  }

  Stream<List<EventModel>> getEventsStream() {
    return _firestore
        .collection('events')
        .orderBy('startTime', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList());
  }

  Stream<List<EventModel>> getUpcomingEventsStream() {
    return _firestore
        .collection('events')
        .where('startTime', isGreaterThan: Timestamp.now())
        .orderBy('startTime', descending: false)
        .limit(10)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList());
  }

  Stream<List<EventModel>> getFeaturedEvents() {
    return getUpcomingEventsStream();
  }

  Stream<List<EventModel>> getEvents() {
    return getEventsStream();
  }

  Stream<List<EventModel>> getEventsByCategory(String category) {
    return _firestore
        .collection('events')
        .where('category', isEqualTo: category)
        .orderBy('startTime', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList());
  }

  Stream<List<EventModel>> getUserRegisteredEvents(String userId) {
    return getUserEventsStream(userId);
  }

  Stream<List<EventModel>> getUserEventsStream(String userId) {
    return _firestore
        .collection('events')
        .where('attendeeIds', arrayContains: userId)
        .orderBy('startTime', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList());
  }

  Future<void> registerForEvent(String eventId, String userId) async {
    await _firestore.collection('events').doc(eventId).update({
      'attendeeIds': FieldValue.arrayUnion([userId]),
    });
  }

  Future<void> unregisterFromEvent(String eventId, String userId) async {
    await _firestore.collection('events').doc(eventId).update({
      'attendeeIds': FieldValue.arrayRemove([userId]),
    });
  }

  Future<void> updateEvent(String eventId, Map<String, dynamic> updates) async {
    await _firestore.collection('events').doc(eventId).update(updates);
  }

  Future<void> deleteEvent(String eventId) async {
    await _firestore.collection('events').doc(eventId).delete();
  }

  Future<EventModel?> getEventByQRCode(String qrCode) async {
    final querySnapshot = await _firestore
        .collection('events')
        .where('qrCode', isEqualTo: qrCode)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) return null;
    return EventModel.fromFirestore(querySnapshot.docs.first);
  }
}
