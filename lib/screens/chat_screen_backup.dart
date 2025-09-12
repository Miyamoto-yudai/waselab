import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/message_service.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../models/message.dart';
import '../models/app_user.dart';
import '../widgets/custom_circle_avatar.dart';
import '../widgets/user_detail_dialog.dart';
import '../models/avatar_design.dart';

class ChatScreen extends StatefulWidget {
  final String? conversationId;
  final String otherUserId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final MessageService _messageService = MessageService();
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _currentUserId;
  String? _currentUserName;
  AppUser? _currentAppUser;
  AppUser? _otherUser;
  String? _actualConversationId;
  bool _isSending = false;
  bool _showTemplates = false;
  
  // 編集・リプライ関連
  Message? _editingMessage;
  Message? _replyingToMessage;
  String? _originalContent;

  @override
  void initState() {
    super.initState();
    _actualConversationId = widget.conversationId;
    _getCurrentUser();
    _getOtherUser();
    if (widget.conversationId != null && widget.conversationId!.isNotEmpty) {
      _markMessagesAsRead();
    }
  }

  Future<void> _getCurrentUser() async {
    final user = _authService.currentUser;
    if (user != null) {
      final appUser = await _authService.getCurrentAppUser();
      setState(() {
        _currentUserId = user.uid;
        _currentUserName = appUser?.name ?? 'Unknown';
        _currentAppUser = appUser;
      });
    }
  }

  Future<void> _getOtherUser() async {
    final user = await _userService.getUserById(widget.otherUserId);
    if (mounted) {
      setState(() {
        _otherUser = user;
      });
    }
  }

