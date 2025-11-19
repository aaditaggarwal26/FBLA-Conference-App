import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/parsed_event_model.dart';
import '../../services/event_import_service.dart';
import 'nccc_event_group_page.dart';

class NCCCEventDetailScreen extends StatefulWidget {
  final String schoolId;
  final String? currentUserName; // For highlighting user's events

  const NCCCEventDetailScreen({
    super.key,
    required this.schoolId,
    this.currentUserName,
  });

  @override
  State<NCCCEventDetailScreen> createState() => _NCCCEventDetailScreenState();
}

class _NCCCEventDetailScreenState extends State<NCCCEventDetailScreen>
    with SingleTickerProviderStateMixin {
  final EventImportService _eventService = EventImportService();
  late TabController _tabController;
  String _searchQuery = '';
  bool _showOnlyMyEvents = false;

  final List<String> _eventCategories = [
    'All Events',
    'Technology',
    'Business',
    'Design',
    'Speaking',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _eventCategories.length, vsync: this);
    _checkAndImportEvents();
  }

  Future<void> _checkAndImportEvents() async {
    // Check if events already exist
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('parsed_events')
          .where('schoolId', isEqualTo: widget.schoolId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        // Auto-import events on first load
        await _eventService.importNCCC2025Events(widget.schoolId);
      }
    } catch (e) {
      print('Error checking/importing events: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<ParsedEventModel> _filterEvents(List<ParsedEventModel> events) {
    var filtered = events;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((event) {
        return event.eventName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            event.location.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            event.participants.any((name) =>
                name.toLowerCase().contains(_searchQuery.toLowerCase()));
      }).toList();
    }

    // Filter by category
    final currentCategory = _eventCategories[_tabController.index];
    if (currentCategory != 'All Events') {
      filtered = filtered.where((event) {
        switch (currentCategory) {
          case 'Technology':
            return event.eventName.toLowerCase().contains('coding') ||
                event.eventName.toLowerCase().contains('programming') ||
                event.eventName.toLowerCase().contains('website') ||
                event.eventName.toLowerCase().contains('mobile') ||
                event.eventName.toLowerCase().contains('computer') ||
                event.eventName.toLowerCase().contains('data');
          case 'Business':
            return event.eventName.toLowerCase().contains('business') ||
                event.eventName.toLowerCase().contains('financial') ||
                event.eventName.toLowerCase().contains('management');
          case 'Design':
            return event.eventName.toLowerCase().contains('design') ||
                event.eventName.toLowerCase().contains('animation') ||
                event.eventName.toLowerCase().contains('visual') ||
                event.eventName.toLowerCase().contains('graphic');
          case 'Speaking':
            return event.eventName.toLowerCase().contains('speaking') ||
                event.eventName.toLowerCase().contains('presentation');
          default:
            return true;
        }
      }).toList();
    }

    // Filter by user's events
    if (_showOnlyMyEvents && widget.currentUserName != null) {
      filtered = filtered.where((event) {
        return event.participants.any((name) =>
            name.toLowerCase().contains(widget.currentUserName!.toLowerCase()));
      }).toList();
    }

    return filtered;
  }

  bool _isMyEvent(ParsedEventModel event) {
    if (widget.currentUserName == null) return false;
    return event.participants.any((name) =>
        name.toLowerCase().contains(widget.currentUserName!.toLowerCase()));
  }

  Color _getEventColor(String eventName) {
    if (eventName.toLowerCase().contains('coding') ||
        eventName.toLowerCase().contains('programming') ||
        eventName.toLowerCase().contains('website') ||
        eventName.toLowerCase().contains('mobile')) {
      return Colors.blue;
    } else if (eventName.toLowerCase().contains('design') ||
        eventName.toLowerCase().contains('animation')) {
      return Colors.purple;
    } else if (eventName.toLowerCase().contains('business') ||
        eventName.toLowerCase().contains('financial')) {
      return Colors.green;
    } else if (eventName.toLowerCase().contains('speaking') ||
        eventName.toLowerCase().contains('presentation')) {
      return Colors.orange;
    }
    return const Color(0xFF001231);
  }

  IconData _getEventIcon(String eventName) {
    if (eventName.toLowerCase().contains('coding') ||
        eventName.toLowerCase().contains('programming')) {
      return Icons.code;
    } else if (eventName.toLowerCase().contains('website')) {
      return Icons.web;
    } else if (eventName.toLowerCase().contains('mobile')) {
      return Icons.phone_android;
    } else if (eventName.toLowerCase().contains('design')) {
      return Icons.design_services;
    } else if (eventName.toLowerCase().contains('animation')) {
      return Icons.animation;
    } else if (eventName.toLowerCase().contains('business')) {
      return Icons.business_center;
    } else if (eventName.toLowerCase().contains('financial')) {
      return Icons.attach_money;
    } else if (eventName.toLowerCase().contains('speaking')) {
      return Icons.mic;
    } else if (eventName.toLowerCase().contains('presentation')) {
      return Icons.present_to_all;
    }
    return Icons.event;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E27) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('NCCC 2025 - Event Schedule'),
        backgroundColor: isDark ? const Color(0xFF001231) : const Color(0xFF001231),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search events, participants, or rooms...',
                      prefixIcon: Icon(Icons.search, color: isDark ? Colors.white70 : Colors.grey),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => setState(() => _searchQuery = ''),
                            )
                          : null,
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E2744) : Colors.white,
                      hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                ),
              ),
              // Tabs
              TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: const Color(0xFF4A90E2),
                labelColor: const Color(0xFF4A90E2),
                unselectedLabelColor: isDark ? Colors.white60 : Colors.white70,
                onTap: (_) => setState(() {}),
                tabs: _eventCategories
                    .map((category) => Tab(text: category))
                    .toList(),
              ),
            ],
          ),
        ),
        actions: [
          if (widget.currentUserName != null)
            IconButton(
              icon: Icon(
                _showOnlyMyEvents ? Icons.person : Icons.person_outline,
                color: _showOnlyMyEvents ? Colors.yellow : Colors.white,
              ),
              tooltip: 'Show only my events',
              onPressed: () {
                setState(() => _showOnlyMyEvents = !_showOnlyMyEvents);
              },
            ),
        ],
      ),
      body: StreamBuilder<List<ParsedEventModel>>(
        stream: _eventService.getParsedEvents(widget.schoolId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allEvents = snapshot.data!;
          final filteredEvents = _filterEvents(allEvents);

          if (filteredEvents.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _searchQuery.isNotEmpty
                        ? Icons.search_off
                        : Icons.event_busy,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isNotEmpty
                        ? 'No events found for "$_searchQuery"'
                        : 'No events available',
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Group events by event name
          final Map<String, List<ParsedEventModel>> groupedEvents = {};
          for (final event in filteredEvents) {
            groupedEvents.putIfAbsent(event.eventName, () => []).add(event);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groupedEvents.length,
            itemBuilder: (context, index) {
              final eventName = groupedEvents.keys.elementAt(index);
              final events = groupedEvents[eventName]!;
              events.sort((a, b) => a.startTime.compareTo(b.startTime));

              final eventColor = _getEventColor(eventName);
              final eventIcon = _getEventIcon(eventName);
              final hasMyEvent = events.any(_isMyEvent);

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: hasMyEvent ? 4 : 2,
                color: isDark ? const Color(0xFF1E2744) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: hasMyEvent
                      ? const BorderSide(color: Colors.amber, width: 2)
                      : BorderSide.none,
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NCCCEventGroupPage(
                          eventName: eventName,
                          events: events,
                          schoolId: widget.schoolId,
                          eventColor: eventColor,
                          eventIcon: eventIcon,
                          currentUserName: widget.currentUserName,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: eventColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(eventIcon, color: eventColor, size: 28),
                        ),
                        const SizedBox(width: 16),
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
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: hasMyEvent ? Colors.amber.shade900 : (isDark ? Colors.white : Colors.black87),
                                      ),
                                    ),
                                  ),
                                  if (hasMyEvent)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.amber,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'MY EVENT',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.location_on,
                                      size: 14, color: isDark ? Colors.white60 : Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Room ${events.first.location}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? Colors.white70 : Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(Icons.access_time, size: 14, color: isDark ? Colors.white60 : Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${events.length} time slots',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? Colors.white70 : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: isDark ? Colors.white60 : Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final stats = await _eventService.getEventStatistics(widget.schoolId);
          if (context.mounted) {
            _showStatisticsDialog(stats);
          }
        },
        icon: const Icon(Icons.analytics),
        label: const Text('Stats'),
        backgroundColor: const Color(0xFF001231),
      ),
    );
  }

  void _showStatisticsDialog(Map<String, dynamic> stats) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('NCCC 2025 Statistics'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatRow('Total Events', stats['totalEvents'].toString()),
              _buildStatRow(
                'With Location',
                stats['eventsWithLocation'].toString(),
                color: Colors.green,
              ),
              _buildStatRow(
                'Without Location',
                stats['eventsWithoutLocation'].toString(),
                color: Colors.orange,
              ),
              const Divider(height: 24),
              const Text(
                'Event Types:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...((stats['eventTypes'] as Map<String, dynamic>).entries.toList()
                    ..sort((a, b) => (b.value as int).compareTo(a.value as int)))
                  .take(10)
                  .map((entry) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                entry.key,
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              entry.value.toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )),
            ],
          ),
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

  Widget _buildStatRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
