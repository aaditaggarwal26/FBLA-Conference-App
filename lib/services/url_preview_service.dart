import 'package:metadata_fetch/metadata_fetch.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class URLPreviewService {
  // Cache for URL metadata to avoid repeated fetches
  static final Map<String, URLMetadata?> _cache = {};

  /// Extract URLs from text
  static List<String> extractUrls(String text) {
    final urlPattern = RegExp(
      r'https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)',
      caseSensitive: false,
    );
    
    final matches = urlPattern.allMatches(text);
    return matches.map((match) => match.group(0)!).toList();
  }

  /// Fetch metadata for a URL
  static Future<URLMetadata?> getMetadata(String url) async {
    // Check cache first
    if (_cache.containsKey(url)) {
      return _cache[url];
    }

    try {
      final data = await MetadataFetch.extract(url).timeout(const Duration(seconds: 5));
      
      final metadata = URLMetadata(
        url: url,
        title: data?.title ?? '',
        description: data?.description ?? '',
        image: data?.image ?? '',
        siteName: data?.url ?? '',
      );
      
      _cache[url] = metadata;
      return metadata;
    } catch (e) {
      print('Error fetching URL metadata: $e');
      _cache[url] = null;
      return null;
    }
  }

  /// Clear cache
  static void clearCache() {
    _cache.clear();
  }

  /// Open URL in browser
  static Future<void> openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class URLMetadata {
  final String url;
  final String title;
  final String description;
  final String image;
  final String siteName;

  URLMetadata({
    required this.url,
    required this.title,
    required this.description,
    required this.image,
    required this.siteName,
  });

  bool get hasImage => image.isNotEmpty;
  bool get hasTitle => title.isNotEmpty;
  bool get hasDescription => description.isNotEmpty;
}

/// URL Preview Card Widget
class URLPreviewCard extends StatefulWidget {
  final String url;
  final VoidCallback? onClose;

  const URLPreviewCard({
    super.key,
    required this.url,
    this.onClose,
  });

  @override
  State<URLPreviewCard> createState() => _URLPreviewCardState();
}

class _URLPreviewCardState extends State<URLPreviewCard> {
  URLMetadata? _metadata;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    final metadata = await URLPreviewService.getMetadata(widget.url);
    if (mounted) {
      setState(() {
        _metadata = metadata;
        _isLoading = false;
        _hasError = metadata == null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 16),
              Text(
                'Loading preview...',
                style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    if (_hasError || _metadata == null) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: InkWell(
          onTap: () => URLPreviewService.openUrl(widget.url),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.link, color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.url,
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      decoration: TextDecoration.underline,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: widget.onClose,
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => URLPreviewService.openUrl(widget.url),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_metadata!.hasImage)
              Image.network(
                _metadata!.image,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: double.infinity,
                  height: 180,
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                  child: Icon(
                    Icons.broken_image,
                    size: 60,
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_metadata!.siteName.isNotEmpty)
                    Text(
                      _metadata!.siteName,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  if (_metadata!.siteName.isNotEmpty) const SizedBox(height: 4),
                  if (_metadata!.hasTitle)
                    Text(
                      _metadata!.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (_metadata!.hasDescription) ...[
                    const SizedBox(height: 8),
                    Text(
                      _metadata!.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.open_in_new,
                        size: 14,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _metadata!.url,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).primaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.onClose != null)
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: widget.onClose,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
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
}

/// Compact URL Preview (for chat bubbles)
class CompactURLPreview extends StatelessWidget {
  final String url;
  final URLMetadata? metadata;

  const CompactURLPreview({
    super.key,
    required this.url,
    this.metadata,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => URLPreviewService.openUrl(url),
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            if (metadata?.hasImage ?? false)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  metadata!.image,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 50,
                    height: 50,
                    color: isDark ? Colors.grey[700] : Colors.grey[300],
                    child: Icon(Icons.link, size: 24, color: Colors.grey[500]),
                  ),
                ),
              )
            else
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  Icons.link,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (metadata?.hasTitle ?? false)
                    Text(
                      metadata!.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    Text(
                      url,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).primaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 2),
                  Text(
                    Uri.parse(url).host,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.open_in_new,
              size: 18,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }
}
