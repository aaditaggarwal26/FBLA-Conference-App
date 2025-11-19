import 'package:flutter/material.dart';
import '../../models/location_pin_model.dart';
import '../../models/parsed_event_model.dart';
import '../../services/location_pin_service.dart';
import '../../services/event_import_service.dart';

class LinkEventsToLocationsScreen extends StatefulWidget {
  final String schoolId;

  const LinkEventsToLocationsScreen({
    super.key,
    required this.schoolId,
  });

  @override
  State<LinkEventsToLocationsScreen> createState() =>
      _LinkEventsToLocationsScreenState();
}

class _LinkEventsToLocationsScreenState
    extends State<LinkEventsToLocationsScreen> {
  final LocationPinService _locationService = LocationPinService();
  final EventImportService _eventService = EventImportService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Link Events to Locations'),
        backgroundColor: const Color(0xFF001231),
      ),
      body: StreamBuilder<List<ParsedEventModel>>(
        stream: _eventService.getEventsWithoutLocation(widget.schoolId),
        builder: (context, eventSnapshot) {
          if (eventSnapshot.hasError) {
            return Center(child: Text('Error: ${eventSnapshot.error}'));
          }

          if (!eventSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final eventsWithoutLocation = eventSnapshot.data!;

          if (eventsWithoutLocation.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 80, color: Colors.green),
                  SizedBox(height: 16),
                  Text(
                    'All events have locations!',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: eventsWithoutLocation.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final event = eventsWithoutLocation[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange,
                    child: Text('${event.startTime.hour}:${event.startTime.minute.toString().padLeft(2, '0')}'),
                  ),
                  title: Text(
                    event.eventName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Room: ${event.location}'),
                      Text('Participants: ${event.participants.join(", ")}'),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () => _showLocationPicker(event),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showLocationPicker(ParsedEventModel event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF001231),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Select Location for\n${event.eventName}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                    Text(
                      'Room: ${event.location}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<List<LocationPinModel>>(
                  stream: _locationService.getLocationPins(widget.schoolId),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final pins = snapshot.data!;

                    if (pins.isEmpty) {
                      return const Center(
                        child: Text('No location pins available.\nDrop some pins first!'),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: pins.length,
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (context, index) {
                        final pin = pins[index];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF001231),
                              child: Text(
                                pin.floorLevel == 0
                                    ? 'G'
                                    : pin.floorLevel > 0
                                        ? '${pin.floorLevel}'
                                        : 'B${-pin.floorLevel}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              pin.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (pin.buildingName != null)
                                  Text(pin.buildingName!),
                                if (pin.description != null)
                                  Text(
                                    pin.description!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                            trailing: ElevatedButton(
                              onPressed: () => _linkEventToLocation(event, pin),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              child: const Text('Link'),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _linkEventToLocation(
    ParsedEventModel event,
    LocationPinModel pin,
  ) async {
    try {
      await _eventService.linkEventToLocation(event.id, pin.id);
      
      if (mounted) {
        Navigator.pop(context); // Close bottom sheet
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${event.eventName} linked to ${pin.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to link: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
