import 'package:cloud_firestore/cloud_firestore.dart';
import 'message_model.dart';

class MessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> getOrCreateChatRoom(String userId1, String userId2) async {
    final participants = [userId1, userId2]..sort();
    final chatRoomId = participants.join('_');

    final chatRoomDoc = await _firestore.collection('chatRooms').doc(chatRoomId).get();

    if (!chatRoomDoc.exists) {
      await _firestore.collection('chatRooms').doc(chatRoomId).set({
        'participants': participants,
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount': {userId1: 0, userId2: 0},
      });
    }

    return chatRoomId;
  }

  Future<void> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String receiverId,
    required String message,
    String? pinId,
  }) async {
    final messageData = MessageModel(
      id: '',
      senderId: senderId,
      receiverId: receiverId,
      message: message,
      timestamp: DateTime.now(),
      pinId: pinId,
    ).toFirestore();

    await _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .add(messageData);

    await _firestore.collection('chatRooms').doc(chatRoomId).update({
      'lastMessage': message,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCount.$receiverId': FieldValue.increment(1),
    });
  }

  Stream<List<MessageModel>> getMessages(String chatRoomId) {
    return _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<ChatRoom>> getUserChatRooms(String userId) {
    return _firestore
        .collection('chatRooms')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ChatRoom.fromFirestore(doc)).toList());
  }

  Future<void> markAsRead(String chatRoomId, String userId) async {
    await _firestore.collection('chatRooms').doc(chatRoomId).update({
      'unreadCount.$userId': 0,
    });
  }

  Future<void> deleteChatRoom(String chatRoomId) async {
    final messages = await _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .get();

    for (var doc in messages.docs) {
      await doc.reference.delete();
    }

    await _firestore.collection('chatRooms').doc(chatRoomId).delete();
  }
}
