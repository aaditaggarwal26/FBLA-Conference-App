import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_badge_control/flutter_app_badge_control.dart';
import 'package:provider/provider.dart';
import 'frontend/login/login_page.dart';
import 'frontend/select_chapter/chapter_select.dart';
import 'frontend/flutter_flow/theme_provider.dart';
import 'firebase_options.dart';
import 'app_info.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'setup_admin.dart'; // Import setup admin

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    log(error.toString());
    log(stack.toString());
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  AppInfo.database = FirebaseFirestore.instance;
  AppInfo.messenger = FirebaseMessaging.instance;
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // SETUP SUPER ADMIN - Run once to create ncfbla@gmail.com as super admin
  // Uncomment the line below, run the app once, then comment it again
  // await setupSuperAdmin();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget with WidgetsBindingObserver {
  MyApp({super.key});

  void initState() {
    WidgetsBinding.instance.addObserver(this);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      FlutterAppBadgeControl.removeBadge();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'Simplex Chapter',
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading...'),
                  ],
                ),
              ),
            );
          }
          
          if (snapshot.hasData) {
            return FutureBuilder<void>(
              future: AppInfo.loadData().timeout(
                const Duration(seconds: 10),
                onTimeout: () {
                  if (kDebugMode) {
                    print('AppInfo.loadData() timed out after 10 seconds');
                  }
                  // Set defaults on timeout
                  AppInfo.currentEvents = [];
                  AppInfo.currentPackets = [];
                },
              ),
              builder: (context, loadSnapshot) {
                if (loadSnapshot.connectionState == ConnectionState.waiting) {
                  return Scaffold(
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Setting up your account...'),
                        ],
                      ),
                    ),
                  );
                }

                if (loadSnapshot.hasError) {
                  if (kDebugMode) {
                    print('Error loading data: ${loadSnapshot.error}');
                  }
                  return const LoginWidget();
                }

                return const ChapterSelectWidget();
              },
            );
          }
          
          return const LoginWidget();
        },
      ),
        );
      },
    );
  }
}

Future firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  FlutterAppBadgeControl.updateBadgeCount(1);
}
