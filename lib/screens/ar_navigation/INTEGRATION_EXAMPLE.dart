// Quick Integration Guide for AR Navigation
// Add these navigation routes to your existing app

// 1. ADD TO YOUR ROUTER/NAVIGATION
// In your school admin dashboard or menu:

ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DropLocationPinScreen(
          schoolId: yourSchoolId,
          userId: currentUserId,
        ),
      ),
    );
  },
  child: const Text('Drop Location Pin'),
);

ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LinkEventsToLocationsScreen(
          schoolId: yourSchoolId,
        ),
      ),
    );
  },
  child: const Text('Link Events to Locations'),
);

// 2. IMPORT EVENTS (One-time setup, call from admin screen)
Future<void> importFBLAEvents() async {
  final eventService = EventImportService();
  try {
    final count = await eventService.importEventsFromJson(
      schoolId: yourSchoolId,
    );
    print('✅ Imported $count FBLA events!');
  } catch (e) {
    print('❌ Failed to import: $e');
  }
}

// 3. SHOW STUDENT EVENTS WITH AR NAVIGATION
// In your events list screen, for each event with location:

StreamBuilder<List<ParsedEventModel>>(
  stream: EventImportService().getEventsForParticipant(
    schoolId,
    studentName, // e.g., "AaditAggarwal"
  ),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return CircularProgressIndicator();
    
    final myEvents = snapshot.data!;
    
    return ListView.builder(
      itemCount: myEvents.length,
      itemBuilder: (context, index) {
        final event = myEvents[index];
        
        return Card(
          child: ListTile(
            title: Text(event.eventName),
            subtitle: Text('${event.startTime.hour}:${event.startTime.minute}'),
            trailing: event.hasLocationPin()
              ? ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ARNavigationScreen(
                          event: event,
                          schoolId: schoolId,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.navigation),
                  label: const Text('Navigate'),
                )
              : const Text('No location'),
          ),
        );
      },
    );
  },
);

// 4. IMPORTS NEEDED AT TOP OF FILES
import 'package:your_app/screens/ar_navigation/drop_location_pin_screen.dart';
import 'package:your_app/screens/ar_navigation/link_events_to_locations_screen.dart';
import 'package:your_app/screens/ar_navigation/ar_navigation_screen.dart';
import 'package:your_app/services/event_import_service.dart';
import 'package:your_app/models/parsed_event_model.dart';

// 5. ADMIN SETUP WORKFLOW
// Step 1: Call importFBLAEvents() once to import all 208 events
// Step 2: Walk around venue and drop location pins at each room
// Step 3: Use LinkEventsToLocationsScreen to link events to pins
// Step 4: Students can now use AR navigation!

// 6. QUERY EXAMPLES

// Get all events for a specific location
EventImportService().getEventsForLocation(schoolId, locationPinId);

// Get events without locations (for admin to link)
EventImportService().getEventsWithoutLocation(schoolId);

// Get nearby location pins (within 1km)
LocationPinService().getLocationPinsNearby(
  schoolId: schoolId,
  latitude: currentLat,
  longitude: currentLng,
  radiusMeters: 1000,
);

// Search location pins by name
LocationPinService().searchLocationPins(schoolId, 'Room 22');

// Get event statistics
final stats = await EventImportService().getEventStatistics(schoolId);
print('Total events: ${stats['totalEvents']}');
print('With location: ${stats['eventsWithLocation']}');
print('Without location: ${stats['eventsWithoutLocation']}');
