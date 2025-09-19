import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/message_service.dart';
import '../../models/message.dart';
import '../../models/app_user.dart';

/// 管理者用サポートチャット管理画面
class AdminSupportChatManagementScreen extends StatefulWidget {
  const AdminSupportChatManagementScreen({super.key});

  @override
  State<AdminSupportChatManagementScreen> createState() => _AdminSupportChatManagementScreenState();
}

class _AdminSupportChatManagementScreenState extends State<AdminSupportChatManagementScreen> {
  final AuthService _authService = AuthService();
  final MessageService _messageService = MessageService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  String? _selectedUserId;
  String? _selectedUserName;
  String? _selectedConversationId;
  String? _currentAdminId;
  bool _isSending = false;
  final Map<String, int> _unreadCounts = {};
  final Map<String, Message?> _lastMessages = {};
  final Map<String, AppUser> _usersCache = {};

  @override
  void initState() {
    super.initState();
    _initializeAdmin();
    _loadSupportConversations();
    // 10秒ごとにサポート会話を更新
    Future.delayed(Duration.zero, () {
      Timer.periodic(const Duration(seconds: 10), (timer) {
        if (mounted) {
          _loadSupportConversations();
        } else {
          timer.cancel();
        }
      });
    });
  }

  Future<void> _initializeAdmin() async {
    final user = _authService.currentUser;
    if (user != null) {
      setState(() {
        _currentAdminId = user.uid;
      });
    }
  }

  Future<void> _loadSupportConversations() async {
    try {
      _unreadCounts.clear();
      _lastMessages.clear();
      _usersCache.clear();
      
      // メッセージコレクションから直接support_team関連のメッセージを取得
      
      QuerySnapshot messagesAsReceiver;
      QuerySnapshot messagesAsSender;
      
      try {
        // support_teamが受信者のメッセージを取得
        messagesAsReceiver = await FirebaseFirestore.instance
            .collection('messages')
            .where('receiverId', isEqualTo: 'support_team')
            .orderBy('createdAt', descending: true)
            .get();
      } catch (e) {
        // インデックスエラーの場合、orderByなしで試す
        messagesAsReceiver = await FirebaseFirestore.instance
            .collection('messages')
            .where('receiverId', isEqualTo: 'support_team')
            .get();
      }
      
      try {
        // support_teamが送信者のメッセージを取得
        messagesAsSender = await FirebaseFirestore.instance
            .collection('messages')
            .where('senderId', isEqualTo: 'support_team')
            .orderBy('createdAt', descending: true)
            .get();
      } catch (e) {
        // インデックスエラーの場合、orderByなしで試す
        messagesAsSender = await FirebaseFirestore.instance
            .collection('messages')
            .where('senderId', isEqualTo: 'support_team')
            .get();
      }
      
      
      // ユーザーIDごとにメッセージをグループ化
      final Map<String, List<QueryDocumentSnapshot>> userMessages = {};
      
      for (var doc in messagesAsReceiver.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final senderId = data['senderId'] as String? ?? '';
        if (senderId != 'support_team' && senderId.isNotEmpty) {
          userMessages.putIfAbsent(senderId, () => []).add(doc);
        }
      }
      
      for (var doc in messagesAsSender.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final receiverId = data['receiverId'] as String? ?? '';
        if (receiverId != 'support_team') {
          userMessages.putIfAbsent(receiverId, () => []).add(doc);
        }
      }
      
      
      // 各ユーザーの情報を取得
      
      for (var userId in userMessages.keys) {
        
        if (userId.isNotEmpty) {
          // ユーザー情報を取得
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
          
          if (userDoc.exists) {
            final userData = userDoc.data()!;
            
            // AppUserにデータを変換
            if (userData['createdAt'] != null && userData['createdAt'] is! Timestamp) {
              userData['createdAt'] = Timestamp.fromDate(DateTime.now());
            }
            
            final userName = userData['name'] ?? userData['displayName'] ?? userData['email']?.split('@')[0] ?? 'ユーザー';
            
            _usersCache[userId] = AppUser(
              uid: userId,
              email: userData['email'] ?? '',
              name: userName,
              isWasedaUser: userData['isWasedaUser'] ?? false,
              canCreateExperiment: userData['canCreateExperiment'] ?? false,
              createdAt: (userData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              participatedExperiments: userData['participatedExperiments'] ?? 0,
              goodCount: userData['goodCount'] ?? 0,
              badCount: userData['badCount'] ?? 0,
            );
          } else {
            // ユーザードキュメントが存在しない場合でも表示できるように
            final fallbackName = userId.length > 8 ? 'ユーザー (ID: ${userId.substring(0, 8)}...)' : 'ユーザー';
            
            _usersCache[userId] = AppUser(
              uid: userId,
              email: '',
              name: fallbackName,
              isWasedaUser: false,
              canCreateExperiment: false,
              createdAt: DateTime.now(),
            );
          }

          // 最新メッセージと未読数を取得
          final messages = userMessages[userId]!;
          // メッセージを日付順にソート
          messages.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime = (aData['createdAt'] as Timestamp).toDate();
            final bTime = (bData['createdAt'] as Timestamp).toDate();
            return bTime.compareTo(aTime); // 降順
          });
          
          // 最新メッセージを設定
          if (messages.isNotEmpty) {
            final latestMessageData = messages.first.data() as Map<String, dynamic>;
            final conversationId = latestMessageData['conversationId'] ?? '';
            
            _lastMessages[userId] = Message(
              id: messages.first.id,
              senderId: latestMessageData['senderId'] ?? '',
              receiverId: latestMessageData['receiverId'] ?? '',
              conversationId: conversationId,
              content: latestMessageData['content'] ?? '',
              createdAt: (latestMessageData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              isRead: latestMessageData['isRead'] ?? false,
            );
            
            // 未読メッセージ数をカウント
            int unreadCount = 0;
            for (var msg in messages) {
              final msgData = msg.data() as Map<String, dynamic>;
              if (msgData['receiverId'] == 'support_team' && msgData['isRead'] == false) {
                unreadCount++;
              }
            }
            _unreadCounts[userId] = unreadCount;
          }
        }
      }
      
      _usersCache.forEach((id, user) {
      });

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
    }
  }

