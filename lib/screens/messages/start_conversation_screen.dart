import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../../services/message_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/school_badge.dart';
import '../../services/school_service.dart';
import '../messages/chat_screen.dart';

class StartConversationScreen extends StatefulWidget {
  const StartConversationScreen({super.key});

  @override
  State<StartConversationScreen> createState() =>
      _StartConversationScreenState();
}

class _StartConversationScreenState extends State<StartConversationScreen> {
  final _searchController = TextEditingController();
  final MessageService _messageService = MessageService();
  final SchoolService _schoolService = SchoolService();
  List<UserModel> _searchResults = [];
  List<UserModel> _adminUsers = [];
  bool _isSearching = false;
  bool _isLoadingAdmins = true;

  @override
  void initState() {
    super.initState();
    _loadAdmins();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAdmins() async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) {
        setState(() => _isLoadingAdmins = false);
        return;
      }

      final adminsSnapshot = await FirebaseFirestore.instance
          .collection('admins')
          .get();

      final List<UserModel> admins = [];

      for (final adminDoc in adminsSnapshot.docs) {
        final adminId = adminDoc.id;
        if (adminId == currentUserId) continue;

        try {
          final adminUserDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(adminId)
              .get();

          if (adminUserDoc.exists) {
            final adminUser = UserModel.fromFirestore(adminUserDoc);
            admins.add(adminUser);
          }
        } catch (e) {
          // Skip if admin user doc doesn't exist or error
          continue;
        }
      }

      // Sort admins by name
      admins.sort((a, b) => a.name.compareTo(b.name));

      setState(() {
        _adminUsers = admins;
        _isLoadingAdmins = false;
        // Show admins when screen first loads
        _searchResults = admins;
      });
    } catch (e) {
      setState(() => _isLoadingAdmins = false);
    }
  }

  Future<void> _searchUsers(String query) async {
    final queryTrimmed = query.trim();
    
    if (queryTrimmed.isEmpty) {
      // Show admins when search is empty
      setState(() {
        _searchResults = _adminUsers;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;

      final queryLower = queryTrimmed.toLowerCase();
      final Set<String> foundUserIds = {};
      final List<UserModel> matchingAdmins = [];
      final List<UserModel> matchingUsers = [];

      // First, filter admins that match the query
      for (final admin in _adminUsers) {
        if (admin.name.toLowerCase().contains(queryLower) ||
            admin.email.toLowerCase().contains(queryLower)) {
          matchingAdmins.add(admin);
          foundUserIds.add(admin.id);
        }
      }

      // Then search regular users by name
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();

      for (final doc in usersSnapshot.docs) {
        if (doc.id == currentUserId || foundUserIds.contains(doc.id)) {
          continue; // Exclude current user and already found admins
        }
        
        final user = UserModel.fromFirestore(doc);
        if (user.name.toLowerCase().contains(queryLower) ||
            user.email.toLowerCase().contains(queryLower)) {
          matchingUsers.add(user);
          foundUserIds.add(user.id);
        }
      }

      // Sort each list by name
      matchingAdmins.sort((a, b) => a.name.compareTo(b.name));
      matchingUsers.sort((a, b) => a.name.compareTo(b.name));

      // Combine: admins first, then regular users
      final combinedResults = [...matchingAdmins, ...matchingUsers];

      setState(() {
        _searchResults = combinedResults.take(20).toList(); // Limit to 20 results
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching users: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _startConversation(UserModel user) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      // Get or create chat room
      await _messageService.getOrCreateChatRoom(currentUserId, user.id);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              otherUserId: user.id,
              otherUserName: user.name,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting conversation: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.background,
      appBar: AppBar(
        title: const Text('New Message'),
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for people...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchUsers(''); // Show admins again
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: isDark ? AppTheme.darkSurface : Colors.white,
              ),
              onChanged: (value) {
                _searchUsers(value);
              },
            ),
          ),

          // Results
          Expanded(
            child: _isLoadingAdmins || _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty && _searchController.text.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_search_rounded,
                              size: 64,
                              color: AppTheme.mediumGray,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No users found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : AppTheme.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try searching with a different name',
                              style: TextStyle(
                                color: AppTheme.mediumGray,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _searchResults.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 64,
                                  color: AppTheme.mediumGray,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Start a conversation',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        isDark ? Colors.white : AppTheme.black,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Search for someone to message',
                                  style: TextStyle(
                                    color: AppTheme.mediumGray,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final user = _searchResults[index];
                              final isAdmin = _adminUsers.any((admin) => admin.id == user.id);
                              return _buildUserCard(user, isDark, isAdmin: isAdmin);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(UserModel user, bool isDark, {bool isAdmin = false}) {
    return InkWell(
      onTap: () => _startConversation(user),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isAdmin
                ? AppTheme.primaryBlue.withValues(alpha: 0.5)
                : (isDark ? AppTheme.darkCard : AppTheme.lightGray),
            width: isAdmin ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightGray,
                  backgroundImage:
                      user.photoUrl != null && user.photoUrl!.isNotEmpty ? NetworkImage(user.photoUrl!) : null,
                  child: user.photoUrl == null || user.photoUrl!.isEmpty
                      ? Icon(
                          Icons.person,
                          color: isDark ? Colors.white : AppTheme.darkGray,
                          size: 28,
                        )
                      : null,
                ),
                if (isAdmin)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? AppTheme.darkSurface : Colors.white,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings_rounded,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
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
                          user.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppTheme.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isAdmin) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            'Admin',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        ),
                      ],
                      if (user.hasSchool) ...[
                        const SizedBox(width: 6),
                        SchoolBadgeAsync(
                          schoolId: user.schoolId!,
                          fetchSchool: (id) =>
                              _schoolService.getSchool(id),
                          isOwner: user.isSchoolOwner,
                          fontSize: 10,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.mediumGray,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chat_bubble_outline_rounded,
              color: isDark ? AppTheme.darkPrimary : AppTheme.primaryBlue,
            ),
          ],
        ),
      ),
    );
  }
}
