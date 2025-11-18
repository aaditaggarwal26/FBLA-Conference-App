import 'package:flutter/material.dart';
import '../home/home_screen.dart';
import '../events/events_screen.dart';
import '../schedule/schedule_screen.dart';
import '../messages/messages_list_screen.dart';
import '../pins/pin_trading_screen.dart';
import '../profile/profile_screen.dart';
import '../../theme/app_theme.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const EventsScreen(),
    const ScheduleScreen(),
    const MessagesListScreen(),
    const PinTradingScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
          selectedItemColor: AppTheme.primaryBlue,
          unselectedItemColor: isDark ? Colors.white60 : AppTheme.mediumGray,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.event_rounded),
              label: 'Events',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_rounded),
              label: 'Schedule',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.message_rounded),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.push_pin_rounded),
              label: 'Pins',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
