import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/parsed_event_model.dart';
import 'event_import_service.dart';

class SiriIntegrationService {
  SiriIntegrationService._();

  static final SiriIntegrationService instance = SiriIntegrationService._();

  static const String scheduleSnapshotKey = 'siri_schedule_snapshot_v1';
  static const String pendingActionKey = 'siri_pending_action_v1';
  static const MethodChannel _storageChannel = MethodChannel(
    'com.convex.fblaConferenceApp/siri_storage',
  );

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final EventImportService _eventImportService = EventImportService();

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _userSnapshotSubscription;
  bool _isInitialized = false;
  bool _isRefreshing = false;

  bool get _supportsSharedSiriStorage {
    if (kIsWeb) {
      return false;
    }

    return defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    _isInitialized = true;
    _authSubscription = _auth.authStateChanges().listen(_handleAuthStateChanged);
    await _handleAuthStateChanged(_auth.currentUser);
  }

  Future<void> dispose() async {
    await _authSubscription?.cancel();
    await _userSnapshotSubscription?.cancel();
    _authSubscription = null;
    _userSnapshotSubscription = null;
    _isInitialized = false;
  }

  Future<void> refreshSnapshotForCurrentUser() async {
    if (_isRefreshing) {
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      await _clearScheduleSnapshot();
      return;
    }

    _isRefreshing = true;
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        await _clearScheduleSnapshot();
        return;
      }

      final userData = userDoc.data() ?? <String, dynamic>{};
      final registeredEventKeys = List<String>.from(
        userData['registeredEvents'] ?? const <String>[],
      ).where((value) => value.contains('::')).toSet();

      if (registeredEventKeys.isEmpty) {
        await _saveScheduleSnapshot(
          userId: user.uid,
          schoolIds: _readSchoolIds(userData),
          upcomingEvents: const <Map<String, dynamic>>[],
        );
        return;
      }

      final allScheduleEvents = await _eventImportService.loadSBLCSchedule();
      final matchingEvents = allScheduleEvents.where((event) {
        return registeredEventKeys.contains(_eventCompositeId(event));
      }).toList()
        ..sort((left, right) => left.startTime.compareTo(right.startTime));

      final enrichedEvents = await _enrichEvents(
        matchingEvents,
        fallbackSchoolIds: _readSchoolIds(userData),
      );

