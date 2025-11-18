import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/school_service.dart';
import '../../services/auth_service.dart';
import '../../models/school_model.dart';
import '../../models/school_join_request_model.dart';
import '../../theme/app_theme.dart';

class JoinSchoolWithCodeScreen extends StatefulWidget {
  const JoinSchoolWithCodeScreen({super.key});

  @override
  State<JoinSchoolWithCodeScreen> createState() => _JoinSchoolWithCodeScreenState();
}

class _JoinSchoolWithCodeScreenState extends State<JoinSchoolWithCodeScreen> {
  final _codeController = TextEditingController();
  final SchoolService _schoolService = SchoolService();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  SchoolModel? _foundSchool;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _searchSchool() async {
    if (_codeController.text.trim().length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Join code must be 6 digits'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final school = await _schoolService.getSchoolByJoinCode(_codeController.text.trim());

      setState(() {
        _foundSchool = school;
        _isLoading = false;
      });

      if (school == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('School not found. Please check the code.'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _submitJoinRequest() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _foundSchool == null) return;

    setState(() => _isLoading = true);

    try {
      // Check if already has pending request
      final hasPending = await _schoolService.hasPendingRequest(_foundSchool!.id, user.uid);
      if (hasPending) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You already have a pending request for this school'),
              backgroundColor: AppTheme.warning,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // Get user data
      final userModel = await _authService.getUserData(user.uid);
      if (userModel == null) throw Exception('User data not found');

      // Create join request
      final request = SchoolJoinRequestModel(
        id: '',
        schoolId: _foundSchool!.id,
        userId: user.uid,
        userName: userModel.name,
        userEmail: userModel.email,
        userPhotoUrl: userModel.photoUrl,
        requestedAt: DateTime.now(),
        status: JoinRequestStatus.pending,
      );

      await _schoolService.createJoinRequest(request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('Join request submitted! Wait for admin approval.')),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.background,
      appBar: AppBar(
        title: const Text('Join with Code'),
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.qr_code_scanner_rounded,
              size: 80,
              color: isDark ? AppTheme.darkPrimary : AppTheme.primaryBlue,
            ),
            const SizedBox(height: 24),
            Text(
              'Enter School Code',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ask your teacher or admin for the 6-digit join code',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.mediumGray,
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                hintText: '000000',
                prefixIcon: const Icon(Icons.pin),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: isDark ? AppTheme.darkSurface : Colors.white,
                counterText: '',
              ),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
              maxLength: 6,
              onChanged: (value) {
                if (value.length == 6) {
                  _searchSchool();
                } else {
                  setState(() => _foundSchool = null);
                }
              },
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_foundSchool != null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppTheme.darkCard : AppTheme.lightGray,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.school_rounded,
                      size: 48,
                      color: isDark ? AppTheme.darkPrimary : AppTheme.primaryBlue,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _foundSchool!.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    if (_foundSchool!.city.isNotEmpty && _foundSchool!.state.isNotEmpty)
                      Text(
                        '${_foundSchool!.city}, ${_foundSchool!.state}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.mediumGray,
                        ),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_rounded, size: 16, color: AppTheme.mediumGray),
                        const SizedBox(width: 4),
                        Text(
                          '${_foundSchool!.memberIds.length} members',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.mediumGray,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _submitJoinRequest,
                icon: const Icon(Icons.send_rounded),
                label: const Text('Request to Join'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? AppTheme.darkPrimary : AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 20, color: AppTheme.warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'An admin will review your request before you can join',
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white.withValues(alpha: 0.9) : AppTheme.darkGray),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
