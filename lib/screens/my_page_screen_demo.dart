import 'package:flutter/material.dart';
import '../services/demo_auth_service.dart';
import '../models/experiment.dart';
import 'package:intl/intl.dart';

/// デモモード用のマイページ画面
class MyPageScreenDemo extends StatefulWidget {
  final DemoAuthService authService;
  final VoidCallback onLogout;

  const MyPageScreenDemo({
    super.key,
    required this.authService,
    required this.onLogout,
  });

  @override
  State<MyPageScreenDemo> createState() => _MyPageScreenDemoState();
}

class _MyPageScreenDemoState extends State<MyPageScreenDemo> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isEditing = false;
  final TextEditingController _bioController = TextEditingController(
    text: 'わせラボで実験に参加しています。心理学と認知科学に興味があります。',
  );
  final TextEditingController _departmentController = TextEditingController(
    text: '政治経済学部',
  );
  final TextEditingController _gradeController = TextEditingController(
    text: '3年',
  );
  
  // デモ用のサンプル実験データ
  final List<Experiment> _demoParticipatedExperiments = [
    Experiment(
      id: '1',
      title: '視覚認知に関する実験',
      description: '画像を見て反応速度を測定する実験です',
      reward: 1500,
      location: 'オンライン',
      type: ExperimentType.online,
      isPaid: true,
      creatorId: 'demo_creator',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      experimentDate: DateTime.now().subtract(const Duration(days: 25)),
    ),
    Experiment(
      id: '2',
      title: '言語処理に関するアンケート調査',
      description: '日本語の文章理解に関するアンケートです',
      reward: 500,
      location: 'オンライン',
      type: ExperimentType.survey,
      isPaid: true,
      creatorId: 'demo_creator2',
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
      experimentDate: DateTime.now().subtract(const Duration(days: 40)),
    ),
    Experiment(
      id: '3',
      title: '心理学実験への参加者募集',
      description: '記憶と学習に関する対面実験です',
      reward: 2000,
      location: '早稲田キャンパス14号館',
      type: ExperimentType.onsite,
      isPaid: true,
      creatorId: 'demo_creator3',
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
      experimentDate: DateTime.now().subtract(const Duration(days: 55)),
    ),
  ];
  
  final List<Experiment> _demoCreatedExperiments = [
    Experiment(
      id: '4',
      title: 'VR空間での行動分析実験',
      description: 'VRヘッドセットを使用した空間認知実験です',
      reward: 3000,
      location: '理工学部51号館',
      type: ExperimentType.onsite,
      isPaid: true,
      creatorId: 'current_user',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      experimentDate: DateTime.now().add(const Duration(days: 5)),
    ),
    Experiment(
      id: '5',
      title: '消費者行動に関するオンライン調査',
      description: '購買意思決定プロセスに関する調査です',
      reward: 1000,
      location: 'オンライン',
      type: ExperimentType.online,
      isPaid: true,
      creatorId: 'current_user',
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      experimentDate: DateTime.now().subtract(const Duration(days: 15)),
    ),
  ];

  String _formatCurrency(int amount) {
    final formatter = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return formatter;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bioController.dispose();
    _departmentController.dispose();
    _gradeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = widget.authService.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('ユーザー情報を取得できませんでした'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('マイページ'),
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
            Tab(text: 'プロフィール'),
            Tab(text: '参加履歴'),
            Tab(text: '募集履歴'),
          ],
        ),
        actions: [
          if (!_isEditing && _tabController.index == 0)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: widget.onLogout,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // プロフィールタブ
          SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: const Color(0xFF8E1728),
                          child: Text(
                            currentUser.name[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 36,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          currentUser.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currentUser.email,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (currentUser.isWasedaUser)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  '早稲田大学',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Googleアカウント',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8E1728).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                '参加実験数: 5',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF8E1728),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // 統計情報カード（デモ用固定値）
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
                              Row(
                                children: [
                                  Icon(
                                    Icons.thumb_up,
                                    color: Colors.green[700],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    '評価統計',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
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
                                        size: 28,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '18',
                                        style: TextStyle(
                                          fontSize: 20,
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
                                        size: 28,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '2',
                                        style: TextStyle(
                                          fontSize: 20,
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
                                ],
                              ),
                              const SizedBox(height: 8),
                              Center(
                                child: Text(
                                  '評価率: 90.0%',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.payments,
                                    color: Colors.amber[700],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    '収益統計',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '総収益',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '¥${_formatCurrency(25000)}',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber[700],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    '今月の収益',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '¥${_formatCurrency(8500)}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'プロフィール情報',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_isEditing)
                              Row(
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _isEditing = false;
                                      });
                                    },
                                    child: const Text('キャンセル'),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        _isEditing = false;
                                      });
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('プロフィールを更新しました（デモ）'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    },
                                    child: const Text('保存'),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildProfileField(
                          label: '学部・学科',
                          controller: _departmentController,
                          isEditing: _isEditing,
                          hintText: '例: 政治経済学部',
                        ),
                        const SizedBox(height: 16),
                        _buildProfileField(
                          label: '学年',
                          controller: _gradeController,
                          isEditing: _isEditing,
                          hintText: '例: 3年',
                        ),
                        const SizedBox(height: 16),
                        _buildProfileField(
                          label: '自己紹介',
                          controller: _bioController,
                          isEditing: _isEditing,
                          hintText: '自己紹介を入力してください',
                          maxLines: 4,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (currentUser.canCreateExperiment)
                  Card(
                    elevation: 2,
                    color: const Color(0xFF8E1728).withValues(alpha: 0.1),
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.verified,
                            color: Color(0xFF8E1728),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '実験募集権限',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '早稲田大学のメールアドレスでログインしているため、実験を募集できます',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
          ),
          // 参加履歴タブ
          _buildExperimentHistoryTab(_demoParticipatedExperiments, '参加した実験'),
          // 募集履歴タブ
          _buildExperimentHistoryTab(_demoCreatedExperiments, '募集した実験'),
        ],
      ),
    );
  }

  Widget _buildExperimentHistoryTab(List<Experiment> experiments, String emptyMessage) {
    if (experiments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '$emptyMessageがありません',
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
      itemCount: experiments.length,
      itemBuilder: (context, index) {
        final experiment = experiments[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getTypeColor(experiment.type),
              child: Icon(
                _getTypeIcon(experiment.type),
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
                const SizedBox(height: 4),
                Text(
                  experiment.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      experiment.experimentDate != null
                        ? DateFormat('yyyy/MM/dd').format(experiment.experimentDate!)
                        : '日程未定',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.payments, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      experiment.isPaid ? '¥${experiment.reward}' : '無償',
                      style: TextStyle(
                        fontSize: 12,
                        color: experiment.isPaid ? Colors.green[700] : Colors.grey[600],
                        fontWeight: experiment.isPaid ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: experiment.type == ExperimentType.online
                    ? Colors.blue.withValues(alpha: 0.1)
                    : experiment.type == ExperimentType.onsite
                        ? Colors.orange.withValues(alpha: 0.1)
                        : Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                experiment.type.label,
                style: TextStyle(
                  fontSize: 12,
                  color: _getTypeColor(experiment.type),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
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

  IconData _getTypeIcon(ExperimentType type) {
    switch (type) {
      case ExperimentType.online:
        return Icons.computer;
      case ExperimentType.onsite:
        return Icons.place;
      case ExperimentType.survey:
        return Icons.assignment;
    }
  }

  Widget _buildProfileField({
    required String label,
    required TextEditingController controller,
    required bool isEditing,
    String? hintText,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        if (isEditing)
          TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hintText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              controller.text.isEmpty ? '未設定' : controller.text,
              style: TextStyle(
                fontSize: 16,
                color: controller.text.isEmpty ? Colors.grey : Colors.black,
              ),
            ),
          ),
      ],
    );
  }
}