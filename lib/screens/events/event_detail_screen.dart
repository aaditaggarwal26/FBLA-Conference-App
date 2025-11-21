import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import '../../services/auth_service.dart';
import '../../services/linkedin_service.dart';
import '../../theme/app_theme.dart';
import 'event_qr_code_screen.dart';

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
  bool _isRegistered = false;
  bool _isLoading = false;
  bool _isSharingToLinkedIn = false;

  @override
  void initState() {
    super.initState();
    _checkRegistrationStatus();
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
