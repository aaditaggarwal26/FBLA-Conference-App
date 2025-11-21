import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/linkedin_service.dart';
import '../../theme/app_theme.dart';

class LinkedInSettingsScreen extends StatefulWidget {
  final String? schoolId;

  const LinkedInSettingsScreen({super.key, this.schoolId});

  @override
  State<LinkedInSettingsScreen> createState() => _LinkedInSettingsScreenState();
}

class _LinkedInSettingsScreenState extends State<LinkedInSettingsScreen> {
  final LinkedInService _linkedInService = LinkedInService();
  bool _isLoading = false;
  bool _isConnected = false;
  bool _autoPost = false;
  String? _username;

  @override
  void initState() {
    super.initState();
    _loadConnectionStatus();
  }

  Future<void> _loadConnectionStatus() async {
    setState(() => _isLoading = true);
    try {
      final status = await _linkedInService.getConnectionStatus(
        schoolId: widget.schoolId,
      );
      
      if (status != null) {
        setState(() {
          _isConnected = status['connected'] as bool? ?? false;
          _autoPost = status['autoPost'] as bool? ?? false;
          _username = status['username'] as String?;
        });
      }
    } catch (e) {
      print('Error loading LinkedIn status: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _connectLinkedIn() async {
    try {
      // Get authorization URL
      final authUrl = _linkedInService.getAuthorizationUrl();
      
      // Open in browser
      final uri = Uri.parse(authUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        
        // Show dialog with instructions
        if (mounted) {
          _showConnectionInstructions();
        }
      } else {
        throw Exception('Could not launch LinkedIn authorization');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error connecting to LinkedIn: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _showConnectionInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connect LinkedIn'),
        content: const Text(
          'After authorizing in your browser, you\'ll be redirected back to the app. '
          'Please copy the authorization code from the URL and paste it below.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showCodeInputDialog();
            },
            child: const Text('I have the code'),
          ),
        ],
      ),
    );
  }

  void _showCodeInputDialog() {
    final codeController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Authorization Code'),
        content: TextField(
          controller: codeController,
          decoration: const InputDecoration(
            hintText: 'Paste authorization code here',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final code = codeController.text.trim();
              if (code.isNotEmpty) {
                Navigator.pop(context);
                await _handleAuthorizationCode(code);
              }
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAuthorizationCode(String code) async {
    setState(() => _isLoading = true);
    
    try {
      final success = await _linkedInService.handleOAuthCallback(
        code,
        schoolId: widget.schoolId,
      );
      
      if (success) {
        await _loadConnectionStatus();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('LinkedIn connected successfully!'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      } else {
        throw Exception('Failed to connect LinkedIn');
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
      setState(() => _isLoading = false);
    }
  }

  Future<void> _disconnectLinkedIn() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect LinkedIn?'),
        content: const Text(
          'Are you sure you want to disconnect your LinkedIn account? '
          'You will need to reconnect to post to LinkedIn.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.error,
            ),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _linkedInService.disconnect(schoolId: widget.schoolId);
        await _loadConnectionStatus();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('LinkedIn disconnected'),
              backgroundColor: AppTheme.success,
            ),
          );
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
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleAutoPost(bool value) async {
    setState(() => _isLoading = true);
    try {
      await _linkedInService.setAutoPost(value, schoolId: widget.schoolId);
      setState(() => _autoPost = value);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value
                  ? 'Auto-post enabled'
                  : 'Auto-post disabled',
            ),
            backgroundColor: AppTheme.success,
          ),
        );
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
      setState(() => _isLoading = false);
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
        title: Text(
          'LinkedIn Integration',
          style: TextStyle(
            color: isDark ? Colors.white : AppTheme.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading && !_isConnected
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF0077B5).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0077B5).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.business_rounded,
                            color: Color(0xFF0077B5),
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'LinkedIn Integration',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : AppTheme.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Connect your LinkedIn account to share announcements and events',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.7)
                                      : AppTheme.mediumGray,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Connection Status
                  if (_isConnected) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.success.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: AppTheme.success,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Connected',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.success,
                                ),
                              ),
                            ],
                          ),
                          if (_username != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Account: $_username',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.8)
                                    : AppTheme.darkGray,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Auto-post toggle
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppTheme.darkCard : AppTheme.lightGray,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Auto-post to LinkedIn',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : AppTheme.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Automatically share new announcements',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.6)
                                        : AppTheme.mediumGray,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _autoPost,
                            onChanged: _toggleAutoPost,
                            activeColor: const Color(0xFF0077B5),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Disconnect button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _disconnectLinkedIn,
                        icon: const Icon(Icons.link_off_rounded),
                        label: const Text('Disconnect LinkedIn'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.error,
                          side: BorderSide(color: AppTheme.error),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Connect button
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppTheme.darkCard : AppTheme.lightGray,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Not Connected',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppTheme.black,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Connect your LinkedIn account to start sharing announcements and events directly from the app.',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.7)
                                  : AppTheme.mediumGray,
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _connectLinkedIn,
                              icon: const Icon(Icons.business_rounded),
                              label: const Text('Connect LinkedIn'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0077B5),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Info section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.warning.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: AppTheme.warning,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'To use LinkedIn integration, you need to create a LinkedIn app and get API credentials. See documentation for setup instructions.',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.8)
                                  : AppTheme.darkGray,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

