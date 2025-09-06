import 'package:flutter/material.dart';
import '../services/demo_auth_service.dart';
import '../models/app_user.dart';

/// デモモード用のチャット画面
class ChatScreenDemo extends StatefulWidget {
  final String otherUserName;
  final DemoAuthService authService;
  final String? experimentTitle;
  final String? currentUserName;
  final String? currentUserDepartment;
  final String? currentUserGrade;

  const ChatScreenDemo({
    super.key,
    required this.otherUserName,
    required this.authService,
    this.experimentTitle,
    this.currentUserName,
    this.currentUserDepartment,
    this.currentUserGrade,
  });

  @override
  State<ChatScreenDemo> createState() => _ChatScreenDemoState();
}

class _ChatScreenDemoState extends State<ChatScreenDemo> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showTemplates = false;
  
  final List<Map<String, dynamic>> _messages = [
    {
      'content': 'こんにちは！実験に興味があります。',
      'isMe': true,
      'time': '14:30',
    },
    {
      'content': 'ご連絡ありがとうございます。実験の詳細をお送りします。',
      'isMe': false,
      'time': '14:32',
    },
    {
      'content': '実験は来週の月曜日14時から約1時間を予定しています。',
      'isMe': false,
      'time': '14:33',
    },
    {
      'content': '了解しました。参加させていただきます。',
      'isMe': true,
      'time': '14:35',
    },
  ];

  void _selectTemplate(String templateType) {
    final templates = _getQuickTemplates();
    final selected = templates.firstWhere((t) => t['type'] == templateType);
    _messageController.text = selected['template'] as String;
    setState(() {
      _showTemplates = false;
    });
    }

  List<Map<String, dynamic>> _getQuickTemplates() {
    final experiment = widget.experimentTitle ?? '[実験名]';
    final userInfo = widget.currentUserName ?? 'デモユーザー';
    String affiliation = '';
    
    if (widget.currentUserDepartment != null) {
      affiliation = '早稲田大学';
      affiliation += widget.currentUserDepartment!;
      if (widget.currentUserGrade != null) {
        affiliation += widget.currentUserGrade!;
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
            '「$experiment」の実験を拝見し、大変興味を持ちました。\n'
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
            '「$experiment」の実験について、以下の点をお伺いできますでしょうか。\n\n'
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
            '「$experiment」の実験に参加させていただきたく存じます。\n\n'
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
            '「$experiment」の実験への参加を検討しております。\n'
            '参加条件について確認させていただけますでしょうか。\n\n'
            'ご確認のほど、よろしくお願いいたします。',
      },
      {
        'type': 'access',
        'label': 'アクセス',
        'icon': Icons.location_on,
        'template': 'お世話になっております。$userInfoです。\n\n'
            '「$experiment」の実験会場へのアクセスについて、\n'
            '詳細を教えていただけますでしょうか。\n\n'
            'よろしくお願いいたします。',
      },
      {
        'type': 'thanks',
        'label': 'お礼',
        'icon': Icons.favorite,
        'template': 'お世話になっております。$userInfoです。\n\n'
            '先日は「$experiment」の実験でお世話になり、\n'
            '誠にありがとうございました。\n\n'
            '貴重な経験をさせていただき、大変勉強になりました。\n'
            '今後ともどうぞよろしくお願いいたします。',
      },
    ];
  }

  void _showTemplatesSheet() {
    // デモ用のユーザー情報を作成
    final demoUser = AppUser(
      uid: 'demo',
      email: 'demo@waseda.jp',
      name: widget.currentUserName ?? 'デモユーザー',
      isWasedaUser: true,
      canCreateExperiment: false,
      createdAt: DateTime.now(),
      department: widget.currentUserDepartment ?? '基幹理工学部',
      grade: widget.currentUserGrade ?? '3年',
    );
    
    // この関数は使用しないため、空実装にする
    // テンプレートは上部のチップリストから選択
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _messages.add({
        'content': _messageController.text.trim(),
        'isMe': true,
        'time': '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      });
    });

    _messageController.clear();
    _scrollToBottom();

    // デモ用の自動返信
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _messages.add({
            'content': 'メッセージを受け取りました（デモ返信）',
            'isMe': false,
            'time': '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
          });
        });
        _scrollToBottom();
      }
    });
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
      appBar: AppBar(
        title: Text(widget.otherUserName),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(widget.otherUserName),
                  content: const Text('ユーザー詳細情報は準備中です（デモ）'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
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
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Text(
                      'メッセージを開始しましょう',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isMe = message['isMe'] as bool;

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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isMe
                                ? const Color(0xFF8E1728)
                                : Colors.grey[200],
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isMe ? 16 : 4),
                              bottomRight: Radius.circular(isMe ? 4 : 16),
                            ),
                          ),
                          child: Text(
                            message['content'],
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
                            message['time'],
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
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: _sendMessage,
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