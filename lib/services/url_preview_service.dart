import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;

class URLPreviewData {
  final String url;
  final String? title;
  final String? description;
  final String? imageUrl;

  URLPreviewData({
    required this.url,
    this.title,
    this.description,
    this.imageUrl,
  });
}

class URLPreviewService {
  static final RegExp _urlRegex = RegExp(
    r'https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)',
    caseSensitive: false,
  );

  /// Detects URLs in a message
  static List<String> detectUrls(String text) {
    final matches = _urlRegex.allMatches(text);
    return matches.map((match) => match.group(0)!).toList();
  }

  /// Fetches preview data for a URL
  static Future<URLPreviewData?> fetchPreview(String url) async {
    try {
      final uri = Uri.parse(url);
      final response = await http.get(uri).timeout(
        const Duration(seconds: 5),
      );

      if (response.statusCode != 200) {
        return null;
      }

      final document = html_parser.parse(response.body);

      // Try to get Open Graph metadata first
      String? title = document
          .querySelector('meta[property="og:title"]')
          ?.attributes['content'];
      String? description = document
          .querySelector('meta[property="og:description"]')
          ?.attributes['content'];
      String? imageUrl = document
          .querySelector('meta[property="og:image"]')
          ?.attributes['content'];

      // Fallback to Twitter Card metadata
      title ??= document
          .querySelector('meta[name="twitter:title"]')
          ?.attributes['content'];
      description ??= document
          .querySelector('meta[name="twitter:description"]')
          ?.attributes['content'];
      imageUrl ??= document
          .querySelector('meta[name="twitter:image"]')
          ?.attributes['content'];

      // Final fallback to standard HTML tags
      title ??= document.querySelector('title')?.text;
      description ??=
          document.querySelector('meta[name="description"]')?.attributes[
              'content'];

      return URLPreviewData(
        url: url,
        title: title?.trim(),
        description: description?.trim(),
        imageUrl: imageUrl?.trim(),
      );
    } catch (e) {
      print('Error fetching URL preview: $e');
      return null;
    }
  }

  /// Checks if text contains a URL
  static bool containsUrl(String text) {
    return _urlRegex.hasMatch(text);
  }
}
