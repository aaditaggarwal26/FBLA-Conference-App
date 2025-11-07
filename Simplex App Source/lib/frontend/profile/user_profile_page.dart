import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../app_info.dart';
import '../flutter_flow/flutter_flow_theme.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _isEditing = false;
  bool _isSaving = false;
  File? _imageFile;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    setState(() {
      _nameController.text = AppInfo.currentUser.name;
      _emailController.text = AppInfo.currentUser.email;
      _bioController.text = AppInfo.currentUser.bio;
      _phoneController.text = AppInfo.currentUser.phone;
      _photoUrl = AppInfo.currentUser.profilePic;
    });
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return null;

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return null;

      final ref = FirebaseStorage.instance
          .ref()
          .child('user_photos')
          .child('$userId.jpg');

      await ref.putFile(_imageFile!);
      return await ref.getDownloadURL();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      // Upload image if changed
      String? newPhotoUrl = _photoUrl;
      if (_imageFile != null) {
        newPhotoUrl = await _uploadImage();
      }

      // Update Firestore
      await AppInfo.database.collection('users').doc(userId).update({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'bio': _bioController.text.trim(),
        'phone': _phoneController.text.trim(),
        if (newPhotoUrl != null) 'profilePic': newPhotoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local AppInfo
      AppInfo.currentUser.bio = _bioController.text.trim();
      AppInfo.currentUser.phone = _phoneController.text.trim();
      if (newPhotoUrl != null) {
        setState(() => _photoUrl = newPhotoUrl);
      }

      // Reload user data from Firestore to ensure consistency
      AppInfo.currentUser = await AppInfo.getCurrentUserData();

      setState(() {
        _isEditing = false;
        _imageFile = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _imageFile = null;
    });
    _loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
      appBar: AppBar(
        backgroundColor: FlutterFlowTheme.of(context).primary,
        title: Text(
          'My Profile',
          style: FlutterFlowTheme.of(context).headlineMedium.override(
                fontFamily: 'Google Sans',
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w500,
                useGoogleFonts: false,
              ),
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: _cancelEdit,
            ),
        ],
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    
                    // Profile Photo
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  FlutterFlowTheme.of(context).primary,
                                  FlutterFlowTheme.of(context).secondary,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: FlutterFlowTheme.of(context).primary.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: CircleAvatar(
                                radius: 60,
                                backgroundImage: _imageFile != null
                                    ? FileImage(_imageFile!)
                                    : (_photoUrl != null
                                        ? NetworkImage(_photoUrl!)
                                        : null) as ImageProvider?,
                                child: (_imageFile == null && _photoUrl == null)
                                    ? Text(
                                        AppInfo.currentUser.name.isNotEmpty
                                            ? AppInfo.currentUser.name[0].toUpperCase()
                                            : 'U',
                                        style: const TextStyle(
                                          fontSize: 48,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          if (_isEditing)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: FlutterFlowTheme.of(context).primary,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Form Fields
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name
                          _buildLabel('Full Name'),
                          TextFormField(
                            controller: _nameController,
                            enabled: _isEditing,
                            decoration: _buildInputDecoration(
                              hint: 'Enter your name',
                              icon: Icons.person,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Name is required';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          // Email
                          _buildLabel('Email'),
                          TextFormField(
                            controller: _emailController,
                            enabled: _isEditing,
                            decoration: _buildInputDecoration(
                              hint: 'Enter your email',
                              icon: Icons.email,
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Email is required';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                  .hasMatch(value)) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          // Phone
                          _buildLabel('Phone Number'),
                          TextFormField(
                            controller: _phoneController,
                            enabled: _isEditing,
                            decoration: _buildInputDecoration(
                              hint: 'Enter your phone number',
                              icon: Icons.phone,
                            ),
                            keyboardType: TextInputType.phone,
                          ),

                          const SizedBox(height: 20),

                          // Bio
                          _buildLabel('Bio'),
                          TextFormField(
                            controller: _bioController,
                            enabled: _isEditing,
                            maxLines: 4,
                            decoration: _buildInputDecoration(
                              hint: 'Tell us about yourself',
                              icon: Icons.description,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Chapter Info (Read-only)
                          _buildLabel('Current Chapter'),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context).secondaryBackground,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: FlutterFlowTheme.of(context).alternate,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.school,
                                  color: FlutterFlowTheme.of(context).secondaryText,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  AppInfo.currentUser.currentChapter.isNotEmpty
                                      ? 'Chapter ID: ${AppInfo.currentUser.currentChapter}'
                                      : 'No chapter selected',
                                  style: FlutterFlowTheme.of(context).bodyMedium,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Save Button
                          if (_isEditing)
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _saveProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: FlutterFlowTheme.of(context).primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Save Changes',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: FlutterFlowTheme.of(context).labelMedium.override(
              fontFamily: 'Google Sans',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              useGoogleFonts: false,
            ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(
        icon,
        color: FlutterFlowTheme.of(context).secondaryText,
      ),
      filled: true,
      fillColor: _isEditing
          ? FlutterFlowTheme.of(context).secondaryBackground
          : FlutterFlowTheme.of(context).alternate,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: FlutterFlowTheme.of(context).alternate,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: FlutterFlowTheme.of(context).alternate,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: FlutterFlowTheme.of(context).primary,
          width: 2,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: FlutterFlowTheme.of(context).alternate,
        ),
      ),
    );
  }
}
