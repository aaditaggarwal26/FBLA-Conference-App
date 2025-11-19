import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/parsed_event_model.dart';
import 'event_detail_page.dart';

class NCCCEventGroupPage extends StatelessWidget {
  final String eventName;
  final List<ParsedEventModel> events;
  final String schoolId;
  final Color eventColor;
  final IconData eventIcon;
  final String? currentUserName;

  const NCCCEventGroupPage({
    super.key,
    required this.eventName,
    required this.events,
    required this.schoolId,
    required this.eventColor,
    required this.eventIcon,
    this.currentUserName,
  });

  bool _isMyEvent(ParsedEventModel event) {
    if (currentUserName == null) return false;
    return event.participants.any(
      (participant) =>
          participant.toLowerCase().contains(currentUserName!.toLowerCase()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sortedEvents = List<ParsedEventModel>.from(events)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E27) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          eventName,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF001231),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [eventColor, eventColor.withOpacity(0.6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: eventColor.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    eventIcon,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eventName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 16, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(
                            '${sortedEvents.length} time slots',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Icon(Icons.location_on, size: 16, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(
                            'Room ${sortedEvents.first.location}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
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

          // Time Slots List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: sortedEvents.length,
              itemBuilder: (context, index) {
                final event = sortedEvents[index];
                final isMyTimeSlot = _isMyEvent(event);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: isMyTimeSlot ? 4 : 1,
                  color: isDark ? const Color(0xFF1E2744) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isMyTimeSlot
                        ? const BorderSide(color: Colors.amber, width: 2)
                        : BorderSide.none,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EventDetailPage(
                            event: event,
                            schoolId: schoolId,
                            isAdmin: true,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Time and My Event badge
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: eventColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 16,
                                      color: eventColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      DateFormat('h:mm a').format(event.startTime),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isMyTimeSlot) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.star,
                                        size: 14,
                                        color: Colors.black,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'MY EVENT',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Participants Section
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.people,
                                size: 20,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: event.participants.map((participant) {
                                    final isMe = currentUserName != null &&
                                        participant
                                            .toLowerCase()
                                            .contains(currentUserName!.toLowerCase());
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isMe
                                            ? Colors.amber.withOpacity(0.3)
                                            : eventColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isMe
                                              ? Colors.amber
                                              : eventColor.withOpacity(0.3),
                                          width: isMe ? 2 : 1,
                                        ),
                                      ),
                                      child: Text(
                                        participant,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isMe
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          color: isMe
                                              ? Colors.amber.shade900
                                              : (isDark ? Colors.white : Colors.black87),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Location info
                          Row(
                            children: [
                              Icon(
                                Icons.meeting_room,
                                size: 16,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Room ${event.location}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.white70 : Colors.black54,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 14,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
