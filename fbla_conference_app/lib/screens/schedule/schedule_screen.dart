import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/event_service.dart';
import '../../models/event_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/event_card.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final EventService _eventService = EventService();

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      appBar: AppBar(
        title: const Text('My Schedule'),
      ),
      body: userId == null
          ? Center(
              child: Text(
                'Please sign in to view your schedule',
                style: TextStyle(color: AppTheme.mediumGray),
              ),
            )
          : StreamBuilder<List<EventModel>>(
              stream: _eventService.getUserRegisteredEvents(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 80,
                          color: AppTheme.mediumGray,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No events in your schedule',
                          style: TextStyle(
                            color: AppTheme.mediumGray,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Register for events to see them here',
                          style: TextStyle(
                            color: AppTheme.mediumGray,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    return EventCard(event: snapshot.data![index]);
                  },
                );
              },
            ),
    );
  }
}
