import 'package:flutter/material.dart';
import '../services/demo_auth_service.dart';
import 'chat_screen_demo.dart';

/// デモモード用のメッセージ画面
class MessagesScreenDemo extends StatefulWidget {
  final DemoAuthService authService;

  const MessagesScreenDemo({
    super.key,
    required this.authService,
  });

  @override
  State<MessagesScreenDemo> createState() => _MessagesScreenDemoState();
}

class _MessagesScreenDemoState extends State<MessagesScreenDemo> {
  final List<Map<String, dynamic>> _demoConversations = [
    {
      'id': '1',
      'userName': '田中研究室',
      'lastMessage': '実験日程の確認をお願いします',
      'time': '5分前',
      'unreadCount': 2,
    },
    {
      'id': '2',
      'userName': '山田太郎',
      'lastMessage': 'ありがとうございました！',
      'time': '1時間前',
      'unreadCount': 0,
    },
    {
      'id': '3',
      'userName': '心理学研究室',
      'lastMessage': '明日の実験は14時からです',
      'time': '昨日',
      'unreadCount': 1,
    },
    {
      'id': '4',
      'userName': '佐藤花子',
      'lastMessage': '実験の詳細を教えてください',
      'time': '2日前',
      'unreadCount': 0,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('メッセージ'),
      ),
      body: ListView.builder(
        itemCount: _demoConversations.length,
        itemBuilder: (context, index) {
          final conversation = _demoConversations[index];
          final unreadCount = conversation['unreadCount'] as int;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            elevation: 1,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF8E1728),
                child: Text(
                  conversation['userName'][0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      conversation['userName'],
                      style: TextStyle(
                        fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  Text(
                    conversation['time'],
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
                      conversation['lastMessage'],
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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreenDemo(
                      otherUserName: conversation['userName'],
                      authService: widget.authService,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('新しいメッセージ'),
              content: const Text('この機能は準備中です。\n実験詳細画面からメッセージを送信してください。'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        },
        backgroundColor: const Color(0xFF8E1728),
        child: const Icon(Icons.add_comment),
      ),
    );
  }
}