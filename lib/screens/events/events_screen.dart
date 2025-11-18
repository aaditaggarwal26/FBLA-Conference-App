import 'package:flutter/material.dart';
import '../../services/event_service.dart';
import '../../models/event_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/event_card.dart';
import 'event_qr_scanner_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final EventService _eventService = EventService();
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'General',
    'Workshop',
    'Keynote',
    'Networking',
    'Competition',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // Consistent Header
          SliverAppBar(
            expandedHeight: 100,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.background,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 24, bottom: 16, right: 24),
              title: Text(
                'Events',
                style: TextStyle(
                  color: isDark ? Colors.white : AppTheme.black,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkBackground : AppTheme.background,
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: IconButton(
                  icon: Icon(
                    Icons.qr_code_scanner_rounded,
                    color: isDark ? Colors.white : AppTheme.black,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EventQRScannerScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // Category Filter
          SliverToBoxAdapter(
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category;
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedCategory = category);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryBlue
                              : (isDark ? AppTheme.darkSurface : Colors.white),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryBlue
                                : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade300),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            category,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.white.withValues(alpha: 0.7) : Colors.grey.shade700),
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Events List
          StreamBuilder<List<EventModel>>(
            stream: _selectedCategory == 'All'
                ? _eventService.getEvents()
                : _eventService.getEventsByCategory(_selectedCategory),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy_rounded,
                          size: 64,
                          color: isDark ? Colors.white.withValues(alpha: 0.3) : Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No events found',
                          style: TextStyle(
                            color: isDark ? Colors.white.withValues(alpha: 0.6) : Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return EventCard(event: snapshot.data![index]);
                    },
                    childCount: snapshot.data!.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
