import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/experiment.dart';
import '../models/experiment_slot.dart';
import '../models/experiment_reservation.dart';
import '../services/reservation_service.dart';
import '../widgets/experiment_calendar_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/message_service.dart';
import '../services/auth_service.dart';
import 'chat_screen.dart';

/// 実験詳細画面
/// 選択された実験の詳細情報を表示する
class ExperimentDetailScreen extends StatefulWidget {
  final Experiment experiment;

  const ExperimentDetailScreen({
    super.key,
    required this.experiment,
  });

  @override
  State<ExperimentDetailScreen> createState() => _ExperimentDetailScreenState();
}

class _ExperimentDetailScreenState extends State<ExperimentDetailScreen> {
  final ReservationService _reservationService = ReservationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final MessageService _messageService = MessageService();
  final AuthService _authService = AuthService();
  bool _showCalendar = false;

  /// 実験種別のアイコンを取得
  IconData _getTypeIcon(ExperimentType type) {
    switch (type) {
      case ExperimentType.online:
        return Icons.computer;
      case ExperimentType.onsite:
        return Icons.location_on;
      case ExperimentType.survey:
        return Icons.assignment;
    }
  }

  /// 実験種別の色を取得
  Color _getTypeColor(ExperimentType type) {
    switch (type) {
      case ExperimentType.online:
        return Colors.blue;
      case ExperimentType.onsite:
        return Colors.green;
      case ExperimentType.survey:
        return Colors.orange;
    }
  }

  /// 日時のフォーマット
  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '未定';
    
