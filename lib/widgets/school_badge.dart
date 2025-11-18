import 'package:flutter/material.dart';
import '../models/school_model.dart';
import '../theme/app_theme.dart';

class SchoolBadge extends StatelessWidget {
  final SchoolModel school;
  final bool isOwner;
  final double fontSize;
  final EdgeInsets padding;

  const SchoolBadge({
    super.key,
    required this.school,
    this.isOwner = false,
    this.fontSize = 10,
    this.padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        _showSchoolInfo(context);
      },
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: isOwner
              ? AppTheme.gold.withValues(alpha: 0.2)
              : (isDark ? AppTheme.darkPrimary : AppTheme.primaryBlue)
                  .withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isOwner
                ? AppTheme.gold
                : (isDark ? AppTheme.darkPrimary : AppTheme.primaryBlue),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isOwner) ...[
              Icon(
                Icons.verified_rounded,
                size: fontSize + 2,
                color: AppTheme.gold,
              ),
              const SizedBox(width: 2),
            ],
            Text(
              school.abbreviation,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: isOwner
                    ? AppTheme.gold
                    : (isDark ? AppTheme.darkPrimary : AppTheme.primaryBlue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSchoolInfo(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.school_rounded,
              color: isDark ? AppTheme.darkPrimary : AppTheme.primaryBlue,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                school.name,
                style: TextStyle(
                  color: isDark ? Colors.white : AppTheme.black,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (school.city.isNotEmpty && school.state.isNotEmpty) ...[
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: AppTheme.mediumGray,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${school.city}, ${school.state}',
                    style: TextStyle(
                      color: isDark ? AppTheme.mediumGray : AppTheme.darkGray,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (school.description != null && school.description!.isNotEmpty) ...[
              Text(
                school.description!,
                style: TextStyle(
                  color: isDark ? AppTheme.mediumGray : AppTheme.darkGray,
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Icon(
                  Icons.people_rounded,
                  size: 16,
                  color: AppTheme.mediumGray,
                ),
                const SizedBox(width: 4),
                Text(
                  '${school.memberIds.length} ${school.memberIds.length == 1 ? 'student' : 'students'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.mediumGray,
                  ),
                ),
              ],
            ),
            if (isOwner) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      size: 16,
                      color: AppTheme.gold,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'School Owner',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.gold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Async version that fetches school data by ID
class SchoolBadgeAsync extends StatelessWidget {
  final String schoolId;
  final bool isOwner;
  final double fontSize;
  final EdgeInsets padding;
  final Future<SchoolModel?> Function(String) fetchSchool;

  const SchoolBadgeAsync({
    super.key,
    required this.schoolId,
    required this.fetchSchool,
    this.isOwner = false,
    this.fontSize = 10,
    this.padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SchoolModel?>(
      future: fetchSchool(schoolId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: 40,
            height: 16,
            child: Center(
              child: SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 1.5),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        return SchoolBadge(
          school: snapshot.data!,
          isOwner: isOwner,
          fontSize: fontSize,
          padding: padding,
        );
      },
    );
  }
}
