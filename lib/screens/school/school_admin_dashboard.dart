import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/school_service.dart';
import '../../services/auth_service.dart';
import '../../models/school_model.dart';
import '../../models/school_announcement_model.dart';
import '../../models/school_resource_model.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class SchoolAdminDashboard extends StatefulWidget {
  final String schoolId;

  const SchoolAdminDashboard({super.key, required this.schoolId});

  @override
  State<SchoolAdminDashboard> createState() => _SchoolAdminDashboardState();
}

class _SchoolAdminDashboardState extends State<SchoolAdminDashboard> {
  final SchoolService _schoolService = SchoolService();
  final AuthService _authService = AuthService();
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return FutureBuilder<SchoolModel?>(
      future: _schoolService.getSchool(widget.schoolId),
      builder: (context, schoolSnapshot) {
        if (schoolSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final school = schoolSnapshot.data;
        if (school == null) {
          return Scaffold(
            body: Center(
              child: Text('School not found'),
            ),
          );
        }

        final isOwner = school.isOwner(currentUserId ?? '');
        final isAdmin = school.isAdmin(currentUserId ?? '');

        if (!isAdmin) {
          return Scaffold(
            appBar: AppBar(title: const Text('Access Denied')),
            body: const Center(
              child: Text('You do not have admin access to this school'),
            ),
          );
        }

        return Scaffold(
          backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.background,
          body: CustomScrollView(
            slivers: [
              // Modern Header
              SliverAppBar(
                expandedHeight: 200,
                floating: false,
                pinned: true,
                backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    school.name,
                    style: TextStyle(
                      color: isDark ? Colors.white : AppTheme.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [
                                AppTheme.darkPrimary,
                                AppTheme.darkPrimary.withValues(alpha: 0.7),
                              ]
                            : [
                                AppTheme.primaryBlue,
                                AppTheme.primaryBlue.withValues(alpha: 0.8),
                              ],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (isOwner)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.success.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppTheme.success.withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.verified_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'School Owner',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Tabs
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    labelColor: isDark ? AppTheme.darkPrimary : AppTheme.primaryBlue,
                    unselectedLabelColor: AppTheme.mediumGray,
                    indicatorColor: isDark ? AppTheme.darkPrimary : AppTheme.primaryBlue,
                    tabs: const [
                      Tab(text: 'Overview'),
                      Tab(text: 'Announcements'),
                      Tab(text: 'Resources'),
                      Tab(text: 'Members'),
                    ],
                    onTap: (index) => setState(() => _selectedTab = index),
                  ),
                ),
              ),

              // Content
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      switch (_selectedTab) {
                        case 0:
                          return _buildOverviewTab(school, isDark);
                        case 1:
                          return _buildAnnouncementsTab(school, isDark, isAdmin);
                        case 2:
                          return _buildResourcesTab(school, isDark, isAdmin);
                        case 3:
                          return _buildMembersTab(school, isDark, isOwner, isAdmin);
                        default:
                          return const SizedBox();
                      }
                    },
                    childCount: 1,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOverviewTab(SchoolModel school, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick Stats
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Members',
                school.memberIds.length.toString(),
                Icons.people_rounded,
                isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Admins',
                school.adminIds.length.toString(),
                Icons.admin_panel_settings_rounded,
                isDark,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // School Info
        _buildInfoCard(school, isDark),

        const SizedBox(height: 24),

        // Recent Activity (placeholder for now)
        Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppTheme.black,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppTheme.darkCard : AppTheme.lightGray,
            ),
          ),
          child: Center(
            child: Text(
              'No recent activity',
              style: TextStyle(
                color: isDark ? AppTheme.mediumGray : AppTheme.darkGray,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnnouncementsTab(SchoolModel school, bool isDark, bool isAdmin) {
    return Column(
      children: [
        if (isAdmin)
          ElevatedButton.icon(
            onPressed: () => _showCreateAnnouncementDialog(school.id),
            icon: const Icon(Icons.add),
            label: const Text('Create Announcement'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? AppTheme.darkPrimary : AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        const SizedBox(height: 16),
        StreamBuilder<List<SchoolAnnouncementModel>>(
          stream: _schoolService.getSchoolAnnouncements(school.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }

            final announcements = snapshot.data ?? [];
            if (announcements.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.campaign_rounded,
                        size: 48,
                        color: AppTheme.mediumGray,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No announcements yet',
                        style: TextStyle(color: AppTheme.mediumGray),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: announcements.length,
              itemBuilder: (context, index) {
                final announcement = announcements[index];
                return _buildAnnouncementCard(announcement, isDark, isAdmin);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildResourcesTab(SchoolModel school, bool isDark, bool isAdmin) {
    return Column(
      children: [
        if (isAdmin)
          ElevatedButton.icon(
            onPressed: () => _showCreateResourceDialog(school.id),
            icon: const Icon(Icons.add),
            label: const Text('Add Resource'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? AppTheme.darkPrimary : AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        const SizedBox(height: 16),
        StreamBuilder<List<SchoolResourceModel>>(
          stream: _schoolService.getSchoolResources(school.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }

            final resources = snapshot.data ?? [];
            if (resources.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.folder_rounded,
                        size: 48,
                        color: AppTheme.mediumGray,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No resources yet',
                        style: TextStyle(color: AppTheme.mediumGray),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: resources.length,
              itemBuilder: (context, index) {
                final resource = resources[index];
                return _buildResourceCard(resource, isDark, isAdmin);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildMembersTab(
    SchoolModel school,
    bool isDark,
    bool isOwner,
    bool isAdmin,
  ) {
    return FutureBuilder<List<UserModel>>(
      future: _getSchoolMembers(school.memberIds),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        final members = snapshot.data ?? [];
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: members.length,
          itemBuilder: (context, index) {
            final member = members[index];
            final isMemberAdmin = school.adminIds.contains(member.id);
            final isMemberOwner = school.ownerId == member.id;

            return _buildMemberCard(
              member,
              isDark,
              isOwner,
              isAdmin,
              isMemberAdmin,
              isMemberOwner,
              school.id,
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.darkCard : AppTheme.lightGray,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 32,
            color: isDark ? AppTheme.darkPrimary : AppTheme.primaryBlue,
          ),
          const SizedBox(height: 12),
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
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppTheme.mediumGray : AppTheme.darkGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(SchoolModel school, bool isDark) {
    return Container(
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
            'School Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.black,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.location_on, '${school.address}, ${school.city}', isDark),
          _buildInfoRow(Icons.map, '${school.state} ${school.zipCode}', isDark),
          if (school.description != null) ...[
            const SizedBox(height: 12),
            Text(
              school.description!,
              style: TextStyle(
                color: isDark ? AppTheme.mediumGray : AppTheme.darkGray,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isDark ? AppTheme.darkPrimary : AppTheme.primaryBlue,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isDark ? Colors.white : AppTheme.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard(
    SchoolAnnouncementModel announcement,
    bool isDark,
    bool isAdmin,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              Expanded(
                child: Text(
                  announcement.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.black,
                  ),
                ),
              ),
              if (isAdmin)
                IconButton(
                  icon: const Icon(Icons.delete, color: AppTheme.error),
                  onPressed: () => _deleteAnnouncement(announcement.id),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            announcement.content,
            style: TextStyle(
              color: isDark ? AppTheme.mediumGray : AppTheme.darkGray,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'By ${announcement.authorName} • ${_formatDate(announcement.createdAt)}',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.mediumGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceCard(
    SchoolResourceModel resource,
    bool isDark,
    bool isAdmin,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              Icon(
                _getResourceIcon(resource.type),
                color: isDark ? AppTheme.darkPrimary : AppTheme.primaryBlue,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resource.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.black,
                      ),
                    ),
                    Text(
                      resource.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppTheme.mediumGray : AppTheme.darkGray,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.open_in_new),
                color: isDark ? AppTheme.darkPrimary : AppTheme.primaryBlue,
                onPressed: () => _launchUrl(resource.url),
              ),
              if (isAdmin)
                IconButton(
                  icon: const Icon(Icons.delete, color: AppTheme.error),
                  onPressed: () => _deleteResource(resource.id),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(
    UserModel member,
    bool isDark,
    bool isOwner,
    bool isAdmin,
    bool isMemberAdmin,
    bool isMemberOwner,
    String schoolId,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.darkCard : AppTheme.lightGray,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.lightBlue,
            backgroundImage:
                member.photoUrl != null ? NetworkImage(member.photoUrl!) : null,
            child: member.photoUrl == null
                ? Icon(Icons.person, color: AppTheme.primaryBlue)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      member.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.black,
                      ),
                    ),
                    if (isMemberOwner) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Owner',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ] else if (isMemberAdmin) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Admin',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  member.email,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppTheme.mediumGray : AppTheme.darkGray,
                  ),
                ),
              ],
            ),
          ),
          if (isOwner && !isMemberOwner)
            PopupMenuButton(
              itemBuilder: (context) => [
                if (!isMemberAdmin)
                  PopupMenuItem(
                    child: const Text('Make Admin'),
                    onTap: () => _addAdmin(schoolId, member.id),
                  )
                else
                  PopupMenuItem(
                    child: const Text('Remove Admin'),
                    onTap: () => _removeAdmin(schoolId, member.id),
                  ),
                PopupMenuItem(
                  child: const Text('Remove Member'),
                  onTap: () => _removeMember(schoolId, member.id),
                ),
              ],
            ),
        ],
      ),
    );
  }

  IconData _getResourceIcon(String type) {
    switch (type) {
      case 'document':
        return Icons.description_rounded;
      case 'video':
        return Icons.video_library_rounded;
      case 'file':
        return Icons.attach_file_rounded;
      default:
        return Icons.link_rounded;
    }
  }

  Future<List<UserModel>> _getSchoolMembers(List<String> memberIds) async {
    final members = <UserModel>[];
    for (final memberId in memberIds) {
      final user = await _authService.getUserData(memberId);
      if (user != null) {
        members.add(user);
      }
    }
    return members;
  }

  void _showCreateAnnouncementDialog(String schoolId) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Announcement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(
                labelText: 'Content',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty &&
                  contentController.text.isNotEmpty) {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  final userData = await _authService.getUserData(user.uid);
                  final announcement = SchoolAnnouncementModel(
                    id: '',
                    schoolId: schoolId,
                    title: titleController.text,
                    content: contentController.text,
                    authorId: user.uid,
                    authorName: userData?.name ?? 'Unknown',
                    createdAt: DateTime.now(),
                  );
                  await _schoolService.createAnnouncement(announcement);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showCreateResourceDialog(String schoolId) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final urlController = TextEditingController();
    String selectedType = 'link';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Resource'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: 'URL',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'link', child: Text('Link')),
                  DropdownMenuItem(value: 'document', child: Text('Document')),
                  DropdownMenuItem(value: 'video', child: Text('Video')),
                  DropdownMenuItem(value: 'file', child: Text('File')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedType = value);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty &&
                    urlController.text.isNotEmpty) {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    final userData = await _authService.getUserData(user.uid);
                    final resource = SchoolResourceModel(
                      id: '',
                      schoolId: schoolId,
                      title: titleController.text,
                      description: descriptionController.text,
                      url: urlController.text,
                      type: selectedType,
                      uploadedBy: user.uid,
                      uploaderName: userData?.name ?? 'Unknown',
                      uploadedAt: DateTime.now(),
                    );
                    await _schoolService.createResource(resource);
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteAnnouncement(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Announcement'),
        content: const Text('Are you sure you want to delete this announcement?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _schoolService.deleteAnnouncement(id);
    }
  }

  Future<void> _deleteResource(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Resource'),
        content: const Text('Are you sure you want to delete this resource?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _schoolService.deleteResource(id);
    }
  }

  Future<void> _addAdmin(String schoolId, String userId) async {
    await _schoolService.addAdmin(schoolId, userId);
    setState(() {});
  }

  Future<void> _removeAdmin(String schoolId, String userId) async {
    await _schoolService.removeAdmin(schoolId, userId);
    setState(() {});
  }

  Future<void> _removeMember(String schoolId, String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: const Text('Are you sure you want to remove this member?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _schoolService.removeMember(schoolId, userId);
      setState(() {});
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open URL')),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
