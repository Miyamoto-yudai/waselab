import 'package:flutter/material.dart';
import '../../services/admin_service.dart';

/// 管理者用お知らせ配信画面
class AdminAnnouncementScreen extends StatefulWidget {
  const AdminAnnouncementScreen({super.key});

  @override
  State<AdminAnnouncementScreen> createState() => _AdminAnnouncementScreenState();
}

class _AdminAnnouncementScreenState extends State<AdminAnnouncementScreen> {
  final AdminService _adminService = AdminService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  
  bool _isSending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _sendAnnouncement() async {
    if (_titleController.text.trim().isEmpty || 
        _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('タイトルとメッセージは必須です'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('お知らせ配信確認'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '全ユーザーに以下のお知らせを配信しますか？',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'タイトル:',
              style: TextStyle(color: Colors.grey[600]),
            ),
            Text(
              _titleController.text,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'メッセージ:',
              style: TextStyle(color: Colors.grey[600]),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _messageController.text,
                style: const TextStyle(fontSize: 14),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_imageUrlController.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '画像URL:',
                style: TextStyle(color: Colors.grey[600]),
              ),
              Text(
                _imageUrlController.text,
                style: const TextStyle(fontSize: 12, color: Colors.blue),
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'この操作は取り消せません',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
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
              backgroundColor: Colors.red,
            ),
            child: const Text('配信する'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSending = true);

    final success = await _adminService.sendAnnouncement(
      title: _titleController.text,
      message: _messageController.text,
      imageUrl: _imageUrlController.text.isEmpty ? null : _imageUrlController.text,
    );

    if (mounted) {
      setState(() => _isSending = false);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('お知らせを配信しました'),
            backgroundColor: Colors.green,
          ),
        );
        
        // フィールドをクリア
        _titleController.clear();
        _messageController.clear();
        _imageUrlController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('配信に失敗しました'),
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
        title: const Text('お知らせ配信'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 注意事項
            Card(
              color: Colors.blue.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '全ユーザーへの配信',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'このフォームから送信されたお知らせは、アプリを利用している全ユーザーに通知されます。',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // タイトル入力
            const Text(
              'タイトル *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              maxLines: 1,
              decoration: InputDecoration(
                hintText: 'お知らせのタイトルを入力',
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // メッセージ入力
            const Text(
              'メッセージ内容 *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              maxLines: 10,
              decoration: InputDecoration(
                hintText: 'お知らせの内容を入力してください...',
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 画像URL入力（オプション）
            const Text(
              '画像URL（オプション）',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _imageUrlController,
              maxLines: 1,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                hintText: 'https://example.com/image.jpg',
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.image),
              ),
            ),
            const SizedBox(height: 16),

            // テンプレート
            const Text(
              'テンプレート',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTemplateChip(
                  'メンテナンス',
                  'システムメンテナンスのお知らせ',
                  'システムメンテナンスを実施いたします。\n\n日時：\n内容：\n\nメンテナンス中はサービスをご利用いただけません。\nご不便をおかけしますが、ご理解のほどよろしくお願いいたします。',
                ),
                _buildTemplateChip(
                  '新機能',
                  '新機能リリースのお知らせ',
                  '新機能をリリースしました！\n\n機能名：\n概要：\n\nぜひお試しください。',
                ),
                _buildTemplateChip(
                  'イベント',
                  'イベント開催のお知らせ',
                  'イベントを開催します！\n\nイベント名：\n日時：\n場所：\n内容：\n\n皆様のご参加をお待ちしております。',
                ),
                _buildTemplateChip(
                  '重要',
                  '重要なお知らせ',
                  '【重要】\n\n',
                ),
              ],
            ),
            const SizedBox(height: 32),

            // プレビュー
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'プレビュー',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.campaign, color: Colors.purple, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _titleController.text.isEmpty 
                                      ? 'タイトル未入力' 
                                      : _titleController.text,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: _titleController.text.isEmpty
                                        ? Colors.grey
                                        : Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _messageController.text.isEmpty 
                                ? 'メッセージ内容未入力' 
                                : _messageController.text,
                            style: TextStyle(
                              fontSize: 14,
                              color: _messageController.text.isEmpty
                                  ? Colors.grey
                                  : Colors.black87,
                            ),
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // 送信ボタン
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: (_titleController.text.isNotEmpty && 
                          _messageController.text.isNotEmpty && 
                          !_isSending)
                    ? _sendAnnouncement
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
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
                  _isSending ? '配信中...' : '全ユーザーに配信',
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
    );
  }

  Widget _buildTemplateChip(String label, String title, String message) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        setState(() {
          _titleController.text = title;
          _messageController.text = message;
        });
      },
      backgroundColor: Colors.grey[200],
    );
  }
}