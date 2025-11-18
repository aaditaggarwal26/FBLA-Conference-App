import 'package:flutter/material.dart';
import '../../models/event_model.dart';
import '../../widgets/weather_widget.dart';
import 'package:intl/intl.dart';

class EventDetailScreen extends StatelessWidget {
  final EventModel event;

  const EventDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(event.title),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.imageUrl != null)
              Image.network(
                event.imageUrl!,
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('MMM d, yyyy').format(event.startTime),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        '${DateFormat('h:mm a').format(event.startTime)} - ${DateFormat('h:mm a').format(event.endTime)}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16),
                      const SizedBox(width: 8),
                      Text(event.location),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(event.description),
                  const SizedBox(height: 16),
                  
                  // Weather Forecast
                  Text(
                    'Weather Forecast',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  WeatherWidget(
                    locationName: event.location,
                    showForecast: true,
                  ),
                  const SizedBox(height: 16),
                  
                  if (event.speakers.isNotEmpty) ...[
                    Text(
                      'Speakers',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    ...event.speakers.map((speaker) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.person, size: 16),
                              const SizedBox(width: 8),
                              Text(speaker),
                            ],
                          ),
                        )),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    'Attendance: ${event.attendeeIds.length}/${event.capacity}',
                    style: Theme.of(context).textTheme.bodyMedium,
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
