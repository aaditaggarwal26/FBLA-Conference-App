import 'dart:math' show atan2, cos, sin, pi;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/location_pin_model.dart';

class ARNavigationService {
  // Request necessary permissions for AR navigation
  Future<bool> requestPermissions() async {
    try {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.camera,
        Permission.locationWhenInUse,
      ].request();

      final cameraGranted = statuses[Permission.camera]?.isGranted ?? false;
      final locationGranted = statuses[Permission.locationWhenInUse]?.isGranted ?? false;

      return cameraGranted && locationGranted;
    } catch (e) {
      return false;
    }
  }

  // Request only location permission (for dropping pins)
  Future<bool> requestLocationPermission() async {
    try {
      // Check if location services are enabled first
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      // Check current status
      final currentStatus = await Permission.locationWhenInUse.status;
      
      // If already granted, return true
      if (currentStatus.isGranted) {
        return true;
      }
      
      // If permanently denied, cannot request again
      if (currentStatus.isPermanentlyDenied) {
        return false;
      }
      
      // Request permission
      final status = await Permission.locationWhenInUse.request();
      return status.isGranted;
    } catch (e) {
      print('Error requesting location permission: $e');
      return false;
    }
  }

  // Check if location permission is permanently denied
  Future<bool> isLocationPermanentlyDenied() async {
    try {
      final status = await Permission.locationWhenInUse.status;
      return status.isPermanentlyDenied;
    } catch (e) {
      return false;
    }
  }

  // Check if all required permissions are granted
  Future<bool> hasRequiredPermissions() async {
    try {
      final cameraStatus = await Permission.camera.status;
      final locationStatus = await Permission.locationWhenInUse.status;
      
      return cameraStatus.isGranted && locationStatus.isGranted;
    } catch (e) {
      return false;
    }
  }

  // Get current user location with better error handling
  Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled');
        return null;
      }

      // Check location permission status
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permissions are denied');
          return null;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied');
        return null;
      }

      // Get position with timeout
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  // Get continuous location stream
  Stream<Position> getLocationStream() {
    final LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 1,
    );
    
    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  // Calculate distance between two points in meters
  double calculateDistance({
    required double fromLatitude,
    required double fromLongitude,
    required double toLatitude,
    required double toLongitude,
  }) {
    return Geolocator.distanceBetween(
      fromLatitude,
      fromLongitude,
      toLatitude,
      toLongitude,
    );
  }

  // Calculate bearing (direction) from current location to destination
  // Returns angle in degrees (0-360) where 0 is North, 90 is East, 180 is South, 270 is West
  double calculateBearing({
    required double fromLatitude,
    required double fromLongitude,
    required double toLatitude,
    required double toLongitude,
  }) {
    final lat1 = _toRadians(fromLatitude);
    final lat2 = _toRadians(toLatitude);
    final dLon = _toRadians(toLongitude - fromLongitude);

    final y = sin(dLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);

    final bearing = atan2(y, x);
    return (_toDegrees(bearing) + 360) % 360; // Normalize to 0-360
  }

  double _toRadians(double degrees) => degrees * pi / 180.0;
  double _toDegrees(double radians) => radians * 180.0 / pi;

  // Get navigation instructions based on distance and bearing
  NavigationInstruction getNavigationInstruction({
    required Position currentPosition,
    required LocationPinModel destination,
    required double currentHeading, // User's current heading in degrees
  }) {
    final distance = calculateDistance(
      fromLatitude: currentPosition.latitude,
      fromLongitude: currentPosition.longitude,
      toLatitude: destination.latitude,
      toLongitude: destination.longitude,
    );

    final bearing = calculateBearing(
      fromLatitude: currentPosition.latitude,
      fromLongitude: currentPosition.longitude,
      toLatitude: destination.latitude,
      toLongitude: destination.longitude,
    );

    // Calculate relative bearing (difference between destination bearing and current heading)
    double relativeBearing = bearing - currentHeading;
    if (relativeBearing < 0) relativeBearing += 360;
    if (relativeBearing > 360) relativeBearing -= 360;
    
    // Ensure relativeBearing is finite
    if (!relativeBearing.isFinite) {
      relativeBearing = 0.0;
    }

    // Determine direction instruction
    String direction;
    String arrowDirection;

    if (distance < 3) {
      direction = 'You have arrived!';
      arrowDirection = 'arrived';
    } else if (relativeBearing >= 350 || relativeBearing <= 10) {
      direction = 'Continue straight ahead';
      arrowDirection = 'straight';
    } else if (relativeBearing > 10 && relativeBearing <= 45) {
      direction = 'Turn slightly right';
      arrowDirection = 'slight_right';
    } else if (relativeBearing > 45 && relativeBearing <= 135) {
      direction = 'Turn right';
      arrowDirection = 'right';
    } else if (relativeBearing > 135 && relativeBearing <= 170) {
      direction = 'Turn sharp right';
      arrowDirection = 'sharp_right';
    } else if (relativeBearing > 170 && relativeBearing <= 190) {
      direction = 'Turn around';
      arrowDirection = 'u_turn';
    } else if (relativeBearing > 190 && relativeBearing <= 225) {
      direction = 'Turn sharp left';
      arrowDirection = 'sharp_left';
    } else if (relativeBearing > 225 && relativeBearing <= 315) {
      direction = 'Turn left';
      arrowDirection = 'left';
    } else {
      direction = 'Turn slightly left';
      arrowDirection = 'slight_left';
    }

    return NavigationInstruction(
      distance: distance,
      bearing: bearing,
      relativeBearing: relativeBearing,
      direction: direction,
      arrowDirection: arrowDirection,
      destination: destination,
      currentFloor: 0, // TODO: Implement floor detection
      destinationFloor: destination.floorLevel,
      needsFloorChange: destination.floorLevel != 0,
    );
  }

  // Get formatted distance string
  String formatDistance(double meters) {
    if (meters < 1) {
      return '${meters.toStringAsFixed(1)} m';
    } else if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(2)} km';
    }
  }

  // Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Open location settings
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  // Open app settings
  Future<void> openAppSettings() async {
    await Permission.locationWhenInUse.request();
  }
}

// Navigation instruction model
class NavigationInstruction {
  final double distance; // in meters
  final double bearing; // absolute bearing in degrees
  final double relativeBearing; // relative to user's heading
  final String direction; // human-readable direction
  final String arrowDirection; // direction for AR arrow rendering
  final LocationPinModel destination;
  final int currentFloor;
  final int destinationFloor;
  final bool needsFloorChange;

  NavigationInstruction({
    required this.distance,
    required this.bearing,
    required this.relativeBearing,
    required this.direction,
    required this.arrowDirection,
    required this.destination,
    required this.currentFloor,
    required this.destinationFloor,
    required this.needsFloorChange,
  });

  bool get hasArrived => distance < 3;

  String get distanceFormatted {
    if (distance < 1) {
      return '${distance.toStringAsFixed(1)} m';
    } else if (distance < 1000) {
      return '${distance.round()} m';
    } else {
      return '${(distance / 1000).toStringAsFixed(2)} km';
    }
  }

  String get floorInstructions {
    if (!needsFloorChange) return '';
    
    final diff = destinationFloor - currentFloor;
    if (diff > 0) {
      return 'Go up $diff floor${diff > 1 ? 's' : ''}';
    } else if (diff < 0) {
      return 'Go down ${-diff} floor${diff < -1 ? 's' : ''}';
    }
    return '';
  }
}
