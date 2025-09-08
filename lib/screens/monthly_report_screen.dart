import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/monthly_report.dart';
import '../services/monthly_report_service.dart';

class MonthlyReportScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const MonthlyReportScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  final MonthlyReportService _reportService = MonthlyReportService();
  MonthlyReport? _currentReport;
  bool _isLoading = true;
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadAvailableMonths();
  }

  Future<void> _loadAvailableMonths() async {
    final months = await _reportService.getAvailableReportMonths(widget.userId);
    setState(() {
      if (months.isNotEmpty) {
        final latestMonth = months.first;
        _selectedMonth = DateTime(latestMonth ~/ 100, latestMonth % 100);
      }
    });
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
    });

    final report = await _reportService.getMonthlyReport(
      widget.userId,
      _selectedMonth.year,
      _selectedMonth.month,
    );

    setState(() {
      _currentReport = report;
      _isLoading = false;
    });
  }

  String _formatCurrency(int amount) {
    final formatter = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return formatter;
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '$hours時間$mins分';
    }
    return '$mins分';
  }

  Color _getEvaluationColor(String? evaluation) {
    switch (evaluation) {
      case 'good':
        return Colors.green;
      case 'bad':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getEvaluationIcon(String? evaluation) {
    switch (evaluation) {
      case 'good':
        return Icons.thumb_up;
      case 'bad':
        return Icons.thumb_down;
      default:
        return Icons.remove;
    }
  }

  void _changeMonth(int direction) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + direction,
      );
    });
    _loadReport();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('月次レポート'),
        backgroundColor: const Color(0xFF8E1728),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8E1728)),
              ),
            )
          : _currentReport == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.assessment_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${_selectedMonth.year}年${_selectedMonth.month}月のデータがありません',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          _changeMonth(-1);
                        },
                        child: const Text('前月のレポートを見る'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 月選択ヘッダー
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left),
                                onPressed: () => _changeMonth(-1),
                              ),
                              Text(
                                '${_selectedMonth.year}年${_selectedMonth.month}月',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right),
                                onPressed: _selectedMonth.year == DateTime.now().year &&
                                        _selectedMonth.month == DateTime.now().month
                                    ? null
                                    : () => _changeMonth(1),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // サマリーカード
                      Card(
                        elevation: 2,
                        color: const Color(0xFF8E1728).withValues(alpha: 0.1),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.summarize,
                                    color: Color(0xFF8E1728),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    '月次サマリー',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildSummaryItem(
                                    '実験数',
                                    _currentReport!.totalExperiments.toString(),
                                    Icons.science,
                                    Colors.blue,
                                  ),
                                  _buildSummaryItem(
                                    '総収益',
                                    '¥${_formatCurrency(_currentReport!.totalEarnings)}',
                                    Icons.payments,
                                    Colors.amber[700]!,
                                  ),
                                  _buildSummaryItem(
                                    '総時間',
                                    _formatDuration(_currentReport!.totalMinutes),
                                    Icons.timer,
                                    Colors.purple,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 実験タイプ別統計
                      Row(
                        children: [
                          Expanded(
                            child: Card(
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '実施形式',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildStatRow(
                                      'オンライン',
                                      _currentReport!.onlineExperiments,
                                      Colors.green,
                                    ),
                                    const SizedBox(height: 8),
                                    _buildStatRow(
                                      'オフライン',
                                      _currentReport!.offlineExperiments,
                                      Colors.orange,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Card(
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '実験タイプ',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildStatRow(
                                      '研究室実験',
                                      _currentReport!.labExperiments,
                                      Colors.blue,
                                    ),
                                    const SizedBox(height: 8),
                                    _buildStatRow(
                                      'フィールド',
                                      _currentReport!.fieldExperiments,
                                      Colors.purple,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 評価統計
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '評価統計',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Column(
                                    children: [
                                      Icon(
                                        Icons.thumb_up,
                                        color: Colors.green[600],
                                        size: 32,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_currentReport!.goodEvaluations}',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green[700],
                                        ),
                                      ),
                                      Text(
                                        'Good',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Icon(
                                        Icons.thumb_down,
                                        color: Colors.red[600],
                                        size: 32,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_currentReport!.badEvaluations}',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red[700],
                                        ),
                                      ),
                                      Text(
                                        'Bad',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Icon(
                                        Icons.percent,
                                        color: Colors.blue[600],
                                        size: 32,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_currentReport!.goodEvaluationRate.toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue[700],
                                        ),
                                      ),
                                      Text(
                                        '評価率',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 平均値統計
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '平均統計',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ListTile(
                                leading: Icon(
                                  Icons.attach_money,
                                  color: Colors.amber[700],
                                ),
                                title: const Text('平均報酬'),
                                trailing: Text(
                                  '¥${_formatCurrency(_currentReport!.averageEarningsPerExperiment.round())}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              ListTile(
                                leading: const Icon(
                                  Icons.access_time,
                                  color: Colors.purple,
                                ),
                                title: const Text('平均時間'),
                                trailing: Text(
                                  _formatDuration(_currentReport!.averageMinutesPerExperiment.round()),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 実験履歴
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '実験履歴',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (_currentReport!.experiments.isEmpty)
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Text(
                                      '実験履歴がありません',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                )
                              else
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _currentReport!.experiments.length,
                                  separatorBuilder: (context, index) =>
                                      const Divider(),
                                  itemBuilder: (context, index) {
                                    final experiment =
                                        _currentReport!.experiments[index];
                                    return ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor:
                                            const Color(0xFF8E1728).withValues(alpha: 0.2),
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                            color: Color(0xFF8E1728),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        experiment.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.calendar_today,
                                                size: 14,
                                                color: Colors.grey[600],
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                DateFormat('M/d(E)', 'ja')
                                                    .format(experiment
                                                        .participationDate),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Icon(
                                                Icons.timer,
                                                size: 14,
                                                color: Colors.grey[600],
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                _formatDuration(
                                                    experiment.duration),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: experiment.locationType ==
                                                          'online'
                                                      ? Colors.green
                                                          .withValues(alpha: 0.2)
                                                      : Colors.orange
                                                          .withValues(alpha: 0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  experiment.locationType ==
                                                          'online'
                                                      ? 'オンライン'
                                                      : 'オフライン',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: experiment
                                                                .locationType ==
                                                            'online'
                                                        ? Colors.green[700]
                                                        : Colors.orange[700],
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue
                                                      .withValues(alpha: 0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  experiment.experimentType ==
                                                          'lab'
                                                      ? '研究室実験'
                                                      : 'フィールド実験',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.blue[700],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (experiment.evaluation != null) ...[
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  _getEvaluationIcon(
                                                      experiment.evaluation),
                                                  size: 16,
                                                  color: _getEvaluationColor(
                                                      experiment.evaluation),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  experiment.evaluation == 'good'
                                                      ? 'Good評価'
                                                      : 'Bad評価',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: _getEvaluationColor(
                                                        experiment.evaluation),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                          if (experiment.comment != null &&
                                              experiment.comment!.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              experiment.comment!,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[600],
                                                fontStyle: FontStyle.italic,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ],
                                      ),
                                      trailing: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            '¥${_formatCurrency(experiment.reward)}',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.amber[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          size: 32,
          color: color,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, int value, Color color) {
    final total = _currentReport!.totalExperiments;
    final percentage = total > 0 ? (value / total * 100) : 0;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 50,
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: color.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
          ),
        ),
      ],
    );
  }
}