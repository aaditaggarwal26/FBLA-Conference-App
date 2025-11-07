import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../backend/pin_trading/message_service.dart';
import '../../backend/pin_trading/message_model.dart';
import '../flutter_flow/flutter_flow_theme.dart';
import 'chat_page.dart';

class MessagesListPage extends StatelessWidget {
  const MessagesListPage({super.key});

  Future<Map<String, String>> _getUserNames(List<String> userIds) async {
    final Map<String, String> userNames = {};
    
    for (final userId in userIds) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        
        if (userDoc.exists) {
          final data = userDoc.data();
          userNames[userId] = data?['name'] ?? 'User';
        }
      } catch (e) {
        userNames[userId] = 'User';
      }
    }
    
    return userNames;
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F6F7),
        body: const Center(child: Text('Please sign in to view messages')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F7),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              floating: true,
              pinned: true,
              snap: false,
              elevation: 0,
              backgroundColor: FlutterFlowTheme.of(context).primary,
              expandedHeight: 140,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        FlutterFlowTheme.of(context).primary,
                        FlutterFlowTheme.of(context).secondary,
                      ],
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.fromLTRB(24, 80, 24, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '💬 Messages',
                          style: TextStyle(
                            fontFamily: 'Google Sans',
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Your pin trading conversations',
                          style: TextStyle(
                            fontFamily: 'Google Sans',
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ];
        },
        body: StreamBuilder<List<ChatRoom>>(
          stream: MessageService().getUserChatRooms(currentUserId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final chatRooms = snapshot.data ?? [];

            if (chatRooms.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFD8DEFE), Color(0xFFB8C9FE)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 60,
                        color: Color(0xFF3B58F4),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'No messages yet',
                      style: TextStyle(
                        fontFamily: 'Google Sans',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start a conversation from pin details!',
                      style: TextStyle(
                        fontFamily: 'Google Sans',
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: chatRooms.length,
              itemBuilder: (context, index) {
                final chatRoom = chatRooms[index];
                final otherUserId = chatRoom.participants.firstWhere(
                  (id) => id != currentUserId,
                  orElse: () => '',
                );

                return FutureBuilder<Map<String, String>>(
                  future: _getUserNames([otherUserId]),
                  builder: (context, userSnapshot) {
                    final otherUserName =
                        userSnapshot.data?[otherUserId] ?? 'User';
                    final unreadCount = chatRoom.unreadCount[currentUserId] ?? 0;

                    return _buildChatRoomCard(
                      context,
                      chatRoom,
                      otherUserId,
                      otherUserName,
                      unreadCount,
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildChatRoomCard(
    BuildContext context,
    ChatRoom chatRoom,
    String otherUserId,
    String otherUserName,
    int unreadCount,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B58F4).withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatPage(
                  otherUserId: otherUserId,
                  otherUserName: otherUserName,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFD8DEFE), Color(0xFFB8C9FE)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      otherUserName.isNotEmpty
                          ? otherUserName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        fontFamily: 'Google Sans',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3B58F4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              otherUserName,
                              style: const TextStyle(
                                fontFamily: 'Google Sans',
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _formatTimestamp(chatRoom.lastMessageTime),
                            style: TextStyle(
                              fontFamily: 'Google Sans',
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chatRoom.lastMessage.isEmpty
                                  ? 'Start a conversation'
                                  : chatRoom.lastMessage,
                              style: TextStyle(
                                fontFamily: 'Google Sans',
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: unreadCount > 0
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (unreadCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF3B58F4), Color(0xFF526BF4)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                unreadCount.toString(),
                                style: const TextStyle(
                                  fontFamily: 'Google Sans',
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${timestamp.month}/${timestamp.day}';
    }
  }
}
