part of 'models.dart';

/// **⚠️ UNDER CONSTRUCTION ⚠️**\
/// [ChatroomModel] encapsulates fields of a Firebase Chatroom Document
///
/// This entire class needs to be redone in order to be generalized from
/// the ground up and optimally implemented. Research needs to be done
/// to figure out the best way to do this..
///
/// Furthermore, it needs to be implmeneted with the district privacy restirctions taken into consideration
///
/// THIS CLASS NEEDS TO BE SANITIZED
class ChatroomModel {
  final String id;
  final List<Map<String, String>> chats;
  final String studentUid;
  final bool readByBarnes;
  final bool readByStudent;
  final String advisorId;

  ChatroomModel(
      {required this.id,
      required this.chats,
      required this.studentUid,
      required this.readByBarnes,
      required this.readByStudent,
      required this.advisorId});

  /// THIS NEEDS TO BE SANITIZED
  static Future<List<ChatroomModel>> searchChatrooms(
      String search, int num, String advisorId) async {
    List<UserModel> users = await UserModel.searchUsers(search, num);
    List<ChatroomModel> chats = [];

    if (advisorId != "1HPfOe8jKzRX6Z4R8EgtQ5OTrCy1" &&
        advisorId != "45XDSFj7bLO5b622cwHxUegCQ973") {
      advisorId = "1HPfOe8jKzRX6Z4R8EgtQ5OTrCy1";
    }
    for (UserModel u in users) {
      try {
        DocumentSnapshot d = await AppInfo.database
            .collection('chatrooms')
            .doc(u.id + advisorId)
            .get();
        List<Map<String, String>> chatsList = [];
        List<dynamic> announcementList =
            (d.get('chats') as List).cast<dynamic>();

        for (int i = 0; i < announcementList.length; i++) {
          dynamic item = announcementList[i];
          Map<String, String> a = {};
          Map<dynamic, dynamic> map = (item as Map).cast<dynamic, dynamic>();
          map.forEach((key, value) {
            a[key.toString()] = value.toString();
          });

          chatsList.add(a);
        }
        chatsList.sort((a, b) {
          DateTime timestampA = DateTime.parse(a['timestamp']!);
          DateTime timestampB = DateTime.parse(b['timestamp']!);
          return timestampA.compareTo(timestampB);
        });

        chats.add(ChatroomModel(
            advisorId: advisorId,
            id: u.id + advisorId,
            chats: chatsList,
            studentUid: u.id,
            readByBarnes: d.get('readByBarnes') as bool,
            readByStudent: d.get('readByStudent') as bool));
      } catch (e) {
        continue;
      }
    }

    return chats;
  }

  /// THIS NEEDS TO BE SANITIZED
  static Future<void> addChatroom(String uid) async {
    Map<String, dynamic> chatInfo = {};
    chatInfo['readByBarnes'] = true;
    chatInfo['readByStudent'] = false;
    chatInfo['studentUid'] = uid;
    chatInfo['advisorId'] = "1HPfOe8jKzRX6Z4R8EgtQ5OTrCy1";
    chatInfo['chats'] = [
      {
        "imgURL": "",
        "senderName": "Ian Barnes",
        "senderPfp":
            "https://firebasestorage.googleapis.com/v0/b/mad3-269d4.appspot.com/o/profilepics%2F372906799_724627012809162_1467117906119225248_n.png?alt=media&token=0461fc64-ad69-482a-987a-bcd6590b2e36",
        "text":
            "This is an automatically generated message. Hello! Welcome to the chatroom where you can ask Mr. Barnes any questions, whether they pertain to a task, an event, or any other topic. Please ensure that all messages remain appropriate for a school setting, as they are being monitored.",
        "timestamp": DateTime.now().toUtc().toString(),
      }
    ];

    await AppInfo.database
        .collection('chatrooms')
        .doc("${uid}1HPfOe8jKzRX6Z4R8EgtQ5OTrCy1")
        .set(chatInfo);

    chatInfo['advisorId'] = "45XDSFj7bLO5b622cwHxUegCQ973";

    chatInfo['chats'] = [
      {
        "imgURL": "",
        "senderName": "Tomi Huesch",
        "senderPfp":
            "https://firebasestorage.googleapis.com/v0/b/mad3-269d4.appspot.com/o/profilepics%2FProfessional%20Headshot.jpg?alt=media&token=b2ce5aed-7755-4771-9e3f-fccba2b485bf&_gl=1*sakid3*_ga*MTQ0MDgyNTAyMC4xNjg2MzczOTY2*_ga_CW55HF8NVT*MTY5NzY2ODA1Ny4yOTUuMS4xNjk3NjY4MDcyLjQ1LjAuMA..",
        "text":
            "This is an automatically generated message. Hello! Welcome to the chatroom where you can ask Ms. Huesch any questions, whether they pertain to a task, an event, or any other topic. Please ensure that all messages remain appropriate for a school setting, as they are being monitored.",
        "timestamp": DateTime.now().toUtc().toString(),
      }
    ];

    await AppInfo.database
        .collection('chatrooms')
        .doc("${uid}45XDSFj7bLO5b622cwHxUegCQ973")
        .set(chatInfo);
  }

