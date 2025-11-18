import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/url_preview_service.dart';
import '../theme/app_theme.dart';

class CompactURLPreview extends StatelessWidget {
  final URLPreviewData previewData;
  final bool isFromCurrentUser;

  const CompactURLPreview({
    super.key,
    required this.previewData,
    required this.isFromCurrentUser,
  });

  Future<void> _launchUrl() async {
    final Uri url = Uri.parse(previewData.url);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      print('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasImage = previewData.imageUrl != null &&
        previewData.imageUrl!.isNotEmpty;
    final hasTitle = previewData.title != null &&
        previewData.title!.isNotEmpty;
    final hasDescription = previewData.description != null &&
        previewData.description!.isNotEmpty;

    // Don't show preview if no metadata is available
    if (!hasImage && !hasTitle && !hasDescription) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: isFromCurrentUser
            ? Colors.white.withValues(alpha: 0.2)
            : (isDark
                  ? AppTheme.darkCard.withValues(alpha: 0.5)
                  : AppTheme.lightGray.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFromCurrentUser
              ? Colors.white.withValues(alpha: 0.3)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : AppTheme.mediumGray.withValues(alpha: 0.2)),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _launchUrl,
          borderRadius: BorderRadius.circular(12),
          child: hasImage
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: Image.network(
                        previewData.imageUrl!,
                        width: double.infinity,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox.shrink(),
                      ),
                    ),
                    // Text content
                    if (hasTitle || hasDescription)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (hasTitle) ...[
                              Text(
                                previewData.title!,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isFromCurrentUser
                                      ? Colors.white
                                      : (isDark
                                            ? Colors.white
                                            : AppTheme.black),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            if (hasDescription) ...[
                              const SizedBox(height: 4),
                              Text(
                                previewData.description!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isFromCurrentUser
                                      ? Colors.white.withValues(alpha: 0.8)
                                      : (isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.7,
                                              )
                                            : AppTheme.darkGray),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                )
              : Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasTitle) ...[
                        Text(
                          previewData.title!,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isFromCurrentUser
                                ? Colors.white
                                : (isDark ? Colors.white : AppTheme.black),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (hasDescription) ...[
                        const SizedBox(height: 4),
                        Text(
                          previewData.description!,
                          style: TextStyle(
                            fontSize: 11,
                            color: isFromCurrentUser
                                ? Colors.white.withValues(alpha: 0.8)
                                : (isDark
                                      ? Colors.white.withValues(alpha: 0.7)
                                      : AppTheme.darkGray),
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.link_rounded,
                            size: 12,
                            color: isFromCurrentUser
                                ? Colors.white.withValues(alpha: 0.7)
                                : (isDark
                                      ? AppTheme.darkPrimary
                                      : AppTheme.primaryBlue),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              Uri.parse(previewData.url).host,
                              style: TextStyle(
                                fontSize: 10,
                                color: isFromCurrentUser
                                    ? Colors.white.withValues(alpha: 0.7)
                                    : (isDark
                                          ? AppTheme.darkPrimary
                                          : AppTheme.primaryBlue),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
