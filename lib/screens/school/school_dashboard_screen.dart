import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/school_service.dart';
import '../../services/auth_service.dart';
import '../../models/school_model.dart';
import '../../models/school_join_request_model.dart';
import '../../theme/app_theme.dart';
import 'school_broadcast_screen.dart';
import 'create_school_resource_screen.dart';
import 'create_school_event_screen.dart';

class SchoolDashboardScreen extends StatefulWidget {
  final String schoolId;

  const SchoolDashboardScreen({super.key, required this.schoolId});

  @override
  State<SchoolDashboardScreen> createState() => _SchoolDashboardScreenState();
}

class _SchoolDashboardScreenState extends State<SchoolDashboardScreen> {
  final SchoolService _schoolService = SchoolService();
  int _selectedIndex = 0;
  bool _isGeneratingCode = false;

  @override
  void initState() {
    super.initState();
    _checkAndGenerateJoinCode();
  }

  Future<void> _checkAndGenerateJoinCode() async {
    try {
      final schoolDoc = await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .get();
      
      if (schoolDoc.exists) {
        final data = schoolDoc.data();
        final joinCode = data?['joinCode'] as String?;
        
        if (joinCode == null || joinCode.isEmpty) {
          setState(() => _isGeneratingCode = true);
          final newCode = _generateJoinCode();
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(widget.schoolId)
              .update({'joinCode': newCode});
          setState(() => _isGeneratingCode = false);
        }
      }
    } catch (e) {
      print('Error checking join code: $e');
      setState(() => _isGeneratingCode = false);
    }
  }

