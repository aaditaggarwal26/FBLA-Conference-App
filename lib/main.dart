import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'services/accessibility_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/navigation/main_navigation_screen.dart';
import 'services/notification_service.dart';

/// Entry point of the application.
/// Initializes Firebase, sets up notifications, and runs the app.
void main() async {
  // Ensure Flutter bindings are initialized before calling native code
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  
  // Preserve the splash screen until initialization is complete
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Load environment variables
  await dotenv.load(fileName: '.env').catchError((_) {
    // .env missing — ChatService will surface an error when used
  });

  try {
    // Initialize Firebase with platform-specific options
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Set up background message handler for Firebase Messaging
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    
    // Initialize the notification service
    final notificationService = NotificationService();
    notificationService.initialize().catchError((e) {
      print('Notification init error (non-critical): $e');
    });
  } catch (e) {
    print('Firebase initialization error: $e');
  }

  // Remove the splash screen once initialization is done
  FlutterNativeSplash.remove();

  // Run the application with providers
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

/// The root widget of the application.
/// Configures the MaterialApp, themes, and routes.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to ThemeProvider and AccessibilityService for changes
    return Consumer2<ThemeProvider, AccessibilityService>(
      builder: (context, themeProvider, accessibilityService, _) {
        return MaterialApp(
          title: 'FBLA',
          // Apply themes with accessibility adjustments
          theme: _buildTheme(AppTheme.lightTheme, accessibilityService),
          darkTheme: _buildTheme(AppTheme.darkTheme, accessibilityService),
          // Switch between light and dark mode based on provider state
          themeMode: themeProvider.isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          debugShowCheckedModeBanner: false,
          // Set the initial screen based on authentication state
          home: const AuthWrapper(),
          // Define named routes for navigation
          routes: {
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/forgot-password': (context) => const ForgotPasswordScreen(),
            '/home': (context) => const MainNavigationScreen(),
          },
          // Global builder to apply text scaling
          builder: (context, child) {
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

  /// Helper method to build a theme with accessibility modifications.
  /// Adjusts colors for high contrast mode if enabled.
  ThemeData _buildTheme(ThemeData baseTheme, AccessibilityService accessibility) {
    if (!accessibility.highContrast) {
      return baseTheme;
    }

    // Determine if the base theme is dark or light
    final isDark = baseTheme.brightness == Brightness.dark;
    
    // Return a modified theme with high contrast colors
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

/// Widget to handle authentication state.
/// Shows the LoginScreen if not authenticated, or MainNavigationScreen if authenticated.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // Listen to Firebase Auth state changes
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading indicator while checking auth state
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

        // If user is logged in, navigate to home
        if (snapshot.hasData) {
          return const MainNavigationScreen();
        }

        // Otherwise, show login screen
        return const LoginScreen();
      },
    );
  }
}
