import 'package:flutter/material.dart';
import '../services/message_service.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../models/conversation.dart';
import '../models/app_user.dart';
import '../widgets/custom_circle_avatar.dart';
import '../models/avatar_design.dart';
import 'chat_screen.dart';
import 'support_chat_screen.dart';
import 'user_selection_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final MessageService _messageService = MessageService();
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _getCurrentUserId();
  }

  void _getCurrentUserId() {
    final user = _authService.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
      });
    }
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 7) {
      return '${dateTime.month}/${dateTime.day}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}日前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}時間前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分前';
    } else {
      return 'たった今';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return const Scaffold(
        body: Center(
          child: Text('ログインが必要です'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('メッセージ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.support_agent),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SupportChatScreen()),
              );
            },
            tooltip: 'サポート',
          ),
        ],
      ),
      body: StreamBuilder<List<Conversation>>(
        stream: _messageService.getUserConversations(_currentUserId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8E1728)),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'エラーが発生しました',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final conversations = snapshot.data ?? [];

          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.message_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'メッセージはまだありません',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ユーザーとメッセージを始めましょう',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SupportChatScreen()),
                      );
                    },
                    icon: const Icon(Icons.support_agent),
                    label: const Text('サポートに問い合わせる'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8E1728),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              final otherUserName = conversation.getOtherParticipantName(_currentUserId!);
              final otherUserId = conversation.getOtherParticipantId(_currentUserId!);
              final unreadCount = conversation.unreadCounts[_currentUserId] ?? 0;

              return FutureBuilder<AppUser?>(
                future: _userService.getUserById(otherUserId),
                builder: (context, userSnapshot) {
                  // ユーザー情報から最新の名前を取得
                  final latestUserName = userSnapshot.hasData && userSnapshot.data != null
                      ? userSnapshot.data!.name
                      : otherUserName;
                  
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    elevation: 1,
                    child: ListTile(
                      leading: userSnapshot.hasData && userSnapshot.data != null
                        ? CustomCircleAvatar(
                            frameId: userSnapshot.data!.selectedFrame,
                            radius: 20,
                            backgroundColor: const Color(0xFF8E1728),
                            designBuilder: userSnapshot.data!.selectedDesign != null && userSnapshot.data!.selectedDesign != 'default'
                                ? AvatarDesigns.getById(userSnapshot.data!.selectedDesign!).builder
                                : null,
                            child: userSnapshot.data!.selectedDesign == null || userSnapshot.data!.selectedDesign == 'default'
                                ? Text(
                                    latestUserName.isNotEmpty ? latestUserName[0].toUpperCase() : '?',
                                    style: const TextStyle(color: Colors.white),
                                  )
                                : null,
                          )
                        : CustomCircleAvatar(
                            frameId: null,
                            radius: 20,
                            backgroundColor: const Color(0xFF8E1728),
                            child: Text(
                              latestUserName.isNotEmpty ? latestUserName[0].toUpperCase() : '?',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              latestUserName,
                              style: TextStyle(
                                fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                      if (conversation.lastMessageTime != null)
                        Text(
                          _formatTime(conversation.lastMessageTime),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                  subtitle: Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.lastMessage ?? 'メッセージを開始',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: unreadCount > 0 ? Colors.black87 : Colors.grey[600],
                            fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8E1728),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                      onTap: () {
                        // 最新の名前をChatScreenに渡す
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              conversationId: conversation.id,
                              otherUserId: otherUserId,
                              otherUserName: latestUserName,
                            ),
                          ),
                        ).then((_) {
                          _messageService.markMessagesAsRead(conversation.id, _currentUserId!);
                        });
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showNewMessageDialog();
        },
        backgroundColor: const Color(0xFF8E1728),
        child: const Icon(Icons.add_comment),
      ),
    );
  }

  void _showNewMessageDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const UserSelectionScreen(),
      ),
    );
  }
}