  /// THIS NEEDS TO BE SANITIZED
  static Future<void> updateChatroomStudent(
      String id, List<Map<String, String>> announcements) async {
    await AppInfo.database
        .collection('chatrooms')
        .doc(id)
        .update({'chats': announcements, 'readByBarnes': false});
  }

  /// THIS NEEDS TO BE SANITIZED
  static Future<void> updateChatroomBarnes(
      String id, List<Map<String, String>> announcements) async {
    await AppInfo.database
        .collection('chatrooms')
        .doc(id)
        .update({'chats': announcements, 'readByStudent': false});
  }

  /// THIS NEEDS TO BE SANITIZED
  static Future<void> readChatroomStudent(String id) async {
    await AppInfo.database
        .collection('chatrooms')
        .doc(id)
        .update({'readByStudent': true});
  }

  /// THIS NEEDS TO BE SANITIZED
  static Future<void> readChatroomBarnes(String id) async {
    await AppInfo.database
        .collection('chatrooms')
        .doc(id)
        .update({'readByBarnes': true});
  }

  /// THIS NEEDS TO BE SANITIZED
  static Future<List<ChatroomModel>> getChatroomsAdmin(String id) async {
    if (id != "1HPfOe8jKzRX6Z4R8EgtQ5OTrCy1" &&
        id != "45XDSFj7bLO5b622cwHxUegCQ973") {
      id = "1HPfOe8jKzRX6Z4R8EgtQ5OTrCy1";
    }

    QuerySnapshot chatRef = await AppInfo.database
        .collection('chatrooms')
        .where('advisorId', isEqualTo: id)
        .where('readByBarnes', isEqualTo: false)
        .get();

    List<ChatroomModel> chats = [];
    for (QueryDocumentSnapshot chat in chatRef.docs) {
      List<Map<String, String>> chatsList = [];
      List<dynamic> announcementList =
          (chat.get('chats') as List).cast<dynamic>();

      for (int i = 0; i < announcementList.length; i++) {
        dynamic item = announcementList[i];
        Map<String, String> a = {};
        Map<dynamic, dynamic> map = (item as Map).cast<dynamic, dynamic>();
        map.forEach((key, value) {
          a[key.toString()] = value.toString();
        });

        chatsList.add(a);
      }
      chatsList.sort((a, b) {
        DateTime timestampA = DateTime.parse(a['timestamp']!);
        DateTime timestampB = DateTime.parse(b['timestamp']!);
        return timestampA.compareTo(timestampB);
      });

      chats.add(ChatroomModel(
        advisorId: id,
        id: chat.id,
        chats: chatsList,
        readByBarnes: chat.get('readByBarnes') as bool,
        readByStudent: chat.get('readByStudent') as bool,
        studentUid: chat.get('studentUid') as String,
      ));
    }

    return chats;
  }