      await _saveScheduleSnapshot(
        userId: user.uid,
        schoolIds: _readSchoolIds(userData),
        upcomingEvents: enrichedEvents,
      );
    } catch (error, stackTrace) {
      debugPrint('Siri snapshot refresh failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _handleAuthStateChanged(User? user) async {
    await _userSnapshotSubscription?.cancel();
    _userSnapshotSubscription = null;

    if (user == null) {
      await _clearScheduleSnapshot();
      return;
    }

    _userSnapshotSubscription = _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen(
          (_) {
            unawaited(refreshSnapshotForCurrentUser());
          },
          onError: (Object error, StackTrace stackTrace) {
            debugPrint('Siri user snapshot listener failed: $error');
            debugPrintStack(stackTrace: stackTrace);
          },
        );

    await refreshSnapshotForCurrentUser();
  }

  List<String> _readSchoolIds(Map<String, dynamic> userData) {
    final schoolIds = List<String>.from(userData['schoolIds'] ?? const []);
    if (schoolIds.isNotEmpty) {
      return schoolIds;
    }

    final schoolId = userData['schoolId'];
    if (schoolId is String && schoolId.isNotEmpty) {
      return <String>[schoolId];
    }

    return const <String>[];
  }

  Future<List<Map<String, dynamic>>> _enrichEvents(
    List<ParsedEventModel> events, {
    required List<String> fallbackSchoolIds,
  }) async {
    return Future.wait(
      events.map(
        (event) async {
          final compositeId = _eventCompositeId(event);
          String? schoolId = event.schoolId.isNotEmpty ? event.schoolId : null;
          String? locationPinId = event.locationPinId;

          try {
            final linkSnapshot = await _firestore
                .collection('event_location_links')
                .doc(compositeId)
                .get();

            if (linkSnapshot.exists) {
              final linkData = linkSnapshot.data() ?? <String, dynamic>{};
              final linkedSchoolId = linkData['schoolId'];
              final linkedLocationPinId = linkData['locationPinId'];

              if (linkedSchoolId is String && linkedSchoolId.isNotEmpty) {
                schoolId = linkedSchoolId;
              }

              if (linkedLocationPinId is String && linkedLocationPinId.isNotEmpty) {
                locationPinId = linkedLocationPinId;
              }
            }
          } catch (error, stackTrace) {
            debugPrint('Failed to resolve event link for $compositeId: $error');
            debugPrintStack(stackTrace: stackTrace);
          }

          schoolId ??= fallbackSchoolIds.isNotEmpty ? fallbackSchoolIds.first : null;

          return <String, dynamic>{
            'eventKey': compositeId,
            'eventName': event.eventName,
            'schoolName': event.schoolName ?? '',
            'schoolId': schoolId ?? '',
            'location': event.location,
            'locationPinId': locationPinId ?? '',
            'startTime': event.startTime.toIso8601String(),
            'endTime': event.endTime.toIso8601String(),
            'participants': event.participants,
            'supportsArNavigation':
                (schoolId != null && schoolId.isNotEmpty) &&
                (locationPinId != null && locationPinId.isNotEmpty),
          };
        },
      ),
    );
  }

  Future<void> _saveScheduleSnapshot({
    required String userId,
    required List<String> schoolIds,
    required List<Map<String, dynamic>> upcomingEvents,
  }) async {
    final now = DateTime.now();

    final nextEvent = _findCurrentOrNextEvent(upcomingEvents, now: now);

    final nextNavigableEvent = _findCurrentOrNextEvent(
      upcomingEvents,
      now: now,
      requiresArNavigation: true,
    );

    final snapshot = <String, dynamic>{
      'generatedAt': now.toIso8601String(),
      'userId': userId,
      'schoolIds': schoolIds,
      'upcomingEvents': upcomingEvents,
      'nextEvent': nextEvent,
      'nextNavigableEvent': nextNavigableEvent,
    };

    await _writeStoredString(scheduleSnapshotKey, jsonEncode(snapshot));
  }

  Future<void> _clearScheduleSnapshot() async {
    await _removeStoredValue(scheduleSnapshotKey);
  }

  Future<String?> readPendingAction() {
    return _readStoredString(pendingActionKey);
  }

  Future<void> clearPendingAction() {
    return _removeStoredValue(pendingActionKey);
  }

  String _eventCompositeId(ParsedEventModel event) {
    return '${event.eventName}::${event.schoolName ?? ''}';
  }

  Map<String, dynamic>? _findCurrentOrNextEvent(
    List<Map<String, dynamic>> events, {
    required DateTime now,
    bool requiresArNavigation = false,
  }) {
    for (final event in events) {
      final startTime = DateTime.tryParse(event['startTime'] as String? ?? '');
      final endTime = DateTime.tryParse(event['endTime'] as String? ?? '');
      if (startTime == null) {
        continue;
      }
      if (requiresArNavigation && event['supportsArNavigation'] != true) {
        continue;
      }
      if (!startTime.isAfter(now) && (endTime == null || endTime.isAfter(now))) {
        return event;
      }
    }

    for (final event in events) {
      final startTime = DateTime.tryParse(event['startTime'] as String? ?? '');
      if (startTime == null || startTime.isBefore(now)) {
        continue;
      }
      if (requiresArNavigation && event['supportsArNavigation'] != true) {
        continue;
      }
      return event;
    }

    return null;
  }

  Future<void> _writeStoredString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);

    if (!_supportsSharedSiriStorage) {
      return;
    }

    try {
      await _storageChannel.invokeMethod<void>('setString', {
        'key': key,
        'value': value,
      });
    } catch (error, stackTrace) {
      debugPrint('Failed to write shared Siri value for $key: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<String?> _readStoredString(String key) async {
    if (_supportsSharedSiriStorage) {
      try {
        final value = await _storageChannel.invokeMethod<String>('getString', {
          'key': key,
        });
        if (value != null) {
          return value;
        }
      } catch (error, stackTrace) {
        debugPrint('Failed to read shared Siri value for $key: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }

    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  Future<void> _removeStoredValue(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);

    if (!_supportsSharedSiriStorage) {
      return;
    }

    try {
      await _storageChannel.invokeMethod<void>('remove', {'key': key});
    } catch (error, stackTrace) {
      debugPrint('Failed to remove shared Siri value for $key: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}