  String _generateJoinCode() {
    final random = Random();
    return List.generate(6, (_) => random.nextInt(10)).join();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<SchoolModel?>(
      stream: _getSchoolStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.background,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final school = snapshot.data;
        if (school == null) {
          return Scaffold(
            backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.background,
            appBar: AppBar(
              title: const Text('Error'),
              backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
            ),
            body: const Center(child: Text('School not found')),
          );
        }

        final isOwner = school.isOwner(currentUserId ?? '');
        final isAdmin = school.isAdmin(currentUserId ?? '');

        if (!isAdmin) {
          return Scaffold(
            backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.background,
            appBar: AppBar(
              title: const Text('Access Denied'),
              backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
            ),
            body: const Center(child: Text('You do not have admin access')),
          );
        }

        return Scaffold(
          backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.background,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  school.name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.black,
                  ),
                ),
                Text(
                  isOwner ? 'Owner' : 'Administrator',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.mediumGray,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {},
              ),
            ],
          ),
          body: _buildBody(school, isOwner, isDark),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(0, Icons.dashboard_rounded, 'Overview', isDark),
                    _buildNavItem(1, Icons.people_rounded, 'Members', isDark),
                    _buildNavItem(2, Icons.inbox_rounded, 'Requests', isDark),
                    _buildNavItem(3, Icons.settings_rounded, 'Settings', isDark),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Stream<SchoolModel?> _getSchoolStream() {
    return FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .snapshots()
        .map((doc) => doc.exists ? SchoolModel.fromFirestore(doc) : null);
  }

  Widget _buildNavItem(int index, IconData icon, String label, bool isDark) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppTheme.darkPrimary : AppTheme.primaryBlue).withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? (isDark ? AppTheme.darkPrimary : AppTheme.primaryBlue)
                    : AppTheme.mediumGray,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? (isDark ? AppTheme.darkPrimary : AppTheme.primaryBlue)
                      : AppTheme.mediumGray,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(SchoolModel school, bool isOwner, bool isDark) {
    switch (_selectedIndex) {
      case 0:
        return _buildOverview(school, isDark);
      case 1:
        return _buildMembers(school, isOwner, isDark);
      case 2:
        return _buildRequests(school, isDark);
      case 3:
        return _buildSettings(school, isDark);
      default:
        return const SizedBox();
    }
  }

  Widget _buildOverview(SchoolModel school, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Join Code Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkPrimary : AppTheme.primaryBlue,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? AppTheme.darkPrimary : AppTheme.primaryBlue).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Join Code',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _isGeneratingCode
                          ? const SizedBox(
                              height: 42,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              ),
                            )
                          : FittedBox(
                              alignment: Alignment.centerLeft,
                              fit: BoxFit.scaleDown,
                              child: SelectableText(
                                school.joinCode.isNotEmpty
                                    ? school.joinCode.toUpperCase()
                                    : 'GENERATING...',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 42,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 6,
                                  height: 1.1,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(0, 3),
                                      blurRadius: 6,
                                      color: Colors.black45,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                    IconButton(
                      onPressed: () => _copyJoinCode(school.joinCode),
                      icon: const Icon(Icons.copy_rounded, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Share this code with students to join your school',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Stats Grid
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Members',
                  school.memberIds.length.toString(),
                  Icons.people_rounded,
                  AppTheme.success,
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Admins',
                  school.adminIds.length.toString(),
                  Icons.admin_panel_settings_rounded,
                  AppTheme.warning,
                  isDark,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Quick Actions
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.black,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildActionButton(
            'Send Announcement',
            'Broadcast a message to all members',
            Icons.campaign_rounded,
            AppTheme.primaryBlue,
            isDark,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SchoolBroadcastScreen(schoolId: school.id),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            'View Members',
            'Manage school members and admins',
            Icons.people_rounded,
            AppTheme.success,
            isDark,
            () => setState(() => _selectedIndex = 1),
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            'Review Requests',
            'Approve or deny join requests',
            Icons.inbox_rounded,
            AppTheme.warning,
            isDark,
            () => setState(() => _selectedIndex = 2),
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            'Add Resource',
            'Upload files and links for members',
            Icons.folder_rounded,
            AppTheme.primaryBlue,
            isDark,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateSchoolResourceScreen(schoolId: school.id),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            'Create Event',
            'Schedule events for your school',
            Icons.event_rounded,
            AppTheme.warning,
            isDark,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateSchoolEventScreen(schoolId: school.id),
                ),
              );
            },
          ),
          
          const SizedBox(height: 24),
          
          // School Info
          Text(
            'School Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.black,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildInfoRow(Icons.location_on_outlined, '${school.city}, ${school.state}', isDark),
                if (school.description != null && school.description!.isNotEmpty) ...[
                  const Divider(height: 32),
                  _buildInfoRow(Icons.description_outlined, school.description!, isDark),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembers(SchoolModel school, bool isOwner, bool isDark) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getMembersWithDetails(school),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final members = snapshot.data ?? [];
        
        return Column(
          children: [
            // Header with search
            Container(
              padding: const EdgeInsets.all(16),
              color: isDark ? AppTheme.darkSurface : Colors.white,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${members.length} Member${members.length != 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppTheme.black,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${school.adminIds.length} Admin${school.adminIds.length != 1 ? 's' : ''}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Members list
            Expanded(
              child: members.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 64, color: AppTheme.mediumGray),
                          const SizedBox(height: 16),
                          Text(
                            'No members yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark ? Colors.white : AppTheme.black,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: members.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final member = members[index];
                        final userId = member['id'] as String;
                        final isAdmin = school.adminIds.contains(userId);
                        final isMemberOwner = school.ownerId == userId;
                        
                        return _buildMemberCard(
                          member,
                          isAdmin,
                          isMemberOwner,
                          isOwner,
                          school.id,
                          isDark,
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRequests(SchoolModel school, bool isDark) {
    return StreamBuilder<List<SchoolJoinRequestModel>>(
      stream: _schoolService.getPendingJoinRequests(school.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data ?? [];

        return Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              color: isDark ? AppTheme.darkSurface : Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Join Requests',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.black,
                      ),
                    ),
                  ),
                  if (requests.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${requests.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.warning,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Requests list
            Expanded(
              child: requests.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline_rounded, size: 64, color: AppTheme.success),
                          const SizedBox(height: 16),
                          Text(
                            'All caught up!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppTheme.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'No pending join requests',
                            style: TextStyle(color: AppTheme.mediumGray),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: requests.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildRequestCard(requests[index], isDark);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSettings(SchoolModel school, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'School Settings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.black,
            ),
          ),
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.approval_rounded, color: AppTheme.primaryBlue, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Require Approval',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppTheme.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Review join requests before adding members',
                        style: TextStyle(fontSize: 13, color: AppTheme.mediumGray),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: school.requireApproval,
                  onChanged: (value) async {
                    try {
                      await _schoolService.updateSchool(widget.schoolId, {
                        'requireApproval': value,
                      });
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              value
                                  ? 'Join approval now required'
                                  : 'Students can join automatically',
                            ),
                            backgroundColor: AppTheme.success,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: AppTheme.error,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                  activeColor: AppTheme.success,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppTheme.mediumGray),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String title, String subtitle, IconData icon, Color color, bool isDark, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppTheme.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: AppTheme.mediumGray),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppTheme.mediumGray),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.mediumGray),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white : AppTheme.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMemberCard(
    Map<String, dynamic> member,
    bool isAdmin,
    bool isMemberOwner,
    bool isCurrentUserOwner,
    String schoolId,
    bool isDark,
  ) {
    final userId = member['id'] as String;
    final name = member['name'] as String? ?? 'Unknown';
    final email = member['email'] as String? ?? '';
    final photoUrl = member['photoUrl'] as String?;
    
    final showActions = !isMemberOwner && isCurrentUserOwner;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMemberOwner
              ? AppTheme.gold.withValues(alpha: 0.3)
              : (isAdmin
                  ? AppTheme.primaryBlue.withValues(alpha: 0.3)
                  : (isDark ? AppTheme.darkCard : AppTheme.lightGray)),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightGray,
                backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                child: photoUrl == null
                    ? Icon(Icons.person, color: isDark ? Colors.white : AppTheme.darkGray, size: 28)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : AppTheme.black,
                            ),
                          ),
                        ),
                        if (isMemberOwner) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.gold.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppTheme.gold),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_rounded, size: 12, color: AppTheme.gold),
                                SizedBox(width: 4),
                                Text(
                                  'OWNER',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.gold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else if (isAdmin) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppTheme.primaryBlue),
                            ),
                            child: const Text(
                              'ADMIN',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: const TextStyle(fontSize: 13, color: AppTheme.mediumGray),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (showActions) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                if (isAdmin)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _demoteAdmin(schoolId, userId, name),
                      icon: const Icon(Icons.remove_moderator_rounded, size: 18),
                      label: const Text('Remove Admin'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.warning,
                        side: const BorderSide(color: AppTheme.warning),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _promoteToAdmin(schoolId, userId, name),
                      icon: const Icon(Icons.admin_panel_settings_rounded, size: 18),
                      label: const Text('Make Admin'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryBlue,
                        side: const BorderSide(color: AppTheme.primaryBlue),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _removeMember(schoolId, userId, name),
                    icon: const Icon(Icons.person_remove_rounded, size: 18),
                    label: const Text('Remove'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: const BorderSide(color: AppTheme.error),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRequestCard(SchoolJoinRequestModel request, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightGray,
                backgroundImage: request.userPhotoUrl != null ? NetworkImage(request.userPhotoUrl!) : null,
                child: request.userPhotoUrl == null
                    ? Icon(Icons.person, color: isDark ? Colors.white : AppTheme.darkGray, size: 28)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.userName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppTheme.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      request.userEmail,
                      style: const TextStyle(fontSize: 13, color: AppTheme.mediumGray),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _approveRequest(request.id),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _rejectRequest(request.id),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    side: const BorderSide(color: AppTheme.error),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getMembersWithDetails(SchoolModel school) async {
    final members = <Map<String, dynamic>>[];
    final authService = AuthService();
    
    for (final memberId in school.memberIds) {
      try {
        final userData = await authService.getUserData(memberId);
        if (userData != null) {
          final isSuperAdmin = await _isSuperAdmin(memberId);
          if (!isSuperAdmin) {
            members.add({
              'id': memberId,
              'name': userData.name,
              'email': userData.email,
              'photoUrl': userData.photoUrl,
            });
          }
        }
      } catch (e) {
        print('Error fetching member $memberId: $e');
      }
    }
    
    members.sort((a, b) {
      final aId = a['id'] as String;
      final bId = b['id'] as String;
      
      if (school.ownerId == aId) return -1;
      if (school.ownerId == bId) return 1;
      
      final aIsAdmin = school.adminIds.contains(aId);
      final bIsAdmin = school.adminIds.contains(bId);
      
      if (aIsAdmin && !bIsAdmin) return -1;
      if (!aIsAdmin && bIsAdmin) return 1;
      
      return 0;
    });
    
    return members;
  }

  Future<bool> _isSuperAdmin(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('admins').doc(userId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  void _copyJoinCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text('Join code "$code" copied!'),
          ],
        ),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _promoteToAdmin(String schoolId, String userId, String userName) async {
    try {
      await _schoolService.addAdmin(schoolId, userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$userName is now an admin'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _demoteAdmin(String schoolId, String userId, String userName) async {
    try {
      await _schoolService.removeAdmin(schoolId, userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$userName is no longer an admin'),
            backgroundColor: AppTheme.warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _removeMember(String schoolId, String userId, String userName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Remove $userName from the school? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _schoolService.removeMember(schoolId, userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$userName removed from school'),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _approveRequest(String requestId) async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;

      await _schoolService.approveJoinRequest(requestId, currentUserId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Request approved!'),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;

      await _schoolService.rejectJoinRequest(requestId, currentUserId, null);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.info, color: Colors.white),
                SizedBox(width: 8),
                Text('Request rejected'),
              ],
            ),
            backgroundColor: AppTheme.warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
