import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/announcement_model.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import '../services/message_service.dart';
import '../services/linkedin_service.dart';
import '../screens/messages/chat_screen.dart';

class AnnouncementCard extends StatefulWidget {
  final AnnouncementModel announcement;

  const AnnouncementCard({super.key, required this.announcement});

  @override
  State<AnnouncementCard> createState() => _AnnouncementCardState();
}

class _AnnouncementCardState extends State<AnnouncementCard> {
  bool _isExpanded = false;
  final MessageService _messageService = MessageService();
  final LinkedInService _linkedInService = LinkedInService();
  bool _isSharingToLinkedIn = false;

  @override
  Widget build(BuildContext context) {
    final announcement = widget.announcement;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryBlue.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image if available
            if (announcement.imageUrl != null &&
                announcement.imageUrl!.isNotEmpty)
              Stack(
                children: [
                  Image.network(
                    announcement.imageUrl!,
                    width: double.infinity,
                    height: 160,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const SizedBox.shrink();
                    },
                  ),
                  // Pinned badge on image
                  if (announcement.isPinned)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.warning.withValues(alpha: 0.8),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.push_pin_rounded,
                              size: 14,
                              color: AppTheme.warning,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Pinned',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row with category, pinned badge, and time
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(
                            announcement.category,
                          ).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _getCategoryColor(
                              announcement.category,
                            ).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getCategoryIcon(announcement.category),
                              size: 12,
                              color: _getCategoryColor(announcement.category),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              announcement.category,
                              style: TextStyle(
                                color: _getCategoryColor(announcement.category),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (announcement.isPinned &&
                          announcement.imageUrl == null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.warning.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppTheme.warning.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.push_pin_rounded,
                                size: 12,
                                color: AppTheme.warning,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Pinned',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.warning,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const Spacer(),
                      Icon(
                        Icons.access_time_rounded,
                        size: 13,
                        color: isDark ? AppTheme.mediumGray : AppTheme.darkGray,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat(
                          'MMM d, h:mm a',
                        ).format(announcement.postedAt),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppTheme.mediumGray
                              : AppTheme.darkGray,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Title
                  Text(
                    announcement.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppTheme.black,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Content with expand/collapse
                  Builder(
                    builder: (context) {
                      final shouldShowExpand =
                          announcement.content.length > 150;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            announcement.content,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.7)
                                  : AppTheme.darkGray,
                            ),
                            maxLines: _isExpanded ? null : 3,
                            overflow: _isExpanded
                                ? null
                                : TextOverflow.ellipsis,
                          ),
                          if (shouldShowExpand) ...[
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isExpanded = !_isExpanded;
                                });
                              },
                              child: Text(
                                _isExpanded ? 'Show less' : 'Show more',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 14),

                  // Footer with author and chat button
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppTheme.primaryBlue.withValues(
                          alpha: 0.1,
                        ),
                        child: Text(
                          announcement.postedBy.isNotEmpty
                              ? announcement.postedBy[0].toUpperCase()
                              : 'A',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Posted by',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.5)
                                    : AppTheme.mediumGray,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              announcement.postedBy,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.8)
                                    : AppTheme.darkGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => _openChatWithPoster(context),
                        icon: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 16,
                        ),
                        label: const Text('Chat'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryBlue,
                          side: BorderSide(color: AppTheme.primaryBlue),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          minimumSize: const Size(0, 32),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _isSharingToLinkedIn
                            ? null
                            : _shareToLinkedIn,
                        icon: _isSharingToLinkedIn
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.business_rounded, size: 16),
                        label: const Text('Share'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0077B5),
                          side: const BorderSide(color: Color(0xFF0077B5)),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          minimumSize: const Size(0, 32),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'important':
        return AppTheme.error;
      case 'event':
        return AppTheme.success;
      case 'reminder':
        return AppTheme.warning;
      case 'general':
      default:
        return AppTheme.primaryBlue;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'important':
        return Icons.error_rounded;
      case 'event':
        return Icons.event_rounded;
      case 'reminder':
        return Icons.notifications_active_rounded;
      case 'general':
      default:
        return Icons.info_rounded;
    }
  }

  Future<void> _openChatWithPoster(BuildContext context) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to start a chat'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Search for user by name (postedBy)
      final postedByName = widget.announcement.postedBy;

      // First, try to find user by exact name match
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('name', isEqualTo: postedByName)
          .limit(1)
          .get();

      String? targetUserId;
      String? targetUserName;

      if (usersSnapshot.docs.isNotEmpty) {
        final user = UserModel.fromFirestore(usersSnapshot.docs.first);
        targetUserId = user.id;
        targetUserName = user.name;
      } else {
        // If not found, search admins collection
        final adminsSnapshot = await FirebaseFirestore.instance
            .collection('admins')
            .get();

        for (final adminDoc in adminsSnapshot.docs) {
          final adminId = adminDoc.id;
          final adminData = adminDoc.data();
          final adminEmail = adminData['email'] ?? '';

          // Try to get user data for this admin
          final adminUserDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(adminId)
              .get();

          if (adminUserDoc.exists) {
            final adminUser = UserModel.fromFirestore(adminUserDoc);
            // Check if name or email matches
            if (adminUser.name == postedByName ||
                adminEmail.contains(postedByName)) {
              targetUserId = adminUser.id;
              targetUserName = adminUser.name;
              break;
            }
          } else if (adminEmail.contains(postedByName)) {
            // If user doc doesn't exist but email matches, use admin ID
            targetUserId = adminId;
            targetUserName = postedByName;
            break;
          }
        }
      }

      if (!mounted) return;

      Navigator.pop(context); // Close loading dialog

      if (targetUserId == null || targetUserId == currentUserId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not find user to chat with'),
            backgroundColor: AppTheme.warning,
          ),
        );
        return;
      }

      // Store in non-nullable variable for flow analysis
      final userId = targetUserId;
      final userName = targetUserName ?? postedByName;

      // Get or create chat room
      await _messageService.getOrCreateChatRoom(currentUserId, userId);

      // Navigate to chat screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ChatScreen(otherUserId: userId, otherUserName: userName),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening chat: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _shareToLinkedIn() async {
    final isConnected = await _linkedInService.isConnected();

    if (!isConnected) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please connect LinkedIn in Profile settings first'),
            backgroundColor: AppTheme.warning,
          ),
        );
      }
      return;
    }

    setState(() => _isSharingToLinkedIn = true);

    try {
      final success = await _linkedInService.shareAnnouncement(
        title: widget.announcement.title,
        content: widget.announcement.content,
        context: context,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Announcement shared on LinkedIn!'
                  : 'Failed to share on LinkedIn',
            ),
            backgroundColor: success ? AppTheme.success : AppTheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing to LinkedIn: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharingToLinkedIn = false);
      }
    }
  }
}
