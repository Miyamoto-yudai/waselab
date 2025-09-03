import 'package:flutter/material.dart';
import '../models/experiment.dart';
import 'experiment_calendar_view_base.dart';

/// 実験詳細画面の共通ベースウィジェット
class ExperimentDetailBase extends StatefulWidget {
  final Experiment experiment;
  final bool isDemo;
  final bool isMyExperiment;
  final Future<void> Function()? onApply;
  final Future<void> Function()? onMessage;
  final Future<void> Function(DateTime, String)? onSlotSelected;

  const ExperimentDetailBase({
    super.key,
    required this.experiment,
    this.isDemo = false,
    this.isMyExperiment = false,
    this.onApply,
    this.onMessage,
    this.onSlotSelected,
  });

  @override
  State<ExperimentDetailBase> createState() => _ExperimentDetailBaseState();
}

class _ExperimentDetailBaseState extends State<ExperimentDetailBase> {
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
    return '${date.year}年${date.month.toString().padLeft(2, '0')}月${date.day.toString().padLeft(2, '0')}日';
  }

  /// スロット選択時の処理
  Future<void> _handleSlotSelection(DateTime date, String timeSlot) async {
    if (widget.onSlotSelected != null) {
      await widget.onSlotSelected!(date, timeSlot);
      if (mounted) {
        setState(() {
          _showCalendar = false;
        });
      }
    } else if (widget.isDemo) {
      // デモモード用の処理
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
                          '${date.year}年${date.month.toString().padLeft(2, '0')}月${date.day.toString().padLeft(2, '0')}日',
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
                          timeSlot,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // 相互評価必須の注意書きを追加
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.amber[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '重要なお願い',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber[800],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '実験終了後は必ず相互評価を行ってください。',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.amber[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
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
                backgroundColor: const Color(0xFF8E1728),
              ),
              child: const Text('予約する'),
            ),
          ],
        ),
      );

      if (confirmed == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} $timeSlot で予約しました。実験終了後は必ず相互評価をお願いします（デモ）'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
        
        setState(() {
          _showCalendar = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('実験詳細'),
      ),
      floatingActionButton: widget.isMyExperiment
          ? null // 自分の実験の場合はFABを表示しない
          : FloatingActionButton.extended(
              heroTag: 'experiment_detail_fab_${widget.experiment.id}',
              onPressed: widget.onMessage ?? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('メッセージ機能は開発中です'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
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
            // 自分の実験かつ募集中または進行中の場合のみバナーを表示
            if (widget.isMyExperiment && 
                (widget.experiment.status == ExperimentStatus.recruiting || 
                 widget.experiment.status == ExperimentStatus.ongoing))
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF8E1728).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF8E1728).withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFF8E1728),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.experiment.status == ExperimentStatus.recruiting 
                              ? 'あなたが募集中の実験'
                              : 'あなたが実施中の実験',
                            style: const TextStyle(
                              color: Color(0xFF8E1728),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '参加者数: ${widget.experiment.participants?.length ?? 0}名',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        // 今後実装: 参加者管理画面への遷移
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('参加者管理機能は開発中です'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.people,
                        size: 18,
                      ),
                      label: const Text('管理'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF8E1728),
                      ),
                    ),
                  ],
                ),
              ),
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
                    if (widget.experiment.simultaneousCapacity > 1) ...[
                      _buildInfoRow(
                        Icons.groups,
                        '同時実験可能人数',
                        '${widget.experiment.simultaneousCapacity}名',
                        Colors.purple,
                      ),
                      const SizedBox(height: 8),
                    ],
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

            // 利用可能な時間枠一覧を表示
            if (widget.experiment.timeSlots.isNotEmpty) ...[
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
                            Icons.schedule,
                            color: Color(0xFF8E1728),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '利用可能な時間枠',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8E1728).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '全${widget.experiment.timeSlots.length}枠',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF8E1728),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(7, (index) {
                        final weekday = index + 1;
                        final weekdaySlots = widget.experiment.timeSlots
                            .where((slot) => slot.weekday == weekday)
                            .toList();
                        
                        if (weekdaySlots.isEmpty) return const SizedBox.shrink();
                        
                        const weekdayNames = ['月', '火', '水', '木', '金', '土', '日'];
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 0.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF8E1728).withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        weekdayNames[index],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Color(0xFF8E1728),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${weekdayNames[index]}曜日',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: weekdaySlots.map((slot) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.grey.shade400,
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.access_time,
                                          size: 14,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          slot.timeRangeString,
                                          style: const TextStyle(
                                            fontSize: 12,
                                          ),
                                        ),
                                        if (slot.maxCapacity > 1) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: Colors.purple.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '${slot.maxCapacity}名',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.purple,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        );
                      }),
                      if (widget.experiment.simultaneousCapacity > 1) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.purple.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: Colors.purple.shade700,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '各時間枠で最大${widget.experiment.simultaneousCapacity}名まで同時に実験に参加できます',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.purple.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
                      ExperimentCalendarViewBase(
                        experiment: widget.experiment,
                        onSlotSelected: _handleSlotSelection,
                        isDemo: widget.isDemo,
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
                onPressed: widget.onApply ?? () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('応募機能は開発中です'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
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