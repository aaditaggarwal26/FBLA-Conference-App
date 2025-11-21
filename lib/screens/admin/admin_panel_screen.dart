import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../theme/app_theme.dart';
import 'create_event_screen.dart';
import 'create_announcement_screen.dart';
import 'linkedin_settings_screen.dart';

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final adminService = AdminService();

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.offWhite,
      appBar: AppBar(
        title: const Text(
          'Admin Panel',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.white,
        elevation: 0,
      ),
      body: FutureBuilder<bool>(
        future: adminService.isAdmin(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!) {
            return _buildAccessDenied(isDark);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Welcome header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : AppTheme.primaryBlue,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.admin_panel_settings_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Administrator Controls',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Manage events, announcements, and schedules',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Action cards
                _buildActionCard(
                  context: context,
                  isDark: isDark,
                  title: 'Create Event',
                  description: 'Add new conference events',
                  icon: Icons.event_rounded,
                  color: const Color(0xFF3B82F6),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateEventScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                _buildActionCard(
                  context: context,
                  isDark: isDark,
                  title: 'Create Announcement',
                  description: 'Post important updates',
                  icon: Icons.campaign_rounded,
                  color: const Color(0xFF8B5CF6),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateAnnouncementScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                _buildActionCard(
                  context: context,
                  isDark: isDark,
                  title: 'Manage Schedule',
                  description: 'Update conference schedule',
                  icon: Icons.schedule_rounded,
                  color: const Color(0xFF10B981),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Schedule management coming soon'),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                _buildActionCard(
                  context: context,
                  isDark: isDark,
                  title: 'Manage Users',
                  description: 'View and manage attendees',
                  icon: Icons.people_rounded,
                  color: const Color(0xFFF59E0B),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('User management coming soon'),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                _buildActionCard(
                  context: context,
                  isDark: isDark,
                  title: 'LinkedIn Integration',
                  description: 'Connect and manage LinkedIn sharing',
                  icon: Icons.business_rounded,
                  color: const Color(0xFF0077B5),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LinkedInSettingsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAccessDenied(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_rounded,
              size: 80,
              color: isDark ? AppTheme.darkCard : AppTheme.mediumGray,
            ),
            const SizedBox(height: 24),
            Text(
              'Access Denied',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You do not have administrator privileges.\nPlease contact a conference organizer.',
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white.withValues(alpha: 0.7) : AppTheme.mediumGray,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required bool isDark,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 28,
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
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppTheme.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white.withValues(alpha: 0.6) : AppTheme.mediumGray,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
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
