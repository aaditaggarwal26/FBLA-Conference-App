import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themePreferenceKey = 'isDarkMode';
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themePreferenceKey) ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themePreferenceKey, _isDarkMode);
    notifyListeners();
  }

  Future<void> setTheme(bool isDark) async {
    _isDarkMode = isDark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themePreferenceKey, _isDarkMode);
    notifyListeners();
  }

  // Light theme colors
  static const Color lightPrimary = Color(0xFF4B39EF);
  static const Color lightSecondary = Color(0xFF39D2C0);
  static const Color lightTertiary = Color(0xFFEE8B60);
  static const Color lightBackground = Color(0xFFF1F4F8);
  static const Color lightSurface = Colors.white;
  static const Color lightCardColor = Colors.white;
  static const Color lightTextPrimary = Color(0xFF0F1113);
  static const Color lightTextSecondary = Color(0xFF57636C);
  static const Color lightDivider = Color(0xFFE0E3E7);

  // Dark theme colors
  static const Color darkPrimary = Color(0xFF6F61EF);
  static const Color darkSecondary = Color(0xFF39D2C0);
  static const Color darkTertiary = Color(0xFFEE8B60);
  static const Color darkBackground = Color(0xFF0F1113);
  static const Color darkSurface = Color(0xFF1D2428);
  static const Color darkCardColor = Color(0xFF262D34);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFF95A1AC);
  static const Color darkDivider = Color(0xFF262D34);

  ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          primary: lightPrimary,
          secondary: lightSecondary,
          tertiary: lightTertiary,
          surface: lightSurface,
          background: lightBackground,
          error: const Color(0xFFFF5963),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: lightTextPrimary,
          onBackground: lightTextPrimary,
        ),
        scaffoldBackgroundColor: lightBackground,
        cardColor: lightCardColor,
        dividerColor: lightDivider,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: lightTextPrimary,
          elevation: 0,
          iconTheme: IconThemeData(color: lightTextPrimary),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontFamily: 'Readex Pro',
            color: lightTextPrimary,
            fontSize: 57,
            fontWeight: FontWeight.w400,
          ),
          displayMedium: TextStyle(
            fontFamily: 'Readex Pro',
            color: lightTextPrimary,
            fontSize: 45,
            fontWeight: FontWeight.w400,
          ),
          displaySmall: TextStyle(
            fontFamily: 'Readex Pro',
            color: lightTextPrimary,
            fontSize: 36,
            fontWeight: FontWeight.w400,
          ),
          headlineLarge: TextStyle(
            fontFamily: 'Readex Pro',
            color: lightTextPrimary,
            fontSize: 32,
            fontWeight: FontWeight.w600,
          ),
          headlineMedium: TextStyle(
            fontFamily: 'Readex Pro',
            color: lightTextPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
          headlineSmall: TextStyle(
            fontFamily: 'Readex Pro',
            color: lightTextPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w500,
          ),
          titleLarge: TextStyle(
            fontFamily: 'Readex Pro',
            color: lightTextPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
          titleMedium: TextStyle(
            fontFamily: 'Readex Pro',
            color: lightTextPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          titleSmall: TextStyle(
            fontFamily: 'Readex Pro',
            color: lightTextSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          bodyLarge: TextStyle(
            fontFamily: 'Readex Pro',
            color: lightTextPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Readex Pro',
            color: lightTextPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          bodySmall: TextStyle(
            fontFamily: 'Readex Pro',
            color: lightTextSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
          labelLarge: TextStyle(
            fontFamily: 'Readex Pro',
            color: lightTextPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          labelMedium: TextStyle(
            fontFamily: 'Readex Pro',
            color: lightTextSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          labelSmall: TextStyle(
            fontFamily: 'Readex Pro',
            color: lightTextSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: lightPrimary,
            foregroundColor: Colors.white,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: lightDivider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: lightDivider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: lightPrimary, width: 2),
          ),
        ),
      );

  ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: darkPrimary,
          secondary: darkSecondary,
          tertiary: darkTertiary,
          surface: darkSurface,
          background: darkBackground,
          error: const Color(0xFFFF5963),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: darkTextPrimary,
          onBackground: darkTextPrimary,
        ),
        scaffoldBackgroundColor: darkBackground,
        cardColor: darkCardColor,
        dividerColor: darkDivider,
        appBarTheme: AppBarTheme(
          backgroundColor: darkSurface,
          foregroundColor: darkTextPrimary,
          elevation: 0,
          iconTheme: const IconThemeData(color: darkTextPrimary),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontFamily: 'Readex Pro',
            color: darkTextPrimary,
            fontSize: 57,
            fontWeight: FontWeight.w400,
          ),
          displayMedium: TextStyle(
            fontFamily: 'Readex Pro',
            color: darkTextPrimary,
            fontSize: 45,
            fontWeight: FontWeight.w400,
          ),
          displaySmall: TextStyle(
            fontFamily: 'Readex Pro',
            color: darkTextPrimary,
            fontSize: 36,
            fontWeight: FontWeight.w400,
          ),
          headlineLarge: TextStyle(
            fontFamily: 'Readex Pro',
            color: darkTextPrimary,
            fontSize: 32,
            fontWeight: FontWeight.w600,
          ),
          headlineMedium: TextStyle(
            fontFamily: 'Readex Pro',
            color: darkTextPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
          headlineSmall: TextStyle(
            fontFamily: 'Readex Pro',
            color: darkTextPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w500,
          ),
          titleLarge: TextStyle(
            fontFamily: 'Readex Pro',
            color: darkTextPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
          titleMedium: TextStyle(
            fontFamily: 'Readex Pro',
            color: darkTextPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          titleSmall: TextStyle(
            fontFamily: 'Readex Pro',
            color: darkTextSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          bodyLarge: TextStyle(
            fontFamily: 'Readex Pro',
            color: darkTextPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Readex Pro',
            color: darkTextPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          bodySmall: TextStyle(
            fontFamily: 'Readex Pro',
            color: darkTextSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
          labelLarge: TextStyle(
            fontFamily: 'Readex Pro',
            color: darkTextPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          labelMedium: TextStyle(
            fontFamily: 'Readex Pro',
            color: darkTextSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          labelSmall: TextStyle(
            fontFamily: 'Readex Pro',
            color: darkTextSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: darkPrimary,
            foregroundColor: Colors.white,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: darkCardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: darkDivider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: darkDivider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: darkPrimary, width: 2),
          ),
        ),
      );
}
