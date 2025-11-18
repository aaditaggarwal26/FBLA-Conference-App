import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../services/school_service.dart';
import '../../services/auth_service.dart';
import '../../services/school_search_service.dart';
import 'school_admin_dashboard.dart';

class CreateSchoolScreen extends StatefulWidget {
  const CreateSchoolScreen({super.key});

  @override
  State<CreateSchoolScreen> createState() => _CreateSchoolScreenState();
}

class _CreateSchoolScreenState extends State<CreateSchoolScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  final _schoolService = SchoolService();
  final _authService = AuthService();
  final _searchService = SchoolSearchService();
  
  bool _isLoading = false;
  bool _showSearchResults = false;
  List<SchoolSearchResult> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  void _onSchoolNameChanged(String value) async {
    if (value.length < 2) {
      setState(() {
        _showSearchResults = false;
        _searchResults = [];
      });
      return;
    }

    setState(() => _isSearching = true);

    final results = await _searchService.searchSchools(value);
    
    if (mounted) {
      setState(() {
        _searchResults = results;
        _showSearchResults = results.isNotEmpty;
        _isSearching = false;
      });
    }
  }

  void _selectSchool(SchoolSearchResult school) {
    _nameController.text = school.name;
    _addressController.text = school.address;
    _cityController.text = school.city ?? '';
    _stateController.text = school.state ?? '';
    _zipController.text = school.zipCode ?? '';
    
    setState(() {
      _showSearchResults = false;
      _searchResults = [];
    });
  }

  Future<void> _createSchool() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;

      // Create the school
      final school = await _schoolService.createSchool(
        name: _nameController.text.trim(),
        address: _addressController.text.trim().isEmpty ? 'Address not provided' : _addressController.text.trim(),
        city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        state: _stateController.text.trim().isEmpty ? null : _stateController.text.trim(),
        zipCode: _zipController.text.trim().isEmpty ? null : _zipController.text.trim(),
        creatorId: userId,
      );

      // Update user role to school admin
      await _authService.updateUserData(userId, {
        'role': 'school_admin',
        'schoolId': school.id,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('School created successfully! Invite code: ${school.inviteCode}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => SchoolAdminDashboard(schoolId: school.id),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating school: $e'),
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
        title: const Text('Create Your School'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            // Dismiss search results when tapping outside
            if (_showSearchResults) {
              setState(() {
                _showSearchResults = false;
              });
            }
            // Dismiss keyboard
            FocusScope.of(context).unfocus();
          },
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Set up your school administration',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.darkBlue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Search for your school or enter details manually',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // School Name with Search
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'School Name *',
                        hintText: 'Start typing to search...',
                        prefixIcon: const Icon(Icons.school),
                        suffixIcon: _isSearching 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: isDark ? AppTheme.darkCard : Colors.white,
                      ),
                      onChanged: _onSchoolNameChanged,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter school name';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Address (Optional)
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: 'Street Address (Optional)',
                        hintText: 'e.g., 123 Main Street',
                        prefixIcon: const Icon(Icons.location_on),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: isDark ? AppTheme.darkCard : Colors.white,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // City, State, Zip Row
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _cityController,
                            decoration: InputDecoration(
                              labelText: 'City',
                              hintText: 'City',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: isDark ? AppTheme.darkCard : Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _stateController,
                            decoration: InputDecoration(
                              labelText: 'State',
                              hintText: 'CA',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: isDark ? AppTheme.darkCard : Colors.white,
                              counter: const SizedBox.shrink(),
                            ),
                            textCapitalization: TextCapitalization.characters,
                            maxLength: 2,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _zipController,
                            decoration: InputDecoration(
                              labelText: 'ZIP',
                              hintText: '12345',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: isDark ? AppTheme.darkCard : Colors.white,
                              counter: const SizedBox.shrink(),
                            ),
                            keyboardType: TextInputType.number,
                            maxLength: 5,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryBlue.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppTheme.primaryBlue,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'After creating your school, you will receive a unique invite code that students can use to join.',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white : AppTheme.darkBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _createSchool,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Create School',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
              // Search Results Overlay
              if (_showSearchResults)
                Positioned(
                  top: 150,
                  left: 24,
                  right: 24,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 300),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header with close button
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withOpacity(0.1),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search,
                                  size: 18,
                                  color: AppTheme.primaryBlue,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${_searchResults.length} schools found',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryBlue,
                                  ),
                                ),
                                const Spacer(),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _showSearchResults = false;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    child: Icon(
                                      Icons.close,
                                      size: 18,
                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Results list
                          Flexible(
                            child: ListView.separated(
                              shrinkWrap: true,
                              padding: const EdgeInsets.all(8),
                              itemCount: _searchResults.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final school = _searchResults[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                                    child: Icon(
                                      Icons.school,
                                      color: AppTheme.primaryBlue,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    school.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    school.fullAddress,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                                    ),
                                  ),
                                  onTap: () => _selectSchool(school),
                                );
                              },
                            ),
                          ),
                          // "Not listed" button
                          InkWell(
                            onTap: () {
                              setState(() {
                                _showSearchResults = false;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Enter your school details manually below'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey[800] : Colors.grey[100],
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.edit,
                                    size: 18,
                                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'School not listed? Enter manually',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.grey[400] : Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
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
