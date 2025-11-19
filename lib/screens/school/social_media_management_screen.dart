import 'package:flutter/material.dart';
import '../../services/school_service.dart';
import '../../theme/app_theme.dart';

class SocialMediaManagementScreen extends StatefulWidget {
  final String schoolId;

  const SocialMediaManagementScreen({super.key, required this.schoolId});

  @override
  State<SocialMediaManagementScreen> createState() =>
      _SocialMediaManagementScreenState();
}

class _SocialMediaManagementScreenState
    extends State<SocialMediaManagementScreen> {
  final SchoolService _schoolService = SchoolService();
  final Map<String, TextEditingController> _controllers = {};
  bool _isLoading = false;

  final List<Map<String, dynamic>> _socialMediaPlatforms = [
    {
      'key': 'instagram',
      'label': 'Instagram',
      'icon': Icons.camera_alt_rounded,
      'color': Color(0xFFE4405F),
      'placeholder': 'https://instagram.com/yourchapter',
    },
    {
      'key': 'twitter',
      'label': 'Twitter',
      'icon': Icons.alternate_email_rounded,
      'color': Color(0xFF1DA1F2),
      'placeholder': 'https://twitter.com/yourchapter',
    },
    {
      'key': 'facebook',
      'label': 'Facebook',
      'icon': Icons.facebook_rounded,
      'color': Color(0xFF1877F2),
      'placeholder': 'https://facebook.com/yourchapter',
    },
    {
      'key': 'linkedin',
      'label': 'LinkedIn',
      'icon': Icons.business_rounded,
      'color': Color(0xFF0077B5),
      'placeholder': 'https://linkedin.com/company/yourchapter',
    },
    {
      'key': 'youtube',
      'label': 'YouTube',
      'icon': Icons.play_circle_filled_rounded,
      'color': Color(0xFFFF0000),
      'placeholder': 'https://youtube.com/@yourchapter',
    },
    {
      'key': 'tiktok',
      'label': 'TikTok',
      'icon': Icons.music_note_rounded,
      'color': Color(0xFF000000),
      'placeholder': 'https://tiktok.com/@yourchapter',
    },
    {
      'key': 'snapchat',
      'label': 'Snapchat',
      'icon': Icons.camera_alt_outlined,
      'color': Color(0xFFFFFC00),
      'placeholder': 'yourchapter',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadSocialMediaLinks();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSocialMediaLinks() async {
    try {
      final school = await _schoolService.getSchool(widget.schoolId);
      if (school != null) {
        setState(() {
          for (final platform in _socialMediaPlatforms) {
            final key = platform['key'] as String;
            _controllers[key] = TextEditingController(
              text: school.socialMediaLinks[key] ?? '',
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading social media links: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _saveSocialMediaLinks() async {
    setState(() => _isLoading = true);

    try {
      final socialMediaLinks = <String, String>{};
      for (final platform in _socialMediaPlatforms) {
        final key = platform['key'] as String;
        final controller = _controllers[key];
        if (controller != null && controller.text.trim().isNotEmpty) {
          var url = controller.text.trim();
          // Add https:// if not present
          if (!url.startsWith('http://') && !url.startsWith('https://')) {
            // For Snapchat, don't add https
            if (key == 'snapchat') {
              socialMediaLinks[key] = url;
              continue;
            }
            url = 'https://$url';
          }
          socialMediaLinks[key] = url;
        }
      }

      await _schoolService.updateSchool(widget.schoolId, {
        'socialMediaLinks': socialMediaLinks,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Social media links saved successfully!'),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving links: $e'),
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
        elevation: 0,
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        title: Text(
          'Social Media Links',
          style: TextStyle(
            color: isDark ? Colors.white : AppTheme.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _saveSocialMediaLinks,
              child: Text(
                'Save',
                style: TextStyle(
                  color: isDark ? AppTheme.darkPrimary : AppTheme.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkPrimary : AppTheme.primaryBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Add your chapter\'s social media links to help members stay connected.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Platforms',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.black,
              ),
            ),
            const SizedBox(height: 16),
            ..._socialMediaPlatforms.map((platform) {
              final key = platform['key'] as String;
              final label = platform['label'] as String;
              final icon = platform['icon'] as IconData;
              final color = platform['color'] as Color;
              final placeholder = platform['placeholder'] as String;

              if (_controllers[key] == null) {
                _controllers[key] = TextEditingController();
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(icon, color: color, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : AppTheme.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _controllers[key],
                        decoration: InputDecoration(
                          hintText: placeholder,
                          hintStyle: TextStyle(
                            color: AppTheme.mediumGray,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppTheme.darkCard
                                  : AppTheme.lightGray,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppTheme.darkCard
                                  : AppTheme.lightGray,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: color,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? AppTheme.darkBackground
                              : AppTheme.background,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        style: TextStyle(
                          color: isDark ? Colors.white : AppTheme.black,
                        ),
                        keyboardType: TextInputType.url,
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
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
                    Icons.lightbulb_outline_rounded,
                    color: AppTheme.warning,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tip: You can leave fields empty if you don\'t have that platform. Snapchat usernames don\'t need URLs.',
                      style: TextStyle(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.8)
                            : AppTheme.darkGray,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

