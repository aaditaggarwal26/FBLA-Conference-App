import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/location_pin_model.dart';

/// Service to manage location pins in Firestore and Storage.
/// Handles creation, retrieval, updating, and deletion of pins.
class LocationPinService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  /// Creates a new location pin in Firestore.
  /// Uploads associated images to Firebase Storage if provided.
  /// Returns the ID of the newly created pin.
  Future<String> createLocationPin({
    required String schoolId,
    required String name,
    String? description,
    required double latitude,
    required double longitude,
    required int floorLevel,
    String? buildingName,
    required String userId,
    File? imageFile,
    File? arReferenceImageFile,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      String? imageUrl;
      String? arReferenceImageUrl;

      // Upload main location image if provided
      if (imageFile != null) {
        imageUrl = await _uploadImage(
          schoolId,
          'location_images',
          imageFile,
        );
      }

      // Upload AR reference image if provided
      if (arReferenceImageFile != null) {
        arReferenceImageUrl = await _uploadImage(
          schoolId,
          'ar_reference_images',
          arReferenceImageFile,
        );
      }

      // Create the pin model
      final locationPin = LocationPinModel(
        id: '', // ID will be assigned by Firestore
        schoolId: schoolId,
        name: name,
        description: description,
        latitude: latitude,
        longitude: longitude,
        floorLevel: floorLevel,
        buildingName: buildingName,
        imageUrl: imageUrl,
        arReferenceImageUrl: arReferenceImageUrl,
        createdAt: DateTime.now(),
        createdBy: userId,
        metadata: metadata,
      );

      // Add to Firestore
      final docRef = await _firestore
          .collection('location_pins')
          .add(locationPin.toFirestore());

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create location pin: $e');
    }
  }

  /// Helper method to upload an image to Firebase Storage.
  /// Returns the download URL of the uploaded image.
  Future<String> _uploadImage(
    String schoolId,
    String folder,
    File imageFile,
  ) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
    final ref = _storage.ref().child('$folder/$schoolId/$fileName');
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  /// Returns a stream of all location pins for a specific school.
  /// Ordered by creation date (newest first).
  Stream<List<LocationPinModel>> getLocationPins(String schoolId) {
    return _firestore
        .collection('location_pins')
        .where('schoolId', isEqualTo: schoolId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => LocationPinModel.fromFirestore(doc)).toList());
  }

  /// Fetches a specific location pin by its ID.
  /// Returns null if the pin does not exist.
  Future<LocationPinModel?> getLocationPinById(String pinId) async {
    try {
      final doc = await _firestore.collection('location_pins').doc(pinId).get();
      if (doc.exists) {
        return LocationPinModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get location pin: $e');
    }
  }

  /// Updates an existing location pin in Firestore.
  Future<void> updateLocationPin(LocationPinModel pin) async {
    try {
      await _firestore
          .collection('location_pins')
          .doc(pin.id)
          .update(pin.toFirestore());
    } catch (e) {
      throw Exception('Failed to update location pin: $e');
    }
  }

  /// Deletes a location pin from Firestore.
  /// Note: Does not currently delete associated images from Storage.
  Future<void> deleteLocationPin(String pinId) async {
    try {
      await _firestore.collection('location_pins').doc(pinId).delete();
    } catch (e) {
      throw Exception('Failed to delete location pin: $e');
    }
  }

  /// Finds location pins within a specified radius of a coordinate.
  /// Returns a list of pins sorted by distance (closest first).
  Future<List<LocationPinModel>> getLocationPinsNearby({
    required String schoolId,
    required double latitude,
    required double longitude,
    double radiusMeters = 1000,
  }) async {
    try {
      // Fetch all pins for the school first (filtering by distance happens in memory)
      // Note: For large datasets, use GeoFlutterFire or similar for server-side filtering.
      final allPins = await _firestore
          .collection('location_pins')
          .where('schoolId', isEqualTo: schoolId)
          .get();

      final nearbyPins = <LocationPinModel>[];
      for (final doc in allPins.docs) {
        final pin = LocationPinModel.fromFirestore(doc);
        final distance = pin.distanceTo(latitude, longitude);
        if (distance <= radiusMeters) {
          nearbyPins.add(pin);
        }
      }

      // Sort by distance
      nearbyPins.sort((a, b) =>
          a.distanceTo(latitude, longitude).compareTo(b.distanceTo(latitude, longitude)));

      return nearbyPins;
    } catch (e) {
      throw Exception('Failed to get nearby location pins: $e');
    }
  }

  /// Opens the image picker to select an image from gallery or camera.
  /// Returns the selected File, or null if cancelled.
  Future<File?> pickImage({bool fromCamera = false}) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  /// Searches for location pins by name, building name, or description.
  /// Performs client-side filtering on the stream.
  Stream<List<LocationPinModel>> searchLocationPins(
    String schoolId,
    String searchTerm,
  ) {
    return _firestore
        .collection('location_pins')
        .where('schoolId', isEqualTo: schoolId)
        .snapshots()
        .map((snapshot) {
      final allPins =
          snapshot.docs.map((doc) => LocationPinModel.fromFirestore(doc)).toList();
      return allPins
          .where((pin) =>
              pin.name.toLowerCase().contains(searchTerm.toLowerCase()) ||
              (pin.buildingName?.toLowerCase().contains(searchTerm.toLowerCase()) ??
                  false) ||
              (pin.description?.toLowerCase().contains(searchTerm.toLowerCase()) ??
                  false))
          .toList();
    });
  }
}
