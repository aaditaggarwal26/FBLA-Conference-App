import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';

/// Service to handle event-related operations in Firestore.
/// Includes fetching, searching, and registering for events.
class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Returns a stream of all events, ordered by start time.
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

  /// Returns a stream of the next 10 upcoming events.
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

  /// Returns a stream of events marked as featured.
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

  /// Fetches a single event by its ID.
  /// Returns null if the event does not exist.
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

  /// Registers a user for an event.
  /// Updates both the event document (registeredUsers list) and user document (registeredEvents list).
  Future<void> registerForEvent(String eventId, String userId) async {
    // Add user ID to event's registered users
    await _firestore.collection('events').doc(eventId).update({
      'registeredUsers': FieldValue.arrayUnion([userId]),
    });

    // Add event ID to user's registered events
    await _firestore.collection('users').doc(userId).update({
      'registeredEvents': FieldValue.arrayUnion([eventId]),
    });
  }

  /// Unregisters a user from an event.
  /// Updates both the event document and user document.
  Future<void> unregisterFromEvent(String eventId, String userId) async {
    // Remove user ID from event's registered users
    await _firestore.collection('events').doc(eventId).update({
      'registeredUsers': FieldValue.arrayRemove([userId]),
    });

    // Remove event ID from user's registered events
    await _firestore.collection('users').doc(userId).update({
      'registeredEvents': FieldValue.arrayRemove([eventId]),
    });
  }

  /// Returns a stream of events that the user has registered for.
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

  /// Searches for events by title.
  /// Uses a range query for prefix matching.
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

  /// Returns a stream of events filtered by category.
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
