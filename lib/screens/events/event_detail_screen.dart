import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/event_model.dart';
import '../../models/location_pin_model.dart';
import '../../services/event_service.dart';
import '../../services/auth_service.dart';
import '../../services/linkedin_service.dart';
import '../../services/location_pin_service.dart';
import '../../theme/app_theme.dart';
import 'event_qr_code_screen.dart';
import '../ar_navigation/drop_location_pin_screen.dart';
import '../ar_navigation/ar_navigation_screen.dart';
import '../../models/parsed_event_model.dart';

class EventDetailScreen extends StatefulWidget {
  final EventModel event;

  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final EventService _eventService = EventService();
  final AuthService _authService = AuthService();
  final LinkedInService _linkedInService = LinkedInService();
  final LocationPinService _locationPinService = LocationPinService();
  bool _isRegistered = false;
  bool _isLoading = false;
  bool _isSharingToLinkedIn = false;
  LocationPinModel? _linkedLocation;
  bool _isLoadingPin = false;
  String? _userSchoolId;

  @override
  void initState() {
    super.initState();
    _checkRegistrationStatus();
    _loadLocationPin();
    _loadUserSchool();
  }

  Future<void> _loadUserSchool() async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && mounted) {
        setState(() {
          _userSchoolId = (doc.data() as Map<String, dynamic>)['schoolId'] as String?;
        });
      }
    } catch (_) {}
  }

  String get _locationLinkId => widget.event.id;

  Future<void> _loadLocationPin() async {
    setState(() => _isLoadingPin = true);
    try {
      final linkDoc = await FirebaseFirestore.instance
          .collection('event_location_links')
          .doc(_locationLinkId)
          .get();
      if (linkDoc.exists) {
        final pinId = linkDoc.data()?['locationPinId'] as String?;
        if (pinId != null && pinId.isNotEmpty) {
          final pin = await _locationPinService.getLocationPinById(pinId);
          if (mounted) setState(() => _linkedLocation = pin);
        }
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoadingPin = false);
    }
  }

  Future<void> _dropLocationPin() async {
    final userId = _authService.currentUser?.uid;
    final schoolId = _userSchoolId;
    if (userId == null) return;
    if (schoolId == null || schoolId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Join a school first to drop location pins'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => DropLocationPinScreen(
          schoolId: schoolId,
          userId: userId,
        ),
      ),
    );

    if (result != null && mounted) {
      try {
        await FirebaseFirestore.instance
            .collection('event_location_links')
            .doc(_locationLinkId)
            .set({
          'locationPinId': result,
          'schoolId': schoolId,
          'eventName': widget.event.title,
          'schoolName': '',
        });
        await _loadLocationPin();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location pin linked to this event!'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error linking pin: $e'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    }
  }

  void _checkRegistrationStatus() {
    final userId = _authService.currentUser?.uid;
    if (userId != null) {
      setState(() {
        _isRegistered = widget.event.registeredUsers.contains(userId);
      });
    }
  }

  Future<void> _toggleRegistration() async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      if (_isRegistered) {
        await _eventService.unregisterFromEvent(widget.event.id, userId);
      } else {
        if (widget.event.isFull) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This event is full'),
              backgroundColor: AppTheme.error,
            ),
          );
          return;
        }
        await _eventService.registerForEvent(widget.event.id, userId);
      }

      setState(() => _isRegistered = !_isRegistered);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isRegistered
                ? 'Successfully registered!'
                : 'Registration cancelled',
          ),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            actions: [
              IconButton(
                icon: _isSharingToLinkedIn
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.business_rounded),
                onPressed: _isSharingToLinkedIn ? null : _shareToLinkedIn,
                tooltip: 'Share on LinkedIn',
              ),
              IconButton(
                icon: const Icon(Icons.qr_code_rounded),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          EventQRCodeScreen(event: widget.event),
                    ),
                  );
                },
                tooltip: 'Show QR Code',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background:
                  widget.event.imageUrl != null &&
                      widget.event.imageUrl!.isNotEmpty
                  ? Image.network(
                      widget.event.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPlaceholderImage();
                      },
                    )
                  : _buildPlaceholderImage(),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.lightBlue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.event.category,
                      style: TextStyle(
                        color: AppTheme.darkBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Title
                  Text(
                    widget.event.title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Time
                  _buildInfoRow(
                    Icons.access_time_rounded,
                    'Time',
                    '${DateFormat('EEEE, MMM d').format(widget.event.startTime)}\n${DateFormat('h:mm a').format(widget.event.startTime)} - ${DateFormat('h:mm a').format(widget.event.endTime)}',
                  ),

                  const SizedBox(height: 16),

                  // Location
                  _buildInfoRow(
                    Icons.location_on_rounded,
                    'Location',
                    widget.event.location,
                  ),

                  const SizedBox(height: 16),

                  // Capacity
                  _buildInfoRow(
                    Icons.people_rounded,
                    'Capacity',
                    '${widget.event.registeredUsers.length}/${widget.event.maxCapacity} registered',
                  ),

                  const SizedBox(height: 24),

                  // Description
                  Text(
                    'About',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    widget.event.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),

                  if (widget.event.speakers.isNotEmpty) ...[
                    const SizedBox(height: 24),

                    Text(
                      'Speakers',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    ...widget.event.speakers.map(
                      (speaker) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppTheme.lightBlue,
                              child: Icon(
                                Icons.person,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              speaker,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // AR Navigation Section
                  Text(
                    'AR Navigation',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_isLoadingPin)
                    const Center(child: CircularProgressIndicator())
                  else if (_linkedLocation != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.lightBlue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_on_rounded, color: AppTheme.primaryBlue, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _linkedLocation!.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                if (_linkedLocation!.buildingName != null)
                                  Text(
                                    _linkedLocation!.buildingName!,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ARNavigationScreen(
                                event: ParsedEventModel(
                                  id: widget.event.id,
                                  schoolId: _userSchoolId ?? '',
                                  eventName: widget.event.title,
                                  location: widget.event.location,
                                  startTime: widget.event.startTime,
                                  endTime: widget.event.endTime,
                                  participants: const [],
                                  totalParticipants: 0,
                                  locationPinId: _linkedLocation!.id,
                                ),
                                schoolId: _userSchoolId ?? '',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.navigation_rounded),
                        label: const Text('Navigate with AR'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _dropLocationPin,
                        icon: const Icon(Icons.edit_location_alt_rounded),
                        label: const Text('Update Location Pin'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryBlue,
                          side: BorderSide(color: AppTheme.primaryBlue),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.mediumGray.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_off_rounded, color: AppTheme.mediumGray),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text('No location pin set for this event yet.'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _dropLocationPin,
                        icon: const Icon(Icons.add_location_alt_rounded),
                        label: const Text('Drop Location Pin'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _toggleRegistration,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isRegistered
                  ? AppTheme.mediumGray
                  : AppTheme.primaryBlue,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    _isRegistered ? 'Cancel Registration' : 'Register Now',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.lightBlue,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryBlue, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.mediumGray),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: AppTheme.lightBlue,
      child: Center(
        child: Icon(Icons.event_rounded, size: 80, color: AppTheme.primaryBlue),
      ),
    );
  }

  Future<void> _shareToLinkedIn() async {
    final isConnected = await _linkedInService.isConnected();
    
    if (!isConnected) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please connect LinkedIn in Profile settings first'),
            backgroundColor: AppTheme.warning,
          ),
        );
      }
      return;
    }

    setState(() => _isSharingToLinkedIn = true);

    try {
      final success = await _linkedInService.shareEvent(
        title: widget.event.title,
        description: widget.event.description,
        startTime: widget.event.startTime,
        location: widget.event.location,
        context: context,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Event shared on LinkedIn!'
                  : 'Failed to share on LinkedIn',
            ),
            backgroundColor: success ? AppTheme.success : AppTheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing to LinkedIn: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharingToLinkedIn = false);
      }
    }
  }
}
