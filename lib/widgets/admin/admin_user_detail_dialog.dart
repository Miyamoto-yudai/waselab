import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/app_user.dart';
import '../../services/admin_service.dart';

/// 管理者用ユーザー詳細ダイアログ
class AdminUserDetailDialog extends StatefulWidget {
  final AppUser user;
  final VoidCallback? onStatusUpdated;

  const AdminUserDetailDialog({
    super.key,
    required this.user,
    this.onStatusUpdated,
  });

  @override
  State<AdminUserDetailDialog> createState() => _AdminUserDetailDialogState();
}

class _AdminUserDetailDialogState extends State<AdminUserDetailDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AdminService _adminService = AdminService();
  
  Map<String, dynamic>? _userDetails;
  bool _isLoading = true;

  // 編集用コントローラー
  late TextEditingController _pointsController;
  late TextEditingController _goodCountController;
  late TextEditingController _badCountController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _pointsController = TextEditingController(text: widget.user.points.toString());
    _goodCountController = TextEditingController(text: widget.user.goodCount.toString());
    _badCountController = TextEditingController(text: widget.user.badCount.toString());
    _loadUserDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pointsController.dispose();
    _goodCountController.dispose();
    _badCountController.dispose();
    super.dispose();
  }

  Future<void> _loadUserDetails() async {
    final details = await _adminService.getUserDetails(widget.user.uid);
    
    if (mounted) {
      setState(() {
        _userDetails = details;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateUserStatus() async {
    final updates = <String, dynamic>{};
    
    final points = int.tryParse(_pointsController.text);
    final goodCount = int.tryParse(_goodCountController.text);
    final badCount = int.tryParse(_badCountController.text);
    
    if (points != null && points != widget.user.points) {
      updates['points'] = points;
    }
    if (goodCount != null && goodCount != widget.user.goodCount) {
      updates['goodCount'] = goodCount;
    }
    if (badCount != null && badCount != widget.user.badCount) {
      updates['badCount'] = badCount;
    }
    
    if (updates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('変更がありません'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ステータス更新'),
        content: Text('${widget.user.name}のステータスを更新しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('更新'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    final success = await _adminService.updateUserStatus(widget.user.uid, updates);
    
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ステータスを更新しました'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onStatusUpdated?.call();
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('更新に失敗しました'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        constraints: const BoxConstraints(
          maxWidth: 800,
          maxHeight: 600,
        ),
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: Text(widget.user.name),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: '基本情報'),
                Tab(text: '実験履歴'),
                Tab(text: 'ステータス編集'),
              ],
            ),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBasicInfoTab(),
                    _buildExperimentHistoryTab(),
                    _buildStatusEditTab(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoTab() {
    final dateFormatter = DateFormat('yyyy/MM/dd HH:mm');
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('UID', widget.user.uid),
                  const Divider(),
                  _buildInfoRow('メールアドレス', widget.user.email),
                  const Divider(),
                  _buildInfoRow('名前', widget.user.name),
                  const Divider(),
                  _buildInfoRow('性別', widget.user.gender ?? '未設定'),
                  const Divider(),
                  _buildInfoRow('年齢', widget.user.age?.toString() ?? '未設定'),
                  const Divider(),
                  _buildInfoRow('学部・学科', widget.user.department ?? '未設定'),
                  const Divider(),
                  _buildInfoRow('学年', widget.user.grade ?? '未設定'),
                  const Divider(),
                  _buildInfoRow(
                    'アカウントタイプ',
                    widget.user.isWasedaUser ? '早稲田ユーザー' : '一般ユーザー',
                  ),
                  const Divider(),
                  _buildInfoRow(
                    'メール認証',
                    widget.user.emailVerified ? '認証済み' : '未認証',
                  ),
                  const Divider(),
                  _buildInfoRow(
                    '登録日時',
                    dateFormatter.format(widget.user.createdAt),
                  ),
                  if (widget.user.emailVerifiedAt != null) ...[
                    const Divider(),
                    _buildInfoRow(
                      'メール認証日時',
                      dateFormatter.format(widget.user.emailVerifiedAt!),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '統計情報',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildStatRow(
                    'Good評価数',
                    widget.user.goodCount.toString(),
                    Icons.thumb_up,
                    Colors.green,
                  ),
                  const SizedBox(height: 8),
                  _buildStatRow(
                    'Bad評価数',
                    widget.user.badCount.toString(),
                    Icons.thumb_down,
                    Colors.red,
                  ),
                  const SizedBox(height: 8),
                  _buildStatRow(
                    '保有ポイント',
                    widget.user.points.toString(),
                    Icons.point_of_sale,
                    Colors.blue,
                  ),
                  const SizedBox(height: 8),
                  _buildStatRow(
                    '参加実験数',
                    widget.user.participatedExperiments.toString(),
                    Icons.science,
                    Colors.orange,
                  ),
                  const SizedBox(height: 8),
                  _buildStatRow(
                    '予定実験数',
                    widget.user.scheduledExperiments.toString(),
                    Icons.schedule,
                    Colors.purple,
                  ),
                  const SizedBox(height: 8),
                  _buildStatRow(
                    '総収益',
                    '¥${widget.user.totalEarnings}',
                    Icons.payments,
                    Colors.green,
                  ),
                  const SizedBox(height: 8),
                  _buildStatRow(
                    '今月の収益',
                    '¥${widget.user.monthlyEarnings}',
                    Icons.calendar_today,
                    Colors.teal,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExperimentHistoryTab() {
    if (_userDetails == null || _userDetails!['experiments'] == null) {
      return const Center(
        child: Text('実験履歴がありません'),
      );
    }
    
    final experiments = _userDetails!['experiments'] as List;
    final dateFormatter = DateFormat('yyyy/MM/dd');
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: experiments.length,
      itemBuilder: (context, index) {
        final experiment = experiments[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getExperimentTypeColor(experiment.type),
              child: Icon(
                _getExperimentTypeIcon(experiment.type),
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(
              experiment.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('募集者: ${experiment.creatorName}'),
                if (experiment.isPaid)
                  Text(
                    '報酬: ¥${experiment.reward}',
                    style: TextStyle(color: Colors.green[700]),
                  ),
                if (experiment.experimentPeriodStart != null)
                  Text(
                    '実施: ${dateFormatter.format(experiment.experimentPeriodStart!)}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
              ],
            ),
            trailing: _buildExperimentStatusChip(experiment.status),
          ),
        );
      },
    );
  }

  Widget _buildStatusEditTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: Colors.orange.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange[700],
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'ステータスの変更は慎重に行ってください。\n変更履歴は記録されます。',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ポイント・評価の編集',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _pointsController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'ポイント',
                      prefixIcon: Icon(Icons.point_of_sale),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _goodCountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Good評価数',
                      prefixIcon: Icon(Icons.thumb_up, color: Colors.green),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _badCountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Bad評価数',
                      prefixIcon: Icon(Icons.thumb_down, color: Colors.red),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _updateUserStatus,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      child: const Text(
                        'ステータスを更新',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: Colors.grey[700]),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _getExperimentTypeColor(dynamic type) {
    // ExperimentTypeのenumに基づく色
    switch (type.toString()) {
      case 'ExperimentType.online':
        return Colors.blue;
      case 'ExperimentType.onsite':
        return Colors.orange;
      case 'ExperimentType.survey':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getExperimentTypeIcon(dynamic type) {
    switch (type.toString()) {
      case 'ExperimentType.online':
        return Icons.computer;
      case 'ExperimentType.onsite':
        return Icons.location_on;
      case 'ExperimentType.survey':
        return Icons.assignment;
      default:
        return Icons.science;
    }
  }

  Widget _buildExperimentStatusChip(dynamic status) {
    String label;
    Color color;
    
    switch (status.toString()) {
      case 'ExperimentStatus.recruiting':
        label = '募集中';
        color = const Color(0xFF8E1728);
        break;
      case 'ExperimentStatus.ongoing':
        label = '進行中';
        color = Colors.blue;
        break;
      case 'ExperimentStatus.waitingEvaluation':
        label = '評価待ち';
        color = Colors.orange;
        break;
      case 'ExperimentStatus.completed':
        label = '完了';
        color = Colors.grey;
        break;
      default:
        label = '不明';
        color = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}