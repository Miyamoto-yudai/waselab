import 'package:flutter/material.dart';
import '../models/experiment.dart';
import '../screens/experiment_detail_screen.dart';

/// 実験カードの共通ウィジェット
class ExperimentCard extends StatelessWidget {
  final Experiment experiment;
  
  const ExperimentCard({
    super.key,
    required this.experiment,
  });

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
        return const Color(0xFF2E7D32); // 緑
      case ExperimentType.onsite:
        return const Color(0xFF1976D2); // 青
      case ExperimentType.survey:
        return const Color(0xFFE65100); // オレンジ
    }
  }

  @override
  Widget build(BuildContext context) {
    // 締切までの残り日数を計算
    final daysLeft = experiment.endDate?.difference(DateTime.now()).inDays;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF8E1728).withValues(alpha: 0.08),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ExperimentDetailScreen(experiment: experiment),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 328, // 固定高さでレイアウトを制約
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // 締切タグ
              if (daysLeft != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: daysLeft <= 3 
                      ? Colors.red.withValues(alpha: 0.1)
                      : daysLeft <= 7
                        ? Colors.orange.withValues(alpha: 0.1)
                        : Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    daysLeft <= 0 
                      ? '本日締切' 
                      : daysLeft == 1
                        ? '明日締切'
                        : 'あと$daysLeft日',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: daysLeft <= 3 
                        ? Colors.red[700]
                        : daysLeft <= 7
                          ? Colors.orange[700]
                          : Colors.green[700],
                    ),
                  ),
                ),
              
              // タイトルと研究室名
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    experiment.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2C2C2C),
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (experiment.labName != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8E1728).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.school,
                            size: 12,
                            color: Color(0xFF8E1728),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            experiment.labName!,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF8E1728),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              
              const SizedBox(height: 8),
              
              // 説明文
              Text(
                experiment.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  height: 1.3,
                  letterSpacing: 0.05,
                ),
              ),
              
              const Spacer(),
              const SizedBox(height: 8),
              
              // 情報グリッド
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F9F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    // 報酬（最重要）
                    Icon(
                      Icons.payments_outlined,
                      size: 16,
                      color: experiment.isPaid ? const Color(0xFF8E1728) : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      experiment.isPaid 
                        ? '¥${experiment.reward.toString().replaceAllMapped(
                            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                            (Match m) => '${m[1]},',
                          )}'
                        : '無償',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: experiment.isPaid ? const Color(0xFF8E1728) : Colors.grey[700],
                      ),
                    ),
                    // 所要時間（2番目）
                    if (experiment.duration != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 1,
                        height: 24,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.timer_outlined, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 2),
                      Text(
                        '${experiment.duration}分',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                    // カテゴリ（3番目）
                    const SizedBox(width: 6),
                    Container(
                      width: 1,
                      height: 24,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getTypeIcon(experiment.type),
                            size: 16,
                            color: _getTypeColor(experiment.type),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              experiment.type.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _getTypeColor(experiment.type),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 募集人数（最後）
                    if (experiment.maxParticipants != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 1,
                        height: 20,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.group_outlined, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '募集${experiment.maxParticipants}名',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 4),
              
              // 場所情報
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blue.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 16, color: Colors.blue[700]),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        experiment.location,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[900],
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}