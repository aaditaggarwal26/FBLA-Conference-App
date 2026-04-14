import 'dart:math' show atan2, cos, sin, pi;
import 'package:geolocator/geolocator.dart';
import '../models/location_pin_model.dart';

/// Service to handle AR navigation logic, including location tracking,
/// bearing calculation, and navigation instructions.
class ARNavigationService {
  
  /// Checks if location permission is currently granted.
  /// Returns true if permission is 'whileInUse' or 'always'.
  Future<bool> checkLocationPermission() async {
    try {
      print('📍 Checking location permission...');
      final permission = await Geolocator.checkPermission();
      print('📍 Location permission status: $permission');
      
      final granted = permission == LocationPermission.whileInUse || 
                     permission == LocationPermission.always;
      print(granted ? '✅ Location permission granted' : '❌ Location permission denied');
      
      return granted;
    } catch (e) {
      print('❌ Error checking location permission: $e');
      return false;
    }
  }
  
  /// Requests location permission from the user.
  /// Returns true if permission is granted after the request.
  Future<bool> requestLocationPermission() async {
    try {
      print('🔄 Requesting location permission...');
      final permission = await Geolocator.requestPermission();
      print('📍 Location permission after request: $permission');
      
      final granted = permission == LocationPermission.whileInUse || 
                     permission == LocationPermission.always;
      print(granted ? '✅ Location GRANTED' : '❌ Location DENIED');
      
      return granted;
    } catch (e) {
      print('❌ Error requesting location permission: $e');
      return false;
    }
  }

  /// Wrapper to request location permission specifically for dropping pins.
  Future<bool> requestLocationPermissionForPin() async {
    return await requestLocationPermission();
  }

  /// Retrieves the current user location with high accuracy.
  /// Handles permission checks and service status checks internally.
  /// Returns null if location cannot be retrieved.
  Future<Position?> getCurrentLocation() async {
    try {
      // Verify that location services are enabled on the device
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled');
        return null;
      }

      // Check and request permissions if necessary
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

      // Fetch the current position with a 10-second timeout
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  /// Returns a stream of position updates.
  /// Useful for real-time navigation.
  Stream<Position> getLocationStream() {
    final LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 1, // Update every 1 meter
    );
    
    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  /// Calculates the distance in meters between two coordinates.
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

  /// Calculates the bearing (direction) from the start point to the end point.
  /// Returns the angle in degrees (0-360), where 0 is North.
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
    return (_toDegrees(bearing) + 360) % 360; // Normalize to 0-360 range
  }

  /// Converts degrees to radians.
  double _toRadians(double degrees) => degrees * pi / 180.0;
  
  /// Converts radians to degrees.
  double _toDegrees(double radians) => radians * 180.0 / pi;

  /// Generates navigation instructions based on current position and destination.
  /// Calculates distance, bearing, and directional cues (e.g., "Turn left").
  NavigationInstruction getNavigationInstruction({
    required Position currentPosition,
    required LocationPinModel destination,
    required double currentHeading, // User's current compass heading in degrees
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

    // Calculate relative bearing (difference between target bearing and user heading)
    double relativeBearing = bearing - currentHeading;
    if (relativeBearing < 0) relativeBearing += 360;
    if (relativeBearing > 360) relativeBearing -= 360;
    
    // Handle edge cases where calculation might result in NaN or infinite
    if (!relativeBearing.isFinite) {
      relativeBearing = 0.0;
    }

    // Determine the text instruction and arrow icon based on relative bearing
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
      currentFloor: 0, // Placeholder for floor detection logic
      destinationFloor: destination.floorLevel,
      needsFloorChange: destination.floorLevel != 0,
    );
  }

  /// Formats a distance in meters to a human-readable string (m or km).
  String formatDistance(double meters) {
    if (meters < 1) {
      return '${meters.toStringAsFixed(1)} m';
    } else if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(2)} km';
    }
  }

  /// Checks if location services are enabled on the device.
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Opens the device's location settings.
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Opens the app's settings (permissions).
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }
}

/// Model class to hold navigation instruction details.
class NavigationInstruction {
  final double distance; // Distance to target in meters
  final double bearing; // Absolute bearing to target in degrees
  final double relativeBearing; // Bearing relative to user's heading
  final String direction; // Text instruction (e.g., "Turn left")
  final String arrowDirection; // Icon identifier for UI
  final LocationPinModel destination; // Target location
  final int currentFloor; // User's current floor (estimated)
  final int destinationFloor; // Target floor
  final bool needsFloorChange; // Whether a floor change is required

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

  /// Returns true if the user is within 3 meters of the destination.
  bool get hasArrived => distance < 3;

  /// Returns a formatted string representation of the distance.
  String get distanceFormatted {
    if (distance < 1) {
      return '${distance.toStringAsFixed(1)} m';
    } else if (distance < 1000) {
      return '${distance.round()} m';
    } else {
      return '${(distance / 1000).toStringAsFixed(2)} km';
    }
  }

  /// Returns instructions for changing floors if necessary.
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
