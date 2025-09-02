import 'package:flutter/material.dart';
import '../models/experiment.dart';
import '../models/experiment_evaluation.dart';
import '../models/app_user.dart';
import '../services/evaluation_service.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'package:intl/intl.dart';

class ExperimentEvaluationScreen extends StatefulWidget {
  final Experiment experiment;
  
  const ExperimentEvaluationScreen({
    super.key,
    required this.experiment,
  });

  @override
  State<ExperimentEvaluationScreen> createState() => _ExperimentEvaluationScreenState();
}

class _ExperimentEvaluationScreenState extends State<ExperimentEvaluationScreen> {
  final EvaluationService _evaluationService = EvaluationService();
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final TextEditingController _commentController = TextEditingController();
  
  EvaluationType? _selectedEvaluation;
  AppUser? _currentUser;
  AppUser? _otherUser;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _hasEvaluated = false;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    try {
      // 現在のユーザー情報を取得
      final currentUser = await _authService.getCurrentAppUser();
      if (currentUser == null) {
        if (mounted) {
          Navigator.pop(context);
        }
        return;
      }
      
      // 相手のユーザー情報を取得
      String otherUserId;
      if (widget.experiment.creatorId == currentUser.uid) {
        // 自分が実験者の場合、相手は参加者（最初の参加者）
        if (widget.experiment.participants.isEmpty) {
          throw Exception('参加者がいません');
        }
        otherUserId = widget.experiment.participants.first;
      } else {
        // 自分が参加者の場合、相手は実験者
        otherUserId = widget.experiment.creatorId;
      }
      
      final otherUser = await _userService.getUser(otherUserId);
      
      // 評価状態を確認
      final evaluationStatus = await _evaluationService.getExperimentEvaluationStatus(
        widget.experiment.id,
        currentUser.uid,
      );
      
      if (mounted) {
        setState(() {
          _currentUser = currentUser;
          _otherUser = otherUser;
          _hasEvaluated = evaluationStatus['hasEvaluated'] ?? false;
          _isLoading = false;
        });
        
        if (_hasEvaluated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('既に評価済みです'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('データの読み込みに失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _submitEvaluation() async {
    if (_selectedEvaluation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('評価を選択してください'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    if (_currentUser == null || _otherUser == null) return;
    
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      // 評価者の役割を判定
      final evaluatorRole = widget.experiment.creatorId == _currentUser!.uid
        ? EvaluatorRole.experimenter
        : EvaluatorRole.participant;
      
      // 評価を送信
      await _evaluationService.createEvaluation(
        experimentId: widget.experiment.id,
        evaluatorId: _currentUser!.uid,
        evaluatedUserId: _otherUser!.uid,
        evaluatorRole: evaluatorRole,
        type: _selectedEvaluation!,
        comment: _commentController.text.trim().isNotEmpty 
          ? _commentController.text.trim() 
          : null,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('評価を送信しました'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // 評価完了を親画面に通知
      }
    } catch (e) {
      debugPrint('Error submitting evaluation: $e');
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('評価の送信に失敗しました: $e'),
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
        title: const Text('実験評価'),
        backgroundColor: const Color(0xFF8E1728),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 実験情報カード
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.experiment.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              widget.experiment.experimentPeriodEnd != null
                                ? DateFormat('yyyy/MM/dd').format(widget.experiment.experimentPeriodEnd!)
                                : '日程未定',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(width: 16),
                            Icon(Icons.monetization_on, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              '¥${widget.experiment.reward}',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // 相手の情報
                if (_otherUser != null) ...[
                  Text(
                    _currentUser?.uid == widget.experiment.creatorId
                      ? '参加者の評価'
                      : '実験者の評価',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF8E1728),
                        child: Text(
                          _otherUser!.name.isNotEmpty ? _otherUser!.name[0] : '?',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(_otherUser!.name),
                      subtitle: Text(_otherUser!.email),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                
                // 評価選択
                Text(
                  '評価を選択してください',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                if (_hasEvaluated)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: const Text(
                      '既に評価済みです',
                      style: TextStyle(color: Colors.orange),
                    ),
                  )
                else ...[
                  Row(
                    children: [
                      Expanded(
                        child: _EvaluationButton(
                          type: EvaluationType.good,
                          selected: _selectedEvaluation == EvaluationType.good,
                          onTap: () {
                            setState(() {
                              _selectedEvaluation = EvaluationType.good;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _EvaluationButton(
                          type: EvaluationType.bad,
                          selected: _selectedEvaluation == EvaluationType.bad,
                          onTap: () {
                            setState(() {
                              _selectedEvaluation = EvaluationType.bad;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // コメント入力
                  Text(
                    'コメント（任意）',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _commentController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: '実験の感想や改善点などをお書きください',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // 送信ボタン
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitEvaluation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8E1728),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('評価を送信'),
                    ),
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // 注意事項
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '双方の評価が完了すると実験が完了し、報酬が付与されます。\n実験終了から1週間経過すると自動的に完了となります。',
                          style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

/// 評価ボタンウィジェット
class _EvaluationButton extends StatelessWidget {
  final EvaluationType type;
  final bool selected;
  final VoidCallback onTap;
  
  const _EvaluationButton({
    required this.type,
    required this.selected,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final isGood = type == EvaluationType.good;
    final color = isGood ? Colors.green : Colors.red;
    final icon = isGood ? Icons.thumb_up : Icons.thumb_down;
    final label = isGood ? 'Good' : 'Bad';
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? color : Colors.grey[300]!,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: selected ? color : Colors.grey[600],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: selected ? color : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}