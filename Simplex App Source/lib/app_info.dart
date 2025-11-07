import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_app_badge_control/flutter_app_badge_control.dart';
// import 'package:mad3/frontend/pages/pages.dart'
//     show firebaseMessagingBackgroundHandler;

import 'backend/models.dart';

/// TODO: this whole ugly global state thing is not going to cut it.. needs to be reimplemented
/// [AppInfo] contains statics storing singleton instances of Firebase objects, like [database], basic
///  configuration info necessary for in-app presentation, like [darkMode] and [isAdmin], and data from the database
///  like [currentEvents], [currentTasks], [currentPackets]
///
class AppInfo {
  ///
  static late FirebaseFirestore database;

  ///
  static late FirebaseMessaging messenger;

  ///
  static late UserModel currentUser;

  ///
  static late ChapterModel currentChapter;

  ///
  static late List<EventModel>? currentEvents;

  ///
  static late List<TaskModel> currentTasks;

  ///
  static late List<PacketModel> currentPackets;

  ///
  static List<UserModel> userList = [];

  ///
  static bool isOwner = false;
  static bool isAdmin = false;

  ///
  static bool darkMode = false;

  ///
  static String font = 'Montserrat';

  ///
  static Future<String> getVersion() async {
    DocumentSnapshot docRef = await AppInfo.database
        .collection('version')
        .doc('xNkwvDdbext00XQEtvlB')
        .get();
    return docRef.get('version') as String;
  }

  ///
  static Future<void> loadData() async {
    await getCurrentUserData().then(
      (value) {
        AppInfo.currentUser = value;
      },
    );

    if (AppInfo.currentUser.currentChapter != "") {
      await EventModel.getCurrentEvents().then(
        (value) {
          AppInfo.currentEvents = value;
        },
      );
      DocumentSnapshot d = await AppInfo.database
          .collection('chapters')
          .doc(currentUser.currentChapter)
          .get();
      List<String> exec = (d.get('exec') as List).cast<String>();
      AppInfo.isAdmin = exec.contains(AppInfo.currentUser.id);
      AppInfo.isOwner = (d.get('owner') as String) == AppInfo.currentUser.id;
    }

    // await TaskModel.getCurrentTasks().then(
    //   (value) {
    //     AppInfo.currentTasks = value;
    //   },
    // );
    await PacketModel.getPackets().then(
      (value) {
        AppInfo.currentPackets = value;
      },
    );
  }

  static Future<void> configureFirebaseMessaging() async {
    if (kIsWeb) {
      return;
    }

    NotificationSettings settings =
        await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    // FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      FlutterAppBadgeControl.removeBadge();
    });
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      await messenger.subscribeToTopic('announcements');
    }

    //print('Subscribed to topic successfully');

    // Request permission to receive push notifications (required for iOS)
  }

  /// Fetches the current user's data and returns a [UserModel] for easy reading
  ///
  /// Wrapper around [getUserModelWithId]
  static Future<UserModel> getCurrentUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    String id = user!.uid;
    return await UserModel.getUserById(id);
  }
}
