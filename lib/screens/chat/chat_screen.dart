import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/parsed_event_model.dart';
import '../../services/chat_service.dart';
import '../../services/event_import_service.dart';
import '../../theme/app_theme.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _history = [];
  bool _isLoading = false;
  String? _userName;
  List<String> _registeredEvents = [];
  final EventImportService _eventImportService = EventImportService();
  List<RegisteredEventContext> _registeredEventDetails = [];

  @override
  void initState() {
    super.initState();
    _loadUserContext();
  }

  Future<void> _loadUserContext() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!mounted) return;
      final data = doc.data();
      final savedEvents = List<String>.from(data?['registeredEvents'] ?? []);
      setState(() {
        _userName = data?['name'] as String? ?? user.displayName;
        _registeredEvents = savedEvents;
      });
      await _loadRegisteredEventDetails(savedEvents);
    } catch (_) {
      // Non-critical — chat still works without context
    }
  }

  Future<void> _loadRegisteredEventDetails(List<String> savedEvents) async {
    try {
      final schedule = await _eventImportService.loadSBLCSchedule();
      if (!mounted) return;

      final byEventName = <String, List<ParsedEventModel>>{};
      for (final event in schedule) {
        byEventName.putIfAbsent(event.eventName, () => []).add(event);
      }

      final details = <RegisteredEventContext>[];
      for (final saved in savedEvents) {
        final parts = saved.split('::');
        final eventName = parts.first.trim();
        final schoolName = parts.length > 1 ? parts.sublist(1).join('::').trim() : '';

        final candidates = schedule.where((event) {
          final sameName = event.eventName == eventName;
          final sameSchool = schoolName.isEmpty ||
              (event.schoolName?.trim() ?? '') == schoolName;
          return sameName && sameSchool;
        }).toList();

        final eventList = byEventName[eventName] ?? [];
        final competitorSchools = eventList
            .map((e) => (e.schoolName ?? '').trim())
            .where((name) => name.isNotEmpty && name != schoolName)
            .toSet()
            .toList();

        if (candidates.isEmpty) {
          details.add(RegisteredEventContext(
            eventName: eventName,
            schoolName: schoolName,
            participants: const [],
            totalParticipants: eventList.fold<int>(0, (sum, e) => sum + e.participants.length),
            totalTeams: competitorSchools.length + (schoolName.isNotEmpty ? 1 : 0),
            competitorSchools: competitorSchools,
          ));
          continue;
        }

        final event = candidates.first;
        details.add(RegisteredEventContext(
          eventName: event.eventName,
          schoolName: event.schoolName ?? schoolName,
          participants: event.participants,
          totalParticipants: event.totalParticipants,
          totalTeams: eventList
              .map((e) => (e.schoolName ?? '').trim())
              .where((name) => name.isNotEmpty)
              .toSet()
              .length,
          competitorSchools: competitorSchools,
        ));
      }

      setState(() {
        _registeredEventDetails = details;
      });
    } catch (_) {
      // Non-critical; chat still works without details
    }
  }

  static const _suggestions = [
    'How do I prepare for a Business Plan event?',
    'What events are judged by interview?',
    'Tips for Public Speaking at SBLC?',
    'What should I wear to the conference?',
    'How does the scoring work for competitive events?',
  ];

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isLoading) return;

    _inputController.clear();
    setState(() {
      _history.add(ChatMessage(role: 'user', content: trimmed));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final reply = await _chatService.sendMessage(
        _history,
        userName: _userName,
        registeredEvents: _registeredEvents.isEmpty ? null : _registeredEvents,
        registeredEventDetails: _registeredEventDetails.isEmpty
            ? null
            : _registeredEventDetails,
      );
      if (mounted) {
        setState(() {
          _history.add(ChatMessage(role: 'assistant', content: reply));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceAll('Exception: ', '');
        setState(() {
          _history.add(ChatMessage(role: 'assistant', content: msg));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor:
          isDark ? AppTheme.darkBackground : AppTheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor:
            isDark ? AppTheme.darkBackground : AppTheme.background,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : AppTheme.black,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF58A6FF), Color(0xFF79C0FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FBLA Assistant',
                  style: TextStyle(
                    color: isDark ? Colors.white : AppTheme.black,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Powered by OpenRouter',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.45)
                        : AppTheme.mediumGray,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              icon: Icon(Icons.restart_alt_rounded,
                  color: isDark ? Colors.white70 : AppTheme.darkGray),
              tooltip: 'New conversation',
              onPressed: () => setState(() => _history.clear()),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _history.isEmpty
                ? _buildEmptyState(isDark)
                : ListView.builder(
                    controller: _scrollController,
                    padding:
                        const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount:
                        _history.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _history.length) {
                        return _buildTypingIndicator(isDark);
                      }
                      return _buildBubble(_history[index], isDark);
                    },
                  ),
          ),
          _buildInputBar(isDark),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF58A6FF), Color(0xFF79C0FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 40),
          ),
          const SizedBox(height: 20),
          Text(
            'FBLA Conference Assistant',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppTheme.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Ask me anything about FBLA events,\nprep strategies, or the WA SBLC 2026 conference.',
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.5)
                  : AppTheme.mediumGray,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Try asking…',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.4)
                    : Colors.grey[500],
              ),
            ),
          ),
          const SizedBox(height: 10),
          ..._suggestions.map((s) => _buildSuggestionChip(s, isDark)),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text, bool isDark) {
    return GestureDetector(
      onTap: () => _send(text),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF21262D) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? const Color(0xFF30363D)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.chat_bubble_outline_rounded,
                size: 15,
                color: isDark
                    ? const Color(0xFF58A6FF)
                    : AppTheme.primaryBlue),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? const Color(0xFFE6EDF3)
                      : const Color(0xFF374151),
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 12,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.3)
                    : Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(ChatMessage msg, bool isDark) {
    final isUser = msg.role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF58A6FF), Color(0xFF79C0FF)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 14),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? (isDark
                        ? const Color(0xFF1F6FEB)
                        : AppTheme.primaryBlue)
                    : (isDark
                        ? const Color(0xFF21262D)
                        : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser
                    ? null
                    : Border.all(
                        color: isDark
                            ? const Color(0xFF30363D)
                            : const Color(0xFFE5E7EB)),
              ),
              child: isUser
                  ? Text(
                      msg.content,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Colors.white,
                      ),
                    )
                  : MarkdownBody(
                      data: msg.content,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: isDark
                              ? const Color(0xFFE6EDF3)
                              : const Color(0xFF1A1D26),
                        ),
                        strong: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1A1D26),
                        ),
                        em: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: isDark
                              ? const Color(0xFFE6EDF3)
                              : const Color(0xFF1A1D26),
                        ),
                        h1: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF1A1D26),
                        ),
                        h2: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF1A1D26),
                        ),
                        tableHead: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF1A1D26),
                        ),
                        tableBody: TextStyle(
                          fontSize: 14,
                          color: isDark ? const Color(0xFFE6EDF3) : const Color(0xFF1A1D26),
                        ),
                      ),
                    ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF58A6FF), Color(0xFF79C0FF)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 14),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF21262D) : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF30363D)
                    : const Color(0xFFE5E7EB),
              ),
            ),
            child: const _TypingDots(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFE5E7EB),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              enabled: !_isLoading,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: _send,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : AppTheme.black,
              ),
              decoration: InputDecoration(
                hintText: 'Ask about FBLA events or the conference…',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.35)
                      : Colors.grey[400],
                ),
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF0D1117)
                    : const Color(0xFFF9FAFB),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: isDark
                        ? const Color(0xFF30363D)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: isDark
                        ? const Color(0xFF30363D)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: isDark
                        ? const Color(0xFF58A6FF)
                        : AppTheme.primaryBlue,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _isLoading
                ? null
                : () => _send(_inputController.text),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: _isLoading
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFF58A6FF), Color(0xFF1F6FEB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                color: _isLoading
                    ? (isDark
                        ? const Color(0xFF30363D)
                        : Colors.grey[200])
                    : null,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                Icons.arrow_upward_rounded,
                color: _isLoading ? Colors.grey : Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (_controller.value * 3 - i).clamp(0.0, 1.0);
            final opacity = (phase < 0.5 ? phase * 2 : (1 - phase) * 2)
                .clamp(0.3, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF58A6FF),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
