import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme/app_theme.dart';
import '../../models/school_model.dart';
import '../../services/school_service.dart';
import 'school_settings_screen.dart';
import 'school_members_screen.dart';
import 'school_announcements_screen.dart';
import 'school_events_screen.dart';
import 'school_resources_screen.dart';

class SchoolAdminDashboard extends StatefulWidget {
  final String schoolId;

  const SchoolAdminDashboard({
    super.key,
    required this.schoolId,
  });

  @override
  State<SchoolAdminDashboard> createState() => _SchoolAdminDashboardState();
}

class _SchoolAdminDashboardState extends State<SchoolAdminDashboard> {
  final _schoolService = SchoolService();

  void _showInviteCodeDialog(SchoolModel school) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('School Invite Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(
              data: school.inviteCode,
              version: QrVersions.auto,
              size: 200.0,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                school.inviteCode,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Students can scan this QR code or enter the code to join your school',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: school.inviteCode));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Code copied to clipboard')),
              );
            },
            child: const Text('Copy Code'),
          ),
          TextButton(
            onPressed: () {
              Share.share(
                'Join ${school.name} on FBLA Conference App!\n\nUse invite code: ${school.inviteCode}',
              );
            },
            child: const Text('Share'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _regenerateCode(SchoolModel school) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Regenerate Invite Code?'),
        content: const Text(
          'This will invalidate the current code. Students with the old code will not be able to join.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Regenerate'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final newCode = await _schoolService.regenerateInviteCode(widget.schoolId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('New code: $newCode')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.offWhite,
      body: StreamBuilder<SchoolModel?>(
        stream: _schoolService.getSchoolStream(widget.schoolId),
        builder: (context, schoolSnapshot) {
          if (!schoolSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final school = schoolSnapshot.data!;

          return CustomScrollView(
            slivers: [
              // Modern Minimal Header
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkCard : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'School Admin',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.primaryBlue,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  school.name,
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : AppTheme.darkBlue,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.settings_outlined, 
                              color: isDark ? Colors.white70 : AppTheme.mediumGray),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SchoolSettingsScreen(
                                    schoolId: widget.schoolId,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Stats Row
                      Row(
                        children: [
                          _buildQuickStat(
                            icon: Icons.people_outline,
                            value: '${school.memberIds.length}',
                            label: 'Members',
                            color: AppTheme.primaryBlue,
                          ),
                          const SizedBox(width: 12),
                          _buildQuickStat(
                            icon: Icons.admin_panel_settings_outlined,
                            value: '${school.adminIds.length}',
                            label: 'Admins',
                            color: Colors.amber,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Invite Code
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.qr_code, color: AppTheme.primaryBlue),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Invite Code',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.white70 : AppTheme.mediumGray,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    school.inviteCode,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 20),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: school.inviteCode));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Code copied!')),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.qr_code_2, size: 20),
                              onPressed: () => _showInviteCodeDialog(school),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // School Stats Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'School Overview',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppTheme.darkBlue,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatItem(
                                    icon: Icons.people,
                                    label: 'Members',
                                    value: '${school.memberIds.length}',
                                    color: AppTheme.primaryBlue,
                                  ),
                                ),
                                  Expanded(
                                    child: _buildStatItem(
                                      icon: Icons.admin_panel_settings,
                                      label: 'Admins',
                                      value: '${school.adminIds.length}',
                                      color: Colors.amber,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Invite Code Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Invite Students',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : AppTheme.darkBlue,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.refresh),
                                  onPressed: () => _regenerateCode(school),
                                  tooltip: 'Regenerate code',
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.qr_code,
                                    color: AppTheme.primaryBlue,
                                    size: 40,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Invite Code',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        Text(
                                          school.inviteCode,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy),
                                    onPressed: () {
                                      Clipboard.setData(
                                        ClipboardData(text: school.inviteCode),
                                      );
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Code copied!'),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _showInviteCodeDialog(school),
                                icon: const Icon(Icons.qr_code_scanner),
                                label: const Text('Show QR Code'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryBlue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Management Options
                    Text(
                      'Manage School',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.darkBlue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildManagementCard(
                      icon: Icons.campaign,
                      title: 'Announcements',
                      subtitle: 'Post updates to your students',
                      color: Colors.orange,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SchoolAnnouncementsScreen(
                              schoolId: widget.schoolId,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildManagementCard(
                      icon: Icons.event,
                      title: 'Events',
                      subtitle: 'Create and manage school events',
                      color: Colors.purple,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SchoolEventsScreen(
                              schoolId: widget.schoolId,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildManagementCard(
                      icon: Icons.link,
                      title: 'Resources & Links',
                      subtitle: 'Share important links and resources',
                      color: Colors.green,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SchoolResourcesScreen(
                              schoolId: widget.schoolId,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildManagementCard(
                      icon: Icons.people,
                      title: 'Members',
                      subtitle: 'View and manage school members',
                      color: AppTheme.primaryBlue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SchoolMembersScreen(
                              schoolId: widget.schoolId,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildManagementCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}
