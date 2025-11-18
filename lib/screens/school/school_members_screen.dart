import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../models/school_model.dart';
import '../../services/school_service.dart';

class SchoolMembersScreen extends StatefulWidget {
  final String schoolId;

  const SchoolMembersScreen({
    super.key,
    required this.schoolId,
  });

  @override
  State<SchoolMembersScreen> createState() => _SchoolMembersScreenState();
}

class _SchoolMembersScreenState extends State<SchoolMembersScreen> {
  final _schoolService = SchoolService();
  SchoolModel? _school;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSchool();
  }

  Future<void> _loadSchool() async {
    final school = await _schoolService.getSchool(widget.schoolId);
    if (mounted) {
      setState(() => _school = school);
    }
  }

  Future<void> _addAdminDialog() async {
    final emailController = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add School Admin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'User Email',
                hintText: 'Enter user email',
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'The user must already be a member of your school.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                // Find user by email
                // TODO: Implement user lookup by email
                // final users = await _authService.getUserData(emailController.text.trim());
                // In production, you'd query Firestore by email
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Admin functionality needs email lookup'),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeAdmin(String userId, String userName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Admin'),
        content: Text('Remove $userName as admin? They will become a regular student.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _schoolService.removeAdmin(widget.schoolId, userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Admin removed')),
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
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.offWhite,
      appBar: AppBar(
        title: const Text('School Members'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _addAdminDialog,
            tooltip: 'Add admin',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search members...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: _schoolService.getSchoolMembers(widget.schoolId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No members yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                var members = snapshot.data!;
                if (_searchQuery.isNotEmpty) {
                  members = members.where((m) =>
                    m.name.toLowerCase().contains(_searchQuery) ||
                    m.email.toLowerCase().contains(_searchQuery)
                  ).toList();
                }

                // Sort: admins first
                members.sort((a, b) {
                  if (a.isSchoolAdmin && !b.isSchoolAdmin) return -1;
                  if (!a.isSchoolAdmin && b.isSchoolAdmin) return 1;
                  return a.name.compareTo(b.name);
                });

                return ListView.builder(
                  itemCount: members.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final member = members[index];
                    final isAdmin = _school?.adminIds.contains(member.id) ?? false;
                    final isCurrentUser = member.id == currentUserId;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isAdmin 
                              ? AppTheme.primaryBlue 
                              : AppTheme.mediumGray,
                          child: Text(
                            member.name.isNotEmpty 
                                ? member.name[0].toUpperCase() 
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(child: Text(member.name)),
                            if (isAdmin)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
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
                        ),
                        subtitle: Text(member.email),
                        trailing: isAdmin && !isCurrentUser
                            ? IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () => _removeAdmin(member.id, member.name),
                                color: Colors.red,
                              )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
