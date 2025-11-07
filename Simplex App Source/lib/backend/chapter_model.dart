part of 'models.dart';

class ChapterModel {
  final String name;

  final String headerPic;

  final List<String> users;

  final bool parentalApproval;

  final Map<String, bool> modules;

  final String id;

  ChapterModel({
    required this.id,
    required this.name,
    required this.headerPic,
    required this.users,
    required this.parentalApproval,
    required this.modules,
  });

  ChapterModel.fromDocumentSnapshot(DocumentSnapshot<Object?> doc)
      : id = doc.id,
        name = doc.get("name") as String,
        headerPic = doc.get("headerPic") as String,
        users = (doc.get("users") as List).cast<String>(),
        parentalApproval = doc.get("parentalApproval") as bool,
        modules = (doc.get("modules") as Map).cast<String, bool>();

  static Future<void> joinChapter(String chapterID) async {
    AppInfo.database.collection("chapters").doc(chapterID).update({
      'users': FieldValue.arrayUnion([AppInfo.currentUser.id])
    });

    UserModel.addChapter(AppInfo.currentUser, chapterID);
  }
}
