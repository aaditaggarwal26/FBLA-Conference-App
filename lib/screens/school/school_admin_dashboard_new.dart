import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/school_service.dart';
import '../../services/auth_service.dart';
import '../../models/school_model.dart';
import '../../models/school_join_request_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/school_badge.dart';
import 'school_broadcast_screen.dart';

class SchoolAdminDashboardNew extends StatefulWidget {
  final String schoolId;

  const SchoolAdminDashboardNew({super.key, required this.schoolId});

  @override
  State<SchoolAdminDashboardNew> createState() => _SchoolAdminDashboardNewState();
}

class _SchoolAdminDashboardNewState extends State<SchoolAdminDashboardNew> with SingleTickerProviderStateMixin {
  final SchoolService _schoolService = SchoolService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _copyJoinCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text('Join code "$code" copied to clipboard!'),
          ],
        ),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return FutureBuilder<SchoolModel?>(
      future: _schoolService.getSchool(widget.schoolId),
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
            appBar: AppBar(title: const Text('Error')),
            body: const Center(child: Text('School not found')),
          );
        }

        final isOwner = school.isOwner(currentUserId ?? '');
        final isAdmin = school.isAdmin(currentUserId ?? '');

        if (!isAdmin) {
          return Scaffold(
            appBar: AppBar(title: const Text('Access Denied')),
            body: const Center(child: Text('You do not have admin access')),
          );
        }

        return Scaffold(
          backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.background,
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                expandedHeight: 220,
                floating: false,
                pinned: true,
                backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
                iconTheme: const IconThemeData(color: Colors.white),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          isDark ? AppTheme.darkPrimary : AppTheme.primaryBlue,
                          isDark ? AppTheme.darkSecondary : AppTheme.secondaryBlue,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (isOwner)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppTheme.gold.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: AppTheme.gold),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.verified_rounded, size: 14, color: AppTheme.gold),
                                              const SizedBox(width: 4),
                                              Text(
                                                'School Owner',
                                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.gold),
                                              ),
                                            ],
                                          ),
                                        ),
                                      const SizedBox(height: 8),
                                      Text(
                                        school.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          SchoolBadge(school: school, isOwner: isOwner, fontSize: 11),
                                          const SizedBox(width: 12),
                                          Text(
                                            '${school.memberIds.length} members',
                                            style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Join Code Card
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.qr_code_2_rounded, color: Colors.white),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Join Code',
                                          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          school.joinCode,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 2,
                                          ),
                                        ),
                                      ],
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
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(48),
                  child: Container(
                    color: isDark ? AppTheme.darkSurface : Colors.white,
                    child: TabBar(
                      controller: _tabController,
                      labelColor: isDark ? AppTheme.darkPrimary : AppTheme.primaryBlue,
                      unselectedLabelColor: AppTheme.mediumGray,
                      indicatorColor: isDark ? AppTheme.darkPrimary : AppTheme.primaryBlue,
                      indicatorWeight: 3,
                      tabs: const [
                        Tab(text: 'Overview'),
                        Tab(text: 'Requests'),
                        Tab(text: 'Members'),
                        Tab(text: 'Settings'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(school, isDark),
                _buildRequestsTab(school, isDark),
                _buildMembersTab(school, isDark, isOwner),
                _buildSettingsTab(school, isDark),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverviewTab(SchoolModel school, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Members',
                  school.memberIds.length.toString(),
                  Icons.people_rounded,
                  isDark ? AppTheme.darkPrimary : AppTheme.primaryBlue,
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Admins',
                  school.adminIds.length.toString(),
                  Icons.admin_panel_settings_rounded,
                  isDark ? AppTheme.darkSecondary : AppTheme.secondaryBlue,
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
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  'Send Announcement',
                  'Broadcast to all members',
                  Icons.campaign_rounded,
                  AppTheme.success,
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
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  'Manage Members',
                  'View and edit members',
                  Icons.people_rounded,
                  AppTheme.primaryBlue,
                  isDark,
                  () {
                    _tabController.animateTo(2); // Switch to Members tab
                  },
                ),
              ),
            ],
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
          _buildInfoCard(isDark, school),
        ],
      ),
    );
  }

  Widget _buildRequestsTab(SchoolModel school, bool isDark) {
    return StreamBuilder<List<SchoolJoinRequestModel>>(
      stream: _schoolService.getPendingJoinRequests(school.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline_rounded, size: 64, color: AppTheme.mediumGray),
                const SizedBox(height: 16),
                Text(
                  'No pending requests',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppTheme.black),
                ),
                const SizedBox(height: 8),
                Text(
                  'All join requests have been reviewed',
                  style: TextStyle(color: AppTheme.mediumGray),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return _buildRequestCard(request, isDark);
          },
        );
      },
    );
  }

  Widget _buildRequestCard(SchoolJoinRequestModel request, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.darkCard : AppTheme.lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightGray,
                backgroundImage: request.userPhotoUrl != null ? NetworkImage(request.userPhotoUrl!) : null,
                child: request.userPhotoUrl == null
                    ? Icon(Icons.person, color: isDark ? Colors.white : AppTheme.darkGray)
                    : null,
              ),
              const SizedBox(width: 12),
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
                    const SizedBox(height: 2),
                    Text(
                      request.userEmail,
                      style: TextStyle(fontSize: 13, color: AppTheme.mediumGray),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Requested ${_formatDate(request.requestedAt)}',
            style: TextStyle(fontSize: 12, color: AppTheme.mediumGray),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _rejectRequest(request.id),
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    side: const BorderSide(color: AppTheme.error),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _approveRequest(request.id),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMembersTab(SchoolModel school, bool isDark, bool isOwner) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getMembersWithDetails(school),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final members = snapshot.data ?? [];
        
        return Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                onChanged: (value) {
                  setState(() {});
                },
                decoration: InputDecoration(
                  hintText: 'Search members...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? AppTheme.darkCard : AppTheme.lightGray),
                  ),
                  filled: true,
                  fillColor: isDark ? AppTheme.darkSurface : Colors.white,
                ),
              ),
            ),
            
            // Stats row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildMemberStat('Total', members.length.toString(), isDark),
                  const SizedBox(width: 12),
                  _buildMemberStat('Admins', school.adminIds.length.toString(), isDark),
                  const SizedBox(width: 12),
                  _buildMemberStat('Students', (members.length - school.adminIds.length).toString(), isDark),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Members list
            Expanded(
              child: members.isEmpty
                  ? Center(
                      child: Text(
                        'No members yet',
                        style: TextStyle(color: isDark ? Colors.white : AppTheme.black),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: members.length,
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

  Widget _buildMemberStat(String label, String value, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isDark ? AppTheme.darkCard : AppTheme.lightGray),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.black,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: AppTheme.mediumGray),
            ),
          ],
        ),
      ),
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
    
    // Don't show action buttons for owner or if current user is not owner
    final showActions = !isMemberOwner && isCurrentUserOwner;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAdmin 
              ? AppTheme.primaryBlue.withValues(alpha: 0.3)
              : (isDark ? AppTheme.darkCard : AppTheme.lightGray),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightGray,
                backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                child: photoUrl == null
                    ? Icon(Icons.person, color: isDark ? Colors.white : AppTheme.darkGray)
                    : null,
              ),
              const SizedBox(width: 12),
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
                              color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFFFD700)),
                            ),
                            child: const Text(
                              'OWNER',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFFD700),
                              ),
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
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: TextStyle(fontSize: 13, color: AppTheme.mediumGray),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (showActions) ...[
            const SizedBox(height: 12),
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

  Future<List<Map<String, dynamic>>> _getMembersWithDetails(SchoolModel school) async {
    final members = <Map<String, dynamic>>[];
    
    // Filter out super admins
    final authService = AuthService();
    
    for (final memberId in school.memberIds) {
      try {
        final userData = await authService.getUserData(memberId);
        if (userData != null) {
          // Check if user is a super admin (FBLA admin)
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
    
    // Sort: owner first, then admins, then students
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

  Future<void> _promoteToAdmin(String schoolId, String userId, String userName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Promote to Admin'),
        content: Text('Make $userName a school administrator? They will be able to manage announcements, resources, and members.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
            child: const Text('Promote'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _schoolService.addAdmin(schoolId, userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$userName is now an admin'),
              backgroundColor: AppTheme.success,
            ),
          );
          setState(() {});
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
          );
        }
      }
    }
  }

  Future<void> _demoteAdmin(String schoolId, String userId, String userName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Admin Role'),
        content: Text('Remove $userName as administrator? They will remain a member but lose admin privileges.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warning),
            child: const Text('Remove Admin'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _schoolService.removeAdmin(schoolId, userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$userName is no longer an admin'),
              backgroundColor: AppTheme.warning,
            ),
          );
          setState(() {});
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
          );
        }
      }
    }
  }

  Future<void> _removeMember(String schoolId, String userId, String userName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Remove $userName from the school? This action cannot be undone.'),
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
            ),
          );
          setState(() {});
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
          );
        }
      }
    }
  }

  Widget _buildSettingsTab(SchoolModel school, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Join Settings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.black,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? AppTheme.darkCard : AppTheme.lightGray),
            ),
            child: Column(
              children: [
                Row(
                  children: [
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
                          Text(
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
                                      : 'Join approval disabled - students can join automatically',
                                ),
                                backgroundColor: AppTheme.success,
                              ),
                            );
                            setState(() {});
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
                        }
                      },
                      activeColor: AppTheme.success,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.darkCard : AppTheme.lightGray),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 13, color: AppTheme.mediumGray),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(bool isDark, SchoolModel school) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppTheme.darkCard : AppTheme.lightGray),
      ),
      child: Column(
        children: [
          if (school.city.isNotEmpty && school.state.isNotEmpty)
            _buildInfoRow(Icons.location_on_outlined, '${school.city}, ${school.state}', isDark),
          if (school.description != null && school.description!.isNotEmpty) ...[
            const Divider(),
            _buildInfoRow(Icons.description_outlined, school.description!, isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    bool isDark,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.mediumGray,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
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
      ),
    );
  }

  Future<void> _approveRequest(String requestId) async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;

      await _schoolService.approveJoinRequest(requestId, currentUserId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Request approved successfully!'),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving request: $e'),
            backgroundColor: AppTheme.error,
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
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.info, color: Colors.white),
                SizedBox(width: 8),
                Text('Request rejected'),
              ],
            ),
            backgroundColor: AppTheme.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting request: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes} minutes ago';
      }
      return '${diff.inHours} hours ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}