    final year = dateTime.year;
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    
    return '$year年$month月$day日 $hour:$minute';
  }

  /// 日付のフォーマット
  String _formatDate(DateTime? date) {
    if (date == null) return '未定';
    return DateFormat('yyyy年MM月dd日').format(date);
  }

  /// スロット選択時の処理
  Future<void> _handleSlotSelection(ExperimentSlot slot) async {
    // 予約確認ダイアログを表示
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('予約確認'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '以下の日時で予約しますか？',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('yyyy年MM月dd日(E)', 'ja').format(slot.startTime),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        '${DateFormat('HH:mm').format(slot.startTime)} - ${DateFormat('HH:mm').format(slot.endTime)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
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
            child: const Text('予約する'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _makeReservation(slot);
    }
  }

  /// 予約を実行
  Future<void> _makeReservation(ExperimentSlot slot) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('ログインが必要です');
      }

      // 既に予約しているかチェック
      final hasReserved = await _reservationService.hasUserReserved(
        user.uid,
        widget.experiment.id,
      );

      if (hasReserved) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('既にこの実験に予約済みです'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // 予約を作成
      await _reservationService.createReservation(
        userId: user.uid,
        experimentId: widget.experiment.id,
        slotId: slot.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('予約が完了しました'),
            backgroundColor: Colors.green,
          ),
        );
        
        // カレンダーを閉じる
        setState(() {
          _showCalendar = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('予約に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 直接応募（固定日時の場合）
  Future<void> _handleDirectApplication() async {
    // デモ版では実装しない
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('応募機能は開発中です'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// 質問するボタンの処理
  Future<void> _handleMessageButton() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ログインが必要です'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // 現在のユーザー情報を取得
      final currentUser = await _authService.getCurrentAppUser();
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ユーザー情報の取得に失敗しました'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // 実験者名を取得（labNameがあればそれを使用、なければデフォルト）
      final experimenterName = widget.experiment.labName ?? '実験者';

      // 既存の会話を確認または新規作成
      final conversationId = await _messageService.getOrCreateConversation(
        user.uid,
        widget.experiment.creatorId,
        currentUser.name,
        experimenterName,
      );

      if (mounted) {
        // チャット画面に遷移
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              conversationId: conversationId,
              otherUserId: widget.experiment.creatorId,
              otherUserName: experimenterName,
              experimentTitle: widget.experiment.title,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
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
        title: const Text('実験詳細'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handleMessageButton,
        backgroundColor: const Color(0xFF8E1728),
        icon: const Icon(Icons.message, color: Colors.white),
        label: const Text(
          '質問する',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        tooltip: '実験者に質問',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // タイトル
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getTypeIcon(widget.experiment.type),
                          color: _getTypeColor(widget.experiment.type),
                          size: 28,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.experiment.title,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // 種別タグ
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getTypeColor(widget.experiment.type).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            widget.experiment.type.label,
                            style: TextStyle(
                              color: _getTypeColor(widget.experiment.type),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 有償/無償タグ
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: widget.experiment.isPaid 
                              ? Colors.amber.withValues(alpha: 0.2)
                              : Colors.grey.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            widget.experiment.isPaid ? '有償' : '無償',
                            style: TextStyle(
                              color: widget.experiment.isPaid 
                                ? Colors.amber[700] 
                                : Colors.grey[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 基本情報
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '基本情報',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.monetization_on,
                      '報酬',
                      widget.experiment.isPaid ? '¥${widget.experiment.reward}' : 'なし',
                      Colors.amber,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.location_on,
                      '場所',
                      widget.experiment.location,
                      Colors.red,
                    ),
                    const SizedBox(height: 8),
                    if (widget.experiment.allowFlexibleSchedule) ...[
                      _buildInfoRow(
                        Icons.date_range,
                        '実施期間',
                        '${_formatDate(widget.experiment.experimentPeriodStart)} ~ ${_formatDate(widget.experiment.experimentPeriodEnd)}',
                        Colors.blue,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.green.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: Colors.green,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '予約制・日時選択可',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else
                      _buildInfoRow(
                        Icons.calendar_today,
                        '実施日時',
                        _formatDateTime(widget.experiment.experimentDate),
                        Colors.blue,
                      ),
                    if (widget.experiment.duration != null) ...[
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        Icons.timer,
                        '所要時間',
                        '約${widget.experiment.duration}分',
                        Colors.green,
                      ),
                    ],
                    if (widget.experiment.maxParticipants != null) ...[
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        Icons.group,
                        '募集人数',
                        '最大${widget.experiment.maxParticipants}名',
                        Colors.purple,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 実験概要
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '実験概要',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.experiment.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            
            // 詳細内容
            if (widget.experiment.detailedContent != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.description,
                            color: Color(0xFF8E1728),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '詳細内容',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF8E1728),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          widget.experiment.detailedContent!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // 参加条件
            if (widget.experiment.requirements.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '参加条件',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...widget.experiment.requirements.map((requirement) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.check_circle,
                                size: 20,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(requirement),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],

            // 柔軟なスケジュール調整の場合はカレンダー表示
            if (widget.experiment.allowFlexibleSchedule) ...[
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.calendar_month,
                        color: Color(0xFF8E1728),
                      ),
                      title: const Text(
                        '予約日時を選択',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text('カレンダーから希望の日時を選んでください'),
                      trailing: IconButton(
                        icon: Icon(
                          _showCalendar
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        ),
                        onPressed: () {
                          setState(() {
                            _showCalendar = !_showCalendar;
                          });
                        },
                      ),
                      onTap: () {
                        setState(() {
                          _showCalendar = !_showCalendar;
                        });
                      },
                    ),
                    if (_showCalendar)
                      ExperimentCalendarView(
                        experiment: widget.experiment,
                        onSlotSelected: _handleSlotSelection,
                      ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // 応募ボタン
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: widget.experiment.allowFlexibleSchedule && !_showCalendar
                  ? () {
                      setState(() {
                        _showCalendar = true;
                      });
                      // カレンダーセクションまでスクロール
                      Future.delayed(const Duration(milliseconds: 300), () {
                        Scrollable.ensureVisible(
                          context,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                        );
                      });
                    }
                  : !widget.experiment.allowFlexibleSchedule
                    ? () => _handleDirectApplication()
                    : null,
                icon: Icon(
                  widget.experiment.allowFlexibleSchedule
                    ? Icons.calendar_today
                    : Icons.send,
                ),
                label: Text(
                  widget.experiment.allowFlexibleSchedule
                    ? '日時を選択して予約'
                    : 'この実験に応募する',
                ),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// 情報行のウィジェット
  Widget _buildInfoRow(IconData icon, String label, String value, Color iconColor) {
    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}