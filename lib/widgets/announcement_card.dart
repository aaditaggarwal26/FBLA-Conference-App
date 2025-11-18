import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/announcement_model.dart';
import '../theme/app_theme.dart';

class AnnouncementCard extends StatelessWidget {
  final AnnouncementModel announcement;

  const AnnouncementCard({
    super.key,
    required this.announcement,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSchoolAnnouncement = announcement.isSchool;
    
    // Different colors for school vs national announcements
    final accentColor = isSchoolAnnouncement 
        ? const Color(0xFF8B5CF6) // Purple for school
        : const Color(0xFF3B82F6); // Blue for national
    
    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSchoolAnnouncement
              ? accentColor.withValues(alpha: 0.3)
              : (isDark ? AppTheme.darkCard : AppTheme.lightGray).withValues(alpha: 0.5),
          width: isSchoolAnnouncement ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSchoolAnnouncement
                ? accentColor.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
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
            // School announcement banner
            if (isSchoolAnnouncement)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accentColor.withValues(alpha: 0.9),
                      accentColor,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.school_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'School Announcement',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            
            // Image if available
            if (announcement.imageUrl != null && announcement.imageUrl!.isNotEmpty)
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
                  // Gradient overlay for pinned badge
                  if (announcement.isPinned)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category and Time
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(announcement.category).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _getCategoryColor(announcement.category).withValues(alpha: 0.3),
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
                      const Spacer(),
                      Icon(
                        Icons.schedule_rounded,
                        size: 13,
                        color: isDark ? Colors.white.withValues(alpha: 0.5) : AppTheme.mediumGray,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM d, h:mm a').format(announcement.postedAt),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white.withValues(alpha: 0.5) : AppTheme.mediumGray,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Title
                  Text(
                    announcement.title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppTheme.black,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Content
                  Text(
                    announcement.content,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: isDark ? Colors.white.withValues(alpha: 0.7) : AppTheme.darkGray,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 12),

                  // Footer
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
                        child: Text(
                          announcement.postedBy[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          announcement.postedBy,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white.withValues(alpha: 0.6) : AppTheme.darkGray,
                          ),
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
        return AppTheme.primaryBlue;
      case 'reminder':
        return AppTheme.warning;
      case 'general':
      default:
        return AppTheme.success;
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
}
