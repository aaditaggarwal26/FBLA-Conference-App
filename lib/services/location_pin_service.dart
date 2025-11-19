import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/location_pin_model.dart';

class LocationPinService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  // Create a new location pin
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

      // Upload images if provided
      if (imageFile != null) {
        imageUrl = await _uploadImage(
          schoolId,
          'location_images',
          imageFile,
        );
      }

      if (arReferenceImageFile != null) {
        arReferenceImageUrl = await _uploadImage(
          schoolId,
          'ar_reference_images',
          arReferenceImageFile,
        );
      }

      final locationPin = LocationPinModel(
        id: '',
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

      final docRef = await _firestore
          .collection('location_pins')
          .add(locationPin.toFirestore());

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create location pin: $e');
    }
  }

  // Upload image to Firebase Storage
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

  // Get all location pins for a school
  Stream<List<LocationPinModel>> getLocationPins(String schoolId) {
    return _firestore
        .collection('location_pins')
        .where('schoolId', isEqualTo: schoolId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => LocationPinModel.fromFirestore(doc)).toList());
  }

  // Get a specific location pin by ID
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

  // Update a location pin
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

  // Delete a location pin
  Future<void> deleteLocationPin(String pinId) async {
    try {
      await _firestore.collection('location_pins').doc(pinId).delete();
    } catch (e) {
      throw Exception('Failed to delete location pin: $e');
    }
  }

  // Get location pins near a coordinate (within radius in meters)
  Future<List<LocationPinModel>> getLocationPinsNearby({
    required String schoolId,
    required double latitude,
    required double longitude,
    double radiusMeters = 1000,
  }) async {
    try {
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

  // Pick image from gallery or camera
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

  // Search location pins by name
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
