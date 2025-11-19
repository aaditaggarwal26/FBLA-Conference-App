import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/location_pin_model.dart';
import '../../models/parsed_event_model.dart';
import '../../services/ar_navigation_service.dart';
import '../../services/location_pin_service.dart';
import 'dart:math' as math;

class ARNavigationScreen extends StatefulWidget {
  final ParsedEventModel event;
  final String schoolId;

  const ARNavigationScreen({
    super.key,
    required this.event,
    required this.schoolId,
  });

  @override
  State<ARNavigationScreen> createState() => _ARNavigationScreenState();
}

class _ARNavigationScreenState extends State<ARNavigationScreen>
    with TickerProviderStateMixin {
  final ARNavigationService _navService = ARNavigationService();
  final LocationPinService _locationService = LocationPinService();

  LocationPinModel? _destination;
  Position? _currentPosition;
  NavigationInstruction? _navInstruction;
  StreamSubscription<Position>? _positionSubscription;
  double _currentHeading = 0.0;
  bool _isLoading = true;
  String? _errorMessage;

  late AnimationController _pulseController;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _initializeNavigation();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _initializeNavigation() async {
    try {
      // Check permissions
      final hasPermissions = await _navService.hasRequiredPermissions();
      if (!hasPermissions) {
        final granted = await _navService.requestPermissions();
        if (!granted) {
          setState(() {
            _errorMessage = 'Location and camera permissions are required';
            _isLoading = false;
          });
          return;
        }
      }

      // Get destination location pin
      if (widget.event.locationPinId == null) {
        setState(() {
          _errorMessage = 'This event does not have a location assigned';
          _isLoading = false;
        });
        return;
      }

      final destination =
          await _locationService.getLocationPinById(widget.event.locationPinId!);
      if (destination == null) {
        setState(() {
          _errorMessage = 'Location pin not found';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _destination = destination;
      });

      // Get initial position
      final position = await _navService.getCurrentLocation();
      if (position != null) {
        setState(() {
          _currentPosition = position;
          _updateNavigation();
          _isLoading = false;
        });
      }

      // Start listening to position updates
      _positionSubscription = _navService.getLocationStream().listen(
        (position) {
          setState(() {
            _currentPosition = position;
            _updateNavigation();
          });
        },
        onError: (error) {
          setState(() {
            _errorMessage = 'Failed to get location: $error';
          });
        },
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize navigation: $e';
        _isLoading = false;
      });
    }
  }

  void _updateNavigation() {
    if (_currentPosition != null && _destination != null) {
      final instruction = _navService.getNavigationInstruction(
        currentPosition: _currentPosition!,
        destination: _destination!,
        currentHeading: _currentHeading,
      );

      setState(() {
        _navInstruction = instruction;
      });

      // Animate rotation of arrow
      _rotationController.forward(from: 0.0);
    }
  }

  Color _getDirectionColor() {
    if (_navInstruction == null) return Colors.grey;
    if (_navInstruction!.hasArrived) return Colors.green;
    if (_navInstruction!.distance < 10) return Colors.orange;
    return const Color(0xFF001231);
  }

  IconData _getArrowIcon() {
    if (_navInstruction == null) return Icons.navigation;
    
    switch (_navInstruction!.arrowDirection) {
      case 'arrived':
        return Icons.check_circle;
      case 'straight':
        return Icons.arrow_upward;
      case 'slight_right':
        return Icons.arrow_forward;
      case 'right':
        return Icons.arrow_forward;
      case 'sharp_right':
        return Icons.arrow_forward;
      case 'u_turn':
        return Icons.u_turn_right;
      case 'sharp_left':
        return Icons.arrow_back;
      case 'left':
        return Icons.arrow_back;
      case 'slight_left':
        return Icons.arrow_back;
      default:
        return Icons.navigation;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('AR Navigation'),
          backgroundColor: const Color(0xFF001231),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('AR Navigation'),
          backgroundColor: const Color(0xFF001231),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 80, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('AR Navigation'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Camera View Placeholder (AR plugin would go here)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
            child: Center(
              child: Text(
                'AR Camera View',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 24,
                ),
              ),
            ),
          ),

          // Navigation Overlay
          Positioned.fill(
            child: Column(
              children: [
                const SizedBox(height: 100),

                // Event Info Card
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    color: Colors.white.withOpacity(0.95),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            widget.event.eventName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Going to: ${_destination?.name ?? "Unknown"}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // Arrow and Distance Display
                if (_navInstruction != null) ...[
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1.0 + (_pulseController.value * 0.1),
                        child: child,
                      );
                    },
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getDirectionColor().withOpacity(0.2),
                        border: Border.all(
                          color: _getDirectionColor(),
                          width: 4,
                        ),
                      ),
                      child: Center(
                        child: AnimatedBuilder(
                          animation: _rotationController,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _navInstruction!.relativeBearing *
                                  (math.pi / 180),
                              child: Icon(
                                _getArrowIcon(),
                                size: 80,
                                color: _getDirectionColor(),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Distance
                  Text(
                    _navInstruction!.distanceFormatted,
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          blurRadius: 10,
                          color: Colors.black,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Direction Text
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _getDirectionColor(),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      _navInstruction!.direction,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Floor Instructions
                  if (_navInstruction!.needsFloorChange) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.stairs, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            _navInstruction!.floorInstructions,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],

                const SizedBox(height: 100),
              ],
            ),
          ),

          // Bottom Info Panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  if (_destination != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Color(0xFF001231)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _destination!.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (_destination!.buildingName != null)
                                Text(
                                  _destination!.buildingName!,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildInfoChip(
                          icon: Icons.layers,
                          label: _destination!.floorLevel == 0
                              ? 'Ground Floor'
                              : 'Floor ${_destination!.floorLevel}',
                        ),
                        _buildInfoChip(
                          icon: Icons.schedule,
                          label:
                              '${widget.event.startTime.hour}:${widget.event.startTime.minute.toString().padLeft(2, '0')}',
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF001231).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF001231)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
