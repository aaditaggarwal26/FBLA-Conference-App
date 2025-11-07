part of 'models.dart';

// TODO: THIS CLASS IS CURRENTLY NOT FULLY IMPLEMENTED
/// **⚠️ UNDER CONSTRUCTION ⚠️**
///
/// [CompEventModel] encapsulates fields of a Firebase Competitive Event Document found
/// in the 'compEvents' collection
///
/// Instantiate [CompEventModel] using a [DocumentSnapshot] with [CompEventModel.fromDocumentSnapshot] to easily
/// read fields from the document. When an update to the document is required, use [toMap] to
/// quickly transform the object into a [Map] and then write to the [DocumentReference]
class CompEventModel {
  /// the competitive event's unique id
  final String id;

  /// the competitive event's name
  final String name;

  /// a link to the rules for the competitive event
  final String url;

  final List<String> teams;

  /// the number of people that can be on a team for the event
  final int teamSize;

  /// the category of the event
  final String category;

  CompEventModel({
    required this.id,
    required this.name,
    required this.url,
    required this.teams,
    required this.teamSize,
    required this.category,
  });

  /// Utility constructor to easily make a [CompEventModel] from a [DocumentSnapshot]
  ///
  /// Queries the [DocumentSnapshot] for each field and instantiates [CompEventModel] accordingly
  CompEventModel.fromDocumentSnapshot(DocumentSnapshot<Object?> doc)
      : id = doc.id,
        name = doc.get('name') as String,
        url = doc.get('url') as String,
        teams = (doc.get('teams') as List).cast<String>(),
        teamSize = doc.get('teamSize') as int,
        category = doc.get('category') as String;

  /// Utility method to easily make a [Map] from [CompEventModel]
  ///
  /// Invoke [toMap] when writing a [CompEventModel] object to an event document in the database
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'url': url,
      'teams': teams,
      'teamSize': teamSize,
      'category': category,
    };
  }

  /// writes the provided [event] object to the database
  ///
  /// Every field will be overwritten!
  static Future<void> writeCompEvent(CompEventModel event) async {
    AppInfo.database.collection('compEvents').doc(event.id).set(event.toMap());
  }

  /// updates a competitive event with the provided keys and values
  ///
  ///
  static Future<void> updateCompEventById(
      String id, Map<String, dynamic> updates) async {
    AppInfo.database.collection('compEvents').doc(id).update(updates);
  }

  /// deletes the competitive event specified by [id] from the database
  ///
  ///
  static Future<void> deleteCompEventById(String id) async {
    AppInfo.database.collection('compEvents').doc(id).delete;
  }

  /// gets a competitive event with the provided [id] as a [CompEventModel]
  static Future<CompEventModel> getCompEventById(String id) async {
    DocumentSnapshot compEvent =
        await AppInfo.database.collection('compEvents').doc(id).get();
    return CompEventModel.fromDocumentSnapshot(compEvent);
  }
}
