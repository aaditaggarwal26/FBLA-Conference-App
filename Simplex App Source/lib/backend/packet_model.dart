part of 'models.dart';

/// [PacketModel] encapsulates fields of a Firebase Packet Document found in the 'packets' Collection
/// It also contains many helpful static methods for packet-related databse operations
///
/// Instantiate [PacketModel] using a [DocumentSnapshot] with [PacketModel.fromDocumentSnapshot] to easily
/// read fields from the document. When an update to the document is required, use [toMap] to
/// quickly transform the object into a [Map] and then write to the [DocumentReference]
class PacketModel {
  /// the unique id of the packet
  final String id;

  /// the name of the packet
  final String title;

  final String description;

  /// the url to be launched by the packet
  final String url;

  final String color;

  PacketModel({
    required this.id,
    required this.title,
    required this.description,
    required this.url,
    required this.color,
  });

  /// Utility constructor to easily make a [PacketModel] from a [DocumentSnapshot]
  ///
  /// Queries the [DocumentSnapshot] for each field and instantiates [PacketModel] accordingly
  PacketModel.fromDocumentSnapshot(DocumentSnapshot<Object?> doc)
      : id = doc.id,
        title = doc.get('title') as String,
        description = doc.get('description') as String,
        url = doc.get('url') as String,
        color = doc.get('color') as String;

  /// Utility method to easily make a [Map] from [PacketModel]
  ///
  /// Invoke [toMap] when writing a [PacketModel] object to an event's Firebase Document
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'url': url,
      'color': color
    };
  }

  /// Writes the provided [PacketModel] object to the database
  ///
  /// This will overwrite all fields!
  static Future<void> writePacket(PacketModel packet) async {
    AppInfo.database.collection('packets').doc(packet.id).set(packet.toMap());
  }

  /// Updates the specified packet with provided [updates]
  ///
  /// Firebase will merge target fields with incoming fields
  static Future<void> updatePacketById(
      String id, Map<String, dynamic> updates) async {
    AppInfo.database.collection('packets').doc(id).update(updates);
  }

  /// Deletes a packet from the database as specified by the [id]
  ///
  ///
  static void deletePacketById(String id) {
    AppInfo.database.collection('packets').doc(id).delete();
  }

  /// Gets the packet specified by the provided [id]
  ///
  ///
  static Future<PacketModel> getPacketById(String id) async {
    DocumentSnapshot packetQuery =
        await AppInfo.database.collection('packets').doc(id).get();
    return PacketModel.fromDocumentSnapshot(packetQuery);
  }

  static void removePacketById(String id) {
    AppInfo.database.collection("chapters").doc(AppInfo.currentUser.currentChapter).collection('packets').doc(id).delete();
  }

  /// Gets a [List] of the current packets as [PacketModel] objects
  ///
  ///
  static Future<List<PacketModel>> getPackets() async {
    QuerySnapshot packetQuery =
        await AppInfo.database.collection('packets').get();
    return packetQuery.docs
        .map((snapshot) => PacketModel.fromDocumentSnapshot(snapshot))
        .toList();
  }

  static Future<void> createPacket(PacketModel packet) async {
    AppInfo.database.collection("chapters").doc(AppInfo.currentUser.currentChapter).collection('packets').add(packet.toMap());
  }
}
