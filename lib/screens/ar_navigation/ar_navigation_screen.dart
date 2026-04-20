import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:camera/camera.dart';
import 'package:flutter_compass/flutter_compass.dart';
import '../../models/location_pin_model.dart';
import '../../models/parsed_event_model.dart';
import '../../services/ar_navigation_service.dart';
import '../../services/location_pin_service.dart';

/// Screen that displays the AR navigation interface.
/// Combines camera feed, compass heading, and location data to guide the user.
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
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final ARNavigationService _navService = ARNavigationService();
  final LocationPinService _locationService = LocationPinService();
  static const Color _brandNavy = Color(0xFF071B34);
  static const Color _brandBlue = Color(0xFF2F80ED);
  static const Color _brandMint = Color(0xFF27C3A8);
  static const Color _brandAmber = Color(0xFFF4B740);
  static const double _maxOperationalAccuracyMeters = 35.0;

  // Navigation state
  LocationPinModel? _destination;
  Position? _currentPosition;
  NavigationInstruction? _navInstruction;
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<CompassEvent>? _compassSubscription;
  double _currentHeading = 0.0;
  bool _isLoading = true;
  String? _errorMessage;
  double? _currentAccuracyMeters;
  double? _destinationAccuracyMeters;

  // Camera state
  CameraController? _cameraController;
  bool _isCameraInitialized = false;

  // Animation controllers for UI elements
  late AnimationController _pulseController;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    // Observe app lifecycle to handle background/foreground transitions
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize animations
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Start initialization process
    _initializeNavigation();
    _initializeCamera();
    _initializeCompass();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // When app resumes from background (e.g., after granting permissions in Settings)
    if (state == AppLifecycleState.resumed && _errorMessage != null) {
      // Re-check permissions and reinitialize if there was an error
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      _initializeNavigation();
      _initializeCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _positionSubscription?.cancel();
    _compassSubscription?.cancel();
    _cameraController?.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  /// Initializes the camera controller.
  /// Selects the back camera and sets resolution.
  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      // Use the back camera
      final camera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  /// Initializes the compass listener.
  /// Updates the current heading state on every change.
  void _initializeCompass() {
    _compassSubscription = FlutterCompass.events?.listen((event) {
      if (event.heading != null) {
        setState(() {
          _currentHeading = event.heading!;
          _updateNavigation();
        });
      }
    });
  }

  /// Main initialization flow for navigation.
  /// Checks permissions, loads destination, gets initial location, and starts updates.
  Future<void> _initializeNavigation() async {
    try {
      debugPrint('🚀 ========================================');
      debugPrint('🚀 Starting AR Navigation Initialization');
      debugPrint('🚀 ========================================');
      
      // Step 1: Check location services
      debugPrint('📍 Step 1: Checking location services...');
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint('📍 Location services: ${serviceEnabled ? "ENABLED ✅" : "DISABLED ❌"}');
      
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'Location services are disabled.\n\nPlease enable in:\nSettings → Privacy & Security → Location Services';
          _isLoading = false;
        });
        return;
      }

      // Step 2: Check location permission
      debugPrint('📍 Step 2: Checking location permission...');
      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint('📍 Permission status: $permission');
      
      if (permission == LocationPermission.denied) {
        debugPrint('📍 Requesting location permission...');
        permission = await Geolocator.requestPermission();
        debugPrint('📍 Permission after request: $permission');
      }
      
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = 'Location permission is required for AR navigation.\n\nPlease enable in:\nSettings → FBLA → Location → While Using';
          _isLoading = false;
        });
        return;
      }
      
      debugPrint('✅ Step 3: Location permission OK!');

      // Step 4: Try to initialize camera (don't block on it)
      debugPrint('📷 Step 4: Initializing camera...');
      try {
        await _initializeCamera();
        debugPrint('📷 Camera initialized successfully');
      } catch (e) {
        debugPrint('⚠️ Camera initialization warning: $e');
        // Don't fail - camera might work later
      }

      // Step 5: Get destination location pin
      debugPrint('📌 Step 5: Loading destination...');
      final locationPinId = await _resolveLocationPinId();
      if (locationPinId == null || locationPinId.isEmpty) {
        setState(() {
          _errorMessage = 'This event does not have a location assigned';
          _isLoading = false;
        });
        return;
      }

      final destination = await _locationService.getLocationPinById(locationPinId);
      debugPrint('📌 Destination loaded: ${destination?.name ?? "NULL"}');
      
      if (destination == null) {
        setState(() {
          _errorMessage = 'Location pin not found';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _destination = destination;
        _destinationAccuracyMeters =
            (destination.metadata?['capturedAccuracyMeters'] as num?)?.toDouble();
      });

      // Step 6: Get initial position
      debugPrint('🌍 Step 6: Getting current location...');
      final position = await _navService.getBestCurrentLocation();
      debugPrint('🌍 Current position: ${position != null ? "${position.latitude}, ${position.longitude}" : "NULL"}');
      
      if (position == null) {
        setState(() {
          _errorMessage = 'Failed to get current location.\n\nPlease ensure:\n• GPS is enabled\n• You are outdoors or near a window';
          _isLoading = false;
        });
        return;
      }

      if (position.accuracy > _maxOperationalAccuracyMeters) {
        setState(() {
          _errorMessage =
              'GPS accuracy is too low for reliable AR (±${position.accuracy.toStringAsFixed(1)}m).\n\nMove closer to a window or open area, then try again.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _currentPosition = position;
        _currentAccuracyMeters = position.accuracy;
        _updateNavigation();
        _isLoading = false;
      });
      
      debugPrint('✅ ========================================');
      debugPrint('✅ AR Navigation Ready!');
      debugPrint('✅ ========================================');

      // Step 7: Start listening to position updates
      _positionSubscription = _navService.getLocationStream().listen(
        (position) {
          if (position.accuracy > _maxOperationalAccuracyMeters) {
            return;
          }

          setState(() {
            _currentPosition = position;
            _currentAccuracyMeters = position.accuracy;
            _updateNavigation();
          });
        },
        onError: (error) {
          debugPrint('❌ Location stream error: $error');
          setState(() {
            _errorMessage = 'Failed to get location updates: $error';
          });
        },
      );
    } catch (e, stackTrace) {
      debugPrint('❌ ========================================');
      debugPrint('❌ Navigation initialization failed: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      debugPrint('❌ ========================================');
      
      setState(() {
        _errorMessage = 'Failed to initialize navigation: $e';
        _isLoading = false;
      });
    }
  }

  Future<String?> _resolveLocationPinId() async {
    if (widget.event.locationPinId != null && widget.event.locationPinId!.isNotEmpty) {
      return widget.event.locationPinId;
    }

    if (widget.event.schoolName != null) {
      final compositeKey = '${widget.event.eventName}::${widget.event.schoolName ?? ''}';
      final linkDoc = await FirebaseFirestore.instance
          .collection('event_location_links')
          .doc(compositeKey)
          .get();
      final linkedPinId = linkDoc.data()?['locationPinId'] as String?;
      if (linkedPinId != null && linkedPinId.isNotEmpty) {
        return linkedPinId;
      }
    }

    if (widget.event.id.isNotEmpty) {
      final eventDoc = await FirebaseFirestore.instance
          .collection('parsed_events')
          .doc(widget.event.id)
          .get();
      final parsedPinId = eventDoc.data()?['locationPinId'] as String?;
      if (parsedPinId != null && parsedPinId.isNotEmpty) {
        return parsedPinId;
      }
    }

    return null;
  }

  /// Updates the navigation instruction based on current position and heading.
  /// Animates the arrow rotation.
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
      // The arrow should point to the relative bearing
      // relativeBearing is calculated in service as bearing - heading
      // We want the arrow to point towards the destination relative to the phone's top
      // So we rotate it by relativeBearing
      if (instruction.relativeBearing.isFinite) {
        _rotationController.animateTo(
          instruction.relativeBearing / 360.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  /// Returns a color based on the navigation state (distance, arrival).
  Color _getDirectionColor() {
    if (_navInstruction == null) return Colors.grey;
    if (_navInstruction!.hasArrived) return _brandMint;
    if (_navInstruction!.distance < 10) return _brandAmber;
    return _brandBlue;
  }

  /// Returns the appropriate icon for the navigation arrow.
  IconData _getArrowIcon() {
    if (_navInstruction == null) return Icons.navigation;
    
    if (_navInstruction!.hasArrived) {
      return Icons.check_circle;
    }
    
    return Icons.arrow_upward;
  }

  String? _buildAccuracyNotice() {
    final currentAccuracy = _currentAccuracyMeters;
    if (currentAccuracy != null && currentAccuracy > 15) {
      return 'GPS accuracy is limited (±${currentAccuracy.toStringAsFixed(0)}m). Follow directions as approximate guidance.';
    }

    final destinationAccuracy = _destinationAccuracyMeters;
    if (destinationAccuracy != null && destinationAccuracy > 15) {
      return 'The saved pin was captured with ±${destinationAccuracy.toStringAsFixed(0)}m accuracy. Re-drop it for tighter AR guidance.';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('AR Navigation'),
          backgroundColor: _brandNavy,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Show error state with retry options
    if (_errorMessage != null) {
      final bool isPermissionError = _errorMessage!.contains('permission') || 
                                      _errorMessage!.contains('Permission');
      
      return Scaffold(
        appBar: AppBar(
          title: const Text('AR Navigation'),
          backgroundColor: _brandNavy,
          foregroundColor: Colors.white,
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
                if (isPermissionError) ...[
                  ElevatedButton.icon(
                    onPressed: () async {
                      await Geolocator.openAppSettings();
                    },
                    icon: const Icon(Icons.settings),
                    label: const Text('Open Settings'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brandNavy,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                        _errorMessage = null;
                      });
                      _initializeNavigation();
                      _initializeCamera();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
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

    // Main AR View
    return Scaffold(
      appBar: AppBar(
        title: const Text('AR Navigation'),
        backgroundColor: _brandNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Camera View
          if (_isCameraInitialized && _cameraController != null)
            SizedBox.expand(
              child: CameraPreview(_cameraController!),
            )
          else
            Container(
              color: Colors.black,
              child: const Center(
                child: Text(
                  'Initializing Camera...',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),

          // Overlay Gradient for better text visibility
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),

          // Navigation Overlay Elements
          Positioned.fill(
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Event Info Card
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    elevation: 0,
                    color: const Color(0xFFF8FBFF).withValues(alpha: 0.96),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: _brandBlue.withValues(alpha: 0.25)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.event.eventName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: _brandNavy,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Going to: ${_destination?.name ?? "Unknown"}',
                            style: const TextStyle(
                              color: Color(0xFF425466),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (_buildAccuracyNotice() != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: _brandAmber.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _buildAccuracyNotice()!,
                                style: const TextStyle(
                                  color: _brandNavy,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
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
                        child: Transform.rotate(
                          angle: (_navInstruction!.relativeBearing.isFinite 
                              ? _navInstruction!.relativeBearing 
                              : 0.0) * (math.pi / 180),
                          child: Icon(
                            _getArrowIcon(),
                            size: 80,
                            color: _getDirectionColor(),
                          ),
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
                color: const Color(0xFFF8FBFF).withValues(alpha: 0.97),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 18,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  if (_destination != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: _brandNavy),
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
                        if (_currentAccuracyMeters != null)
                          _buildInfoChip(
                            icon: Icons.gps_fixed,
                            label: 'GPS ±${_currentAccuracyMeters!.toStringAsFixed(0)}m',
                          ),
                        _buildInfoChip(
                          icon: Icons.layers,
                          label: _destination!.floorLevel == 0
                              ? 'Ground Floor'
                              : 'Floor ${_destination!.floorLevel}',
                        ),
                        if (_destinationAccuracyMeters != null)
                          _buildInfoChip(
                            icon: Icons.place,
                            label: 'Pin ±${_destinationAccuracyMeters!.toStringAsFixed(0)}m',
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
        color: _brandBlue.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _brandNavy),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}