  Future<void> _selectConversation(String userId, String userName) async {
    setState(() {
      _selectedUserId = userId;
      _selectedUserName = userName;
    });

    // 実際の会話IDを取得または作成
    try {
      final conversationId = await _messageService.getOrCreateConversation(
        userId,
        'support_team',
        userName,
        'わせラボサポート',
      );
      
      setState(() {
        _selectedConversationId = conversationId;
      });
      

      // 選択した会話のメッセージを既読にする
      await _markMessagesAsRead(conversationId);
      _unreadCounts[userId] = 0;
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('会話の読み込みに失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markMessagesAsRead(String conversationId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final unreadMessages = await FirebaseFirestore.instance
          .collection('messages')
          .where('conversationId', isEqualTo: conversationId)
          .where('receiverId', isEqualTo: 'support_team')
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;
    if (_selectedUserId == null || _selectedUserName == null) return;

    setState(() {
      _isSending = true;
    });

    final messageContent = _messageController.text.trim();

    try {
      final conversationId = await _messageService.sendMessage(
        senderId: 'support_team',
        receiverId: _selectedUserId!,
        content: messageContent,
        senderName: 'わせラボサポート',
        receiverName: _selectedUserName!,
      );
      
      // 会話IDが変更された場合は更新
      if (_selectedConversationId != conversationId) {
        setState(() {
          _selectedConversationId = conversationId;
        });
      }
      
      _messageController.clear();
      _scrollToBottom();
      
      // 最新メッセージを更新
      _lastMessages[_selectedUserId!] = Message(
        id: '',
        senderId: 'support_team',
        receiverId: _selectedUserId!,
        conversationId: conversationId,
        content: messageContent,
        createdAt: DateTime.now(),
        isRead: false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('送信に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime dateTime) {
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
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('サポートチャット管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSupportConversations,
            tooltip: '更新',
          ),
        ],
      ),
      body: Row(
        children: [
          // 左側：ユーザーリスト
          Container(
            width: 300,
            decoration: BoxDecoration(
              color: Colors.grey[850],
              border: Border(
                right: BorderSide(
                  color: Colors.grey[700]!,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey[700]!,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.people,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'サポートチャット',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (_unreadCounts.values.any((unreadCount) => unreadCount > 0))
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_unreadCounts.values.fold(0, (total, unreadCount) => total + unreadCount)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: _usersCache.isEmpty
                      ? const Center(
                          child: Text(
                            'サポートチャットはありません',
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _usersCache.length,
                          itemBuilder: (context, index) {
                            final userId = _usersCache.keys.elementAt(index);
                            final user = _usersCache[userId]!;
                            final lastMessage = _lastMessages[userId];
                            final unreadCount = _unreadCounts[userId] ?? 0;
                            final isSelected = _selectedUserId == userId;

                            return InkWell(
                              onTap: () => _selectConversation(userId, user.name),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.blue.withValues(alpha: 0.2)
                                      : Colors.transparent,
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.grey[700]!,
                                      width: 0.5,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Colors.grey[700],
                                      child: Text(
                                        user.name[0].toUpperCase(),
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  user.name,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: unreadCount > 0
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                  ),
                                                ),
                                              ),
                                              if (lastMessage != null)
                                                Text(
                                                  _formatTime(lastMessage.createdAt),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[500],
                                                  ),
                                                ),
                                            ],
                                          ),
                                          if (lastMessage != null) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              lastMessage.content,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: unreadCount > 0
                                                    ? Colors.white70
                                                    : Colors.grey[500],
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    if (unreadCount > 0)
                                      Container(
                                        margin: const EdgeInsets.only(left: 8),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          unreadCount.toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          // 右側：チャット画面
          Expanded(
            child: _selectedUserId == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '左側からチャットを選択してください',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      // チャットヘッダー
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey[700]!,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.grey[700],
                              child: Text(
                                _selectedUserName![0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedUserName!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'ID: $_selectedUserId',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // メッセージエリア
                      Expanded(
                        child: StreamBuilder<List<Message>>(
                          stream: _messageService.getConversationMessages(_selectedConversationId!),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                                ),
                              );
                            }

                            if (snapshot.hasError) {
                              return Center(
                                child: Text(
                                  'エラー: ${snapshot.error}',
                                  style: const TextStyle(color: Colors.red),
                                ),
                              );
                            }

                            final messages = snapshot.data ?? [];

                            if (messages.isEmpty) {
                              return Center(
                                child: Text(
                                  'メッセージはまだありません',
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                              );
                            }

                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _scrollToBottom();
                            });

                            return ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                final message = messages[index];
                                final isSupport = message.senderId == 'support_team';

                                return Align(
                                  alignment: isSupport
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    constraints: BoxConstraints(
                                      maxWidth: MediaQuery.of(context).size.width * 0.5,
                                    ),
                                    child: Column(
                                      crossAxisAlignment: isSupport
                                          ? CrossAxisAlignment.end
                                          : CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSupport
                                                ? Colors.blue
                                                : Colors.grey[700],
                                            borderRadius: BorderRadius.only(
                                              topLeft: const Radius.circular(16),
                                              topRight: const Radius.circular(16),
                                              bottomLeft: Radius.circular(isSupport ? 16 : 4),
                                              bottomRight: Radius.circular(isSupport ? 4 : 16),
                                            ),
                                          ),
                                          child: Text(
                                            message.content,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 4),
                                          child: Text(
                                            '${message.createdAt.hour.toString().padLeft(2, '0')}:${message.createdAt.minute.toString().padLeft(2, '0')}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      // メッセージ入力エリア
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[850],
                          border: Border(
                            top: BorderSide(
                              color: Colors.grey[700]!,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                maxLines: null,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: '返信を入力...',
                                  hintStyle: TextStyle(color: Colors.grey[500]),
                                  filled: true,
                                  fillColor: Colors.grey[800],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                ),
                                onSubmitted: (_) => _sendMessage(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            CircleAvatar(
                              backgroundColor: Colors.blue,
                              radius: 24,
                              child: IconButton(
                                icon: Icon(
                                  _isSending ? Icons.hourglass_empty : Icons.send,
                                  color: Colors.white,
                                ),
                                onPressed: _isSending ? null : _sendMessage,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}