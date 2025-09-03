import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/experiment.dart';
import '../models/experiment_evaluation.dart';
import '../models/app_user.dart';
import '../services/evaluation_service.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'package:intl/intl.dart';

class ExperimentEvaluationScreen extends StatefulWidget {
  final Experiment experiment;
  final String? targetUserId; // 評価対象の参加者ID（実験者から参加者を評価する場合）
  final String? targetUserName; // 評価対象の参加者名
  
  const ExperimentEvaluationScreen({
    super.key,
    required this.experiment,
    this.targetUserId,
    this.targetUserName,
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
      
      // 評価可能かチェック（日時制限を含む）
      if (!widget.experiment.canEvaluate(currentUser.uid)) {
        if (mounted) {
          String message = '評価はまだできません';
          
          // 将来の実験かチェック
          if (widget.experiment.isScheduledFuture(currentUser.uid)) {
            message = '実験実施後に評価が可能になります';
            
            // 実施予定日時を表示
            if (widget.experiment.fixedExperimentDate != null) {
              final dateStr = DateFormat('yyyy/MM/dd').format(widget.experiment.fixedExperimentDate!);
              if (widget.experiment.fixedExperimentTime != null) {
                final hour = widget.experiment.fixedExperimentTime!['hour'] ?? 0;
                final minute = widget.experiment.fixedExperimentTime!['minute'] ?? 0;
                message += '\n実施予定: $dateStr ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
              } else {
                message += '\n実施予定: $dateStr';
              }
            }
          } else if (widget.experiment.hasEvaluated(currentUser.uid)) {
            message = '既に評価済みです';
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
          Navigator.pop(context);
        }
        return;
      }
      
      // 相手のユーザー情報を取得
      String otherUserId;
      if (widget.targetUserId != null) {
        // 特定の参加者が指定されている場合（実験者から参加者を評価）
        otherUserId = widget.targetUserId!;
      } else if (widget.experiment.creatorId == currentUser.uid) {
        // 自分が実験者の場合、相手は参加者（最初の参加者）
        if (widget.experiment.participants.isEmpty) {
          throw Exception('参加者がいません');
        }
        otherUserId = widget.experiment.participants.first;
      } else {
        // 自分が参加者の場合、相手は実験者
        otherUserId = widget.experiment.creatorId;
      }
      
      final otherUser = widget.targetUserName != null 
          ? AppUser(
              uid: otherUserId,
              name: widget.targetUserName!,
              email: '', // 評価には必要ない
              isWasedaUser: false,
              canCreateExperiment: false,
              createdAt: DateTime.now(),
              emailVerified: false,
            )
          : await _userService.getUser(otherUserId);
      
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
    
    // 確認ダイアログを表示
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('評価の確認'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '実験は完了しましたか？',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: const Text(
                '実験が完全に終了してから評価を行ってください。\n一度送信した評価は変更できません。',
                style: TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '選択した評価: ${_selectedEvaluation == EvaluationType.good ? "良い 👍" : "悪い 👎"}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('戻る'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8E1728),
            ),
            child: const Text('実験完了済み・評価を送信'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
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
    } catch (e, stackTrace) {
      debugPrint('Error submitting evaluation: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        
        // より詳細なエラーメッセージを表示
        String errorMessage = '評価の送信に失敗しました';
        if (e.toString().contains('権限がありません')) {
          errorMessage = 'この実験を評価する権限がありません';
        } else if (e.toString().contains('既に評価済み')) {
          errorMessage = '既に評価済みです';
        } else if (e.toString().contains('実験が見つかりません')) {
          errorMessage = '実験が見つかりません';
        } else {
          errorMessage = '評価の送信に失敗しました: ${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
  
  String _getExperimentDateText() {
    // アンケート型の場合
    if (widget.experiment.type == ExperimentType.survey) {
      return 'アンケート実験';
    }
    
    // 固定日時の実験の場合
    if (widget.experiment.fixedExperimentDate != null) {
      final dateStr = DateFormat('yyyy/MM/dd').format(widget.experiment.fixedExperimentDate!);
      if (widget.experiment.fixedExperimentTime != null) {
        final hour = widget.experiment.fixedExperimentTime!['hour'] ?? 0;
        final minute = widget.experiment.fixedExperimentTime!['minute'] ?? 0;
        return '$dateStr ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
      }
      return dateStr;
    }
    
    // 柔軟な日程調整の実験で、参加者が自分の場合
    if (widget.experiment.allowFlexibleSchedule && 
        _currentUser != null &&
        widget.experiment.participants.contains(_currentUser!.uid) && 
        widget.experiment.participantEvaluations != null) {
      final participantInfo = widget.experiment.participantEvaluations![_currentUser!.uid];
      if (participantInfo != null && participantInfo['scheduledDate'] != null) {
        final scheduledDate = (participantInfo['scheduledDate'] as Timestamp).toDate();
        return DateFormat('yyyy/MM/dd HH:mm').format(scheduledDate);
      }
    }
    
    // 実験期間が設定されている場合
    if (widget.experiment.experimentPeriodEnd != null) {
      return '${DateFormat('yyyy/MM/dd').format(widget.experiment.experimentPeriodEnd!)} まで';
    }
    
    // それ以外の場合
    return '日程調整中';
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
                              _getExperimentDateText(),
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
                const SizedBox(height: 16),
                
                // 実験後評価の注意事項
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '重要：実験終了後に評価してください',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'この評価は実験が完全に終了してから行ってください。\n実験前や実験中に評価を行わないようご注意ください。',
                              style: TextStyle(fontSize: 12, color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // 評価対象の表示
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
                
                // 相手の情報
                Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF8E1728),
                      child: Text(
                        _otherUser != null && _otherUser!.name.isNotEmpty 
                          ? _otherUser!.name[0] 
                          : '?',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(_otherUser?.name ?? '読み込み中...'),
                    subtitle: _otherUser != null 
                      ? Text(_otherUser!.email.isNotEmpty ? _otherUser!.email : 'メールアドレス未設定')
                      : null,
                  ),
                ),
                const SizedBox(height: 24),
                
                // 評価選択
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      '実験後の評価を選択してください',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
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