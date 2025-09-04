import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../models/app_user.dart';

/// 管理者用サポートメッセージ送信画面
class AdminSupportMessageScreen extends StatefulWidget {
  const AdminSupportMessageScreen({super.key});

  @override
  State<AdminSupportMessageScreen> createState() => _AdminSupportMessageScreenState();
}

class _AdminSupportMessageScreenState extends State<AdminSupportMessageScreen> {
  final AdminService _adminService = AdminService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  
  List<AppUser> _users = [];
  AppUser? _selectedUser;
  bool _isLoading = false;
  bool _isSending = false;

  @override
  void dispose() {
    _searchController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isLoading = true);

    final users = await _adminService.searchUsers(query);

    if (mounted) {
      setState(() {
        _users = users;
        _isLoading = false;
      });
    }
  }

  Future<void> _sendSupportMessage() async {
    if (_selectedUser == null || _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ユーザーとメッセージを入力してください'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('メッセージ送信確認'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('送信先: ${_selectedUser!.name}'),
            const SizedBox(height: 8),
            const Text('以下のメッセージを送信しますか？'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _messageController.text,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            child: const Text('送信'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSending = true);

    final success = await _adminService.sendSupportMessage(
      userId: _selectedUser!.uid,
      message: _messageController.text,
    );

    if (mounted) {
      setState(() => _isSending = false);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('メッセージを送信しました'),
            backgroundColor: Colors.green,
          ),
        );
        
        // フィールドをクリア
        setState(() {
          _messageController.clear();
          _selectedUser = null;
          _users = [];
          _searchController.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('送信に失敗しました'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('サポートメッセージ'),
      ),
      body: Column(
        children: [
          // ユーザー検索セクション
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '送信先ユーザーを検索',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onSubmitted: (_) => _searchUsers(),
                        decoration: InputDecoration(
                          hintText: '名前またはメールアドレスで検索',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _searchUsers,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('検索'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // 選択されたユーザー表示
          if (_selectedUser != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.blue.withValues(alpha: 0.1),
              child: Row(
                children: [
                  const Icon(Icons.person, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '送信先: ${_selectedUser!.name}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _selectedUser!.email,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedUser = null;
                      });
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
          
          // 検索結果
          if (_users.isNotEmpty)
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final user = _users[index];
                  final isSelected = _selectedUser?.uid == user.uid;
                  
                  return Card(
                    color: isSelected ? Colors.blue.withValues(alpha: 0.1) : null,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: user.isWasedaUser
                            ? const Color(0xFF8E1728)
                            : Colors.blue,
                        child: Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(user.name),
                      subtitle: Text(user.email),
                      selected: isSelected,
                      onTap: () {
                        setState(() {
                          _selectedUser = user;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          
          // メッセージ入力セクション
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'メッセージ内容',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: InputDecoration(
                        hintText: 'サポートメッセージを入力してください...',
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // テンプレートボタン
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildTemplateButton(
                          'お問い合わせありがとうございます',
                          'お問い合わせありがとうございます。\n確認の上、返答させていただきます。',
                        ),
                        const SizedBox(width: 8),
                        _buildTemplateButton(
                          'システムメンテナンス',
                          'システムメンテナンスのお知らせ\n\nメンテナンス日時：\n内容：',
                        ),
                        const SizedBox(width: 8),
                        _buildTemplateButton(
                          '問題解決',
                          'ご報告いただいた問題について、\n解決いたしました。\n\n詳細：',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // 送信ボタン
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: (_selectedUser != null && 
                                _messageController.text.isNotEmpty && 
                                !_isSending)
                          ? _sendSupportMessage
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                      icon: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.send),
                      label: Text(
                        _isSending ? '送信中...' : 'メッセージを送信',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

  Widget _buildTemplateButton(String label, String template) {
    return OutlinedButton(
      onPressed: () {
        setState(() {
          _messageController.text = template;
        });
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}