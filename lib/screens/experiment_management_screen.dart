import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/experiment.dart';
import '../models/app_user.dart';
import '../services/experiment_service.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import 'chat_screen.dart';
import 'experiment_detail_screen.dart';
import 'experiment_evaluation_screen.dart';

/// 実験管理画面
/// 実験募集者が自分の実験を管理するための画面
class ExperimentManagementScreen extends StatefulWidget {
  final Experiment experiment;

  const ExperimentManagementScreen({
    super.key,
    required this.experiment,
  });

  @override
  State<ExperimentManagementScreen> createState() => _ExperimentManagementScreenState();
}

class _ExperimentManagementScreenState extends State<ExperimentManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ExperimentService _experimentService = ExperimentService();
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  
  late Experiment _experiment;
  List<AppUser> _participants = [];
  bool _isLoading = true;
  AppUser? _currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _experiment = widget.experiment;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // 現在のユーザー情報を取得
      _currentUser = await _authService.getCurrentAppUser();
      
      // 最新の実験情報を取得
      final updatedExperiment = await _experimentService.getExperimentById(_experiment.id);
      if (updatedExperiment != null) {
        _experiment = updatedExperiment;
      }
      
      // 参加者情報を取得
      final participantsList = <AppUser>[];
      for (final participantId in _experiment.participants) {
        final user = await _userService.getUserById(participantId);
        if (user != null) {
          participantsList.add(user);
        }
      }
      
      if (mounted) {
        setState(() {
          _participants = participantsList;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('データ読み込みエラー: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ステータス変更機能は削除（システムが自動管理するため）
  // 実験の流れ:
  // 1. 募集中: 募集期限内
  // 2. 進行中: 実験期間中
  // 3. 評価待ち/完了: 参加者ごとに個別管理

  /// 評価可能な参加者数を取得（参加者が実験者を評価済みで、実験者が参加者を未評価の場合）
  int _getEvaluatableParticipantCount() {
    int count = 0;
    final experimentData = _experiment.toFirestore();
    final participantEvals = experimentData['participantEvaluations'] as Map<String, dynamic>? ?? {};
    
    for (final participantId in _experiment.participants) {
      final userEval = participantEvals[participantId] as Map<String, dynamic>? ?? {};
      final creatorToParticipant = userEval['creatorEvaluated'] ?? false;
      final participantToCreator = userEval['participantEvaluated'] ?? false;
      
      // 参加者が実験者を評価済みで、実験者がまだ参加者を評価していない場合のみカウント
      if (participantToCreator && !creatorToParticipant) {
        count++;
      }
    }
    
    return count;
  }

  /// 募集を締め切る
  Future<void> _closeRecruitment() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('募集締切'),
        content: const Text('募集を締め切りますか？締切後は新規応募を受け付けません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('締め切る'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('experiments')
            .doc(_experiment.id)
            .update({
          'recruitmentEndDate': DateTime.now().toIso8601String(),
        });

        await _loadData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('募集を締め切りました'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('募集締切に失敗しました: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// 参加者への一括メッセージ送信
  Future<void> _sendBulkMessage() async {
    final messageController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('参加者への一括メッセージ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('すべての参加者にメッセージを送信します'),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'メッセージを入力...',
                border: OutlineInputBorder(),
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
            child: const Text('送信'),
          ),
        ],
      ),
    );

    if (result == true && messageController.text.isNotEmpty) {
      // TODO: 一括メッセージ送信機能の実装
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('メッセージを送信しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('実験管理'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('実験管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.visibility),
            tooltip: '実験詳細を表示',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExperimentDetailScreen(
                    experiment: _experiment,
                    isMyExperiment: true,
                  ),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.normal,
          ),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            const Tab(text: '概要'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('参加者'),
                  if (_getEvaluatableParticipantCount() > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_getEvaluatableParticipantCount()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: '設定'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 概要タブ
          _buildOverviewTab(),
          // 参加者タブ
          _buildParticipantsTab(),
          // 設定タブ
          _buildSettingsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _sendBulkMessage,
        backgroundColor: const Color(0xFF8E1728),
        icon: const Icon(Icons.send),
        label: const Text('一括メッセージ'),
      ),
    );
  }

  Widget _buildOverviewTab() {
    final participantCount = _participants.length;
    final maxParticipants = _experiment.maxParticipants ?? 0;
    final completionRate = maxParticipants > 0 
        ? (participantCount / maxParticipants * 100).toInt() 
        : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 実験情報カード
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _experiment.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildStatusBadge(_experiment.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _experiment.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildInfoChip(
                        Icons.science,
                        _experiment.type.label,
                        _getTypeColor(_experiment.type),
                      ),
                      const SizedBox(width: 8),
                      if (_experiment.isPaid)
                        _buildInfoChip(
                          Icons.payments,
                          '¥${_experiment.reward}',
                          Colors.green,
                        ),
                      const SizedBox(width: 8),
                      if (_experiment.location.isNotEmpty)
                        Flexible(
                          child: _buildInfoChip(
                            Icons.location_on,
                            _experiment.location,
                            Colors.blue,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 統計情報
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  '参加者数',
                  '$participantCount',
                  subtitle: maxParticipants > 0 ? '/ $maxParticipants名' : null,
                  icon: Icons.people,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  '充足率',
                  '$completionRate%',
                  icon: Icons.donut_large,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  '未評価',
                  '${_getNotEvaluatedCount()}',
                  icon: Icons.pending_actions,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  '評価済み',
                  '${_getEvaluatedCount()}',
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // アクションボタン
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'クイックアクション',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (_experiment.status == ExperimentStatus.recruiting)
                        ElevatedButton.icon(
                          onPressed: _closeRecruitment,
                          icon: const Icon(Icons.block),
                          label: const Text('募集締切'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                        ),
                      ElevatedButton.icon(
                        onPressed: _sendBulkMessage,
                        icon: const Icon(Icons.send),
                        label: const Text('参加者にメッセージ'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8E1728),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          // TODO: 編集画面への遷移
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('編集機能は実装予定です'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('実験情報を編集'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 日程情報
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '日程情報',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDateInfo('募集開始', _experiment.recruitmentStartDate),
                  const SizedBox(height: 8),
                  _buildDateInfo('募集終了', _experiment.recruitmentEndDate),
                  const SizedBox(height: 8),
                  _buildDateInfo('実験期間開始', _experiment.experimentPeriodStart),
                  const SizedBox(height: 8),
                  _buildDateInfo('実験期間終了', _experiment.experimentPeriodEnd),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // 実験詳細を表示ボタン
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ExperimentDetailScreen(
                      experiment: _experiment,
                      isMyExperiment: true,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.visibility),
              label: const Text('実験詳細を表示'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8E1728),
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsTab() {
    if (_participants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'まだ参加者がいません',
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
      itemCount: _participants.length,
      itemBuilder: (context, index) {
        final participant = _participants[index];
        
        // participantEvaluationsから個別の評価状態を取得
        final experimentData = _experiment.toFirestore();
        final participantEvals = experimentData['participantEvaluations'] as Map<String, dynamic>? ?? {};
        final userEval = participantEvals[participant.uid] as Map<String, dynamic>? ?? {};
        
        // 実験者から参加者への評価状態
        final creatorToParticipant = userEval['creatorEvaluated'] ?? false;
        // 参加者から実験者への評価状態
        final participantToCreator = userEval['participantEvaluated'] ?? false;
        // 相互評価完了フラグ
        final mutuallyCompleted = userEval['mutuallyCompleted'] ?? false;
        
        // 評価ステータスを判定
        String evaluationStatus;
        Color statusColor;
        IconData statusIcon;
        
        if (mutuallyCompleted) {
          evaluationStatus = '相互評価完了';
          statusColor = Colors.green;
          statusIcon = Icons.check_circle;
        } else if (creatorToParticipant && !participantToCreator) {
          evaluationStatus = '相手の評価待ち';
          statusColor = Colors.blue;
          statusIcon = Icons.hourglass_empty;
        } else if (!creatorToParticipant && participantToCreator) {
          evaluationStatus = 'あなたの評価待ち';
          statusColor = Colors.orange;
          statusIcon = Icons.rate_review;
        } else {
          evaluationStatus = '実験実施待ち';
          statusColor = Colors.grey;
          statusIcon = Icons.schedule;
        }
        
        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF8E1728),
              backgroundImage: participant.photoUrl != null 
                  ? NetworkImage(participant.photoUrl!)
                  : null,
              child: participant.photoUrl == null
                  ? Text(
                      participant.name[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    )
                  : null,
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    participant.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        evaluationStatus,
                        style: TextStyle(
                          fontSize: 11,
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(participant.email, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                if (participant.department?.isNotEmpty ?? false)
                  Text(
                    '${participant.department} ${participant.grade ?? ""}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Icon(
                              creatorToParticipant ? Icons.check_circle : Icons.radio_button_unchecked,
                              color: creatorToParticipant ? Colors.green : Colors.grey,
                              size: 24,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'あなた→参加者',
                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                            ),
                            Text(
                              creatorToParticipant ? '評価済' : '未評価',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: creatorToParticipant ? Colors.green : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Icon(
                              participantToCreator ? Icons.check_circle : Icons.radio_button_unchecked,
                              color: participantToCreator ? Colors.green : Colors.grey,
                              size: 24,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '参加者→あなた',
                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                            ),
                            Text(
                              participantToCreator ? '評価済' : '未評価',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: participantToCreator ? Colors.green : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(
                                    otherUserId: participant.uid,
                                    otherUserName: participant.name,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.chat_bubble_outline, size: 16),
                            label: const Text('メッセージ'),
                          ),
                        ),
                        // 参加者が実験者を評価済みで、実験者がまだ参加者を評価していない場合のみ評価ボタンを表示
                        if (participantToCreator && !creatorToParticipant) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ExperimentEvaluationScreen(
                                      experiment: _experiment,
                                      targetUserId: participant.uid,
                                      targetUserName: participant.name,
                                    ),
                                  ),
                                ).then((result) {
                                  if (result == true) {
                                    _loadData(); // 評価完了後にデータを再読み込み
                                  }
                                });
                              },
                              icon: const Icon(Icons.star, size: 16),
                              label: const Text('評価する'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '実験設定',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text('実験情報を編集'),
                    subtitle: const Text('タイトル、説明、報酬などを変更'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // TODO: 編集画面への遷移
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('編集機能は実装予定です'),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.notifications),
                    title: const Text('通知設定'),
                    subtitle: const Text('新規応募時の通知など'),
                    trailing: Switch(
                      value: true,
                      onChanged: (value) {
                        // TODO: 通知設定の変更
                      },
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text(
                      '実験を削除',
                      style: TextStyle(color: Colors.red),
                    ),
                    subtitle: const Text('この操作は取り消せません'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('実験の削除'),
                          content: const Text(
                            'この実験を削除しますか？\nこの操作は取り消せません。',
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
                              child: const Text('削除'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        // TODO: 削除処理
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('削除機能は実装予定です'),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // 実験タイプ別の設定
          if (_experiment.type == ExperimentType.survey)
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'アンケート設定',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.link),
                      title: const Text('アンケートURL'),
                      subtitle: Text(
                        _experiment.surveyUrl ?? 'URLが設定されていません',
                        style: TextStyle(
                          color: _experiment.surveyUrl != null 
                              ? Colors.blue 
                              : Colors.grey,
                        ),
                      ),
                      trailing: const Icon(Icons.edit, size: 20),
                      onTap: () {
                        // TODO: URL編集ダイアログ
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('URL編集機能は実装予定です'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value, {
    String? subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ExperimentStatus status) {
    Color color;
    switch (status) {
      case ExperimentStatus.recruiting:
        color = const Color(0xFF8E1728);
        break;
      case ExperimentStatus.ongoing:
        color = Colors.blue;
        break;
      case ExperimentStatus.waitingEvaluation:
        color = Colors.orange;
        break;
      case ExperimentStatus.completed:
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDateInfo(String label, DateTime? date) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Text(
          date != null 
              ? DateFormat('yyyy/MM/dd HH:mm').format(date)
              : '未設定',
          style: TextStyle(
            fontSize: 14,
            fontWeight: date != null ? FontWeight.bold : FontWeight.normal,
            color: date != null ? Colors.black : Colors.grey,
          ),
        ),
      ],
    );
  }

  Color _getTypeColor(ExperimentType type) {
    switch (type) {
      case ExperimentType.online:
        return Colors.blue;
      case ExperimentType.onsite:
        return Colors.orange;
      case ExperimentType.survey:
        return Colors.green;
    }
  }

  int _getNotEvaluatedCount() {
    // 参加者のうち、まだ評価が完了していない人数
    int count = 0;
    for (final participantId in _experiment.participants) {
      final evaluation = _experiment.evaluations?[participantId];
      if (evaluation == null || !(evaluation['evaluated'] ?? false)) {
        count++;
      }
    }
    return count;
  }

  int _getEvaluatedCount() {
    // 参加者のうち、評価が完了している人数
    int count = 0;
    for (final participantId in _experiment.participants) {
      final evaluation = _experiment.evaluations?[participantId];
      if (evaluation != null && (evaluation['evaluated'] ?? false)) {
        count++;
      }
    }
    return count;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}