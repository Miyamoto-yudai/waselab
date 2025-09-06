import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/experiment_evaluation.dart';
import '../models/experiment.dart';
import '../services/evaluation_service.dart';
import '../services/experiment_service.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import 'experiment_detail_screen.dart';

/// 評価履歴画面
class EvaluationHistoryScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final bool isMyHistory;

  const EvaluationHistoryScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.isMyHistory = false,
  });

  @override
  State<EvaluationHistoryScreen> createState() => _EvaluationHistoryScreenState();
}

class _EvaluationHistoryScreenState extends State<EvaluationHistoryScreen>
    with SingleTickerProviderStateMixin {
  final EvaluationService _evaluationService = EvaluationService();
  final ExperimentService _experimentService = ExperimentService();
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  
  late TabController _tabController;
  List<ExperimentEvaluation> _receivedEvaluations = [];
  List<ExperimentEvaluation> _givenEvaluations = [];
  final Map<String, Experiment?> _experimentCache = {};
  final Map<String, String> _userNameCache = {};
  bool _isLoading = true;
  String? _filterType;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadEvaluations();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadEvaluations() async {
    try {
      setState(() => _isLoading = true);
      
      // すべての評価を取得
      final allEvaluations = await _evaluationService.getUserEvaluations(widget.userId);
      
      // 受けた評価と与えた評価に分類
      _receivedEvaluations = allEvaluations
          .where((e) => e.evaluatedUserId == widget.userId)
          .toList();
      _givenEvaluations = allEvaluations
          .where((e) => e.evaluatorId == widget.userId)
          .toList();
      
      // 関連する実験情報を取得
      final experimentIds = <String>{};
      for (final eval in allEvaluations) {
        experimentIds.add(eval.experimentId);
      }
      
      for (final id in experimentIds) {
        final experiment = await _experimentService.getExperimentById(id);
        _experimentCache[id] = experiment;
      }
      
      // 関連するユーザー名を取得
      final userIds = <String>{};
      for (final eval in allEvaluations) {
        userIds.add(eval.evaluatorId);
        userIds.add(eval.evaluatedUserId);
      }
      
      for (final id in userIds) {
        if (id != widget.userId) {
          final user = await _userService.getUser(id);
          if (user != null) {
            _userNameCache[id] = user.name;
          }
        }
      }
      
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading evaluations: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  List<ExperimentEvaluation> _getFilteredEvaluations(List<ExperimentEvaluation> evaluations) {
    if (_filterType == null) return evaluations;
    
    if (_filterType == 'good') {
      return evaluations.where((e) => e.type == EvaluationType.good).toList();
    } else if (_filterType == 'bad') {
      return evaluations.where((e) => e.type == EvaluationType.bad).toList();
    }
    
    return evaluations;
  }
  
  Widget _buildEvaluationList(List<ExperimentEvaluation> evaluations, bool isReceived) {
    final filteredEvaluations = _getFilteredEvaluations(evaluations);
    
    if (filteredEvaluations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isReceived ? Icons.inbox : Icons.outbox,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isReceived ? '受けた評価がありません' : '与えた評価がありません',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredEvaluations.length,
      itemBuilder: (context, index) {
        final evaluation = filteredEvaluations[index];
        return _buildEvaluationCard(evaluation, isReceived);
      },
    );
  }
  
  Widget _buildEvaluationCard(ExperimentEvaluation evaluation, bool isReceived) {
    final experiment = _experimentCache[evaluation.experimentId];
    final otherUserId = isReceived ? evaluation.evaluatorId : evaluation.evaluatedUserId;
    final otherUserName = _userNameCache[otherUserId] ?? '不明なユーザー';
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: experiment != null
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ExperimentDetailScreen(
                      experiment: experiment,
                      isMyExperiment: experiment.creatorId == widget.userId,
                    ),
                  ),
                );
              }
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ヘッダー部分
              Row(
                children: [
                  // 評価タイプアイコン
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: evaluation.type == EvaluationType.good
                          ? Colors.green.withValues(alpha: 0.1)
                          : evaluation.type == EvaluationType.bad
                              ? Colors.red.withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      evaluation.type == EvaluationType.good
                          ? Icons.thumb_up
                          : evaluation.type == EvaluationType.bad
                              ? Icons.thumb_down
                              : Icons.remove,
                      color: evaluation.type == EvaluationType.good
                          ? Colors.green
                          : evaluation.type == EvaluationType.bad
                              ? Colors.red
                              : Colors.grey,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 実験タイトル
                        Text(
                          experiment?.title ?? '実験情報を取得できません',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // 相手のユーザー名と役割
                        Row(
                          children: [
                            Icon(
                              isReceived ? Icons.person : Icons.person_outline,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isReceived
                                  ? '$otherUserNameから評価'
                                  : '$otherUserNameを評価',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: evaluation.evaluatorRole == EvaluatorRole.experimenter
                                    ? const Color(0xFF8E1728).withValues(alpha: 0.1)
                                    : Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                evaluation.evaluatorRole.label,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: evaluation.evaluatorRole == EvaluatorRole.experimenter
                                      ? const Color(0xFF8E1728)
                                      : Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // 日付
                  Text(
                    DateFormat('MM/dd').format(evaluation.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              
              // コメント（ある場合）
              if (evaluation.comment != null && evaluation.comment!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.comment_outlined,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          evaluation.comment!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // 実験情報（ある場合）
              if (experiment != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (experiment.isPaid) ...[
                      Icon(
                        Icons.payments_outlined,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '¥${experiment.reward}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        experiment.location,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              
              // タイムスタンプ
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.access_time,
                    size: 12,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('yyyy年MM月dd日 HH:mm').format(evaluation.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isMyHistory ? '評価履歴' : '${widget.userName}の評価履歴'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 4,
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
          ),
          tabs: [
            Tab(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inbox, size: 18),
                      const SizedBox(width: 6),
                      const Text('受けた評価'),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_receivedEvaluations.length}件',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Tab(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.outbox, size: 18),
                      const SizedBox(width: 6),
                      const Text('与えた評価'),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_givenEvaluations.length}件',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // フィルターボタン
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _filterType = value == 'all' ? null : value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Row(
                  children: [
                    Icon(Icons.all_inclusive, size: 20),
                    SizedBox(width: 12),
                    Text('すべて'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'good',
                child: Row(
                  children: [
                    Icon(Icons.thumb_up, color: Colors.green, size: 20),
                    SizedBox(width: 12),
                    Text('Goodのみ'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'bad',
                child: Row(
                  children: [
                    Icon(Icons.thumb_down, color: Colors.red, size: 20),
                    SizedBox(width: 12),
                    Text('Badのみ'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8E1728)),
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                RefreshIndicator(
                  onRefresh: _loadEvaluations,
                  child: _buildEvaluationList(_receivedEvaluations, true),
                ),
                RefreshIndicator(
                  onRefresh: _loadEvaluations,
                  child: _buildEvaluationList(_givenEvaluations, false),
                ),
              ],
            ),
    );
  }
}