import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/notification.dart';
import '../models/experiment.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../services/experiment_service.dart';
import 'messages_screen.dart';
import 'experiment_detail_screen.dart';
import 'experiment_management_screen.dart';
import 'evaluation_history_screen.dart';
import 'support_chat_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();
  final ExperimentService _experimentService = ExperimentService();
  String? _currentUserId;
  
  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }
  
  Future<void> _loadCurrentUser() async {
    final user = _authService.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
      });
      // 古い通知を削除
      await _notificationService.deleteOldNotifications(user.uid);
    }
  }

  Future<void> _handleNotificationTap(AppNotification notification) async {
    // 通知を既読にする
    await _notificationService.markAsRead(notification.id);
    
    if (!mounted) return;
    
    // 通知タイプに応じて画面遷移
    switch (notification.type) {
      case NotificationType.evaluation:
        // 評価履歴画面に遷移
        if (notification.data?['experimentId'] != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EvaluationHistoryScreen(
                userId: _currentUserId!,
                userName: '',
                isMyHistory: true,
              ),
            ),
          );
        }
        break;
        
      case NotificationType.message:
        // メッセージ画面に遷移
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MessagesScreen(),
          ),
        );
        break;
        
      case NotificationType.experimentJoined:
      case NotificationType.experimentCancelled:
      case NotificationType.experimentCompleted:
        // 実験詳細または管理画面に遷移
        if (notification.data?['experimentId'] != null) {
          try {
            final experiment = await _experimentService.getExperiment(
              notification.data!['experimentId'],
            );
            if (experiment != null && mounted) {
              if (experiment.creatorId == _currentUserId) {
                // 自分が作成した実験なら管理画面へ
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ExperimentManagementScreen(
                      experiment: experiment,
                    ),
                  ),
                );
              } else {
                // 参加した実験なら詳細画面へ
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ExperimentDetailScreen(
                      experiment: experiment,
                      isMyExperiment: false,
                    ),
                  ),
                );
              }
            }
          } catch (e) {
            print('実験情報の取得に失敗: $e');
          }
        }
        break;
        
      case NotificationType.adminMessage:
        // 運営からのお知らせはダイアログで表示
        _showAdminMessageDialog(notification);
        break;
        
      case NotificationType.supportTicket:
      case NotificationType.supportReply:
        // サポートチャット画面に遷移
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SupportChatScreen(),
          ),
        );
        break;
    }
  }
  
  void _showAdminMessageDialog(AppNotification notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.campaign,
              color: Colors.red[700],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                notification.title,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(notification.message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  Future<void> _markAllAsRead() async {
    if (_currentUserId != null) {
      await _notificationService.markAllAsRead(_currentUserId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('すべての通知を既読にしました'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inMinutes < 1) {
      return 'たった今';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}分前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}時間前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}日前';
    } else {
      return DateFormat('yyyy/MM/dd').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('通知'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('通知'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'すべて既読にする',
            onPressed: _markAllAsRead,
          ),
        ],
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: _notificationService.getUserNotifications(_currentUserId!),
        builder: (context, snapshot) {
          // エラーチェックを追加
          if (snapshot.hasError) {
            print('通知取得エラー: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '通知の取得に失敗しました',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.red[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red[400],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '通知はありません',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }
          
          final notifications = snapshot.data!;
          
          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final isUnread = !notification.isRead;
              
              return Dismissible(
                key: Key(notification.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                ),
                onDismissed: (_) async {
                  await _notificationService.deleteNotification(notification.id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('通知を削除しました'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  color: isUnread ? Colors.blue.withOpacity(0.05) : null,
                  child: InkWell(
                    onTap: () => _handleNotificationTap(notification),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _getNotificationColor(notification.type)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              notification.type.icon,
                              color: _getNotificationColor(notification.type),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (isUnread)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        margin: const EdgeInsets.only(right: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.blue,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                    Expanded(
                                      child: Text(
                                        notification.title,
                                        style: TextStyle(
                                          fontWeight: isUnread
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _formatDate(notification.createdAt),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  notification.message,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[800],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  notification.type.label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _getNotificationColor(notification.type),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.chevron_right,
                            size: 20,
                            color: Colors.grey[400],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
  
  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.evaluation:
        return Colors.orange;
      case NotificationType.message:
        return Colors.blue;
      case NotificationType.experimentJoined:
        return Colors.green;
      case NotificationType.experimentCancelled:
        return Colors.red;
      case NotificationType.experimentCompleted:
        return Colors.purple;
      case NotificationType.adminMessage:
        return Colors.red[700]!;
      case NotificationType.supportTicket:
        return Colors.indigo;
      case NotificationType.supportReply:
        return Colors.teal;
    }
  }
}