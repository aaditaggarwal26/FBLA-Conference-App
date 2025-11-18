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
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);

    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;

      // Search by name (case-insensitive)
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: '${query}z')
          .limit(20)
          .get();

      final users = snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .where((user) => user.id != currentUserId) // Exclude current user
          .toList();

      setState(() {
        _searchResults = users;
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
                          setState(() => _searchResults = []);
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
            child: _isSearching
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
                              return _buildUserCard(user, isDark);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(UserModel user, bool isDark) {
    return InkWell(
      onTap: () => _startConversation(user),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppTheme.darkCard : AppTheme.lightGray,
          ),
        ),
        child: Row(
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
