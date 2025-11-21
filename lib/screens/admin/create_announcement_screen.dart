import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../services/admin_service.dart';
import '../../services/linkedin_service.dart';

class CreateAnnouncementScreen extends StatefulWidget {
  const CreateAnnouncementScreen({super.key});

  @override
  State<CreateAnnouncementScreen> createState() => _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState extends State<CreateAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _adminService = AdminService();
  final _linkedInService = LinkedInService();
  
  String _priority = 'normal';
  bool _isLoading = false;
  bool _postToLinkedIn = false;
  bool _isLinkedInConnected = false;

  @override
  void initState() {
    super.initState();
    _checkLinkedInConnection();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _checkLinkedInConnection() async {
    final connected = await _linkedInService.isConnected();
    setState(() {
      _isLinkedInConnected = connected;
    });
  }

  Future<void> _createAnnouncement() async {
    if (!_formKey.currentState!.validate()) return;

    // Check admin permission
    final hasPermission = await _adminService.hasPermission('manage_announcements');
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You do not have permission to create announcements')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create announcement in Firestore
      await FirebaseFirestore.instance.collection('announcements').add({
        'title': _titleController.text.trim(),
        'message': _messageController.text.trim(),
        'priority': _priority,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': FirebaseAuth.instance.currentUser!.uid,
      });

      // Post to LinkedIn if enabled
      if (_postToLinkedIn && _isLinkedInConnected) {
        try {
          await _linkedInService.shareAnnouncement(
            title: _titleController.text.trim(),
            content: _messageController.text.trim(),
          );
        } catch (e) {
          print('Error posting to LinkedIn: $e');
          // Don't fail the whole operation if LinkedIn post fails
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Announcement posted, but LinkedIn share failed: $e'),
                backgroundColor: AppTheme.warning,
              ),
            );
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _postToLinkedIn && _isLinkedInConnected
                  ? 'Announcement posted and shared on LinkedIn!'
                  : 'Announcement posted successfully',
            ),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error posting announcement: $e')),
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
          'Create Announcement',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.white,
        elevation: 0,
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
                    color: isDark ? AppTheme.darkSurface : const Color(0xFF8B5CF6),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.campaign_rounded, size: 40, color: Colors.white),
                      SizedBox(height: 12),
                      Text(
                        'New Announcement',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Title
                _buildTextField(
                  controller: _titleController,
                  label: 'Title',
                  hint: 'e.g., Schedule Change',
                  icon: Icons.title_rounded,
                  isDark: isDark,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Please enter a title' : null,
                ),

                const SizedBox(height: 16),

                // Message
                _buildTextField(
                  controller: _messageController,
                  label: 'Message',
                  hint: 'Announcement details...',
                  icon: Icons.message_rounded,
                  isDark: isDark,
                  maxLines: 6,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Please enter a message' : null,
                ),

                const SizedBox(height: 16),

                // LinkedIn posting option
                if (_isLinkedInConnected)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppTheme.darkCard : AppTheme.lightGray,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0077B5).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.business_rounded,
                            color: Color(0xFF0077B5),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Share on LinkedIn',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : AppTheme.black,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Automatically post this announcement to LinkedIn',
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
                          value: _postToLinkedIn,
                          onChanged: (value) {
                            setState(() => _postToLinkedIn = value);
                          },
                          activeColor: const Color(0xFF0077B5),
                        ),
                      ],
                    ),
                  ),

                if (_isLinkedInConnected) const SizedBox(height: 16),

                // Priority selector
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppTheme.darkCard : AppTheme.lightGray,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Priority',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppTheme.black,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildPriorityChip('normal', 'Normal', isDark),
                          const SizedBox(width: 8),
                          _buildPriorityChip('important', 'Important', isDark),
                          const SizedBox(width: 8),
                          _buildPriorityChip('urgent', 'Urgent', isDark),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Create button
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkPrimary : const Color(0xFF8B5CF6),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: (isDark ? AppTheme.darkPrimary : const Color(0xFF8B5CF6))
                            .withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isLoading ? null : _createAnnouncement,
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
                              : const Text(
                                  'Post Announcement',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
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
      style: TextStyle(color: isDark ? Colors.white : AppTheme.black, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark ? Colors.white.withValues(alpha: 0.3) : AppTheme.mediumGray,
        ),
        labelStyle: TextStyle(
          color: isDark ? Colors.white.withValues(alpha: 0.7) : AppTheme.mediumGray,
        ),
        prefixIcon: Icon(icon, color: isDark ? AppTheme.darkPrimary : const Color(0xFF8B5CF6)),
        alignLabelWithHint: maxLines > 1,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? AppTheme.darkCard : AppTheme.lightGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? AppTheme.darkCard : AppTheme.lightGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? AppTheme.darkPrimary : const Color(0xFF8B5CF6),
            width: 2,
          ),
        ),
        filled: true,
        fillColor: isDark ? AppTheme.darkSurface : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: validator,
    );
  }

  Widget _buildPriorityChip(String value, String label, bool isDark) {
    final isSelected = _priority == value;
    Color getColor() {
      if (value == 'urgent') return const Color(0xFFEF4444);
      if (value == 'important') return const Color(0xFFF59E0B);
      return const Color(0xFF10B981);
    }

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _priority = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? getColor().withValues(alpha: 0.15)
                : (isDark ? AppTheme.darkCard : AppTheme.offWhite),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? getColor() : (isDark ? AppTheme.darkCard : AppTheme.lightGray),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? getColor() : (isDark ? Colors.white : AppTheme.black),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
