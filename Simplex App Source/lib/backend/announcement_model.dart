part of 'models.dart';

/// [AnnouncementModel] encapsulates fields of a Firebase Competitive Event Document found
/// in the 'compEvents' collection
///
/// Instantiate [AnnouncementModel] using a [DocumentSnapshot] with [AnnouncementModel.fromDocumentSnapshot] to easily
/// read fields from the document. When an update to the document is required, use [toMap] to
/// quickly transform the object into a [Map] and then write to the [DocumentReference]
class AnnouncementModel {
  /// the unique Firebase document id of this announcement
  late String id;

  late String chapterid;

  late String name;

  late Color color;

  late List<Map<String, String>> msgs = [];

  /// the URL of the image associated with the announcement

  AnnouncementModel(
      {required this.id,
      required this.name,
      required this.chapterid,
      required this.color,
      required this.msgs});

  /// Utility constructor to easily make an [AnnouncementModel] from a [DocumentSnapshot]
  ///
  /// Queries the [DocumentSnapshot] for each field and instantiates [AnnouncementModel] accordingly
  AnnouncementModel.fromDocumentSnapshot(
      DocumentSnapshot<Object?> doc, this.chapterid) {
    id = doc.id;
    name = doc.get('name') as String;
    color = Color(int.parse('FF${doc.get('color') as String}', radix: 16));
    List<dynamic> msgList = (doc.get('msgs') as List).cast<dynamic>();
    for (int i = 0; i < msgList.length; i++) {
      dynamic item = msgList[i];
      Map<String, String> a = {};
      Map<dynamic, dynamic> map = (item as Map).cast<dynamic, dynamic>();
      map.forEach((key, value) {
        a[key.toString()] = value.toString();
      });

      msgs.add(a);
    }
    msgs.sort((a, b) {
      DateTime timestampA = DateTime.parse(a['timestamp']!);
      DateTime timestampB = DateTime.parse(b['timestamp']!);
      return timestampA.compareTo(timestampB);
    });
  }

  /// Utility method to easily make a [Map] from an [AnnouncementModel]
  ///
  /// Invoke [toMap] when writing a [AnnouncementModel] object to an event document in the database
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'color': color.value.toRadixString(16).substring(2).toUpperCase(),
      'msgs': msgs,
    };
  }

  /// updates the announcement specified by the provided [id] with the
  /// given [updates]
  ///
  /// Firebase will merge the target data with the incoming data
  static Future<void> updateAnnouncementById(
      String chapterid, String id, List<Map<String, dynamic>> updates) async {
    AppInfo.database
        .collection('chapters')
        .doc(chapterid)
        .collection('announcements')
        .doc(id)
        .update({'msgs': updates});
  }

  /// gets all of the sent announcements as a [List] of [AnnouncementModel]s
  ///
  ///
  static Future<List<AnnouncementModel>> getAnnouncements(
      String chapterid) async {
    QuerySnapshot announcementQuery = await AppInfo.database
        .collection('chapters')
        .doc(chapterid)
        .collection('announcements')
        .get();
    return announcementQuery.docs
        .map((snapshot) =>
            AnnouncementModel.fromDocumentSnapshot(snapshot, chapterid))
        .toList();
  }

  static Future<void> configureFirebaseMessaging() async {
    if (kIsWeb) {
      return;
    }

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      FlutterAppBadgeControl.removeBadge();
    });
  }

  Future<void> subscribeNotif() async {
    await FirebaseMessaging.instance.subscribeToTopic(id);
  }

  Future<void> unsubscribeNotif() async {
    await FirebaseMessaging.instance.unsubscribeFromTopic(id);
  }

  static Future<void> createChat(AnnouncementModel a) async {
    AppInfo.database
        .collection("chapters")
        .doc(AppInfo.currentUser.currentChapter)
        .collection('announcements')
        .add(a.toMap());
  }
}
