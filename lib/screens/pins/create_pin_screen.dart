import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  
  bool _isOpenToOffers = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _pinNameController.dispose();
    _descriptionController.dispose();
    _wantInReturnController.dispose();
    super.dispose();
  }

  Future<void> _createPin() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // Note: In a real app, you'd upload images to Firebase Storage first
      // For now, we'll use placeholder URLs
      final pin = PinModel(
        id: '',
        userId: user.uid,
        userName: user.displayName ?? user.email ?? 'Anonymous',
        userPhotoUrl: user.photoURL,
        pinName: _pinNameController.text.trim(),
        imageUrls: [], // TODO: Upload images to Firebase Storage
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
        setState(() => _isLoading = false);
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
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : AppTheme.black,
        ),
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
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.1),
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
                      ? (isDark ? AppTheme.darkSurface : const Color(0xFFDCFCE7))
                      : (isDark ? AppTheme.darkCard : Colors.white),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isOpenToOffers
                        ? (isDark ? AppTheme.darkPrimary : const Color(0xFF22C55E))
                        : (isDark ? AppTheme.darkCard : AppTheme.lightGray),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isOpenToOffers ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
                      color: _isOpenToOffers
                          ? (isDark ? AppTheme.darkPrimary : const Color(0xFF22C55E))
                          : (isDark ? Colors.white.withValues(alpha: 0.5) : AppTheme.mediumGray),
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
                      activeColor: isDark ? AppTheme.darkPrimary : const Color(0xFF22C55E),
                      activeTrackColor: isDark
                          ? AppTheme.darkPrimary.withValues(alpha: 0.5)
                          : const Color(0xFF86EFAC),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Image picker
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : const Color(0xFFE0E7FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? AppTheme.darkPrimary.withValues(alpha: 0.5)
                        : AppTheme.primaryBlue.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (isDark ? AppTheme.darkPrimary : AppTheme.primaryBlue).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add_photo_alternate_rounded,
                        size: 32,
                        color: isDark ? AppTheme.darkPrimary : AppTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Add Photos',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppTheme.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Photo upload coming soon',
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

              const SizedBox(height: 32),

              // Create Button
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkPrimary : AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? AppTheme.darkPrimary : AppTheme.primaryBlue).withValues(alpha: 0.3),
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
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle_rounded, color: Colors.white),
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
          borderSide: const BorderSide(
            color: AppTheme.error,
            width: 1.5,
          ),
        ),
        filled: true,
        fillColor: isDark ? AppTheme.darkSurface : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: validator,
    );
  }
}