import 'package:flutter/material.dart';
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
      final conversationId = await _messageService.sendMessage(
        senderId: _currentUserId!,
        receiverId: widget.otherUserId,
        content: _messageController.text.trim(),
        senderName: _currentUserName!,
        receiverName: widget.otherUserName,
      );
      
      if (_actualConversationId == null || _actualConversationId!.isEmpty) {
        setState(() {
          _actualConversationId = conversationId;
        });
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

  void _selectTemplate(String templateType) {
    final templates = _getQuickTemplates();
    final selected = templates.firstWhere(
      (t) => t['type'] == templateType,
      orElse: () => <String, dynamic>{},
    );
    if (selected.isNotEmpty) {
      _messageController.text = selected['template'] as String;
      setState(() {
        _showTemplates = false;
      });
    }
  }

  List<Map<String, dynamic>> _getQuickTemplates() {
    final userInfo = _currentAppUser?.name ?? '[お名前]';
    String affiliation = '';
    
    if (_currentAppUser != null && _currentAppUser!.isWasedaUser) {
      affiliation = '早稲田大学';
      if (_currentAppUser!.department != null) {
        affiliation += _currentAppUser!.department!;
      }
      if (_currentAppUser!.grade != null) {
        affiliation += _currentAppUser!.grade!;
      }
      affiliation += 'の';
    }
    
    return [
      {
        'type': 'intro',
        'label': '自己紹介',
        'icon': Icons.person_outline,
        'template': 'お世話になっております。\n'
            '$affiliation$userInfoと申します。\n\n'
            '実験を拝見し、大変興味を持ちました。\n'
            'ぜひ参加させていただきたく、ご連絡差し上げました。\n\n'
            '実験の詳細について、いくつかお伺いしたいことがございます。\n'
            'お忙しいところ恐れ入りますが、ご教示いただけますと幸いです。\n\n'
            'どうぞよろしくお願いいたします。',
      },
      {
        'type': 'question',
        'label': '質問',
        'icon': Icons.help_outline,
        'template': 'お世話になっております。$userInfoです。\n\n'
            '実験について、以下の点をお伺いできますでしょうか。\n\n'
            '1. \n'
            '2. \n\n'
            'お手数をおかけしますが、ご回答いただけますと幸いです。\n'
            'よろしくお願いいたします。',
      },
      {
        'type': 'schedule',
        'label': '日程調整',
        'icon': Icons.calendar_today,
        'template': 'お世話になっております。$userInfoです。\n\n'
            '実験に参加させていただきたく存じます。\n\n'
            '私の参加可能な日時は以下の通りです：\n'
            '・\n'
            '・\n\n'
            '上記の中でご都合のよろしい日時はございますでしょうか。\n'
            'ご検討のほど、よろしくお願いいたします。',
      },
      {
        'type': 'requirements',
        'label': '参加条件',
        'icon': Icons.checklist,
        'template': 'お世話になっております。$userInfoです。\n\n'
            '実験への参加を検討しております。\n'
            '参加条件について確認させていただけますでしょうか。\n\n'
            'ご確認のほど、よろしくお願いいたします。',
      },
      {
        'type': 'access',
        'label': 'アクセス',
        'icon': Icons.location_on,
        'template': 'お世話になっております。$userInfoです。\n\n'
            '実験会場へのアクセスについて、\n'
            '詳細を教えていただけますでしょうか。\n\n'
            'よろしくお願いいたします。',
      },
      {
        'type': 'thanks',
        'label': 'お礼',
        'icon': Icons.favorite,
        'template': 'お世話になっております。$userInfoです。\n\n'
            '先日は実験でお世話になり、\n'
            '誠にありがとうございました。\n\n'
            '貴重な経験をさせていただき、大変勉強になりました。\n'
            '今後ともどうぞよろしくお願いいたします。',
      },
    ];
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

                if (snapshot.hasError) {
                  return Center(
                    child: Text('エラー: ${snapshot.error}'),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'メッセージを開始しましょう',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                size: 16,
                                color: Colors.blue[700],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '下のテンプレートボタンから始められます',
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == _currentUserId;
                    
                    // 前のメッセージと同じ送信者かどうかをチェック（連続メッセージの判定）
                    final bool showAvatar = index == 0 || 
                        messages[index - 1].senderId != message.senderId ||
                        message.createdAt.difference(messages[index - 1].createdAt).inMinutes > 3;
                    
                    // 次のメッセージが同じ送信者かどうかをチェック（角丸の調整用）
                    final bool isLastInGroup = index == messages.length - 1 ||
                        messages[index + 1].senderId != message.senderId ||
                        messages[index + 1].createdAt.difference(message.createdAt).inMinutes > 3;

                    return Container(
                      margin: EdgeInsets.only(
                        top: showAvatar ? 8 : 2,
                        bottom: isLastInGroup ? 4 : 2,
                        left: isMe ? 48 : 0,
                        right: isMe ? 0 : 48,
                      ),
                      child: Row(
                        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 相手のアバター（左側）
                          if (!isMe) ...[
                            Container(
                              width: 36,
                              margin: const EdgeInsets.only(left: 4, right: 8),
                              child: showAvatar
                                  ? GestureDetector(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => UserDetailDialog(
                                            userId: widget.otherUserId,
                                            userName: widget.otherUserName,
                                          ),
                                        );
                                      },
                                      child: CustomCircleAvatar(
                                        frameId: _otherUser?.selectedFrame,
                                        radius: 18,
                                        backgroundColor: const Color(0xFF8E1728),
                                        designBuilder: _otherUser?.selectedDesign != null && _otherUser?.selectedDesign != 'default'
                                            ? AvatarDesigns.getById(_otherUser!.selectedDesign!).builder
                                            : null,
                                        child: _otherUser?.selectedDesign == null || _otherUser?.selectedDesign == 'default'
                                            ? Text(
                                                widget.otherUserName.isNotEmpty 
                                                  ? widget.otherUserName[0].toUpperCase() 
                                                  : '?',
                                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                              )
                                            : null,
                                      ),
                                    )
                                  : null,
                            ),
                          ],
                          // メッセージバブル
                          Flexible(
                            child: Column(
                              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                // 送信者名（相手のメッセージで、グループの最初の場合のみ）
                                if (!isMe && showAvatar)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 12, bottom: 2),
                                    child: Text(
                                      widget.otherUserName,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                // メッセージ本体
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? const Color(0xFF8E1728)
                                        : Colors.white,
                                    border: isMe ? null : Border.all(
                                      color: Colors.grey[300]!,
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(!isMe && showAvatar ? 4 : 16),
                                      topRight: Radius.circular(isMe && showAvatar ? 4 : 16),
                                      bottomLeft: Radius.circular(!isMe && isLastInGroup ? 16 : 4),
                                      bottomRight: Radius.circular(isMe && isLastInGroup ? 16 : 4),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 2,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    message.content,
                                    style: TextStyle(
                                      color: isMe ? Colors.white : Colors.black87,
                                      fontSize: 15,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                                // 時刻（グループの最後のメッセージのみ）
                                if (isLastInGroup)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2, left: 12, right: 12),
                                    child: Text(
                                      _formatTime(message.createdAt),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // 自分のアバター（右側）
                          if (isMe) ...[
                            Container(
                              width: 36,
                              margin: const EdgeInsets.only(left: 8, right: 4),
                              child: showAvatar
                                  ? GestureDetector(
                                      onTap: () {
                                        if (_currentUserId != null && _currentUserName != null) {
                                          showDialog(
                                            context: context,
                                            builder: (context) => UserDetailDialog(
                                              userId: _currentUserId!,
                                              userName: _currentUserName!,
                                            ),
                                          );
                                        }
                                      },
                                      child: CustomCircleAvatar(
                                        frameId: _currentAppUser?.selectedFrame,
                                        radius: 18,
                                        backgroundColor: const Color(0xFF8E1728),
                                        designBuilder: _currentAppUser?.selectedDesign != null && _currentAppUser?.selectedDesign != 'default'
                                            ? AvatarDesigns.getById(_currentAppUser!.selectedDesign!).builder
                                            : null,
                                        child: _currentAppUser?.selectedDesign == null || _currentAppUser?.selectedDesign == 'default'
                                            ? Text(
                                                _currentUserName != null && _currentUserName!.isNotEmpty 
                                                  ? _currentUserName![0].toUpperCase() 
                                                  : '?',
                                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                              )
                                            : null,
                                      ),
                                    )
                                  : null,
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: _showTemplates ? 50 : 0,
                child: _showTemplates
                    ? Container(
                        color: Colors.grey[50],
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          children: _getQuickTemplates()
                              .map((template) => Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: ActionChip(
                                      avatar: Icon(
                                        template['icon'] as IconData,
                                        size: 18,
                                        color: const Color(0xFF8E1728),
                                      ),
                                      label: Text(
                                        template['label'] as String,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      backgroundColor: Colors.white,
                                      onPressed: () => _selectTemplate(template['type'] as String),
                                    ),
                                  ))
                              .toList(),
                        ),
                      )
                    : null,
              ),
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
                      IconButton(
                        icon: Icon(
                          _showTemplates ? Icons.expand_more : Icons.expand_less,
                          color: Colors.grey[700],
                        ),
                        onPressed: () {
                          setState(() {
                            _showTemplates = !_showTemplates;
                          });
                        },
                        tooltip: 'テンプレート',
                      ),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          maxLines: null,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                          decoration: InputDecoration(
                            hintText: 'メッセージを入力',
                            hintStyle: const TextStyle(color: Colors.grey),
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: const Color(0xFF8E1728),
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
              ),
            ],
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