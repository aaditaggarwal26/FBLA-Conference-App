import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/parsed_event_model.dart';
import '../../services/event_import_service.dart';
import 'nccc_event_group_page.dart';

class NCCCEventDetailScreen extends StatefulWidget {
  final String schoolId;
  final String? currentUserName;

  const NCCCEventDetailScreen({
    super.key,
    required this.schoolId,
    this.currentUserName,
  });

  @override
  State<NCCCEventDetailScreen> createState() => _NCCCEventDetailScreenState();
}

class _NCCCEventDetailScreenState extends State<NCCCEventDetailScreen> {
  final EventImportService _eventService = EventImportService();
  late Future<List<ParsedEventModel>> _stateEventsFuture;
  late Future<List<ParsedEventModel>> _finalsEventsFuture;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedEvent;
  bool _showOnlyMyEvents = false;
  bool _hasPromptedClaim = false;
  int _selectedScheduleIndex = 0;

  static const _darkBg = Color(0xFF0D1117);
  static const _darkSurface = Color(0xFF161B22);
  static const _darkCard = Color(0xFF21262D);
  static const _darkInput = Color(0xFF30363D);
  static const _darkBorder = Color(0xFF30363D);
  static const _darkTextPrimary = Color(0xFFE6EDF3);
  static const _darkTextSecondary = Color(0xFF8B949E);
  static const _darkAccent = Color(0xFF58A6FF);

  @override
  void initState() {
    super.initState();
    _stateEventsFuture = _eventService.loadSBLCSchedule();
    _finalsEventsFuture = _eventService.loadFinalsSchedule();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Word-boundary name matching: all search name words must appear as exact
  // words in the participant string. Prevents "John" matching "Johnson".
  bool _nameMatches(String participant, String searchName) {
    final pWords = participant.toLowerCase().split(RegExp(r'\s+'));
    final sWords = searchName.toLowerCase().trim().split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (sWords.isEmpty) return false;
    return sWords.every((sw) => pWords.any((pw) => pw == sw));
  }

  Future<bool> _claimAlreadyShown() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return true;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('sblc_claim_shown_$uid') ?? false;
  }