  void _markMessagesAsRead() {
    if (_currentUserId != null && _actualConversationId != null && _actualConversationId!.isNotEmpty) {
      _messageService.markMessagesAsRead(_actualConversationId!, _currentUserId!);
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;
    if (_currentUserId == null || _currentUserName == null) return;

    setState(() {
      _isSending = true;
    });

    try {
      if (_editingMessage != null) {
        // 編集モード
        await _messageService.editMessage(
          _editingMessage!.id,
          _messageController.text.trim(),
        );
        _cancelEdit();
      } else {
        // 新規送信またはリプライ
        final conversationId = await _messageService.sendMessage(
          senderId: _currentUserId!,
          receiverId: widget.otherUserId,
          content: _messageController.text.trim(),
          senderName: _currentUserName!,
          receiverName: widget.otherUserName,
          replyToMessageId: _replyingToMessage?.id,
          replyToContent: _replyingToMessage?.content,
          replyToSenderId: _replyingToMessage?.senderId,
        );
        
        if (_actualConversationId == null || _actualConversationId!.isEmpty) {
          setState(() {
            _actualConversationId = conversationId;
          });
        }
        _cancelReply();
      }
      
      _messageController.clear();
      _scrollToBottom();
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
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // メッセージ長押しメニューを表示
  void _showMessageOptions(BuildContext context, Message message) {
    final isMe = message.senderId == _currentUserId;
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // コピー
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('コピー'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: message.content));
                Navigator.pop(context);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text('メッセージをコピーしました'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
            // リプライ
            if (!message.isDeleted)
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text('リプライ'),
                onTap: () {
                  Navigator.pop(context);
                  _startReply(message);
                },
              ),
            // 転送
            if (!message.isDeleted)
              ListTile(
                leading: const Icon(Icons.forward),
                title: const Text('転送'),
                onTap: () {
                  Navigator.pop(context);
                  _forwardMessage(message);
                },
              ),
            // 編集（自分のメッセージのみ）
            if (isMe && !message.isDeleted)
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('編集'),
                onTap: () {
                  Navigator.pop(context);
                  _startEdit(message);
                },
              ),
            // 削除（自分のメッセージのみ）
            if (isMe && !message.isDeleted)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('削除', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(message);
                },
              ),
          ],
        ),
      ),
    );
  }

  // 編集開始
  void _startEdit(Message message) {
    setState(() {
      _editingMessage = message;
      _originalContent = message.content;
      _messageController.text = message.content;
      _replyingToMessage = null;
    });
  }

  // 編集キャンセル
  void _cancelEdit() {
    setState(() {
      _editingMessage = null;
      _originalContent = null;
      _messageController.clear();
    });
  }

  // リプライ開始
  void _startReply(Message message) {
    setState(() {
      _replyingToMessage = message;
      _editingMessage = null;
    });
  }

  // リプライキャンセル
  void _cancelReply() {
    setState(() {
      _replyingToMessage = null;
    });
  }

  // メッセージ削除確認
  void _confirmDelete(Message message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('メッセージを削除'),
        content: const Text('このメッセージを削除しますか？\n削除されたメッセージは「削除されました」と表示されます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteMessage(message);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  // メッセージ削除
  Future<void> _deleteMessage(Message message) async {
    try {
      await _messageService.deleteMessage(message.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('メッセージを削除しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('削除に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // メッセージ転送
  void _forwardMessage(Message message) {
    _showForwardDialog(message);
  }
  
  // 転送先選択ダイアログ
  Future<void> _showForwardDialog(Message message) async {
    final conversations = await _messageService.getUserConversations(_currentUserId!).first;
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('転送先を選択'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: conversations.isEmpty
              ? const Center(
                  child: Text('転送先がありません'),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: conversations.length,
                  itemBuilder: (context, index) {
                    final conversation = conversations[index];
                    final otherUserId = conversation.participantIds
                        .firstWhere((id) => id != _currentUserId);
                    final otherUserName = conversation.participantNames[otherUserId] ?? 'Unknown';
                    
                    // 現在の会話相手を除外
                    if (otherUserId == widget.otherUserId) {
                      return const SizedBox.shrink();
                    }
                    
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF8E1728),
                        child: Text(
                          otherUserName.isNotEmpty ? otherUserName[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(otherUserName),
                      subtitle: Text(
                        conversation.lastMessage ?? 'メッセージなし',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () async {
                        Navigator.pop(context);
                        await _sendForwardedMessage(message, otherUserId, otherUserName);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }
  
  // 転送メッセージを送信
  Future<void> _sendForwardedMessage(Message originalMessage, String receiverId, String receiverName) async {
    try {
      final originalSenderName = originalMessage.senderId == _currentUserId 
          ? 'あなた' 
          : widget.otherUserName;
      
      await _messageService.forwardMessage(
        originalMessageId: originalMessage.id,
        senderId: _currentUserId!,
        receiverId: receiverId,
        senderName: _currentUserName!,
        receiverName: receiverName,
        forwardedContent: originalMessage.content,
        originalSenderName: originalSenderName,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$receiverNameさんにメッセージを転送しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('転送に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.otherUserName),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUserName),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => UserDetailDialog(
                  userId: widget.otherUserId,
                  userName: widget.otherUserName,
                ),
              );
            },
            tooltip: 'ユーザー詳細',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _actualConversationId != null && _actualConversationId!.isNotEmpty
                  ? _messageService.getConversationMessages(_actualConversationId!)
                  : Stream.value([]),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8E1728)),
                    ),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return const Center(
                    child: Text('メッセージを開始しましょう'),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == _currentUserId;

                    return GestureDetector(
                      onLongPress: () => _showMessageOptions(context, message),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                          children: [
                            Flexible(
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                                ),
                                child: Column(
                                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                  children: [
                                    // リプライ表示
                                    if (message.replyToContent != null)
                                      Container(
                                        margin: const EdgeInsets.only(bottom: 4),
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              message.replyToSenderId == _currentUserId ? 'あなた' : widget.otherUserName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              message.replyToContent!,
                                              style: const TextStyle(fontSize: 12),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    // メッセージ本体
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: message.isDeleted
                                            ? Colors.grey.shade300
                                            : isMe
                                                ? const Color(0xFF8E1728)
                                                : Colors.white,
                                        border: isMe || message.isDeleted
                                            ? null
                                            : Border.all(color: Colors.grey.shade300),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            message.isDeleted ? 'このメッセージは削除されました' : message.content,
                                            style: TextStyle(
                                              color: message.isDeleted
                                                  ? Colors.grey.shade600
                                                  : isMe
                                                      ? Colors.white
                                                      : Colors.black87,
                                              fontStyle: message.isDeleted ? FontStyle.italic : null,
                                            ),
                                          ),
                                          if (message.isEdited && !message.isDeleted)
                                            Text(
                                              '(編集済み)',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: isMe ? Colors.white70 : Colors.grey,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    // 時刻
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        _formatTime(message.createdAt),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ],
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
          // 編集中/リプライ中の表示
          if (_editingMessage != null || _replyingToMessage != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey.shade100,
              child: Row(
                children: [
                  Icon(
                    _editingMessage != null ? Icons.edit : Icons.reply,
                    size: 20,
                    color: Colors.grey.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _editingMessage != null ? '編集中' : 'リプライ',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _editingMessage?.content ?? _replyingToMessage?.content ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: _editingMessage != null ? _cancelEdit : _cancelReply,
                  ),
                ],
              ),
            ),
          // 入力フィールド
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(8),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: _editingMessage != null ? '編集内容を入力' : 'メッセージを入力',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: const Color(0xFF8E1728),
                    child: IconButton(
                      icon: Icon(
                        _editingMessage != null ? Icons.check : Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: _isSending ? null : _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}