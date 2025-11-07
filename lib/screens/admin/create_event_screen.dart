import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../services/admin_service.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _adminService = AdminService();
  
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  Future<void> _createEvent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date and time')),
      );
      return;
    }

    // Check admin permission
    final hasPermission = await _adminService.hasPermission('manage_events');
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You do not have permission to create events')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final eventDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      await FirebaseFirestore.instance.collection('events').add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'dateTime': Timestamp.fromDate(eventDateTime),
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': FirebaseAuth.instance.currentUser!.uid,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event created successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating event: $e')),
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
          'Create Event',
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
                    color: isDark ? AppTheme.darkSurface : const Color(0xFF3B82F6),
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
                      Icon(Icons.event_rounded, size: 40, color: Colors.white),
                      SizedBox(height: 12),
                      Text(
                        'New Event',
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
                  label: 'Event Title',
                  hint: 'e.g., Opening Ceremony',
                  icon: Icons.title_rounded,
                  isDark: isDark,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Please enter a title' : null,
                ),

                const SizedBox(height: 16),

                // Description
                _buildTextField(
                  controller: _descriptionController,
                  label: 'Description',
                  hint: 'Event details...',
                  icon: Icons.description_rounded,
                  isDark: isDark,
                  maxLines: 4,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Please enter a description' : null,
                ),

                const SizedBox(height: 16),

                // Location
                _buildTextField(
                  controller: _locationController,
                  label: 'Location',
                  hint: 'e.g., Main Auditorium',
                  icon: Icons.location_on_rounded,
                  isDark: isDark,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Please enter a location' : null,
                ),

                const SizedBox(height: 16),

                // Date picker
                _buildDateTimeCard(
                  isDark: isDark,
                  title: 'Date',
                  icon: Icons.calendar_today_rounded,
                  value: _selectedDate == null
                      ? null
                      : '${_selectedDate!.month}/${_selectedDate!.day}/${_selectedDate!.year}',
                  onTap: _selectDate,
                ),

                const SizedBox(height: 16),

                // Time picker
                _buildDateTimeCard(
                  isDark: isDark,
                  title: 'Time',
                  icon: Icons.access_time_rounded,
                  value: _selectedTime == null
                      ? null
                      : _selectedTime!.format(context),
                  onTap: _selectTime,
                ),

                const SizedBox(height: 32),

                // Create button
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkPrimary : const Color(0xFF3B82F6),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: (isDark ? AppTheme.darkPrimary : const Color(0xFF3B82F6))
                            .withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isLoading ? null : _createEvent,
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
                                  'Create Event',
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
        prefixIcon: Icon(icon, color: isDark ? AppTheme.darkPrimary : const Color(0xFF3B82F6)),
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
            color: isDark ? AppTheme.darkPrimary : const Color(0xFF3B82F6),
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

  Widget _buildDateTimeCard({
    required bool isDark,
    required String title,
    required IconData icon,
    required String? value,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.darkCard : AppTheme.lightGray,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isDark ? AppTheme.darkPrimary : const Color(0xFF3B82F6),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.7)
                              : AppTheme.mediumGray,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value ?? 'Select $title',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: value != null ? FontWeight.w500 : FontWeight.normal,
                          color: value != null
                              ? (isDark ? Colors.white : AppTheme.black)
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.3)
                                  : AppTheme.mediumGray),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? Colors.white.withValues(alpha: 0.5) : AppTheme.mediumGray,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