  /// THIS NEEDS TO BE SANITIZED
  static Future<List<ChatroomModel>> getRecentChatrooms(String id) async {
    if (id != "1HPfOe8jKzRX6Z4R8EgtQ5OTrCy1" &&
        id != "45XDSFj7bLO5b622cwHxUegCQ973") {
      id = "1HPfOe8jKzRX6Z4R8EgtQ5OTrCy1";
    }

    QuerySnapshot chatRef = await AppInfo.database
        .collection('chatrooms')
        .where('advisorId', isEqualTo: id)
        .where('readByBarnes', isEqualTo: true)
        .get();

    List<ChatroomModel> chats = [];
    for (QueryDocumentSnapshot chat in chatRef.docs) {
      List<Map<String, String>> chatsList = [];
      List<dynamic> announcementList =
          (chat.get('chats') as List).cast<dynamic>();

      if (announcementList.length == 1) {
        continue;
      }

      for (int i = 0; i < announcementList.length; i++) {
        dynamic item = announcementList[i];
        Map<String, String> a = {};
        Map<dynamic, dynamic> map = (item as Map).cast<dynamic, dynamic>();
        map.forEach((key, value) {
          a[key.toString()] = value.toString();
        });

        chatsList.add(a);
      }
      chatsList.sort((a, b) {
        DateTime timestampA = DateTime.parse(a['timestamp']!);
        DateTime timestampB = DateTime.parse(b['timestamp']!);
        return timestampA.compareTo(timestampB);
      });

      chats.add(ChatroomModel(
        advisorId: id,
        id: chat.id,
        chats: chatsList,
        readByBarnes: chat.get('readByBarnes') as bool,
        readByStudent: chat.get('readByStudent') as bool,
        studentUid: chat.get('studentUid') as String,
      ));
    }

    chats.sort((a, b) {
      DateTime a1 = DateTime.parse(a.chats[a.chats.length - 1]['timestamp']!);
      DateTime a2 = DateTime.parse(b.chats[b.chats.length - 1]['timestamp']!);
      return a2.compareTo(a1);
    });
    return chats;
  }

  /// THIS NEEDS TO BE SANITIZED
  static Future<ChatroomModel> getChatroomWithId(UserModel u, String id) async {
    if (AppInfo.isAdmin &&
        (id != "1HPfOe8jKzRX6Z4R8EgtQ5OTrCy1" &&
            id != "45XDSFj7bLO5b622cwHxUegCQ973")) {
      id = "1HPfOe8jKzRX6Z4R8EgtQ5OTrCy1";
    }
    //log(id);
    List<Map<String, String>> chatsList = [];
    DocumentSnapshot announcementDoc1 =
        await AppInfo.database.collection('chatrooms').doc(u.id + id).get();
    List<dynamic> announcementList =
        (announcementDoc1.get('chats') as List).cast<dynamic>();

    for (int i = 0; i < announcementList.length; i++) {
      dynamic item = announcementList[i];
      Map<String, String> a = {};
      Map<dynamic, dynamic> map = (item as Map).cast<dynamic, dynamic>();
      map.forEach((key, value) {
        a[key.toString()] = value.toString();
      });

      chatsList.add(a);
    }
    chatsList.sort((a, b) {
      DateTime timestampA = DateTime.parse(a['timestamp']!);
      DateTime timestampB = DateTime.parse(b['timestamp']!);
      return timestampA.compareTo(timestampB);
    });

    return ChatroomModel(
        advisorId: id,
        id: u.id + id,
        chats: chatsList,
        studentUid: u.id,
        readByBarnes: announcementDoc1.get('readByBarnes') as bool,
        readByStudent: announcementDoc1.get('readByStudent') as bool);
  }

