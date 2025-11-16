import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/admin_service.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../admin/admin_panel_screen.dart';
import 'edit_profile_screen.dart';
import 'help_support_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final AdminService _adminService = AdminService();
  UserModel? _userModel;
  bool _isLoading = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final userData = await _authService.getUserData(user.uid);
        final isUserAdmin = await _adminService.isAdmin();
        if (mounted) {
          setState(() {
            _userModel = userData;
            _isAdmin = isUserAdmin;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      // If Firestore fails, still show the profile with basic info from Firebase Auth
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signOut() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _authService.signOut();
              if (mounted) {
                Navigator.pop(context);
              }
            },
            child: Text('Sign Out', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'Not signed in',
            style: TextStyle(color: AppTheme.mediumGray),
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(
            color: isDark ? Colors.white : AppTheme.black,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.background,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 70,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: Icon(
                Icons.logout_rounded,
                color: isDark ? Colors.white : AppTheme.black,
              ),
              onPressed: _signOut,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              color: AppTheme.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Profile Picture - Use Firestore photoUrl first, then Firebase Auth photoURL
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppTheme.lightBlue,
                    backgroundImage:
                        (_userModel?.photoUrl != null &&
                            _userModel!.photoUrl!.isNotEmpty)
                        ? NetworkImage(_userModel!.photoUrl!)
                        : (user.photoURL != null
                              ? NetworkImage(user.photoURL!)
                              : null),
                    child:
                        (_userModel?.photoUrl == null ||
                                _userModel!.photoUrl!.isEmpty) &&
                            user.photoURL == null
                        ? Icon(
                            Icons.person,
                            size: 50,
                            color: AppTheme.primaryBlue,
                          )
                        : null,
                  ),

                  const SizedBox(height: 16),

                  // Name
                  Text(
                    _userModel?.name ?? user.displayName ?? 'User',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Email
                  Text(
                    user.email ?? '',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: AppTheme.mediumGray),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Stats
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Events Registered',
                      '${_userModel?.registeredEvents.length ?? 0}',
                      Icons.event_rounded,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Member Since',
                      _userModel != null
                          ? '${_userModel!.createdAt.year}'
                          : '2025',
                      Icons.calendar_today_rounded,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Menu Items
            if (_isAdmin) ...[
              _buildMenuItem(
                Icons.admin_panel_settings_rounded,
                'Admin Panel',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminPanelScreen(),
                    ),
                  );
                },
                iconColor: const Color(0xFF8B5CF6),
              ),
            ],
            _buildMenuItem(Icons.person_outline, 'Edit Profile', () async {
              if (_userModel != null) {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        EditProfileScreen(userModel: _userModel!),
                  ),
                );
                // Reload user data if profile was updated
                if (result == true) {
                  _loadUserData();
                }
              }
            }),
            _buildDarkModeToggle(),
            _buildMenuItem(Icons.notifications_outlined, 'Notifications', () {
              // TODO: Navigate to notifications settings
            }),
            _buildMenuItem(Icons.help_outline, 'Help & Support', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HelpSupportScreen(),
                ),
              );
            }),
            _buildMenuItem(Icons.info_outline, 'About', () {
              showAboutDialog(
                context: context,
                applicationName: 'FBLA Conference App',
                applicationVersion: '1.0.0',
                applicationIcon: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    'assets/logo.png',
                    height: 48,
                    width: 48,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.lightGray),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primaryBlue, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: AppTheme.mediumGray),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color? iconColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppTheme.darkCard.withValues(alpha: 0.3)
              : AppTheme.lightGray,
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? AppTheme.primaryBlue),
        title: Text(title),
        trailing: Icon(Icons.chevron_right, color: AppTheme.mediumGray),
        onTap: onTap,
      ),
    );
  }

  Widget _buildDarkModeToggle() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: themeProvider.isDarkMode
                  ? [const Color(0xFF1E293B), const Color(0xFF334155)]
                  : [const Color(0xFFE0E7FF), const Color(0xFFDDD6FE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            leading: Icon(
              themeProvider.isDarkMode
                  ? Icons.dark_mode_rounded
                  : Icons.light_mode_rounded,
              color: themeProvider.isDarkMode
                  ? const Color(0xFFFDB813)
                  : const Color(0xFF4F46E5),
            ),
            title: Text(
              'Dark Mode',
              style: TextStyle(
                color: themeProvider.isDarkMode
                    ? Colors.white
                    : const Color(0xFF0F1113),
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              themeProvider.isDarkMode ? 'Enabled' : 'Disabled',
              style: TextStyle(
                fontSize: 12,
                color: themeProvider.isDarkMode
                    ? Colors.white.withValues(alpha: 0.7)
                    : const Color(0xFF6B7280),
              ),
            ),
            trailing: Switch(
              value: themeProvider.isDarkMode,
              onChanged: (value) {
                themeProvider.toggleTheme();
              },
              activeColor: const Color(0xFF4F46E5),
              activeTrackColor: const Color(0xFF8B7DFF),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: const Color(0xFFE0E3E7),
            ),
          ),
        );
      },
    );
  }
}
