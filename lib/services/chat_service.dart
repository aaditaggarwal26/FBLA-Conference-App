import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;

  const ChatMessage({required this.role, required this.content});

  Map<String, String> toJson() => {'role': role, 'content': content};
}

class RegisteredEventContext {
  final String eventName;
  final String schoolName;
  final List<String> participants;
  final int totalParticipants;
  final int totalTeams;
  final List<String> competitorSchools;

  const RegisteredEventContext({
    required this.eventName,
    required this.schoolName,
    required this.participants,
    required this.totalParticipants,
    required this.totalTeams,
    required this.competitorSchools,
  });
}

class ChatService {
  static const _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';
  static const _modelChain = [
    _ModelConfig('nvidia/nemotron-3-nano-30b-a3b:free'),
  ];

  static String _buildSystemPrompt({
    String? userName,
    List<String>? registeredEvents,
    List<RegisteredEventContext>? registeredEventDetails,
  }) {
    final buffer = StringBuffer();
    buffer.writeln(
        'You are an expert FBLA (Future Business Leaders of America) conference assistant for the 2026 WA SBLC (State Business Leadership Conference).');
    buffer.writeln();

    if (userName != null && userName.isNotEmpty) {
      buffer.writeln('The student you are helping is named $userName.');
    }

    if (registeredEventDetails != null && registeredEventDetails.isNotEmpty) {
      buffer.writeln(
          'They are registered for the following events at SBLC 2026:');
      for (final detail in registeredEventDetails) {
        final members = detail.participants.isNotEmpty
            ? detail.participants.join(', ')
            : 'No competitor names available';
        final opponents = detail.competitorSchools.isNotEmpty
            ? detail.competitorSchools.join(', ')
            : 'Competitor schools unavailable';
        buffer.writeln(
            '  - ${detail.eventName} at ${detail.schoolName}: team members $members. Total participants in this event: ${detail.totalParticipants}. Total competing teams: ${detail.totalTeams}. Competitor schools: $opponents.');
      }
      buffer.writeln(
          'When the student asks about their events, focus on these specific registered events and competitors.');
    } else if (registeredEvents != null && registeredEvents.isNotEmpty) {
      buffer.writeln(
          'They are registered for the following events at SBLC 2026:');
      for (final e in registeredEvents) {
        final display = e.contains('::') ? e.split('::').first : e;
        buffer.writeln('  - $display');
      }
      buffer.writeln(
          'When the student asks about their events, focus on these specifically.');
    }

    buffer.writeln();
    buffer.writeln('''Your expertise covers:
- FBLA competitive events: rules, judging criteria, scoring, and preparation tips
- Conference schedule, logistics, and locations
- General FBLA knowledge: chapters, officer positions, and conference professionalism

When asked about event attendance or competitor counts, answer only when the exact number is available from the current event data. If the exact count is unknown, say that the exact number is not available instead of giving a range.

Respond in concise markdown. Use **bold** for key points and tables for comparisons. Keep replies short, avoid long paragraphs, and prefer bullets or numbered steps when helpful.

Always be helpful to students preparing for or attending the WA SBLC 2026 conference.''');
    return buffer.toString();
  }

  String? get _apiKey {
    try {
      return dotenv.env['OPENROUTER_API_KEY'];
    } catch (_) {
      return null;
    }
  }

  bool get isConfigured {
    final key = _apiKey;
    return key != null &&
        key.isNotEmpty &&
        key != 'PASTE_YOUR_OPENROUTER_KEY_HERE';
  }

  Future<String> sendMessage(
    List<ChatMessage> history, {
    String? userName,
    List<String>? registeredEvents,
    List<RegisteredEventContext>? registeredEventDetails,
  }) async {
    final key = _apiKey;
    if (key == null || key.isEmpty || key == 'PASTE_YOUR_OPENROUTER_KEY_HERE') {
      throw Exception(
          'OpenRouter API key not configured. Add your key to the .env file.');
    }

    final messages = [
      {
        'role': 'system',
        'content': _buildSystemPrompt(
          userName: userName,
          registeredEvents: registeredEvents,
          registeredEventDetails: registeredEventDetails,
        )
      },
      ...history.map((m) => m.toJson()),
    ];

    var sawRecoverableFailure = false;

    try {
      for (final model in _modelChain) {
        try {
          return await _callModel(model, messages);
        } on _RetryWithNextModelException {
          sawRecoverableFailure = true;
          continue;
        }
      }
    } on http.ClientException catch (e) {
      throw Exception('Network error: ${e.message}');
    }

    if (sawRecoverableFailure) {
      throw const _TemporaryAiException();
    }

    throw Exception('No AI model produced a response.');
  }

  Future<String> _callModel(
    _ModelConfig model,
    List<Map<String, String>> messages,
  ) async {
    final key = _apiKey;
    if (key == null || key.isEmpty || key == 'PASTE_YOUR_OPENROUTER_KEY_HERE') {
      throw Exception(
          'OpenRouter API key not configured. Add your key to the .env file.');
    }

    final body = <String, dynamic>{
      'model': model.name,
      'messages': messages,
      'max_tokens': 1024,
    };

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $key',
        'Content-Type': 'application/json',
        'HTTP-Referer': 'fbla-conference-app',
        'X-Title': 'FBLA Conference App',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 429) {
      debugPrint('OpenRouter 429 from ${model.name} — trying fallback');
      throw const _RetryWithNextModelException();
    }

    if (response.statusCode != 200) {
      debugPrint(
        'OpenRouter error ${response.statusCode} (${model.name}): ${response.body}',
      );
      throw Exception('API error ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final content = _extractContent(data['choices']?[0]?['message']);
    if (content == null || content.trim().isEmpty) {
      debugPrint('OpenRouter returned no assistant content from ${model.name}');
      throw const _RetryWithNextModelException();
    }
    return content;
  }

  String? _extractContent(dynamic message) {
    if (message is! Map<String, dynamic>) return null;

    final content = message['content'];
    if (content is String && content.trim().isNotEmpty) {
      return content;
    }

    if (content is List) {
      final buffer = StringBuffer();
      for (final part in content) {
        if (part is Map<String, dynamic>) {
          final text = part['text'];
          if (text is String && text.trim().isNotEmpty) {
            if (buffer.isNotEmpty) buffer.writeln();
            buffer.write(text.trim());
          }
        }
      }
      final merged = buffer.toString().trim();
      if (merged.isNotEmpty) {
        return merged;
      }
    }

    return null;
  }
}

class _ModelConfig {
  final String name;

  const _ModelConfig(this.name);
}

class _RetryWithNextModelException implements Exception {
  const _RetryWithNextModelException();
}

class _TemporaryAiException implements Exception {
  const _TemporaryAiException();

  @override
  String toString() =>
      'The AI is temporarily unavailable. Please try again in a few seconds.';
}