  Future<void> _markClaimShown() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sblc_claim_shown_$uid', true);
  }

  void _onEventsLoaded(List<ParsedEventModel> events) {
    if (_hasPromptedClaim || !mounted || widget.currentUserName == null) return;
    _hasPromptedClaim = true;

    _claimAlreadyShown().then((alreadyShown) {
      if (alreadyShown || !mounted) return;
      final myEvents = events
          .where((e) => e.participants.any((p) => _nameMatches(p, widget.currentUserName!)))
          .toList();
      if (myEvents.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showEventClaimDialog(myEvents);
        });
      }
    });
  }

  Future<void> _showEventClaimDialog(List<ParsedEventModel> events) async {
    await _markClaimShown();
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.event_available, color: Colors.green),
            SizedBox(width: 12),
            Expanded(child: Text('Your Events Found!')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Found ${events.length} event${events.length == 1 ? "" : "s"} with "${widget.currentUserName}":',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: events.map((event) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle, size: 16, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(event.eventName,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              Text(
                                '${event.schoolName ?? ""} \u00b7 ${event.location}',
                                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Add these to your profile to receive reminders?',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No Thanks'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('Add to Profile'),
          ),
        ],
      ),
    );
    if (result == true && mounted) {
      await _claimEvents(events);
    }
  }

  Future<void> _claimEvents(List<ParsedEventModel> events) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return;
      final current = List<String>.from(userDoc.data()?['registeredEvents'] ?? []);
      final newIds = events.map((e) => '${e.eventName}::${e.schoolName ?? ""}').toSet();
      final updated = {...current, ...newIds}.toList();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'registeredEvents': updated});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('\u2705 Added ${events.length} event${events.length == 1 ? "" : "s"} to your profile!'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not save: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  void _showStatisticsDialog(List<ParsedEventModel> events) {
    final schools = events.map((e) => e.schoolName ?? 'Unknown').toSet();
    final dates = events
        .map((e) => DateTime(e.startTime.year, e.startTime.month, e.startTime.day))
        .toSet()
        .toList()
      ..sort();
    final eventTypes = <String, int>{};
    for (final e in events) {
      eventTypes[e.eventName] = (eventTypes[e.eventName] ?? 0) + 1;
    }
    final sorted = eventTypes.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('FBLA State 2026 Stats'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _statRow('Total Entries', '${events.length}'),
              _statRow('Unique Events', '${eventTypes.length}'),
              _statRow('Schools Competing', '${schools.length}'),
              _statRow('Days', '${dates.length}'),
              const Divider(height: 24),
              const Text('Top Events:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...sorted.take(10).map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(entry.key, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
                    Text('${entry.value}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  List<ParsedEventModel> _filterEvents(List<ParsedEventModel> events) {
    var filtered = events;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((e) =>
        (e.schoolName ?? '').toLowerCase().contains(q) ||
        e.eventName.toLowerCase().contains(q) ||
        e.participants.any((p) => p.toLowerCase().contains(q))
      ).toList();
    }
    if (_selectedEvent != null) {
      filtered = filtered.where((e) => e.eventName == _selectedEvent).toList();
    }
    if (_showOnlyMyEvents && widget.currentUserName != null) {
      filtered = filtered
          .where((e) => e.participants.any((p) => _nameMatches(p, widget.currentUserName!)))
          .toList();
    }
    return filtered;
  }

  bool _isMyEvent(ParsedEventModel event) {
    if (widget.currentUserName == null) return false;
    return event.participants.any((p) => _nameMatches(p, widget.currentUserName!));
  }

  Color _getEventColor(String eventName) {
    final lower = eventName.toLowerCase();
    if (lower.contains('coding') || lower.contains('programming') || lower.contains('website') ||
        lower.contains('mobile') || lower.contains('computer') || lower.contains('data')) {
      return Colors.blue;
    }
    if (lower.contains('design') || lower.contains('animation') || lower.contains('visual')) {
      return Colors.purple;
    }
    if (lower.contains('business') || lower.contains('financial') || lower.contains('management') ||
        lower.contains('marketing') || lower.contains('accounting')) {
      return Colors.green;
    }
    if (lower.contains('speaking') || lower.contains('presentation') || lower.contains('debate')) {
      return Colors.orange;
    }
    return const Color(0xFF001231);
  }

  IconData _getEventIcon(String eventName) {
    final lower = eventName.toLowerCase();
    if (lower.contains('coding') || lower.contains('programming')) return Icons.code;
    if (lower.contains('website')) return Icons.web;
    if (lower.contains('mobile')) return Icons.phone_android;
    if (lower.contains('visual') || lower.contains('design')) return Icons.design_services;
    if (lower.contains('animation')) return Icons.animation;
    if (lower.contains('marketing')) return Icons.campaign;
    if (lower.contains('business') || lower.contains('management')) return Icons.business_center;
    if (lower.contains('financial') || lower.contains('accounting')) return Icons.attach_money;
    if (lower.contains('speaking')) return Icons.mic;
    if (lower.contains('presentation')) return Icons.present_to_all;
    return Icons.event;
  }

  Future<List<ParsedEventModel>> get _activeEventsFuture {
    return _selectedScheduleIndex == 0 ? _stateEventsFuture : _finalsEventsFuture;
  }

  String get _activeScheduleLabel {
    return _selectedScheduleIndex == 0 ? 'FBLA State' : 'Finals';
  }

  void _switchSchedule(int index) {
    if (_selectedScheduleIndex == index) return;
    setState(() {
      _selectedScheduleIndex = index;
      _selectedEvent = null;
      _hasPromptedClaim = false;
    });
  }

  void _reloadActiveSchedule() {
    setState(() {
      if (_selectedScheduleIndex == 0) {
        _stateEventsFuture = _eventService.loadSBLCSchedule();
      } else {
        _finalsEventsFuture = _eventService.loadFinalsSchedule();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? _darkBg : const Color(0xFFF5F6FA);
    final surfaceColor = isDark ? _darkSurface : Colors.white;
    final cardColor = isDark ? _darkCard : Colors.white;
    final inputColor = isDark ? _darkInput : const Color(0xFFEEF0F5);
    final textPrimary = isDark ? _darkTextPrimary : const Color(0xFF1A1D26);
    final textSecondary = isDark ? _darkTextSecondary : const Color(0xFF6B7280);
    final accent = isDark ? _darkAccent : const Color(0xFF4A90E2);
    final divider = isDark ? _darkBorder : const Color(0xFFE5E7EB);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Results',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: surfaceColor,
        iconTheme: IconThemeData(color: textPrimary),
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: divider),
        ),
        actions: [
          if (widget.currentUserName != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: IconButton(
                icon: Icon(
                  _showOnlyMyEvents ? Icons.person_rounded : Icons.person_outline_rounded,
                  color: _showOnlyMyEvents ? Colors.amber : textSecondary,
                ),
                tooltip: 'My events only',
                onPressed: () => setState(() => _showOnlyMyEvents = !_showOnlyMyEvents),
              ),
            ),
        ],
      ),
      body: FutureBuilder<List<ParsedEventModel>>(
        future: _activeEventsFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline_rounded, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text('Failed to load schedule',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)),
                    const SizedBox(height: 8),
                    Text('${snapshot.error}',
                        style: TextStyle(fontSize: 12, color: textSecondary), textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _reloadActiveSchedule,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                      style: FilledButton.styleFrom(backgroundColor: accent),
                    ),
                  ],
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: accent, strokeWidth: 2.5),
                  const SizedBox(height: 20),
                  Text('Loading ${_activeScheduleLabel.toLowerCase()} schedule\u2026',
                      style: TextStyle(color: textSecondary, fontSize: 14)),
                ],
              ),
            );
          }

          final allEvents = snapshot.data ?? [];
          _onEventsLoaded(allEvents);

          final uniqueEventNames =
              allEvents.map((e) => e.eventName).toSet().toList()..sort();
          final filteredEvents = _filterEvents(allEvents);
          final groupedEvents = <String, List<ParsedEventModel>>{};
          for (final event in filteredEvents) {
            groupedEvents.putIfAbsent(event.eventName, () => []).add(event);
          }
          final sortedKeys = groupedEvents.keys.toList()..sort();

          return Column(
            children: [
              Container(
                color: surfaceColor,
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: inputColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: divider),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _scheduleTab(
                          label: 'FBLA State',
                          selected: _selectedScheduleIndex == 0,
                          accent: accent,
                          textSecondary: textSecondary,
                          onTap: () => _switchSchedule(0),
                        ),
                      ),
                      Expanded(
                        child: _scheduleTab(
                          label: 'Finals',
                          selected: _selectedScheduleIndex == 1,
                          accent: accent,
                          textSecondary: textSecondary,
                          onTap: () => _switchSchedule(1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Search bar
              Container(
                color: surfaceColor,
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: TextStyle(color: textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search by school, name or event\u2026',
                    hintStyle: TextStyle(color: textSecondary, fontSize: 14),
                    prefixIcon: Icon(Icons.search_rounded, color: textSecondary, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close_rounded, color: textSecondary, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: inputColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: isDark ? _darkBorder : Colors.transparent),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: accent, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    isDense: true,
                  ),
                ),
              ),
              Divider(height: 1, thickness: 1, color: divider),

              // Filter chips
              Container(
                color: surfaceColor,
                height: 46,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                  children: [
                    _chip('All Events', _selectedEvent == null, isDark, accent,
                        () => setState(() => _selectedEvent = null)),
                    ...uniqueEventNames.map((name) => _chip(
                          name,
                          _selectedEvent == name,
                          isDark,
                          accent,
                          () => setState(
                              () => _selectedEvent = _selectedEvent == name ? null : name),
                        )),
                  ],
                ),
              ),
              Divider(height: 1, thickness: 1, color: divider),

              // Stats bar
              Container(
                color: isDark ? const Color(0xFF0D1117) : const Color(0xFFF9FAFB),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                child: Row(
                  children: [
                    Text(
                      '${filteredEvents.length} entries \u00b7 ${sortedKeys.length} event${sortedKeys.length == 1 ? "" : "s"}',
                      style: TextStyle(
                          fontSize: 12, color: textSecondary, fontWeight: FontWeight.w500),
                    ),
                    if (_showOnlyMyEvents) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(isDark ? 0.15 : 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: Colors.amber.withOpacity(isDark ? 0.4 : 0.3)),
                        ),
                        child: Text('My Events',
                            style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.amber[300] : Colors.amber[800],
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                    if (_searchQuery.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: accent.withOpacity(0.3)),
                          ),
                          child: Text(
                            _searchQuery,
                            style: TextStyle(
                                fontSize: 11, color: accent, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // List
              Expanded(
                child: sortedKeys.isEmpty
                    ? _emptyState(isDark, textPrimary, textSecondary)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 80),
                        itemCount: sortedKeys.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final name = sortedKeys[i];
                          final events = groupedEvents[name]!
                            ..sort((a, b) => a.startTime.compareTo(b.startTime));
                          final color = _getEventColor(name);
                          final icon = _getEventIcon(name);
                          final hasMe = events.any(_isMyEvent);
                          final schools = events.map((e) => e.schoolName ?? '').toSet().length;
                          return _eventCard(context, isDark, name, events, color, icon, hasMe,
                              schools, cardColor, textPrimary, textSecondary, divider, accent);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FutureBuilder<List<ParsedEventModel>>(
        future: _activeEventsFuture,
        builder: (context, snap) {
          if (!snap.hasData || snap.data!.isEmpty) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () => _showStatisticsDialog(snap.data!),
            icon: const Icon(Icons.analytics_outlined),
            label: const Text('Stats', style: TextStyle(fontWeight: FontWeight.w600)),
            backgroundColor: isDark ? const Color(0xFF1F6FEB) : const Color(0xFF001231),
            foregroundColor: Colors.white,
            elevation: isDark ? 2 : 4,
          );
        },
      ),
    );
  }

  Widget _scheduleTab({
    required String label,
    required bool selected,
    required Color accent,
    required Color textSecondary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? accent : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : textSecondary,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(
      String label, bool selected, bool isDark, Color accent, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: selected
                ? accent.withOpacity(isDark ? 0.2 : 0.1)
                : (isDark ? const Color(0xFF21262D) : const Color(0xFFF0F2F5)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? accent.withOpacity(isDark ? 0.7 : 0.5)
                  : (isDark ? const Color(0xFF30363D) : Colors.transparent),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected
                  ? accent
                  : (isDark ? const Color(0xFF8B949E) : const Color(0xFF6B7280)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState(bool isDark, Color textPrimary, Color textSecondary) {
    final hasFilters = _searchQuery.isNotEmpty || _selectedEvent != null || _showOnlyMyEvents;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasFilters ? Icons.search_off_rounded : Icons.event_busy_rounded,
              size: 72,
              color: isDark ? const Color(0xFF30363D) : Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No results for "$_searchQuery"'
                  : _selectedEvent != null
                      ? 'No entries for "$_selectedEvent"'
                      : _showOnlyMyEvents
                          ? 'No events found for you'
                          : 'No events found',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (hasFilters)
              Text('Try adjusting your search or filters',
                  style: TextStyle(fontSize: 13, color: textSecondary),
                  textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _eventCard(
      BuildContext context,
      bool isDark,
      String eventName,
      List<ParsedEventModel> events,
      Color eventColor,
      IconData eventIcon,
      bool hasMe,
      int schools,
      Color cardColor,
      Color textPrimary,
      Color textSecondary,
      Color divider,
      Color accent) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NCCCEventGroupPage(
              eventName: eventName,
              events: events,
              schoolId: widget.schoolId,
              eventColor: eventColor,
              eventIcon: eventIcon,
              currentUserName: widget.currentUserName,
              isAdmin: false,
            ),
          ),
        ),
        child: Ink(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasMe
                  ? Colors.amber.withOpacity(0.5)
                  : (isDark ? const Color(0xFF30363D) : const Color(0xFFE5E7EB)),
              width: hasMe ? 1.5 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: eventColor.withOpacity(isDark ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(eventIcon, color: eventColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              eventName,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: hasMe
                                    ? (isDark ? Colors.amber[300] : Colors.amber[800])
                                    : textPrimary,
                              ),
                            ),
                          ),
                          if (hasMe)
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(isDark ? 0.15 : 0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: Colors.amber.withOpacity(0.4), width: 1),
                              ),
                              child: Text(
                                'MY EVENT',
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.amber[300]
                                        : Colors.amber[800],
                                    letterSpacing: 0.5),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 11, color: textSecondary),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              events.first.location.isNotEmpty
                                  ? events.first.location
                                  : 'TBD',
                              style: TextStyle(fontSize: 11.5, color: textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(Icons.groups_outlined, size: 11, color: textSecondary),
                          const SizedBox(width: 2),
                          Text('$schools school${schools == 1 ? "" : "s"}',
                              style: TextStyle(fontSize: 11.5, color: textSecondary)),
                          const SizedBox(width: 10),
                          Icon(Icons.schedule_outlined, size: 11, color: textSecondary),
                          const SizedBox(width: 2),
                          Text('${events.length} slot${events.length == 1 ? "" : "s"}',
                              style: TextStyle(fontSize: 11.5, color: textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.chevron_right_rounded, size: 20, color: textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
