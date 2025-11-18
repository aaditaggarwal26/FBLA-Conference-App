import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/school_model.dart';
import '../../services/school_service.dart';

class SchoolSettingsScreen extends StatefulWidget {
  final String schoolId;

  const SchoolSettingsScreen({
    super.key,
    required this.schoolId,
  });

  @override
  State<SchoolSettingsScreen> createState() => _SchoolSettingsScreenState();
}

class _SchoolSettingsScreenState extends State<SchoolSettingsScreen> {
  final _schoolService = SchoolService();
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _zipController;
  late TextEditingController _websiteController;
  late TextEditingController _facebookController;
  late TextEditingController _twitterController;
  late TextEditingController _instagramController;
  late TextEditingController _calendarController;
  
  bool _isLoading = false;
  SchoolModel? _school;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _addressController = TextEditingController();
    _cityController = TextEditingController();
    _stateController = TextEditingController();
    _zipController = TextEditingController();
    _websiteController = TextEditingController();
    _facebookController = TextEditingController();
    _twitterController = TextEditingController();
    _instagramController = TextEditingController();
    _calendarController = TextEditingController();
    _loadSchool();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _websiteController.dispose();
    _facebookController.dispose();
    _twitterController.dispose();
    _instagramController.dispose();
    _calendarController.dispose();
    super.dispose();
  }

  Future<void> _loadSchool() async {
    final school = await _schoolService.getSchool(widget.schoolId);
    if (school != null && mounted) {
      setState(() {
        _school = school;
        _nameController.text = school.name;
        _addressController.text = school.address;
        _cityController.text = school.city ?? '';
        _stateController.text = school.state ?? '';
        _zipController.text = school.zipCode ?? '';
        _websiteController.text = school.socialMediaLinks['website'] ?? '';
        _facebookController.text = school.socialMediaLinks['facebook'] ?? '';
        _twitterController.text = school.socialMediaLinks['twitter'] ?? '';
        _instagramController.text = school.socialMediaLinks['instagram'] ?? '';
        _calendarController.text = school.calendarUrl ?? '';
      });
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final socialMediaLinks = <String, String>{};
      if (_websiteController.text.isNotEmpty) {
        socialMediaLinks['website'] = _websiteController.text.trim();
      }
      if (_facebookController.text.isNotEmpty) {
        socialMediaLinks['facebook'] = _facebookController.text.trim();
      }
      if (_twitterController.text.isNotEmpty) {
        socialMediaLinks['twitter'] = _twitterController.text.trim();
      }
      if (_instagramController.text.isNotEmpty) {
        socialMediaLinks['instagram'] = _instagramController.text.trim();
      }

      await _schoolService.updateSchool(widget.schoolId, {
        'name': _nameController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        'state': _stateController.text.trim().isEmpty ? null : _stateController.text.trim(),
        'zipCode': _zipController.text.trim().isEmpty ? null : _zipController.text.trim(),
        'socialMediaLinks': socialMediaLinks,
        'calendarUrl': _calendarController.text.trim().isEmpty 
            ? null 
            : _calendarController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.offWhite,
      appBar: AppBar(
        title: const Text('School Settings'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveSettings,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: _school == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Basic Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.darkBlue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'School Name',
                        prefixIcon: Icon(Icons.school),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter school name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Street Address',
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _cityController,
                            decoration: const InputDecoration(
                              labelText: 'City',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _stateController,
                            decoration: const InputDecoration(
                              labelText: 'State',
                            ),
                            textCapitalization: TextCapitalization.characters,
                            maxLength: 2,
                            buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _zipController,
                            decoration: const InputDecoration(
                              labelText: 'ZIP',
                            ),
                            keyboardType: TextInputType.number,
                            maxLength: 5,
                            buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Social Media & Links',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.darkBlue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _websiteController,
                      decoration: const InputDecoration(
                        labelText: 'Website URL',
                        prefixIcon: Icon(Icons.language),
                        hintText: 'https://www.example.com',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _facebookController,
                      decoration: const InputDecoration(
                        labelText: 'Facebook',
                        prefixIcon: Icon(Icons.facebook),
                        hintText: 'https://facebook.com/yourschool',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _twitterController,
                      decoration: const InputDecoration(
                        labelText: 'Twitter/X',
                        prefixIcon: Icon(Icons.close),
                        hintText: 'https://twitter.com/yourschool',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _instagramController,
                      decoration: const InputDecoration(
                        labelText: 'Instagram',
                        prefixIcon: Icon(Icons.camera_alt),
                        hintText: 'https://instagram.com/yourschool',
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Calendar Integration',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.darkBlue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _calendarController,
                      decoration: const InputDecoration(
                        labelText: 'Calendar URL',
                        prefixIcon: Icon(Icons.calendar_today),
                        hintText: 'Google Calendar, iCal, etc.',
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}