  /// THIS NEEDS TO BE SANITIZED
  static Future<List<ChatroomModel>> getChatroom(UserModel u) async {
    List<Map<String, String>> chatsList = [];
    List<Map<String, String>> chatsList2 = [];
    try {
      List<ChatroomModel> c = [];
      DocumentSnapshot announcementDoc1 = await AppInfo.database
          .collection('chatrooms')
          .doc("${u.id}1HPfOe8jKzRX6Z4R8EgtQ5OTrCy1")
          .get();
      DocumentSnapshot announcementDoc2 = await AppInfo.database
          .collection('chatrooms')
          .doc("${u.id}45XDSFj7bLO5b622cwHxUegCQ973")
          .get();

      List<dynamic> announcementList =
          (announcementDoc1.get('chats') as List).cast<dynamic>();
      List<dynamic> announcementList2 =
          (announcementDoc2.get('chats') as List).cast<dynamic>();

      for (int i = 0; i < announcementList.length; i++) {
        dynamic item = announcementList[i];
        Map<String, String> a = {};
        Map<dynamic, dynamic> map = (item as Map).cast<dynamic, dynamic>();
        map.forEach((key, value) {
          a[key.toString()] = value.toString();
        });

        chatsList.add(a);
      }
      chatsList.sort((a, b) {
        DateTime timestampA = DateTime.parse(a['timestamp']!);
        DateTime timestampB = DateTime.parse(b['timestamp']!);
        return timestampA.compareTo(timestampB);
      });

      for (int i = 0; i < announcementList2.length; i++) {
        dynamic item = announcementList2[i];
        Map<String, String> a = {};
        Map<dynamic, dynamic> map = (item as Map).cast<dynamic, dynamic>();
        map.forEach((key, value) {
          a[key.toString()] = value.toString();
        });

        chatsList2.add(a);
      }
      chatsList2.sort((a, b) {
        DateTime timestampA = DateTime.parse(a['timestamp']!);
        DateTime timestampB = DateTime.parse(b['timestamp']!);
        return timestampA.compareTo(timestampB);
      });
      c.add(ChatroomModel(
          advisorId: "1HPfOe8jKzRX6Z4R8EgtQ5OTrCy1",
          id: "${u.id}1HPfOe8jKzRX6Z4R8EgtQ5OTrCy1",
          chats: chatsList,
          studentUid: u.id,
          readByBarnes: announcementDoc1.get('readByBarnes') as bool,
          readByStudent: announcementDoc1.get('readByStudent') as bool));

      c.add(ChatroomModel(
          advisorId: "45XDSFj7bLO5b622cwHxUegCQ973",
          id: "${u.id}45XDSFj7bLO5b622cwHxUegCQ973",
          chats: chatsList2,
          studentUid: u.id,
          readByBarnes: announcementDoc2.get('readByBarnes') as bool,
          readByStudent: announcementDoc2.get('readByStudent') as bool));

      return c;
    } catch (e) {
      Map<String, dynamic> chatInfo = {};
      chatInfo['readByBarnes'] = true;
      chatInfo['readByStudent'] = false;
      chatInfo['studentUid'] = u.id;
      chatInfo['advisorId'] = "1HPfOe8jKzRX6Z4R8EgtQ5OTrCy1";
      List<ChatroomModel> c = [];

      List<Map<String, String>> chat = [
        {
          "imgURL": "",
          "senderName": "Ian Barnes",
          "senderPfp":
              "https://firebasestorage.googleapis.com/v0/b/mad3-269d4.appspot.com/o/profilepics%2F372906799_724627012809162_1467117906119225248_n.png?alt=media&token=0461fc64-ad69-482a-987a-bcd6590b2e36",
          "text":
              "This is an automatically generated message. Hi! This is a chatroom where you can ask Mr. Barnes any questions — whether they be about a task, event, etc. Make sure to keep it school appropriate — all messages are monitored.",
          "timestamp": DateTime.now().toUtc().toString(),
        }
      ];
      chatInfo['chats'] = chat;
      c.add(ChatroomModel(
          advisorId: "1HPfOe8jKzRX6Z4R8EgtQ5OTrCy1",
          id: "${u.id}1HPfOe8jKzRX6Z4R8EgtQ5OTrCy1",
          chats: chat,
          studentUid: u.id,
          readByBarnes: true,
          readByStudent: false));

      AppInfo.database
          .collection('chatrooms')
          .doc("${u.id}1HPfOe8jKzRX6Z4R8EgtQ5OTrCy1")
          .set(chatInfo);

      chat = [
        {
          "imgURL": "",
          "senderName": "Tomi Huesch",
          "senderPfp":
              "https://firebasestorage.googleapis.com/v0/b/mad3-269d4.appspot.com/o/profilepics%2FProfessional%20Headshot.jpg?alt=media&token=b2ce5aed-7755-4771-9e3f-fccba2b485bf&_gl=1*sakid3*_ga*MTQ0MDgyNTAyMC4xNjg2MzczOTY2*_ga_CW55HF8NVT*MTY5NzY2ODA1Ny4yOTUuMS4xNjk3NjY4MDcyLjQ1LjAuMA..",
          "text":
              "This is an automatically generated message. Hi! This is a chatroom where you can ask Ms. Huesch any questions — whether they be about a task, event, etc. Make sure to keep it school appropriate — all messages are monitored.",
          "timestamp": DateTime.now().toUtc().toString(),
        }
      ];

      chatInfo['chats'] = chat;

      chatInfo['advisorId'] = "45XDSFj7bLO5b622cwHxUegCQ973";

      AppInfo.database
          .collection('chatrooms')
          .doc("${u.id}45XDSFj7bLO5b622cwHxUegCQ973")
          .set(chatInfo);

      c.add(ChatroomModel(
          advisorId: "45XDSFj7bLO5b622cwHxUegCQ973",
          id: "${u.id}45XDSFj7bLO5b622cwHxUegCQ973",
          chats: chat,
          studentUid: u.id,
          readByBarnes: true,
          readByStudent: false));
      return c;
    }
  }
}
