import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/parsed_event_model.dart';
import '../../models/location_pin_model.dart';
import '../../services/location_pin_service.dart';
import '../ar_navigation/ar_navigation_screen.dart';
import '../ar_navigation/drop_location_pin_screen.dart';

/// Screen to display detailed information about a specific event.
/// Allows users to view details, see location status, and start AR navigation.
/// Admins can link location pins to events from here.
class EventDetailPage extends StatefulWidget {
  final ParsedEventModel event;
  final String schoolId;
  final bool isAdmin;

  const EventDetailPage({
    super.key,
    required this.event,
    required this.schoolId,
    this.isAdmin = false,
  });

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  final LocationPinService _locationPinService = LocationPinService();
  LocationPinModel? _linkedLocation;
  bool _isLoading = true;
  bool _isSaved = false;
  bool _isSaving = false;

  String get _eventId =>
      '${widget.event.eventName}::${widget.event.schoolName ?? ""}';

  @override
  void initState() {
    super.initState();
    _loadLocationPin();
    _checkIfSaved();
  }

  Future<void> _checkIfSaved() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (!mounted) return;
    final saved =
        List<String>.from(doc.data()?['registeredEvents'] ?? []);
    setState(() => _isSaved = saved.contains(_eventId));
  }

  Future<void> _toggleSave() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _isSaving = true);
    try {
      final ref =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      final doc = await ref.get();
      final current =
          List<String>.from(doc.data()?['registeredEvents'] ?? []);
      if (_isSaved) {
        current.remove(_eventId);
      } else {
        if (!current.contains(_eventId)) current.add(_eventId);
      }
      await ref.update({'registeredEvents': current});
      if (mounted) {
        setState(() {
          _isSaved = !_isSaved;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isSaved
              ? '✅ Added to My Events'
              : 'Removed from My Events'),
          backgroundColor:
              _isSaved ? Colors.green : Colors.orange[700],
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  static String _floorLabel(int level) {
    if (level == 0) return 'Ground Floor';
    if (level == -1) return 'Basement';
    if (level < -1) return 'Level $level';
    return 'Floor $level';
  }

  /// Loads the location pin associated with this event.
  /// Uses a composite key (eventName::schoolName) so JSON-loaded events
  /// (which have no Firestore document ID) work correctly.
  Future<void> _loadLocationPin() async {
    setState(() => _isLoading = true);
    try {
      String? pinId;

      // Primary: look up via composite event key stored in event_location_links
      final linkDoc = await FirebaseFirestore.instance
          .collection('event_location_links')
          .doc(_eventId)
          .get();
      if (linkDoc.exists) {
        pinId = linkDoc.data()?['locationPinId'] as String?;
      }

      // Fallback: event has a real Firestore ID — check parsed_events collection
      if (pinId == null && widget.event.id.isNotEmpty) {
        final eventDoc = await FirebaseFirestore.instance
            .collection('parsed_events')
            .doc(widget.event.id)
            .get();
        if (eventDoc.exists) {
          pinId = eventDoc.data()?['locationPinId'] as String?;
        }
      }

      // Fallback: use locationPinId already present on the model
      pinId ??= widget.event.locationPinId;

      if (pinId != null && pinId.isNotEmpty) {
        final pin = await _locationPinService.getLocationPinById(pinId);
        if (mounted) {
          setState(() {
            _linkedLocation = pin;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _linkedLocation = null;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading location pin: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openDropLocationPin() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return;
    }

    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => DropLocationPinScreen(
          schoolId: widget.schoolId,
          userId: userId,
        ),
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('event_location_links')
          .doc(_eventId)
          .set({
        'locationPinId': result,
        'schoolId': widget.schoolId,
        'eventName': widget.event.eventName,
        'schoolName': widget.event.schoolName,
      });

      if (widget.event.id.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('parsed_events')
            .doc(widget.event.id)
            .set({
          'locationPinId': result,
        }, SetOptions(merge: true));
      }

      await Future.delayed(const Duration(milliseconds: 300));
      await _loadLocationPin();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location pin linked successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error linking pin: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Determines the color theme for the event based on its name/category.
  Color _getEventColor() {
    final eventName = widget.event.eventName.toLowerCase();
    if (eventName.contains('coding') ||
        eventName.contains('programming') ||
        eventName.contains('website') ||
        eventName.contains('mobile')) {
      return const Color(0xFF4A90E2);
    } else if (eventName.contains('design') || eventName.contains('animation')) {
      return const Color(0xFF9B59B6);
    } else if (eventName.contains('business') || eventName.contains('financial')) {
      return const Color(0xFF27AE60);
    } else if (eventName.contains('speaking') || eventName.contains('presentation')) {
      return const Color(0xFFE67E22);
    }
    return const Color(0xFF001231);
  }

  /// Determines the icon for the event based on its name/category.
  IconData _getEventIcon() {
    final eventName = widget.event.eventName.toLowerCase();
    if (eventName.contains('coding') || eventName.contains('programming')) {
      return Icons.code;
    } else if (eventName.contains('website')) {
      return Icons.web;
    } else if (eventName.contains('mobile')) {
      return Icons.phone_android;
    } else if (eventName.contains('design')) {
      return Icons.design_services;
    } else if (eventName.contains('animation')) {
      return Icons.animation;
    } else if (eventName.contains('business')) {
      return Icons.business_center;
    } else if (eventName.contains('financial')) {
      return Icons.attach_money;
    } else if (eventName.contains('speaking')) {
      return Icons.mic;
    } else if (eventName.contains('presentation')) {
      return Icons.present_to_all;
    }
    return Icons.event;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final eventColor = _getEventColor();
    final eventIcon = _getEventIcon();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      body: CustomScrollView(
        slivers: [
          // App Bar with gradient and event icon
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              _isSaving
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white)),
                    )
                  : IconButton(
                      icon: Icon(
                        _isSaved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        color: _isSaved ? Colors.amber : Colors.white,
                      ),
                      tooltip: _isSaved ? 'Remove from My Events' : 'Save to My Events',
                      onPressed: _toggleSave,
                    ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [eventColor, eventColor.withOpacity(0.6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: 20,
                      child: Icon(
                        eventIcon,
                        size: 180,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 80,
                      bottom: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'NCCC 2025',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.event.eventName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  offset: Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Main Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Info Cards (Time, Room, Date, Participants count)
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          isDark,
                          Icons.access_time_rounded,
                          'Time',
                          DateFormat('h:mm a').format(widget.event.startTime),
                          eventColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoCard(
                          isDark,
                          Icons.location_on_rounded,
                          'Room',
                          widget.event.location,
                          eventColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          isDark,
                          Icons.calendar_today_rounded,
                          'Date',
                          DateFormat('MMM d, yyyy').format(widget.event.startTime),
                          eventColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoCard(
                          isDark,
                          Icons.people_rounded,
                          'Participants',
                          widget.event.totalParticipants > widget.event.participants.length
                              ? '${widget.event.participants.length} of ${widget.event.totalParticipants}'
                              : '${widget.event.participants.length}',
                          eventColor,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Save to My Events button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _toggleSave,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Icon(_isSaved
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded),
                      label: Text(_isSaved
                          ? 'Saved to My Events'
                          : 'Save to My Events'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isSaved
                            ? Colors.green[600]
                            : eventColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Participants List Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.group_rounded,
                              color: eventColor,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Participants',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.event.participants.map((participant) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: eventColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: eventColor.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.person,
                                    size: 14,
                                    color: eventColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    participant,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? Colors.white : Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Location & Navigation Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.navigation_rounded,
                              color: eventColor,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Navigation',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_isLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (_linkedLocation != null)
                          Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.check_circle_rounded,
                                      color: Colors.green,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _linkedLocation!.name,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          [
                                            _floorLabel(_linkedLocation!.floorLevel),
                                            if (_linkedLocation!.buildingName?.isNotEmpty ?? false)
                                              _linkedLocation!.buildingName!,
                                          ].join(' · '),
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: isDark ? Colors.white70 : Colors.black54,
                                          ),
                                        ),
                                        if (_linkedLocation!.description?.isNotEmpty ?? false) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            _linkedLocation!.description!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark ? Colors.white54 : Colors.black45,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ARNavigationScreen(
                                          event: widget.event,
                                          schoolId: widget.schoolId,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.navigation_rounded),
                                  label: const Text('Start AR Navigation'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: eventColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _openDropLocationPin,
                                  icon: const Icon(Icons.edit_location_alt_rounded),
                                  label: const Text('Update Location Pin'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: eventColor,
                                    side: BorderSide(color: eventColor),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.location_off_rounded,
                                      color: Colors.orange,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'No location pin set for this event',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isDark ? Colors.white70 : Colors.black54,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _openDropLocationPin,
                                  icon: const Icon(Icons.add_location_rounded),
                                  label: const Text('Drop Location Pin'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: eventColor,
                                    side: BorderSide(color: eventColor),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Additional Details Section
                  if (widget.event.performLocation != null ||
                      widget.event.prepLocation != null)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_rounded,
                                color: eventColor,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Additional Details',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (widget.event.performLocation != null)
                            _buildDetailRow(
                              isDark,
                              Icons.place_rounded,
                              'Performance Location',
                              widget.event.performLocation!,
                            ),
                          if (widget.event.prepLocation != null) ...[
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              isDark,
                              Icons.meeting_room_rounded,
                              'Preparation Room',
                              widget.event.prepLocation!,
                            ),
                          ],
                        ],
                      ),
                    ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Helper widget to build a small info card with an icon, label, and value.
  Widget _buildInfoCard(
    bool isDark,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white60 : Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Helper widget to build a row for additional details.
  Widget _buildDetailRow(bool isDark, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: isDark ? Colors.white60 : Colors.black54),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
