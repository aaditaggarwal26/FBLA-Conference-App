import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all events
  Stream<List<EventModel>> getEvents() {
    return _firestore
        .collection('events')
        .orderBy('startTime')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => EventModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Get upcoming events
  Stream<List<EventModel>> getUpcomingEvents() {
    return _firestore
        .collection('events')
        .where('startTime', isGreaterThan: Timestamp.now())
        .orderBy('startTime')
        .limit(10)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => EventModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Get featured events
  Stream<List<EventModel>> getFeaturedEvents() {
    return _firestore
        .collection('events')
        .where('isFeatured', isEqualTo: true)
        .orderBy('startTime')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => EventModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Get event by ID
  Future<EventModel?> getEventById(String eventId) async {
    try {
      final doc = await _firestore.collection('events').doc(eventId).get();
      if (doc.exists) {
        return EventModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Register for event
  Future<void> registerForEvent(String eventId, String userId) async {
    await _firestore.collection('events').doc(eventId).update({
      'registeredUsers': FieldValue.arrayUnion([userId]),
    });

    await _firestore.collection('users').doc(userId).update({
      'registeredEvents': FieldValue.arrayUnion([eventId]),
    });
  }

  // Unregister from event
  Future<void> unregisterFromEvent(String eventId, String userId) async {
    await _firestore.collection('events').doc(eventId).update({
      'registeredUsers': FieldValue.arrayRemove([userId]),
    });

    await _firestore.collection('users').doc(userId).update({
      'registeredEvents': FieldValue.arrayRemove([eventId]),
    });
  }

  // Get user's registered events
  Stream<List<EventModel>> getUserRegisteredEvents(String userId) {
    return _firestore
        .collection('events')
        .where('registeredUsers', arrayContains: userId)
        .orderBy('startTime')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => EventModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Search events
  Future<List<EventModel>> searchEvents(String query) async {
    try {
      final snapshot = await _firestore
          .collection('events')
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      return snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Get events by category
  Stream<List<EventModel>> getEventsByCategory(String category) {
    return _firestore
        .collection('events')
        .where('category', isEqualTo: category)
        .orderBy('startTime')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => EventModel.fromFirestore(doc))
              .toList(),
        );
  }
}
