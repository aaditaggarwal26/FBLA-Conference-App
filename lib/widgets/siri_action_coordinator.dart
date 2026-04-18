import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/parsed_event_model.dart';
import '../screens/ar_navigation/ar_navigation_screen.dart';
import '../services/event_import_service.dart';
import '../services/siri_integration_service.dart';

class SiriActionCoordinator extends StatefulWidget {
  const SiriActionCoordinator({super.key, required this.child});

  final Widget child;

  @override
  State<SiriActionCoordinator> createState() => _SiriActionCoordinatorState();
}

class _SiriActionCoordinatorState extends State<SiriActionCoordinator>
    with WidgetsBindingObserver {
  final EventImportService _eventImportService = EventImportService();

  StreamSubscription<User?>? _authSubscription;
  bool _isHandlingAction = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _schedulePendingActionHandling();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _schedulePendingActionHandling();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _schedulePendingActionHandling();
    }
  }

  void _schedulePendingActionHandling() {
    if (!mounted) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(SiriIntegrationService.instance.refreshSnapshotForCurrentUser());
      unawaited(_handlePendingAction());
    });
  }

  Future<void> _handlePendingAction() async {
    if (_isHandlingAction || FirebaseAuth.instance.currentUser == null) {
      return;
    }

    _isHandlingAction = true;
    try {
      final rawAction = await SiriIntegrationService.instance.readPendingAction();
      if (rawAction == null || rawAction.isEmpty) {
        return;
      }

      final decodedAction = jsonDecode(rawAction);
      if (decodedAction is! Map<String, dynamic>) {
        await SiriIntegrationService.instance.clearPendingAction();
        return;
      }

      final actionType = decodedAction['type'];
      if (actionType != 'start_navigation') {
        await SiriIntegrationService.instance.clearPendingAction();
        return;
      }

      final route = await _buildNavigationRoute(decodedAction);
      await SiriIntegrationService.instance.clearPendingAction();
      if (!mounted || route == null) {
        return;
      }

      await Navigator.of(context).push(route);
    } catch (error, stackTrace) {
      debugPrint('Failed to handle pending Siri action: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _isHandlingAction = false;
    }
  }

  Future<Route<void>?> _buildNavigationRoute(
    Map<String, dynamic> action,
  ) async {
    final eventKey = action['eventKey'] as String?;
    if (eventKey == null || eventKey.isEmpty) {
      return null;
    }

    final scheduleEvents = await _eventImportService.loadSBLCSchedule();
    ParsedEventModel? matchedEvent;
    for (final event in scheduleEvents) {
      if (_eventCompositeId(event) == eventKey) {
        matchedEvent = event;
        break;
      }
    }

    if (matchedEvent == null) {
      return null;
    }

    String schoolId = action['schoolId'] as String? ?? '';
    String locationPinId = action['locationPinId'] as String? ?? '';

    try {
      final linkSnapshot = await FirebaseFirestore.instance
          .collection('event_location_links')
          .doc(eventKey)
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
      debugPrint('Failed to refresh Siri navigation link: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    if (schoolId.isEmpty || locationPinId.isEmpty) {
      return null;
    }

    final resolvedEvent = matchedEvent.copyWith(
      schoolId: schoolId,
      locationPinId: locationPinId,
    );

    return MaterialPageRoute<void>(
      builder: (_) => ARNavigationScreen(
        event: resolvedEvent,
        schoolId: schoolId,
      ),
    );
  }

  String _eventCompositeId(ParsedEventModel event) {
    return '${event.eventName}::${event.schoolName ?? ''}';
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}