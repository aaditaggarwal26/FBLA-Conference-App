import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/parsed_event_model.dart';
import '../../models/location_pin_model.dart';
import '../../services/location_pin_service.dart';
import '../../services/event_import_service.dart';
import '../ar_navigation/drop_location_pin_screen.dart';
import 'event_detail_page.dart';

class NCCCEventGroupPage extends StatefulWidget {
  final String eventName;
  final List<ParsedEventModel> events;
  final String schoolId;
  final Color eventColor;
  final IconData eventIcon;
  final String? currentUserName;
  final bool isAdmin;

  const NCCCEventGroupPage({
    super.key,
    required this.eventName,
    required this.events,
    required this.schoolId,
    required this.eventColor,
    required this.eventIcon,
    this.currentUserName,
    this.isAdmin = false,
  });

  @override
  State<NCCCEventGroupPage> createState() => _NCCCEventGroupPageState();
}

class _NCCCEventGroupPageState extends State<NCCCEventGroupPage> {
  final LocationPinService _locationPinService = LocationPinService();
  final EventImportService _eventImportService = EventImportService();
  LocationPinModel? _linkedLocation;

  @override
  void initState() {
    super.initState();
    _loadLocationPin();
  }

  Future<void> _loadLocationPin() async {
    try {
      String? pinId;

      for (final event in widget.events) {
        final linkId = '${event.eventName}::${event.schoolName ?? ""}';
        final linkDoc = await FirebaseFirestore.instance
            .collection('event_location_links')
            .doc(linkId)
            .get();
        if (linkDoc.exists) {
          pinId = linkDoc.data()?['locationPinId'] as String?;
        }

        pinId ??= event.locationPinId;
        if (pinId != null && pinId.isNotEmpty) {
          break;
        }
      }

      if (pinId == null || pinId.isEmpty) {
        if (mounted) {
          setState(() => _linkedLocation = null);
        }
        return;
      }

      final pin = await _locationPinService.getLocationPinById(pinId);
      if (mounted) {
        setState(() {
          _linkedLocation = pin;
        });
      }
    } catch (e) {
      debugPrint('Error loading location pin: $e');
    }
  }

  Future<void> _handleHeaderTap() async {
    if (!widget.isAdmin) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    // If location pin exists, show options
    if (_linkedLocation != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Location Pin'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('This event has a location pin set.'),
              const SizedBox(height: 8),
              Text(
                'Location: ${_linkedLocation!.description?.isNotEmpty ?? false ? _linkedLocation!.description : "Floor ${_linkedLocation!.floorLevel}"}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _dropNewPin(userId);
              },
              child: const Text('Change Pin'),
            ),
          ],
        ),
      );
    } else {
      // No pin exists, drop a new one
      await _dropNewPin(userId);
    }
  }

  Future<void> _dropNewPin(String userId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DropLocationPinScreen(
          schoolId: widget.schoolId,
          userId: userId,
        ),
      ),
    );

    if (result != null && mounted) {
      // Link the created pin to ALL events in this group
      try {
        for (final event in widget.events) {
          await _eventImportService.linkEventToLocation(
            event.id,
            result,
          );
        }
        _loadLocationPin();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Location pin linked to all ${widget.events.length} time slots!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error linking pin: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  bool _isMyEvent(ParsedEventModel event) {
    if (widget.currentUserName == null) return false;
    final pWords = (p) => (p as String).toLowerCase().split(RegExp(r'\s+'));
    final sWords = widget.currentUserName!.toLowerCase().trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (sWords.isEmpty) return false;
    return event.participants.any(
      (participant) => sWords.every(
        (sw) => pWords(participant).any((pw) => pw == sw),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sortedEvents = List<ParsedEventModel>.from(widget.events)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        title: Text(
          widget.eventName,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header Card - Tappable for admins to drop pin
          GestureDetector(
            onTap: widget.isAdmin ? _handleHeaderTap : null,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [widget.eventColor, widget.eventColor.withOpacity(0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: widget.eventColor.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          widget.eventIcon,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.eventName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.access_time, size: 16, color: Colors.white70),
                                const SizedBox(width: 4),
                                Text(
                                  '${sortedEvents.length} time slots',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Icon(
                                  _linkedLocation != null
                                      ? Icons.location_on
                                      : Icons.location_off,
                                  size: 16,
                                  color: _linkedLocation != null
                                      ? Colors.greenAccent
                                      : Colors.white70,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    sortedEvents.first.location,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Admin indicator
                  if (widget.isAdmin)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _linkedLocation != null
                                  ? Icons.edit_location
                                  : Icons.add_location,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _linkedLocation != null ? 'Edit Pin' : 'Drop Pin',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Time Slots List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: sortedEvents.length,
              itemBuilder: (context, index) {
                final event = sortedEvents[index];
                final isMyTimeSlot = _isMyEvent(event);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: isMyTimeSlot ? 4 : 1,
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isMyTimeSlot
                        ? const BorderSide(color: Colors.amber, width: 2)
                        : BorderSide.none,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EventDetailPage(
                            event: event,
                            schoolId: widget.schoolId,
                            isAdmin: widget.isAdmin,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Time and My Event badge
                          Row(
                            children: [
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: widget.eventColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 16,
                                        color: widget.eventColor,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        DateFormat('h:mm a').format(event.startTime),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (isMyTimeSlot) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.star,
                                        size: 14,
                                        color: Colors.black,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'MY EVENT',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Participants Section
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.people,
                                size: 20,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: event.participants.map((participant) {
                                    final isMe = widget.currentUserName != null &&
                                        participant
                                            .toLowerCase()
                                            .contains(widget.currentUserName!.toLowerCase());
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isMe
                                            ? Colors.amber.withOpacity(0.3)
                                            : widget.eventColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isMe
                                              ? Colors.amber
                                              : widget.eventColor.withOpacity(0.3),
                                          width: isMe ? 2 : 1,
                                        ),
                                      ),
                                      child: Text(
                                        participant,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isMe
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          color: isMe
                                              ? Colors.amber.shade900
                                              : (isDark ? Colors.white : Colors.black87),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Location info
                          Row(
                            children: [
                              Icon(
                                Icons.meeting_room,
                                size: 16,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  event.location.isNotEmpty ? event.location : 'TBD',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? Colors.white70 : Colors.black54,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 14,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
