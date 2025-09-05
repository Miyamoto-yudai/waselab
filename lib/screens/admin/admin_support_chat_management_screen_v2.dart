import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/message_service.dart';
import '../../models/message.dart';
import '../../models/app_user.dart';

/// 管理者用サポートチャット管理画面 V2（完全リライト版）
class AdminSupportChatManagementScreenV2 extends StatefulWidget {
  const AdminSupportChatManagementScreenV2({super.key});

  @override
  State<AdminSupportChatManagementScreenV2> createState() => _AdminSupportChatManagementScreenV2State();
}

class _AdminSupportChatManagementScreenV2State extends State<AdminSupportChatManagementScreenV2> {
  final MessageService _messageService = MessageService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _refreshTimer;
  
  String? _selectedUserId;
  String? _selectedUserName;
  String? _selectedConversationId;
  bool _isSending = false;
  final Map<String, AppUser> _usersCache = {};
  final Map<String, List<Message>> _userMessages = {};
  final Map<String, int> _unreadCounts = {};

  @override
  void initState() {
    super.initState();
    debugPrint('===== AdminSupportChatManagementScreenV2 initState =====');
    _loadAllSupportMessages();
    // 5秒ごとに自動更新
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _loadAllSupportMessages();
    });
  }
  
  @override
  void dispose() {
    _refreshTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAllSupportMessages() async {
    debugPrint('===== START Loading All Support Messages =====');
    
    try {
      // 1. conversationsコレクションからsupport_team関連の会話を取得
      debugPrint('Fetching conversations involving support_team...');
      
      // support_teamが参加者として含まれる会話を取得
      final conversationSnapshots = await FirebaseFirestore.instance
          .collection('conversations')
          .where('participantIds', arrayContains: 'support_team')
          .get();
      
      debugPrint('Found ${conversationSnapshots.docs.length} conversations with support_team');
      
      // 2. 各会話のメッセージを取得
      final Map<String, List<Message>> tempUserMessages = {};
      final Map<String, int> tempUnreadCounts = {};
      final Set<String> userIds = {};
      
      for (var conversationDoc in conversationSnapshots.docs) {
        final conversationId = conversationDoc.id;
        final data = conversationDoc.data();
        final participantIds = List<String>.from(data['participantIds'] ?? []);
        
        // support_team以外の参加者IDを取得
        final userId = participantIds.firstWhere(
          (id) => id != 'support_team',
          orElse: () => '',
        );
        
        if (userId.isEmpty) continue;
        
        userIds.add(userId);
        debugPrint('Processing conversation $conversationId for user $userId');
        
        // この会話のメッセージを取得（エラーハンドリング付き）
        try {
          final messagesSnapshot = await FirebaseFirestore.instance
              .collection('messages')
              .where('conversationId', isEqualTo: conversationId)
              .orderBy('createdAt', descending: true)
              .limit(50)
              .get();
          
          debugPrint('Found ${messagesSnapshot.docs.length} messages in conversation $conversationId');
          
          for (var messageDoc in messagesSnapshot.docs) {
            final message = Message.fromFirestore(messageDoc);
            tempUserMessages.putIfAbsent(userId, () => []).add(message);
            
            // 未読カウント
            if (message.receiverId == 'support_team' && !message.isRead) {
              tempUnreadCounts[userId] = (tempUnreadCounts[userId] ?? 0) + 1;
            }
          }
        } catch (e) {
          debugPrint('Error fetching messages for conversation $conversationId: $e');
          // インデックスエラーの場合は、orderByなしで試みる
          try {
            final messagesSnapshot = await FirebaseFirestore.instance
                .collection('messages')
                .where('conversationId', isEqualTo: conversationId)
                .limit(50)
                .get();
            
            debugPrint('Found ${messagesSnapshot.docs.length} messages in conversation $conversationId (without orderBy)');
            
            for (var messageDoc in messagesSnapshot.docs) {
              final message = Message.fromFirestore(messageDoc);
              tempUserMessages.putIfAbsent(userId, () => []).add(message);
              
              // 未読カウント
              if (message.receiverId == 'support_team' && !message.isRead) {
                tempUnreadCounts[userId] = (tempUnreadCounts[userId] ?? 0) + 1;
              }
            }
          } catch (e2) {
            debugPrint('Error fetching messages without orderBy: $e2');
          }
        }
      }
      
      // 3. 直接support_teamへのメッセージも取得（conversationIdがない古いメッセージ対策）
      debugPrint('Fetching direct messages to/from support_team...');
      
      // support_teamへのメッセージ
      final toSupportMessages = await FirebaseFirestore.instance
          .collection('messages')
          .where('receiverId', isEqualTo: 'support_team')
          .limit(50)
          .get();
      
      // support_teamからのメッセージ
      final fromSupportMessages = await FirebaseFirestore.instance
          .collection('messages')
          .where('senderId', isEqualTo: 'support_team')
          .limit(50)
          .get();
      
      debugPrint('Found ${toSupportMessages.docs.length} messages to support_team');
      debugPrint('Found ${fromSupportMessages.docs.length} messages from support_team');
      
      // 直接メッセージを処理
      for (var doc in [...toSupportMessages.docs, ...fromSupportMessages.docs]) {
        final data = doc.data();
        final senderId = data['senderId'] as String? ?? '';
        final receiverId = data['receiverId'] as String? ?? '';
        final userId = senderId == 'support_team' ? receiverId : senderId;
        
        if (userId.isNotEmpty && userId != 'support_team') {
          final message = Message.fromFirestore(doc);
          userIds.add(userId);
          
          // 既存のリストに追加（重複チェック）
          final existingMessages = tempUserMessages[userId] ?? [];
          if (!existingMessages.any((m) => m.id == message.id)) {
            tempUserMessages.putIfAbsent(userId, () => []).add(message);
            
            // 未読カウント
            if (receiverId == 'support_team' && !(data['isRead'] ?? false)) {
              tempUnreadCounts[userId] = (tempUnreadCounts[userId] ?? 0) + 1;
            }
          }
        }
      }
      
      debugPrint('Total users with support messages: ${userIds.length}');
      
      // 4. ユーザー情報を取得
      for (var userId in userIds) {
        debugPrint('Loading user info for: $userId');
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
          
          if (userDoc.exists) {
            final userData = userDoc.data()!;
            _usersCache[userId] = AppUser(
              uid: userId,
              email: userData['email'] ?? '',
              name: userData['name'] ?? userData['displayName'] ?? userData['email']?.split('@')[0] ?? 'ユーザー',
              isWasedaUser: userData['isWasedaUser'] ?? false,
              canCreateExperiment: userData['canCreateExperiment'] ?? false,
              createdAt: DateTime.now(),
            );
            debugPrint('User loaded: ${_usersCache[userId]!.name}');
          } else {
            _usersCache[userId] = AppUser(
              uid: userId,
              email: '',
              name: 'ユーザー (${userId.substring(0, 8)}...)',
              isWasedaUser: false,
              canCreateExperiment: false,
              createdAt: DateTime.now(),
            );
            debugPrint('User not found, using fallback name');
          }
        } catch (e) {
          debugPrint('Error loading user $userId: $e');
          _usersCache[userId] = AppUser(
            uid: userId,
            email: '',
            name: 'ユーザー',
            isWasedaUser: false,
            canCreateExperiment: false,
            createdAt: DateTime.now(),
          );
        }
      }
      
      // 5. メッセージをソート
      for (var entry in tempUserMessages.entries) {
        entry.value.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
      
      setState(() {
        _userMessages.clear();
        _userMessages.addAll(tempUserMessages);
        _unreadCounts.clear();
        _unreadCounts.addAll(tempUnreadCounts);
      });
      
      debugPrint('===== COMPLETED Loading Support Messages =====');
      debugPrint('Total users with conversations: ${_userMessages.length}');
    } catch (e) {
      debugPrint('CRITICAL ERROR in _loadAllSupportMessages: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('データ読み込みエラー: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectUser(String userId) async {
    debugPrint('Selecting user: $userId');
    
    setState(() {
      _selectedUserId = userId;
      _selectedUserName = _usersCache[userId]?.name ?? 'ユーザー';
    });
    
    // 会話IDを取得または作成
    try {
      final conversationId = await _messageService.getOrCreateConversation(
        userId,
        'support_team',
        _selectedUserName!,
        'わせラボサポート',
      );
      
      setState(() {
        _selectedConversationId = conversationId;
      });
      
      debugPrint('Conversation ID: $conversationId');
      
      // 未読メッセージを既読にする
      if (_unreadCounts[userId] != null && _unreadCounts[userId]! > 0) {
        await _markMessagesAsRead(userId);
      }
    } catch (e) {
      debugPrint('Error selecting user: $e');
    }
  }

  Future<void> _markMessagesAsRead(String userId) async {
    try {
      final messages = _userMessages[userId] ?? [];
      for (var message in messages) {
        if (message.receiverId == 'support_team' && !message.isRead) {
          await FirebaseFirestore.instance
              .collection('messages')
              .doc(message.id)
              .update({'isRead': true});
        }
      }
      
      setState(() {
        _unreadCounts[userId] = 0;
      });
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;
    if (_selectedUserId == null || _selectedConversationId == null) return;

    setState(() {
      _isSending = true;
    });

    try {
      await _messageService.sendMessage(
        senderId: 'support_team',
        receiverId: _selectedUserId!,
        content: _messageController.text.trim(),
        senderName: 'わせラボサポート',
        receiverName: _selectedUserName!,
      );
      
      _messageController.clear();
      _scrollToBottom();
      
      // メッセージリストを更新
      await _loadAllSupportMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('送信エラー: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSending = false;
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('サポートチャット管理'),
      ),
      body: Row(
        children: [
          // 左側: ユーザーリスト
          Container(
            width: 300,
            decoration: BoxDecoration(
              color: Colors.grey[850],
              border: Border(
                right: BorderSide(color: Colors.grey[700]!),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[700]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.support_agent, color: Colors.blue[400]),
                      const SizedBox(width: 8),
                      const Text(
                        'サポート履歴',
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
                            _unreadCounts.values.where((unreadCount) => unreadCount > 0).length.toString(),
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
                  child: _userMessages.isEmpty
                      ? const Center(
                          child: Text(
                            'サポートメッセージはありません',
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _userMessages.length,
                          itemBuilder: (context, index) {
                            final userId = _userMessages.keys.elementAt(index);
                            final user = _usersCache[userId];
                            final messages = _userMessages[userId]!;
                            final lastMessage = messages.isNotEmpty ? messages.first : null;
                            final unreadCount = _unreadCounts[userId] ?? 0;
                            final isSelected = _selectedUserId == userId;

                            return InkWell(
                              onTap: () => _selectUser(userId),
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
                                        (user?.name ?? 'U')[0].toUpperCase(),
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            user?.name ?? 'ユーザー',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: unreadCount > 0
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
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
          // 右側: チャット画面
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
                          '左側からユーザーを選択してください',
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
                          color: Colors.grey[850],
                          border: Border(
                            bottom: BorderSide(color: Colors.grey[700]!),
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.grey[700],
                              child: Text(
                                (_selectedUserName ?? 'U')[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedUserName ?? 'ユーザー',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'サポートチャット',
                                  style: TextStyle(
                                    color: Colors.grey[400],
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
                        child: _selectedConversationId == null
                            ? const Center(child: CircularProgressIndicator())
                            : StreamBuilder<List<Message>>(
                                stream: _messageService.getConversationMessages(_selectedConversationId!),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return const Center(child: CircularProgressIndicator());
                                  }

                                  final messages = snapshot.data!;
                                  
                                  if (messages.isEmpty) {
                                    return Center(
                                      child: Text(
                                        'メッセージがありません',
                                        style: TextStyle(color: Colors.grey[500]),
                                      ),
                                    );
                                  }

                                  return ListView.builder(
                                    controller: _scrollController,
                                    reverse: true,
                                    padding: const EdgeInsets.all(16),
                                    itemCount: messages.length,
                                    itemBuilder: (context, index) {
                                      final message = messages[messages.length - 1 - index];
                                      final isSupport = message.senderId == 'support_team';
                                      
                                      return Align(
                                        alignment: isSupport
                                            ? Alignment.centerRight
                                            : Alignment.centerLeft,
                                        child: Container(
                                          margin: const EdgeInsets.only(bottom: 8),
                                          padding: const EdgeInsets.all(12),
                                          constraints: BoxConstraints(
                                            maxWidth: MediaQuery.of(context).size.width * 0.4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSupport
                                                ? Colors.blue[600]
                                                : Colors.grey[700],
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            message.content,
                                            style: const TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                      ),
                      // 入力エリア
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[850],
                          border: Border(
                            top: BorderSide(color: Colors.grey[700]!),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'メッセージを入力',
                                  hintStyle: TextStyle(color: Colors.grey[500]),
                                  filled: true,
                                  fillColor: Colors.grey[800],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                ),
                                onSubmitted: (_) => _sendMessage(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: _isSending ? null : _sendMessage,
                              icon: Icon(
                                Icons.send,
                                color: _isSending ? Colors.grey : Colors.blue[400],
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
}