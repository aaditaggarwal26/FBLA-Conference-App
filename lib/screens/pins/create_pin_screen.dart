import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../../services/pin_service.dart';
import '../../models/pin_model.dart';
import '../../theme/app_theme.dart';

class CreatePinScreen extends StatefulWidget {
  const CreatePinScreen({super.key});

  @override
  State<CreatePinScreen> createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends State<CreatePinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pinNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _wantInReturnController = TextEditingController();
  final PinService _pinService = PinService();
  final ImagePicker _imagePicker = ImagePicker();

  List<XFile> _selectedImages = [];
  bool _isOpenToOffers = true;
  bool _isPostingAnonymously = false;
  bool _isLoading = false;
  bool _isUploadingImages = false;

  @override
  void dispose() {
    _pinNameController.dispose();
    _descriptionController.dispose();
    _wantInReturnController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      // Show dialog to choose source
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      // Pick multiple images if from gallery, single if from camera
      if (source == ImageSource.gallery) {
        final List<XFile> images = await _imagePicker.pickMultiImage();
        if (images.isNotEmpty) {
          setState(() {
            _selectedImages.addAll(images);
            // Limit to 5 images
            if (_selectedImages.length > 5) {
              _selectedImages = _selectedImages.sublist(0, 5);
            }
          });
        }
      } else {
        final XFile? image = await _imagePicker.pickImage(source: source);
        if (image != null) {
          setState(() {
            if (_selectedImages.length < 5) {
              _selectedImages.add(image);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Maximum 5 images allowed'),
                  backgroundColor: AppTheme.warning,
                ),
              );
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking images: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<List<String>> _uploadImages(String userId) async {
    if (_selectedImages.isEmpty) return [];

    final List<String> imageUrls = [];
    final storage = FirebaseStorage.instance;

    for (int i = 0; i < _selectedImages.length; i++) {
      final imageFile = File(_selectedImages[i].path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${userId}_${timestamp}_$i.jpg';

      final ref = storage.ref().child('pins').child(userId).child(fileName);

      try {
        await ref.putFile(imageFile);
        final downloadUrl = await ref.getDownloadURL();
        imageUrls.add(downloadUrl);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error uploading image ${i + 1}: $e'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    }

    return imageUrls;
  }

  Future<void> _createPin() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
      _isUploadingImages = _selectedImages.isNotEmpty;
    });

    try {
      // Upload images to Firebase Storage
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        imageUrls = await _uploadImages(user.uid);
      }

      // Fetch user name from Firestore
      String userName = 'Anonymous';
      String? userPhotoUrl;

      if (!_isPostingAnonymously) {
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          if (userDoc.exists) {
            final userData = userDoc.data();
            userName = userData?['name'] ?? user.displayName ?? 'Anonymous';
            userPhotoUrl = userData?['photoUrl'] ?? user.photoURL;
          } else {
            // Fallback to displayName if user doc doesn't exist
            userName = user.displayName ?? 'Anonymous';
            userPhotoUrl = user.photoURL;
          }
        } catch (e) {
          // If there's an error fetching, use displayName as fallback
          userName = user.displayName ?? 'Anonymous';
          userPhotoUrl = user.photoURL;
        }
      }

      final pin = PinModel(
        id: '',
        userId: user.uid,
        userName: userName,
        userPhotoUrl: _isPostingAnonymously ? null : userPhotoUrl,
        pinName: _pinNameController.text.trim(),
        description: _descriptionController.text.trim(),
        imageUrls: imageUrls,
        wantInReturn: _wantInReturnController.text.trim(),
        isOpenToOffers: _isOpenToOffers,
        createdAt: DateTime.now(),
      );

      await _pinService.createPin(pin);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pin listing created successfully!'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating pin: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isUploadingImages = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.offWhite,
      appBar: AppBar(
        title: const Text(
          'Create Pin Listing',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.white,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : AppTheme.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : AppTheme.primaryBlue,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.2 : 0.1,
                        ),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.push_pin_rounded,
                          size: 36,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'List Your Pin',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Share your pin with the community',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Pin Name Field
                _buildTextField(
                  controller: _pinNameController,
                  label: 'Pin Name',
                  hint: 'e.g., FBLA National 2025',
                  icon: Icons.label_rounded,
                  isDark: isDark,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a pin name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Description Field
                _buildTextField(
                  controller: _descriptionController,
                  label: 'Description',
                  hint: 'Describe your pin...',
                  icon: Icons.description_rounded,
                  isDark: isDark,
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Want in Return Field
                _buildTextField(
                  controller: _wantInReturnController,
                  label: 'What do you want in return?',
                  hint: 'e.g., State pins, National pins',
                  icon: Icons.swap_horiz_rounded,
                  isDark: isDark,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please specify what you want';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Open to offers switch
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _isOpenToOffers
                        ? (isDark
                              ? AppTheme.darkSurface
                              : const Color(0xFFDCFCE7))
                        : (isDark ? AppTheme.darkCard : Colors.white),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isOpenToOffers
                          ? (isDark
                                ? AppTheme.darkPrimary
                                : const Color(0xFF22C55E))
                          : (isDark ? AppTheme.darkCard : AppTheme.lightGray),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isOpenToOffers
                            ? Icons.check_circle_rounded
                            : Icons.check_circle_outline_rounded,
                        color: _isOpenToOffers
                            ? (isDark
                                  ? AppTheme.darkPrimary
                                  : const Color(0xFF22C55E))
                            : (isDark
                                  ? Colors.white.withValues(alpha: 0.5)
                                  : AppTheme.mediumGray),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Open to any offers',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : AppTheme.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Accept trades beyond what you specified',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.6)
                                    : AppTheme.mediumGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isOpenToOffers,
                        onChanged: (value) {
                          setState(() => _isOpenToOffers = value);
                        },
                        activeColor: isDark
                            ? AppTheme.darkPrimary
                            : const Color(0xFF22C55E),
                        activeTrackColor: isDark
                            ? AppTheme.darkPrimary.withValues(alpha: 0.5)
                            : const Color(0xFF86EFAC),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Post anonymously switch
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _isPostingAnonymously
                        ? (isDark
                              ? AppTheme.darkSurface
                              : const Color(0xFFFEF3C7))
                        : (isDark ? AppTheme.darkCard : Colors.white),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isPostingAnonymously
                          ? (isDark
                                ? AppTheme.darkPrimary
                                : const Color(0xFFF59E0B))
                          : (isDark ? AppTheme.darkCard : AppTheme.lightGray),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isPostingAnonymously
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: _isPostingAnonymously
                            ? (isDark
                                  ? AppTheme.darkPrimary
                                  : const Color(0xFFF59E0B))
                            : (isDark
                                  ? Colors.white.withValues(alpha: 0.5)
                                  : AppTheme.mediumGray),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Post anonymously',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : AppTheme.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Your name and photo will be hidden',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.6)
                                    : AppTheme.mediumGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isPostingAnonymously,
                        onChanged: (value) {
                          setState(() => _isPostingAnonymously = value);
                        },
                        activeColor: isDark
                            ? AppTheme.darkPrimary
                            : const Color(0xFFF59E0B),
                        activeTrackColor: isDark
                            ? AppTheme.darkPrimary.withValues(alpha: 0.5)
                            : const Color(0xFFFCD34D),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Image picker section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Pin Photos',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppTheme.black,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Selected images grid
                    if (_selectedImages.isNotEmpty)
                      Container(
                        height: 120,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, index) {
                            return Container(
                              width: 120,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? AppTheme.darkCard
                                      : AppTheme.lightGray,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      File(_selectedImages[index].path),
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => _removeImage(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(
                                            alpha: 0.6,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close_rounded,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                    // Add images button
                    GestureDetector(
                      onTap: _selectedImages.length < 5 ? _pickImages : null,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppTheme.darkCard
                              : const Color(0xFFE0E7FF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _selectedImages.length < 5
                                ? (isDark
                                      ? AppTheme.darkPrimary.withValues(
                                          alpha: 0.5,
                                        )
                                      : AppTheme.primaryBlue.withValues(
                                          alpha: 0.3,
                                        ))
                                : (isDark
                                      ? AppTheme.darkCard
                                      : AppTheme.lightGray),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color:
                                    (isDark
                                            ? AppTheme.darkPrimary
                                            : AppTheme.primaryBlue)
                                        .withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.add_photo_alternate_rounded,
                                size: 32,
                                color: _selectedImages.length < 5
                                    ? (isDark
                                          ? AppTheme.darkPrimary
                                          : AppTheme.primaryBlue)
                                    : (isDark
                                          ? Colors.white.withValues(alpha: 0.3)
                                          : AppTheme.mediumGray),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _selectedImages.isEmpty
                                  ? 'Add Photos'
                                  : 'Add More Photos',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: _selectedImages.length < 5
                                    ? (isDark ? Colors.white : AppTheme.black)
                                    : (isDark
                                          ? Colors.white.withValues(alpha: 0.5)
                                          : AppTheme.mediumGray),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedImages.isEmpty
                                  ? 'Tap to add photos (max 5)'
                                  : '${_selectedImages.length}/5 photos',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.6)
                                    : AppTheme.mediumGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Create Button
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkPrimary : AppTheme.primaryBlue,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (isDark
                                    ? AppTheme.darkPrimary
                                    : AppTheme.primaryBlue)
                                .withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isLoading ? null : _createPin,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: _isLoading
                              ? Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    ),
                                    if (_isUploadingImages) ...[
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Uploading images...',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ],
                                )
                              : const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Create Listing',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(
        color: isDark ? Colors.white : AppTheme.black,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark
              ? Colors.white.withValues(alpha: 0.3)
              : AppTheme.mediumGray,
        ),
        labelStyle: TextStyle(
          color: isDark
              ? Colors.white.withValues(alpha: 0.7)
              : AppTheme.mediumGray,
        ),
        prefixIcon: Icon(
          icon,
          color: isDark ? AppTheme.darkPrimary : AppTheme.primaryBlue,
          size: 22,
        ),
        alignLabelWithHint: maxLines > 1,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? AppTheme.darkCard : AppTheme.lightGray,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? AppTheme.darkCard : AppTheme.lightGray,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? AppTheme.darkPrimary : AppTheme.primaryBlue,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.error, width: 1.5),
        ),
        filled: true,
        fillColor: isDark ? AppTheme.darkSurface : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      validator: validator,
    );
  }
}
