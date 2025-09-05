import 'package:flutter/material.dart';
import '../services/message_service.dart';
import '../services/auth_service.dart';
import '../models/message.dart';

class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key});

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final MessageService _messageService = MessageService();
  final AuthService _authService = AuthService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  static const String supportUserId = 'support_team';
  static const String supportUserName = 'わせラボサポート';
  
  String? _currentUserId;
  String? _currentUserName;
  String? _conversationId;
  bool _isSending = false;
  bool _showTemplates = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    final user = _authService.currentUser;
    if (user != null) {
      final appUser = await _authService.getCurrentAppUser();
      
      
      setState(() {
        _currentUserId = user.uid;
        // AppUserが取得できない場合は、FirebaseAuthのdisplayNameまたはemailを使用
        _currentUserName = appUser?.name ?? user.displayName ?? user.email?.split('@')[0] ?? 'ユーザー';
        // サポートとの会話IDを生成（ユーザーIDとサポートIDを組み合わせて一意のIDを作成）
        final ids = [_currentUserId!, supportUserId];
        ids.sort();
        _conversationId = ids.join('_');
      });
      
      debugPrint('Support Chat Initialized:');
      debugPrint('  User ID: $_currentUserId');
      debugPrint('  User Name: $_currentUserName');
      debugPrint('  Conversation ID: $_conversationId');
      
      _markMessagesAsRead();
    }
  }

  void _markMessagesAsRead() {
    if (_conversationId != null && _currentUserId != null) {
      _messageService.markMessagesAsRead(_conversationId!, _currentUserId!);
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;
    if (_currentUserId == null || _currentUserName == null) return;

    setState(() {
      _isSending = true;
    });

    debugPrint('Sending support message:');
    debugPrint('  From: $_currentUserId ($_currentUserName)');
    debugPrint('  To: $supportUserId ($supportUserName)');
    debugPrint('  Content: ${_messageController.text.trim()}');
    
    try {
      final conversationId = await _messageService.sendMessage(
        senderId: _currentUserId!,
        receiverId: supportUserId,
        content: _messageController.text.trim(),
        senderName: _currentUserName!,
        receiverName: supportUserName,
      );
      debugPrint('Message sent successfully. Conversation ID: $conversationId');
      
      // Update the conversation ID if it's different
      if (_conversationId != conversationId) {
        debugPrint('Updating conversation ID from $_conversationId to $conversationId');
        setState(() {
          _conversationId = conversationId;
        });
      }
      
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      debugPrint('Error sending message: $e');
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

  void _selectTemplate(String template) {
    _messageController.text = template;
    setState(() {
      _showTemplates = false;
    });
  }

  List<Map<String, dynamic>> _getSupportTemplates() {
    return [
      {
        'label': 'アプリの使い方',
        'icon': Icons.help_outline,
        'template': 'アプリの使い方について質問があります。\n\n[具体的な質問内容をここに記入してください]',
      },
      {
        'label': 'バグ報告',
        'icon': Icons.bug_report,
        'template': 'アプリで不具合を見つけました。\n\n'
            '発生した問題:\n\n'
            '発生した時の操作:\n\n'
            '使用端末: ',
      },
      {
        'label': '機能要望',
        'icon': Icons.lightbulb_outline,
        'template': '以下の機能があると便利だと思います。\n\n'
            '[提案する機能について記入してください]',
      },
      {
        'label': 'アカウントの問題',
        'icon': Icons.account_circle,
        'template': 'アカウントに関する問題があります。\n\n'
            '[具体的な問題を記入してください]',
      },
      {
        'label': '実験に関する質問',
        'icon': Icons.science,
        'template': '実験について質問があります。\n\n'
            '[質問内容を記入してください]',
      },
      {
        'label': 'その他',
        'icon': Icons.more_horiz,
        'template': 'お問い合わせ内容:\n\n',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null || _conversationId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('サポート'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text('サポート'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('サポートについて'),
                  content: const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('わせラボサポートチームが対応いたします。'),
                      SizedBox(height: 8),
                      Text('対応時間: 平日 9:00-18:00'),
                      SizedBox(height: 8),
                      Text('通常24時間以内に返信いたします。'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('閉じる'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.blue.withValues(alpha: 0.1),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.blue[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'サポートチームがお手伝いします。お気軽にお問い合わせください。',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _messageService.getConversationMessages(_conversationId!),
              builder: (context, snapshot) {
                debugPrint('=== StreamBuilder Update ===');
                debugPrint('ConversationID: $_conversationId');
                debugPrint('Connection state: ${snapshot.connectionState}');
                debugPrint('Has data: ${snapshot.hasData}');
                debugPrint('Has error: ${snapshot.hasError}');
                if (snapshot.hasData) {
                  debugPrint('Message count: ${snapshot.data?.length}');
                }
                
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8E1728)),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  debugPrint('StreamBuilder error: ${snapshot.error}');
                  debugPrint('Error stack trace: ${snapshot.stackTrace}');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('エラー: ${snapshot.error}'),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              // 再読み込み
                            });
                          },
                          child: const Text('再読み込み'),
                        ),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data ?? [];
                debugPrint('Messages received: ${messages.length}');
                
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.support_agent,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'お困りのことはありませんか？',
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
                            color: const Color(0xFF8E1728).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                size: 16,
                                color: Colors.red[700],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '下のテンプレートから選択できます',
                                style: TextStyle(
                                  color: Colors.red[700],
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == _currentUserId;
                    final isSupport = message.senderId == supportUserId;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                        ),
                        child: Column(
                          crossAxisAlignment:
                              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            if (isSupport)
                              Padding(
                                padding: const EdgeInsets.only(left: 4, bottom: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.support_agent,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'サポート',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? const Color(0xFF8E1728)
                                    : isSupport
                                        ? Colors.blue[50]
                                        : Colors.grey[200],
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                                  bottomRight: Radius.circular(isMe ? 4 : 16),
                                ),
                                border: isSupport
                                    ? Border.all(
                                        color: Colors.blue.withValues(alpha: 0.3),
                                        width: 1,
                                      )
                                    : null,
                              ),
                              child: Text(
                                message.content,
                                style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black87,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                _formatTime(message.createdAt),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
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
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: _showTemplates ? 100 : 0,
                child: _showTemplates
                    ? Container(
                        color: Colors.grey[50],
                        padding: const EdgeInsets.all(8),
                        child: GridView.count(
                          crossAxisCount: 3,
                          childAspectRatio: 2.5,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          children: _getSupportTemplates()
                              .map((template) => InkWell(
                                    onTap: () => _selectTemplate(template['template'] as String),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.grey.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(8),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            template['icon'] as IconData,
                                            size: 20,
                                            color: const Color(0xFF8E1728),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            template['label'] as String,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
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
                          _showTemplates ? Icons.expand_more : Icons.apps,
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
                            hintText: 'お問い合わせ内容を入力',
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