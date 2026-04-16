import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/parsed_event_model.dart';

class EventImportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Load SBLC 2026 schedule directly from bundled JSON asset (no Firestore needed)
  Future<List<ParsedEventModel>> loadSBLCSchedule() async {
    final jsonString = await rootBundle.loadString('lib/data/nccc_2025_events.json');
    final jsonData = json.decode(jsonString) as Map<String, dynamic>;
    final eventsJson = jsonData['events'] as List<dynamic>;

    final eventTotals = <String, Set<String>>{};
    for (final raw in eventsJson) {
      final e = raw as Map<String, dynamic>;
      final eventName = e['eventName'] as String?;
      if (eventName == null) continue;
      final participants = ((e['participants'] as List<dynamic>?) ?? []).cast<String>().toSet();
      eventTotals.putIfAbsent(eventName, () => <String>{}).addAll(participants);
    }

    final results = <ParsedEventModel>[];
    for (final raw in eventsJson) {
      final e = raw as Map<String, dynamic>;
      final startTimeStr = e['startTime'] as String?;
      if (startTimeStr == null) continue;
      final startTime = DateTime.tryParse(startTimeStr);
      if (startTime == null) continue;
      final eventName = e['eventName'] as String?;
      if (eventName == null) continue;
      final participants = ((e['participants'] as List<dynamic>?) ?? []).cast<String>().toList();
      results.add(ParsedEventModel(
        id: '',
        schoolId: '',
        schoolName: e['school'] as String?,
        eventName: eventName,
        location: (e['location'] as String?) ?? '',
        startTime: startTime,
        endTime: startTime.add(const Duration(minutes: 20)),
        participants: participants,
        totalParticipants: eventTotals[eventName]?.length ?? participants.length,
        performLocation: e['location'] as String?,
        prepLocation: null,
        locationPinId: null,
        metadata: null,
      ));
    }
    results.sort((a, b) => a.startTime.compareTo(b.startTime));
    return results;
  }

  // Import NCCC 2025 events from the bundled JSON asset
  Future<int> importNCCC2025Events(String schoolId) async {
    try {
      // Load from assets
      final jsonString = await rootBundle.loadString('lib/data/nccc_2025_events.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      if (!jsonData.containsKey('events')) {
        throw Exception('JSON file must contain an "events" array');
      }

      final List<dynamic> eventsJson = jsonData['events'];
      final batch = _firestore.batch();
      int importedCount = 0;

      final eventTotals = <String, Set<String>>{};
      for (final eventJson in eventsJson) {
        final eventName = eventJson['eventName'] as String?;
        if (eventName == null) continue;
        final participantsJson = eventJson['participants'] as List<dynamic>?;
        final participants = (participantsJson ?? []).cast<String>().toSet();
        eventTotals.putIfAbsent(eventName, () => <String>{}).addAll(participants);
      }

      for (final eventJson in eventsJson) {
        try {
          // Parse the event data
          final eventName = eventJson['eventName'] as String;
          final location = eventJson['location'] as String;
          final startTimeStr = eventJson['startTime'] as String;
          final List<dynamic> participantsJson = eventJson['participants'] as List<dynamic>;
          final participants = participantsJson.cast<String>();

          // Parse the start time (ISO format)
          final startTime = DateTime.parse(startTimeStr);
          final endTime = startTime.add(const Duration(minutes: 20));

          // Create the event model
          final event = ParsedEventModel(
            id: '',
            schoolId: schoolId,
            eventName: eventName,
            location: location,
            startTime: startTime,
            endTime: endTime,
            participants: participants,
            totalParticipants: eventTotals[eventName]?.length ?? participants.length,
            performLocation: location,
            prepLocation: null,
            locationPinId: null,
            metadata: {
              'importDate': DateTime.now().toIso8601String(),
              'source': 'nccc_2025',
            },
          );

          // Add to batch
          final docRef = _firestore.collection('parsed_events').doc();
          batch.set(docRef, event.toFirestore());
          importedCount++;
        } catch (e) {
          print('Error importing event: $e');
          // Continue with next event
        }
      }

      // Commit batch
      await batch.commit();
      return importedCount;
    } catch (e) {
      throw Exception('Failed to import NCCC 2025 events: $e');
    }
  }

  // Import events from the parsed JSON file
  Future<int> importEventsFromJson({
    required String schoolId,
    String jsonPath = 'lib/data/parsed_events.json',
  }) async {
    try {
      // Read the JSON file
      final String jsonString = await rootBundle.loadString(jsonPath);
      final List<dynamic> jsonData = json.decode(jsonString);

      int importedCount = 0;
      final batch = _firestore.batch();

      final eventTotals = <String, Set<String>>{};
      for (final eventData in jsonData) {
        final eventName = eventData['eventName'] ?? 'Unknown Event';
        final participants = List<String>.from(eventData['participants'] ?? []);
        eventTotals.putIfAbsent(eventName, () => <String>{}).addAll(participants);
      }

      for (final eventData in jsonData) {
        // Parse the event data
        final eventName = eventData['eventName'] ?? 'Unknown Event';
        final performLocation = eventData['performLocation'] ?? '';
        final prepLocation = eventData['prepLocation'] ?? '';
        final startTimeStr = eventData['startTimeStr'] ?? '';
        final participants = List<String>.from(eventData['participants'] ?? []);
        final pageNumber = eventData['pageNumber'] ?? 0;
        final eventDateStr = eventData['eventDate'] ?? '2025-11-22';

        // Parse time
        final DateTime startTime = _parseDateTime(eventDateStr, startTimeStr);
        final DateTime endTime = startTime.add(const Duration(minutes: 20)); // Default 20 min duration

        // Create ParsedEventModel
        final parsedEvent = ParsedEventModel(
          id: '',
          schoolId: schoolId,
          eventName: eventName,
          location: performLocation,
          startTime: startTime,
          endTime: endTime,
          participants: participants,
          totalParticipants: eventTotals[eventName]?.length ?? participants.length,
          performLocation: performLocation,
          prepLocation: prepLocation.isEmpty ? null : prepLocation,
          locationPinId: null,
          metadata: {
            'pageNumber': pageNumber,
            'rawTimeStr': startTimeStr,
            'source': 'pdf_import',
            'importedAt': DateTime.now().toIso8601String(),
          },
        );

        // Add to batch
        final docRef = _firestore.collection('parsed_events').doc();
        batch.set(docRef, parsedEvent.toFirestore());
        importedCount++;
      }

      // Commit batch
      await batch.commit();

      return importedCount;
    } catch (e) {
      throw Exception('Failed to import events: $e');
    }
  }

  // Parse date and time strings
  DateTime _parseDateTime(String dateStr, String timeStr) {
    try {
      // Parse date (format: 2025-11-22)
      final dateParts = dateStr.split('-');
      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);

      // Parse time (format: 9:00AM or 10:30PM)
      final timePattern = RegExp(r'(\d{1,2}):(\d{2})\s*([AP]M)', caseSensitive: false);
      final match = timePattern.firstMatch(timeStr);

      if (match != null) {
        int hour = int.parse(match.group(1)!);
        final minute = int.parse(match.group(2)!);
        final period = match.group(3)!.toUpperCase();

        // Convert to 24-hour format
        if (period == 'PM' && hour != 12) {
          hour += 12;
        } else if (period == 'AM' && hour == 12) {
          hour = 0;
        }

        return DateTime(year, month, day, hour, minute);
      }

      // Fallback to start of day if parsing fails
      return DateTime(year, month, day, 9, 0);
    } catch (e) {
      // Fallback to a default date/time
      return DateTime(2025, 11, 22, 9, 0);
    }
  }

  // Get all parsed events for a school
  Stream<List<ParsedEventModel>> getParsedEvents(String schoolId) {
    return _firestore
        .collection('parsed_events')
        .where('schoolId', isEqualTo: schoolId)
        .snapshots()
        .map((snapshot) {
          final events = snapshot.docs
              .map((doc) => ParsedEventModel.fromFirestore(doc))
              .toList();
          // Sort in memory to avoid needing composite index
          events.sort((a, b) => a.startTime.compareTo(b.startTime));
          return events;
        });
  }

  // Get parsed events for a specific participant
  Stream<List<ParsedEventModel>> getEventsForParticipant(
    String schoolId,
    String participantName,
  ) {
    return _firestore
        .collection('parsed_events')
        .where('schoolId', isEqualTo: schoolId)
        .where('participants', arrayContains: participantName)
        .snapshots()
        .map((snapshot) {
          final events = snapshot.docs
              .map((doc) => ParsedEventModel.fromFirestore(doc))
              .toList();
          // Sort in memory to avoid needing composite index
          events.sort((a, b) => a.startTime.compareTo(b.startTime));
          return events;
        });
  }

  // Link a parsed event to a location pin
  Future<void> linkEventToLocation(String eventId, String locationPinId) async {
    try {
      await _firestore.collection('parsed_events').doc(eventId).update({
        'locationPinId': locationPinId,
      });
    } catch (e) {
      throw Exception('Failed to link event to location: $e');
    }
  }

  // Unlink event from location
  Future<void> unlinkEventFromLocation(String eventId) async {
    try {
      await _firestore.collection('parsed_events').doc(eventId).update({
        'locationPinId': null,
      });
    } catch (e) {
      throw Exception('Failed to unlink event from location: $e');
    }
  }

  // Get events without location assignments
  Stream<List<ParsedEventModel>> getEventsWithoutLocation(String schoolId) {
    return _firestore
        .collection('parsed_events')
        .where('schoolId', isEqualTo: schoolId)
        .where('locationPinId', isNull: true)
        .orderBy('startTime')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ParsedEventModel.fromFirestore(doc)).toList());
  }

  // Get events linked to a specific location
  Stream<List<ParsedEventModel>> getEventsForLocation(
    String schoolId,
    String locationPinId,
  ) {
    return _firestore
        .collection('parsed_events')
        .where('schoolId', isEqualTo: schoolId)
        .where('locationPinId', isEqualTo: locationPinId)
        .orderBy('startTime')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ParsedEventModel.fromFirestore(doc)).toList());
  }

  // Delete all parsed events for a school (use with caution!)
  Future<void> deleteAllParsedEvents(String schoolId) async {
    try {
      final snapshot = await _firestore
          .collection('parsed_events')
          .where('schoolId', isEqualTo: schoolId)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete parsed events: $e');
    }
  }

  // Get event statistics
  Future<Map<String, dynamic>> getEventStatistics(String schoolId) async {
    try {
      final snapshot = await _firestore
          .collection('parsed_events')
          .where('schoolId', isEqualTo: schoolId)
          .get();

      final totalEvents = snapshot.docs.length;
      int eventsWithLocation = 0;
      final eventTypes = <String, int>{};
      final locations = <String, int>{};

      for (final doc in snapshot.docs) {
        final event = ParsedEventModel.fromFirestore(doc);
        if (event.hasLocationPin()) {
          eventsWithLocation++;
        }

        // Count event types
        eventTypes[event.eventName] = (eventTypes[event.eventName] ?? 0) + 1;

        // Count locations
        if (event.location.isNotEmpty) {
          locations[event.location] = (locations[event.location] ?? 0) + 1;
        }
      }

      return {
        'totalEvents': totalEvents,
        'eventsWithLocation': eventsWithLocation,
        'eventsWithoutLocation': totalEvents - eventsWithLocation,
        'eventTypes': eventTypes,
        'locations': locations,
      };
    } catch (e) {
      throw Exception('Failed to get event statistics: $e');
    }
  }
}
