import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../backend/pin_trading/pin_model.dart';
import '../../backend/pin_trading/pin_service.dart';
import '../../app_info.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../flutter_flow/flutter_flow_theme.dart';

class CreatePinPage extends StatefulWidget {
  const CreatePinPage({super.key});

  @override
  State<CreatePinPage> createState() => _CreatePinPageState();
}

class _CreatePinPageState extends State<CreatePinPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _wantController = TextEditingController();
  final PinService _pinService = PinService();
  
  List<File> _images = [];
  bool _isOpenToOffers = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _wantController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        _images = result.paths.map((path) => File(path!)).toList();
      });
    }
  }

  Future<List<String>> _uploadImages() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return [];

    List<String> urls = [];
    for (var image in _images) {
      final ref = FirebaseStorage.instance
          .ref()
          .child('pins')
          .child('$userId/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(image);
      urls.add(await ref.getDownloadURL());
    }
    return urls;
  }

  Future<void> _createPin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      final imageUrls = await _uploadImages();

      final pin = PinModel(
        id: '',
        userId: userId,
        userName: AppInfo.currentUser.name,
        userPhotoUrl: AppInfo.currentUser.profilePic,
        pinName: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        imageUrls: imageUrls,
        wantInReturn: _wantController.text.trim(),
        isOpenToOffers: _isOpenToOffers,
        createdAt: DateTime.now(),
      );

      await _pinService.createPin(pin);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pin created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F7),
      appBar: AppBar(
        backgroundColor: FlutterFlowTheme.of(context).primary,
        title: const Text(
          'Create Pin Listing',
          style: TextStyle(
            fontFamily: 'Google Sans',
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pin Images',
                        style: TextStyle(
                          fontFamily: 'Google Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _pickImages,
                        child: Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: _images.isEmpty
                              ? const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_photo_alternate, size: 48, color: Color(0xFF3B58F4)),
                                      SizedBox(height: 8),
                                      Text('Tap to add images', style: TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                )
                              : GridView.builder(
                                  padding: const EdgeInsets.all(8),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                  ),
                                  itemCount: _images.length,
                                  itemBuilder: (context, index) {
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(_images[index], fit: BoxFit.cover),
                                    );
                                  },
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      _buildTextField('Pin Name', _nameController, 'Enter pin name'),
                      const SizedBox(height: 16),
                      
                      _buildTextField('Description', _descriptionController, 'Describe your pin', maxLines: 4),
                      const SizedBox(height: 16),
                      
                      _buildTextField('What I Want', _wantController, 'What do you want in return?'),
                      const SizedBox(height: 16),
                      
                      CheckboxListTile(
                        value: _isOpenToOffers,
                        onChanged: (val) => setState(() => _isOpenToOffers = val!),
                        title: const Text('Open to any offers', style: TextStyle(fontFamily: 'Google Sans')),
                        activeColor: FlutterFlowTheme.of(context).primary,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      const SizedBox(height: 32),
                      
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _createPin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: FlutterFlowTheme.of(context).primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            'Create Pin Listing',
                            style: TextStyle(
                              fontFamily: 'Google Sans',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Google Sans',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF3B58F4), width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '$label is required';
            }
            return null;
          },
        ),
      ],
    );
  }
}
