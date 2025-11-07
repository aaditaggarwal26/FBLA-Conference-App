part of 'models.dart';

/// [EventModel] encapsulates fields of a Firebase Event Document found in the 'events' Collection
///
/// Instantiate [EventModel] using a [DocumentSnapshot] with [EventModel.fromDocumentSnapshot] to easily
/// read fields from the document. When an update to the document is required, use [toMap] to
/// quickly transform the object into a [Map] and then write to the [DocumentReference]
class EventModel {
  /// the event's unique Firebase document id
  final String id;

  /// the name of the event
  final String name;

  /// a short textual description of the event details
  final String description;

  /// the date of the event stored in a 'YYYY-MM-DD' format
  final DateTime startDate;

  final DateTime endDate;

  /// **⚠️ UNDER CONSTRUCTION ⚠️**
  /// How is this used??

  /// the name of the location of the event
  final String location;

  /// a list of the names of the users who have attended the event
  final List<String> usersAttended;

  /// a link to an image to be displayed on the event card in the app
  final String image;

  final String eventType;

  final bool allDay;

  EventModel(
      {required this.id,
      required this.name,
      required this.description,
      required this.startDate,
      required this.endDate,
      required this.location,
      required this.usersAttended,
      required this.image,
      required this.allDay,
      required this.eventType});

  /// Utility constructor to easily make an [EventModel] from a [DocumentSnapshot]
  ///
  /// Queries the [DocumentSnapshot] for each field and instantiates [EventModel] accordingly
  EventModel.fromDocumentSnapshot(DocumentSnapshot<Object?> doc)
      : id = doc.id,
        name = doc.get('name') as String,
        description = doc.get('description') as String,
        startDate = (doc.get('startDate') as Timestamp).toDate().toLocal(),
        endDate = (doc.get('endDate') as Timestamp).toDate().toLocal(),
        location = doc.get('location') as String,
        usersAttended = (doc.get('usersAttended') as List).cast<String>(),
        image = doc.get('image') as String,
        allDay = doc.get('allDay') as bool,
        eventType = doc.get('eventType') as String;

  /// Utility method to easily make a [Map] from [EventModel]
  ///
  /// Invoke [toMap] when writing an [EventModel] object to an event document in the database
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'startDate': startDate,
      'endDate': endDate,
      'location': location,
      'usersAttended': usersAttended,
      'image': image,
      'allDay': allDay,
      'eventType': eventType,
      'type': 'event'
    };
  }

  factory EventModel.fromMap(Map<String, dynamic> map) {
    return EventModel(
        name: map['name'],
        description: map['description'],
        startDate: (map['startDate'] as Timestamp).toDate(),
        endDate: (map['endDate'] as Timestamp).toDate(),
        location: map['location'],
        usersAttended: (map['usersAttended'] as List).cast<String>(),
        id: map['id'],
        image: map['image'],
        allDay: (map['allDay'] as bool),
        eventType: map['eventType']);
  }

  /// Writes the provided [EventModel] object to the database
  ///
  /// Every field will be overwritten!
  static Future<void> writeEvent(EventModel event) async {
    AppInfo.database
        .collection("chapters")
        .doc(AppInfo.currentUser.currentChapter)
        .collection('timedObjects')
        .doc(event.id)
        .set(event.toMap());
  }

  static Future<void> createEvent(EventModel event) async {
    AppInfo.database
        .collection("chapters")
        .doc(AppInfo.currentUser.currentChapter)
        .collection('timedObjects')
        .add(event.toMap());
  }

  /// Updates the event specified by the provided [id] with [updates]
  ///
  /// Firebase will merge the target data with the provided data
  static Future<void> updateEventById(
      String id, Map<String, dynamic> updates) async {
    AppInfo.database
        .collection("chapters")
        .doc(AppInfo.currentUser.currentChapter)
        .collection('timedObjects')
        .doc(id)
        .update(updates);
  }

  /// Deletes the event specified by the provided [id]
  ///
  static void removeEventById(String id) {
    AppInfo.database
        .collection("chapters")
        .doc(AppInfo.currentUser.currentChapter)
        .collection('timedObjects')
        .doc(id)
        .delete();
  }

  /// Gets an event with the given [id]
  ///
  ///
  static Future<EventModel> getEventById(String id) async {
    DocumentSnapshot eventInfo = await AppInfo.database
        .collection("chapters")
        .doc(AppInfo.currentUser.currentChapter)
        .collection('timedObjects')
        .doc(id)
        .get();
    return EventModel.fromDocumentSnapshot(eventInfo);
  }

  /// Gets a [List] of all the current events as a [EventModel] objects
  ///
  ///
  static Future<List<EventModel>> getCurrentEvents() async {
    DateTime currentDate = DateTime.now().subtract(const Duration(days: 1));
    String formattedDate = DateFormat('MMMM d, yyyy').format(currentDate);
    String currentChapter = AppInfo.currentUser.currentChapter;

    QuerySnapshot eventQuery = await AppInfo.database
        .collection("chapters")
        .doc(currentChapter)
        .collection('timedObjects')
        .where("type", isEqualTo: "event")
        .where('startDate', isGreaterThanOrEqualTo: formattedDate)
        .where('endDate', isLessThanOrEqualTo: formattedDate)
        .orderBy('endDate')
        .get();
    dv.log(eventQuery.docs.length.toString());
    return (eventQuery.docs as List<dynamic>?)
            // ?.where((event) =>
            //     (event.data() as Map<String, dynamic>)
            //         .containsKey("description") &&
            //     (event.data() as Map<String, dynamic>)['type'] == 'event')
            ?.map((event) => EventModel.fromDocumentSnapshot(event))
            .toList() ??
        [];

    // return eventQuery.docs
    //     .map((snapshot) => EventModel.fromDocumentSnapshot(snapshot))
    //     .toList();
  }

  static Future<void> updateEvents() async {
    await EventModel.getCurrentEvents().then(
      (value) {
        AppInfo.currentEvents = value;
      },
    );
  }

  /// Gets a [List] of all past events as [EventModel] objects
  ///
  ///
  static Future<List<EventModel>> getPastEvents() async {
    DateTime currentDate = DateTime.now().subtract(const Duration(days: 1));
    String formattedDate = DateFormat('MMMM d, yyyy').format(currentDate);
    String currentChapter = AppInfo.currentUser.currentChapter;

    QuerySnapshot eventQuery = await AppInfo.database
        .collection("chapters")
        .doc(currentChapter)
        .collection('timedObjects')
        .where("type", isEqualTo: "event")
        .where('endDate', isGreaterThan: formattedDate)
        .orderBy('endDate')
        .get();

    dv.log(eventQuery.docs.length.toString());
    return (eventQuery.docs as List<dynamic>?)
            // ?.where((event) =>
            //     (event.data() as Map<String, dynamic>)
            //         .containsKey("description") &&
            //     (event.data() as Map<String, dynamic>)['type'] == 'event')
            ?.map((event) => EventModel.fromDocumentSnapshot(event))
            .toList() ??
        [];
  }

  /// adds user by [name] to the provided [event] document in Firebase
  ///
  ///
  static Future<void> recordUserAttendance(
      EventModel event, String name) async {
    AppInfo.database
        .collection("chapters")
        .doc(AppInfo.currentUser.currentChapter)
        .collection('events')
        .doc(event.id)
        .update({
      'usersAttended': FieldValue.arrayUnion([name]),
    });
  }
}
