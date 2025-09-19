import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/message_service.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../models/message.dart';
import '../models/app_user.dart';
import '../models/avatar_color.dart';
import '../models/avatar_design.dart';
import '../widgets/custom_circle_avatar.dart';
import '../widgets/user_detail_dialog.dart';

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
  final Map<String, GlobalKey> _messageKeys = {};
  static const double _kAvatarRadius = 18;
  static const double _kAvatarDiameter = _kAvatarRadius * 2;

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
  String? _highlightedMessageId;
  List<Message> _messages = [];
  StreamSubscription<List<Message>>? _messageSubscription;
  bool _isLoadingMessages = true;

  @override
  void initState() {
    super.initState();
    _actualConversationId = widget.conversationId;
    _getCurrentUser();
    _getOtherUser();
    if (widget.conversationId != null && widget.conversationId!.isNotEmpty) {
      _markMessagesAsRead();
    }
    _startListeningToMessages();
  }

  void _startListeningToMessages() {
    if (_actualConversationId != null && _actualConversationId!.isNotEmpty) {
      _messageSubscription = _messageService
          .getConversationMessages(_actualConversationId!)
          .listen((messages) {
            if (mounted) {
              // 前回のメッセージIDリストを保持
              final oldMessageIds = _messages.map((m) => m.id).toSet();
              final newMessageIds = messages.map((m) => m.id).toSet();

              // 新しく追加されたメッセージがあるかチェック
              final hasNewMessages = newMessageIds
                  .difference(oldMessageIds)
                  .isNotEmpty;
              final isUserMessage =
                  hasNewMessages &&
                  messages.isNotEmpty &&
                  messages.last.senderId == _currentUserId;

              setState(() {
                _messages = messages;
                _isLoadingMessages = false;

                // 新しいメッセージのGlobalKeyを追加
                for (final message in _messages) {
                  _messageKeys[message.id] ??= GlobalKey();
                }
              });

              // ユーザーが新しいメッセージを送信した場合のみスクロール
              if (hasNewMessages && isUserMessage && _messages.isNotEmpty) {
                _scrollToBottom();
              }
            }
          });
    } else {
      setState(() {
        _isLoadingMessages = false;
      });
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
    try {
      final user = await _userService.getUserById(widget.otherUserId);
      if (!mounted) return;
      setState(() {
        _otherUser = user;
      });
    } catch (_) {
      // 取得に失敗した場合は既存の情報を使い続ける
    }
  }

  void _markMessagesAsRead() {
    if (_currentUserId != null &&
        _actualConversationId != null &&
        _actualConversationId!.isNotEmpty) {
      _messageService.markMessagesAsRead(
        _actualConversationId!,
        _currentUserId!,
      );
    }
  }

  Color _resolveAvatarColor(AppUser? user) {
    final colorId = user?.selectedColor ?? 'default';
    final avatarColor = AvatarColors.getById(colorId);
    return AvatarColors.getColorValue(avatarColor);
  }

  Color _resolveAvatarTextColor(Color background) {
    return background.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;
  }

  bool _shouldShowAvatar(Message current, Message? previous) {
    if (previous == null) {
      return true;
    }
    if (previous.senderId != current.senderId) {
      return true;
    }
    final difference = current.createdAt.difference(previous.createdAt);
    return difference.inMinutes > 3;
  }

  Widget _buildAvatar({required bool isMe, required bool showAvatar}) {
    if (!showAvatar) {
      return const SizedBox(width: _kAvatarDiameter, height: _kAvatarDiameter);
    }

    final AppUser? user = isMe ? _currentAppUser : _otherUser;
    final String displayName = isMe
        ? (_currentUserName ?? '')
        : widget.otherUserName;
    final Color backgroundColor = _resolveAvatarColor(user);
    final textColor = _resolveAvatarTextColor(backgroundColor);
    final String? designId = user?.selectedDesign;
    AvatarDesign? avatarDesign;
    if (designId != null && designId != 'default') {
      avatarDesign = AvatarDesigns.getById(designId);
    }
    final designBuilder = avatarDesign?.builder;

    // マイページと同じロジック: selectedDesignがdefaultの場合のみphotoUrlを使用
    final bool usePhotoUrl = (designId == null || designId == 'default') && user?.photoUrl != null;

    Widget avatar = CustomCircleAvatar(
      frameId: user?.selectedFrame,
      radius: _kAvatarRadius,
      backgroundColor: backgroundColor,
      backgroundImage: usePhotoUrl ? user?.photoUrl : null,
      designBuilder: designBuilder,
      child: designBuilder == null && !usePhotoUrl
          ? Text(
              displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
              style: TextStyle(color: textColor, fontSize: 14),
            )
          : null,
    );

    final String? targetUserId = isMe ? _currentUserId : widget.otherUserId;
    final String targetUserName = isMe
        ? (_currentUserName ?? '')
        : widget.otherUserName;

    if (targetUserId != null && targetUserName.isNotEmpty) {
      avatar = GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => UserDetailDialog(
              userId: targetUserId,
              userName: targetUserName,
            ),
          );
        },
        child: avatar,
      );
    }

    return SizedBox(
      width: _kAvatarDiameter,
      height: _kAvatarDiameter,
      child: avatar,
    );
  }

  Widget _buildMessageContent(
    BuildContext context,
    Message message,
    bool isMe,
  ) {
    final bubbleChildren = <Widget>[];

    if (message.replyToContent != null && !message.isDeleted) {
      bubbleChildren.add(
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _jumpToReplyMessage(message.replyToMessageId),
          child: Container(
            padding: const EdgeInsets.only(
              left: 12,
              right: 12,
              top: 8,
              bottom: 4,
            ),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: isMe
                      ? Colors.white.withValues(alpha: 0.5)
                      : Colors.grey.shade400,
                  width: 2,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.reply,
                      size: 12,
                      color: isMe
                          ? Colors.white.withValues(alpha: 0.7)
                          : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      message.replyToSenderId == _currentUserId
                          ? 'あなた'
                          : widget.otherUserName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isMe
                            ? Colors.white.withValues(alpha: 0.8)
                            : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  message.replyToContent!,
                  style: TextStyle(
                    fontSize: 11,
                    color: isMe
                        ? Colors.white.withValues(alpha: 0.7)
                        : Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      );
    }

    bubbleChildren.add(
      Container(
        key: _messageKeys[message.id],
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
    );

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: bubbleChildren,
        ),
      ),
    );
  }

  // テンプレート関連
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
        'template':
            'お世話になっております。\n'
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
        'template':
            'お世話になっております。$userInfoです。\n\n'
            '実験について、以下の点をお伺いできますでしょうか。\n\n'
            '1. \n'
            '2. \n\n'
            'お手数をおかけしますが、ご回答いただけますと幸いです。\n'
            'よろしくお願いいたします。',
      },
      {
        'type': 'thanks',
        'label': 'お礼',
        'icon': Icons.favorite,
        'template':
            'お世話になっております。$userInfoです。\n\n'
            '先日は実験でお世話になり、\n'
            '誠にありがとうございました。\n\n'
            '貴重な経験をさせていただき、大変勉強になりました。\n'
            '今後ともどうぞよろしくお願いいたします。',
      },
      {
        'type': 'schedule',
        'label': '日程調整',
        'icon': Icons.calendar_today,
        'template':
            'お世話になっております。$userInfoです。\n\n'
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
        'template':
            'お世話になっております。$userInfoです。\n\n'
            '実験への参加を検討しております。\n'
            '参加条件について確認させていただけますでしょうか。\n\n'
            'ご確認のほど、よろしくお願いいたします。',
      },
      {
        'type': 'access',
        'label': 'アクセス',
        'icon': Icons.location_on,
        'template':
            'お世話になっております。$userInfoです。\n\n'
            '実験会場へのアクセスについて、\n'
            '詳細を教えていただけますでしょうか。\n\n'
            'よろしくお願いいたします。',
      },
    ];
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
          _startListeningToMessages();
        }
        _cancelReply();
      }

      _messageController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('送信に失敗しました: $e'), backgroundColor: Colors.red),
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

  // ジャンプ処理のデバウンス用
  DateTime? _lastJumpTime;

  // リプライ元へジャンプ
  void _jumpToReplyMessage(String? replyToMessageId) {
    if (replyToMessageId == null) return;

    // デバウンス処理：連続クリックを防ぐ
    final now = DateTime.now();
    if (_lastJumpTime != null &&
        now.difference(_lastJumpTime!).inMilliseconds < 500) {
      return;
    }
    _lastJumpTime = now;

    // リプライ元メッセージが現在のリストに存在するか確認
    final hasMessage = _messages.any((msg) => msg.id == replyToMessageId);

    if (!hasMessage) {
      // メッセージが見つからない場合
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('リプライ元のメッセージが見つかりません'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // GlobalKeyを取得
    final key = _messageKeys[replyToMessageId];
    if (key?.currentContext == null) {
      return;
    }

    // ハイライト表示を先に設定
    setState(() {
      _highlightedMessageId = replyToMessageId;
    });

    // スクロール処理
    Scrollable.ensureVisible(
      key!.currentContext!,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      alignment: 0.3, // メッセージを画面上部寄りに表示
    );

    // 3秒後にハイライトを解除
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _highlightedMessageId == replyToMessageId) {
        setState(() {
          _highlightedMessageId = null;
        });
      }
    });
  }

  // メッセージ長押しメニュー
  void _showMessageOptions(BuildContext context, Message message) {
    final isMe = message.senderId == _currentUserId;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            if (!message.isDeleted)
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text('リプライ'),
                onTap: () {
                  Navigator.pop(context);
                  _startReply(message);
                },
              ),
            if (!message.isDeleted)
              ListTile(
                leading: const Icon(Icons.forward),
                title: const Text('転送'),
                onTap: () {
                  Navigator.pop(context);
                  _forwardMessage(message);
                },
              ),
            if (isMe && !message.isDeleted)
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('編集'),
                onTap: () {
                  Navigator.pop(context);
                  _startEdit(message);
                },
              ),
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

  void _startEdit(Message message) {
    setState(() {
      _editingMessage = message;
      _messageController.text = message.content;
      _replyingToMessage = null;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingMessage = null;
      _messageController.clear();
    });
  }

  void _startReply(Message message) {
    setState(() {
      _replyingToMessage = message;
      _editingMessage = null;
    });
  }

  void _cancelReply() {
    setState(() {
      _replyingToMessage = null;
    });
  }

  void _confirmDelete(Message message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('メッセージを削除'),
        content: const Text('このメッセージを削除しますか？'),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

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
          SnackBar(content: Text('削除に失敗しました: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _forwardMessage(Message message) {
    _showForwardDialog(message);
  }

  Future<void> _showForwardDialog(Message message) async {
    final conversations = await _messageService
        .getUserConversations(_currentUserId!)
        .first;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('転送先を選択'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: conversations.isEmpty
              ? const Center(child: Text('転送先がありません'))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: conversations.length,
                  itemBuilder: (context, index) {
                    final conversation = conversations[index];
                    final otherUserId = conversation.participantIds.firstWhere(
                      (id) => id != _currentUserId,
                    );
                    final otherUserName =
                        conversation.participantNames[otherUserId] ?? 'Unknown';

                    if (otherUserId == widget.otherUserId) {
                      return const SizedBox.shrink();
                    }

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF8E1728),
                        child: Text(
                          otherUserName.isNotEmpty
                              ? otherUserName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(otherUserName),
                      onTap: () async {
                        Navigator.pop(context);
                        await _sendForwardedMessage(
                          message,
                          otherUserId,
                          otherUserName,
                        );
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

  Future<void> _sendForwardedMessage(
    Message originalMessage,
    String receiverId,
    String receiverName,
  ) async {
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
          SnackBar(content: Text('転送に失敗しました: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.otherUserName)),
        body: const Center(child: CircularProgressIndicator()),
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
            child: _isLoadingMessages
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF8E1728),
                      ),
                    ),
                  )
                : _messages.isEmpty
                ? Center(
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
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
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isMe = message.senderId == _currentUserId;
                      final isHighlighted = message.id == _highlightedMessageId;
                      final previousMessage = index > 0
                          ? _messages[index - 1]
                          : null;
                      final shouldShowAvatar = _shouldShowAvatar(
                        message,
                        previousMessage,
                      );
                      final showOtherAvatar = !isMe && shouldShowAvatar;
                      final showCurrentUserAvatar = isMe && shouldShowAvatar;
                      final messageContent = _buildMessageContent(
                        context,
                        message,
                        isMe,
                      );
                      final rowChildren = <Widget>[];
                      if (!isMe) {
                        rowChildren
                          ..add(
                            _buildAvatar(
                              isMe: false,
                              showAvatar: showOtherAvatar,
                            ),
                          )
                          ..add(const SizedBox(width: 8));
                      }

                      rowChildren.add(Flexible(child: messageContent));

                      if (isMe) {
                        rowChildren
                          ..add(const SizedBox(width: 8))
                          ..add(
                            _buildAvatar(
                              isMe: true,
                              showAvatar: showCurrentUserAvatar,
                            ),
                          );
                      }

                      return GestureDetector(
                        onLongPress: () =>
                            _showMessageOptions(context, message),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: isHighlighted
                              ? const EdgeInsets.all(4)
                              : EdgeInsets.zero,
                          decoration: isHighlighted
                              ? BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                )
                              : null,
                          child: Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: rowChildren,
                            ),
                          ),
                        ),
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
                          _editingMessage?.content ??
                              _replyingToMessage?.content ??
                              '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: _editingMessage != null
                        ? _cancelEdit
                        : _cancelReply,
                  ),
                ],
              ),
            ),
          // テンプレート表示
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
                          .map(
                            (template) => Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
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
                                onPressed: () =>
                                    _selectTemplate(template['type'] as String),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  )
                : null,
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
                        hintText: _editingMessage != null
                            ? '編集内容を入力'
                            : 'メッセージを入力',
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

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageSubscription?.cancel();
    super.dispose();
  }
}
