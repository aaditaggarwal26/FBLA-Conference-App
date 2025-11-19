import 'package:flutter/material.dart';
import '../home/home_screen.dart';
import '../events/events_screen.dart';
import '../pins/pin_trading_screen.dart';
import '../profile/profile_screen.dart';
import '../messages/messages_list_screen.dart';
import '../../theme/app_theme.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    EventsScreen(),
    PinTradingScreen(),
    MessagesListScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(0, Icons.home_rounded, 'Home', isDark),
                _buildNavItem(1, Icons.event_rounded, 'Events', isDark),
                _buildNavItem(2, Icons.push_pin_rounded, 'Pins', isDark),
                _buildNavItem(3, Icons.chat_bubble_rounded, 'Messages', isDark),
                _buildNavItem(4, Icons.person_rounded, 'Profile', isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, bool isDark) {
    final isSelected = _currentIndex == index;

    return Flexible(
      flex: isSelected ? 3 : 1,
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: isSelected ? 12 : 4,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark
                      ? AppTheme.darkPrimary.withValues(alpha: 0.2)
                      : AppTheme.primaryBlue.withValues(alpha: 0.1))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? (isDark ? AppTheme.darkPrimary : AppTheme.primaryBlue)
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.5)
                          : Colors.grey),
                size: isSelected ? 26 : 24,
              ),
              if (isSelected) ...[
                const SizedBox(width: 6),
                AnimatedOpacity(
                  opacity: isSelected ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      color: isSelected
                          ? (isDark
                                ? AppTheme.darkPrimary
                                : AppTheme.primaryBlue)
                          : Colors.transparent,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
