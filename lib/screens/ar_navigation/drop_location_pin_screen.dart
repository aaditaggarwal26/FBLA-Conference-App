import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart'; // Add this import
import '../../services/location_pin_service.dart';
import '../../services/ar_navigation_service.dart';

class DropLocationPinScreen extends StatefulWidget {
  final String schoolId;
  final String userId;

  const DropLocationPinScreen({
    super.key,
    required this.schoolId,
    required this.userId,
  });

  @override
  State<DropLocationPinScreen> createState() => _DropLocationPinScreenState();
}

class _DropLocationPinScreenState extends State<DropLocationPinScreen> {
  final LocationPinService _locationService = LocationPinService();
  final ARNavigationService _navService = ARNavigationService();
  
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _buildingController = TextEditingController();
  final _roomNumberController = TextEditingController();
  
  Position? _currentPosition;
  bool _isLoadingLocation = false;
  bool _isSaving = false;
  int _floorLevel = 0;
  File? _locationImage;
  File? _arReferenceImage;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _buildingController.dispose();
    _roomNumberController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      // First, check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          _showLocationServicesDialog();
        }
        setState(() => _isLoadingLocation = false);
        return;
      }

      // Check permission status using Geolocator
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        // Request permission
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permission is required to drop pins'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() => _isLoadingLocation = false);
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          _showPermissionSettingsDialog();
        }
        setState(() => _isLoadingLocation = false);
        return;
      }

      // Permission is granted, get location
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Location acquired: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLocationServicesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Services Disabled'),
        content: const Text(
          'Please enable location services in your device settings to use this feature.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openLocationSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showPermissionSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
          'Location permission was denied. To use AR navigation and location pins, please enable location permission in:\n\nSettings → FBLA → Location → While Using the App',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickLocationImage() async {
    final image = await _locationService.pickImage();
    if (image != null) {
      setState(() => _locationImage = image);
    }
  }

  Future<void> _pickARReferenceImage() async {
    final image = await _locationService.pickImage();
    if (image != null) {
      setState(() => _arReferenceImage = image);
    }
  }

  Future<void> _saveLocationPin() async {
    if (!_formKey.currentState!.validate()) return;
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for location to be acquired'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final metadata = <String, dynamic>{};
      if (_roomNumberController.text.isNotEmpty) {
        metadata['roomNumber'] = _roomNumberController.text;
      }

      await _locationService.createLocationPin(
        schoolId: widget.schoolId,
        name: _nameController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        floorLevel: _floorLevel,
        buildingName: _buildingController.text.isEmpty
            ? null
            : _buildingController.text,
        userId: widget.userId,
        imageFile: _locationImage,
        arReferenceImageFile: _arReferenceImage,
        metadata: metadata.isEmpty ? null : metadata,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location pin dropped successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save location pin: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drop Location Pin'),
        backgroundColor: const Color(0xFF001231),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Location Status Card
              Card(
                color: _currentPosition == null
                    ? Colors.orange.shade50
                    : Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _currentPosition == null
                                ? Icons.location_searching
                                : Icons.location_on,
                            color: _currentPosition == null
                                ? Colors.orange
                                : Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _currentPosition == null
                                ? 'Acquiring Location...'
                                : 'Location Acquired',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      if (_currentPosition != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}\n'
                          'Lng: ${_currentPosition!.longitude.toStringAsFixed(6)}\n'
                          'Accuracy: ±${_currentPosition!.accuracy.toStringAsFixed(1)}m',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh Location'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF001231),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Pin Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Location Name *',
                  hintText: 'e.g., Room 2233, Main Auditorium',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a location name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Add any helpful details about this location',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Building Name
              TextFormField(
                controller: _buildingController,
                decoration: const InputDecoration(
                  labelText: 'Building Name (optional)',
                  hintText: 'e.g., North Building, West Wing',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
              ),
              const SizedBox(height: 16),

              // Room Number
              TextFormField(
                controller: _roomNumberController,
                decoration: const InputDecoration(
                  labelText: 'Room Number (optional)',
                  hintText: 'e.g., 2233, A-105',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.meeting_room),
                ),
              ),
              const SizedBox(height: 16),

              // Floor Level
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Floor Level',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              setState(() => _floorLevel--);
                            },
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                _floorLevel == 0
                                    ? 'Ground Floor'
                                    : _floorLevel > 0
                                        ? 'Floor $_floorLevel'
                                        : 'Basement ${-_floorLevel}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() => _floorLevel++);
                            },
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Location Image
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Location Photo (optional)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_locationImage != null)
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _locationImage!,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton(
                                onPressed: () {
                                  setState(() => _locationImage = null);
                                },
                                icon: const Icon(Icons.close),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: _pickLocationImage,
                          icon: const Icon(Icons.add_a_photo),
                          label: const Text('Add Photo'),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // AR Reference Image
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AR Reference Image (optional)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Text(
                        'For enhanced AR tracking at this location',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      if (_arReferenceImage != null)
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _arReferenceImage!,
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton(
                                onPressed: () {
                                  setState(() => _arReferenceImage = null);
                                },
                                icon: const Icon(Icons.close),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: _pickARReferenceImage,
                          icon: const Icon(Icons.view_in_ar),
                          label: const Text('Add AR Reference'),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveLocationPin,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'Saving...' : 'Drop Location Pin'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF001231),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
