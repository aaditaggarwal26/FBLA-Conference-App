import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'create_school_screen.dart';
import 'join_school_screen.dart';
import 'join_school_with_code_screen.dart';

class SchoolSelectionScreen extends StatelessWidget {
  const SchoolSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.background,
      appBar: AppBar(
        title: const Text('School Setup'),
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Skip',
              style: TextStyle(
                color: isDark ? AppTheme.darkPrimary : AppTheme.primaryBlue,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Icon(
                Icons.school_rounded,
                size: 80,
                color: isDark ? AppTheme.darkPrimary : AppTheme.primaryBlue,
              ),
              const SizedBox(height: 24),
              Text(
                'Join Your School',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: isDark ? Colors.white : AppTheme.black,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Connect with your school to access announcements, resources, and more.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: isDark ? AppTheme.mediumGray : AppTheme.darkGray,
                ),
              ),
              const SizedBox(height: 48),

              // Join with Code Option
              _buildOptionCard(
                context: context,
                isDark: isDark,
                icon: Icons.qr_code_scanner_rounded,
                title: 'Join with Code',
                description: 'Enter a 6-digit code from your teacher',
                color: AppTheme.success,
                onTap: () async {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const JoinSchoolWithCodeScreen(),
                    ),
                  );
                  if (result == true && context.mounted) {
                    Navigator.pop(context);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Join School Option
              _buildOptionCard(
                context: context,
                isDark: isDark,
                icon: Icons.people_rounded,
                title: 'Join a School',
                description: 'Search for your school and join as a student',
                color: isDark ? AppTheme.darkPrimary : AppTheme.primaryBlue,
                onTap: () async {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const JoinSchoolScreen(),
                    ),
                  );
                  if (result == true && context.mounted) {
                    Navigator.pop(context);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Create School Option
              _buildOptionCard(
                context: context,
                isDark: isDark,
                icon: Icons.admin_panel_settings_rounded,
                title: 'Create a School',
                description: 'Set up a new school as an administrator',
                color: isDark ? AppTheme.darkSecondary : AppTheme.secondaryBlue,
                onTap: () async {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateSchoolScreen(),
                    ),
                  );
                  if (result == true && context.mounted) {
                    Navigator.pop(context);
                  }
                },
              ),
              const Spacer(),
              Text(
                'You can also set this up later from your profile.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.mediumGray,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppTheme.darkCard : AppTheme.lightGray,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 32,
                color: color,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppTheme.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppTheme.mediumGray : AppTheme.darkGray,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: isDark ? AppTheme.mediumGray : AppTheme.darkGray,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
