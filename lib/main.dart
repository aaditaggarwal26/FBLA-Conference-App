import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'services/accessibility_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/navigation/main_navigation_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize notifications (non-blocking)
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    final notificationService = NotificationService();
    notificationService.initialize().catchError((e) {
      print('Notification init error (non-critical): $e');
    });
  } catch (e) {
    print('Firebase initialization error: $e');
  }

  FlutterNativeSplash.remove();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AccessibilityService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, AccessibilityService>(
      builder: (context, themeProvider, accessibilityService, _) {
        return MaterialApp(
          title: 'FBLA',
          theme: _buildTheme(AppTheme.lightTheme, accessibilityService),
          darkTheme: _buildTheme(AppTheme.darkTheme, accessibilityService),
          themeMode: themeProvider.isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          debugShowCheckedModeBanner: false,
          home: const AuthWrapper(),
          routes: {
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/forgot-password': (context) => const ForgotPasswordScreen(),
            '/home': (context) => const MainNavigationScreen(),
          },
          builder: (context, child) {
            // Apply text scale factor globally
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(accessibilityService.textScaleFactor),
                boldText: accessibilityService.boldText,
              ),
              child: child!,
            );
          },
        );
      },
    );
  }

  /// Build theme with accessibility adjustments
  ThemeData _buildTheme(ThemeData baseTheme, AccessibilityService accessibility) {
    if (!accessibility.highContrast) {
      return baseTheme;
    }

    // Apply high contrast modifications
    final isDark = baseTheme.brightness == Brightness.dark;
    return baseTheme.copyWith(
      scaffoldBackgroundColor: isDark ? Colors.black : Colors.white,
      cardColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFAFAFA),
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1E40AF),
        surface: isDark ? const Color(0xFF0A0A0A) : Colors.white,
      ),
      textTheme: baseTheme.textTheme.apply(
        bodyColor: isDark ? Colors.white : Colors.black,
        displayColor: isDark ? Colors.white : Colors.black,
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppTheme.white,
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
              ),
            ),
          );
        }

        if (snapshot.hasData) {
          return const MainNavigationScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
