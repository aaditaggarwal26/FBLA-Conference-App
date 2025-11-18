import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../services/school_service.dart';
import '../../models/school_event_model.dart';
import '../../theme/app_theme.dart';

class CreateSchoolEventScreen extends StatefulWidget {
  final String schoolId;

  const CreateSchoolEventScreen({super.key, required this.schoolId});

  @override
  State<CreateSchoolEventScreen> createState() => _CreateSchoolEventScreenState();
}

class _CreateSchoolEventScreenState extends State<CreateSchoolEventScreen> {
  final SchoolService _schoolService = SchoolService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _meetingLinkController = TextEditingController();
  final _maxAttendeesController = TextEditingController();
  
  DateTime _startTime = DateTime.now().add(const Duration(days: 1));
  DateTime _endTime = DateTime.now().add(const Duration(days: 1, hours: 2));
  bool _isAllDay = false;
  bool _isCreating = false;
  final List<String> _tags = [];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _meetingLinkController.dispose();
    _maxAttendeesController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? _startTime : _endTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(isStart ? _startTime : _endTime),
      );

      if (time != null && mounted) {
        setState(() {
          final newDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
          if (isStart) {
            _startTime = newDateTime;
            if (_startTime.isAfter(_endTime)) {
              _endTime = _startTime.add(const Duration(hours: 2));
            }
          } else {
            _endTime = newDateTime;
          }
        });
      }
    }
  }

  Future<void> _createEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('Not logged in');

      final event = SchoolEventModel(
        id: '',
        schoolId: widget.schoolId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        startTime: _startTime,
        endTime: _endTime,
        location: _locationController.text.trim(),
        imageUrl: null,
        createdBy: currentUser.uid,
        creatorName: currentUser.displayName ?? 'Unknown',
        createdAt: DateTime.now(),
        isAllDay: _isAllDay,
        attendeeIds: [],
        maxAttendees: _maxAttendeesController.text.isNotEmpty 
            ? int.tryParse(_maxAttendeesController.text)
            : null,
        meetingLink: _meetingLinkController.text.trim().isNotEmpty 
            ? _meetingLinkController.text.trim()
            : null,
        tags: _tags,
      );

      await _schoolService.createSchoolEvent(event);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Event created successfully!'),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        title: const Text('Create Event'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Event Title',
                hintText: 'e.g., Study Session',
                prefixIcon: const Icon(Icons.title_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: isDark ? AppTheme.darkSurface : Colors.white,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'Event details',
                prefixIcon: const Icon(Icons.description_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: isDark ? AppTheme.darkSurface : Colors.white,
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Location
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: 'Location',
                hintText: 'Room 101 or Virtual',
                prefixIcon: const Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: isDark ? AppTheme.darkSurface : Colors.white,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a location';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 24),
            
            // All Day Toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time_rounded),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('All Day Event')),
                  Switch(
                    value: _isAllDay,
                    onChanged: (value) => setState(() => _isAllDay = value),
                    activeColor: AppTheme.success,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Start Time
            InkWell(
              onTap: () => _selectDateTime(true),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppTheme.darkCard : AppTheme.lightGray),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_rounded),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Start Time', style: TextStyle(fontSize: 12, color: AppTheme.mediumGray)),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMM d, y \'at\' h:mm a').format(_startTime),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : AppTheme.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppTheme.mediumGray),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // End Time
            InkWell(
              onTap: () => _selectDateTime(false),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppTheme.darkCard : AppTheme.lightGray),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_available_rounded),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('End Time', style: TextStyle(fontSize: 12, color: AppTheme.mediumGray)),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMM d, y \'at\' h:mm a').format(_endTime),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : AppTheme.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppTheme.mediumGray),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Meeting Link (Optional)
            TextFormField(
              controller: _meetingLinkController,
              decoration: InputDecoration(
                labelText: 'Meeting Link (Optional)',
                hintText: 'Zoom/Meet link for virtual events',
                prefixIcon: const Icon(Icons.video_call_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: isDark ? AppTheme.darkSurface : Colors.white,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Max Attendees (Optional)
            TextFormField(
              controller: _maxAttendeesController,
              decoration: InputDecoration(
                labelText: 'Max Attendees (Optional)',
                hintText: 'Leave empty for unlimited',
                prefixIcon: const Icon(Icons.people_outline_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: isDark ? AppTheme.darkSurface : Colors.white,
              ),
              keyboardType: TextInputType.number,
            ),
            
            const SizedBox(height: 24),
            
            // Create Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isCreating ? null : _createEvent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isCreating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Create Event',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
