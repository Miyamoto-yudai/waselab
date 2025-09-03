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

  /// 実験ステータスを更新
  Future<void> _updateExperimentStatus(ExperimentStatus newStatus) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ステータス変更'),
        content: Text('実験のステータスを「${newStatus.label}」に変更しますか？'),
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
            child: const Text('変更'),
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
          'status': newStatus.name,
          if (newStatus == ExperimentStatus.completed) 
            'completedAt': FieldValue.serverTimestamp(),
        });

        await _loadData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ステータスを「${newStatus.label}」に変更しました'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ステータス変更に失敗しました: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
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
          tabs: const [
            Tab(text: '概要'),
            Tab(text: '参加者'),
            Tab(text: '設定'),
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
                  '評価待ち',
                  '${_getWaitingEvaluationCount()}',
                  icon: Icons.rate_review,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  '完了',
                  '${_getCompletedCount()}',
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
                      if (_experiment.status == ExperimentStatus.recruiting)
                        ElevatedButton.icon(
                          onPressed: () => _updateExperimentStatus(ExperimentStatus.ongoing),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('実験開始'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                        ),
                      if (_experiment.status == ExperimentStatus.ongoing)
                        ElevatedButton.icon(
                          onPressed: () => _updateExperimentStatus(ExperimentStatus.waitingEvaluation),
                          icon: const Icon(Icons.rate_review),
                          label: const Text('評価待ちへ'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                          ),
                        ),
                      if (_experiment.status == ExperimentStatus.waitingEvaluation)
                        ElevatedButton.icon(
                          onPressed: () => _updateExperimentStatus(ExperimentStatus.completed),
                          icon: const Icon(Icons.check_circle),
                          label: const Text('完了'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                        ),
                      OutlinedButton.icon(
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
                        label: const Text('詳細を見る'),
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
        final hasEvaluated = _experiment.evaluations?[participant.uid]?['evaluated'] ?? false;
        
        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
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
            title: Text(
              participant.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(participant.email),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (participant.department?.isNotEmpty ?? false) ...[
                      Icon(Icons.school, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        participant.department!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (participant.grade?.isNotEmpty ?? false) ...[
                      Icon(Icons.grade, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        participant.grade!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasEvaluated)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '評価済',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          otherUserId: participant.uid,
                          otherUserName: participant.name,
                          conversationId: '${_currentUser?.uid ?? ''}_${participant.uid}',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
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

  int _getWaitingEvaluationCount() {
    if (_experiment.evaluations == null) return 0;
    return _experiment.evaluations!.values
        .where((eval) => !(eval['evaluated'] ?? false))
        .length;
  }

  int _getCompletedCount() {
    if (_experiment.evaluations == null) return 0;
    return _experiment.evaluations!.values
        .where((eval) => eval['evaluated'] ?? false)
        .length;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}