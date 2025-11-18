import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../theme/app_theme.dart';
import '../../services/school_service.dart';
import 'student_school_view.dart';

class JoinSchoolScreen extends StatefulWidget {
  const JoinSchoolScreen({super.key});

  @override
  State<JoinSchoolScreen> createState() => _JoinSchoolScreenState();
}

class _JoinSchoolScreenState extends State<JoinSchoolScreen> {
  final _schoolService = SchoolService();
  final _codeController = TextEditingController();
  bool _isLoading = false;
  bool _showScanner = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _joinWithCode(String code) async {
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an invite code')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      await _schoolService.joinSchool(userId, code.toUpperCase());

      if (mounted) {
        final school = await _schoolService.getSchoolByInviteCode(code);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Joined ${school?.name ?? "school"} successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => StudentSchoolView(schoolId: school!.id),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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
        title: const Text('Join School'),
      ),
      body: _showScanner
          ? _buildQRScanner()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Join Your School',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppTheme.darkBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter the invite code provided by your school administrator',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(
                            Icons.school,
                            size: 64,
                            color: AppTheme.primaryBlue,
                          ),
                          const SizedBox(height: 24),
                          TextField(
                            controller: _codeController,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                            ),
                            decoration: InputDecoration(
                              hintText: 'ENTER CODE',
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                letterSpacing: 4,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            textCapitalization: TextCapitalization.characters,
                            maxLength: 8,
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading 
                                  ? null 
                                  : () => _joinWithCode(_codeController.text),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryBlue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
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
                                      'Join School',
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
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[300])),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey[300])),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() => _showScanner = true);
                      },
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Scan QR Code'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AppTheme.primaryBlue,
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildQRScanner() {
    return Stack(
      children: [
        MobileScanner(
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              final code = barcode.rawValue;
              if (code != null) {
                setState(() => _showScanner = false);
                _joinWithCode(code);
                break;
              }
            }
          },
        ),
        Positioned(
          top: 16,
          left: 16,
          child: IconButton(
            onPressed: () {
              setState(() => _showScanner = false);
            },
            icon: const Icon(Icons.close, color: Colors.white, size: 32),
          ),
        ),
        Positioned(
          bottom: 32,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Text(
                'Align QR code within frame',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
