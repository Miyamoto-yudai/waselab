import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/experiment_service.dart';
import '../models/app_user.dart';
import '../models/experiment.dart';
import 'login_screen.dart';
import 'experiment_detail_screen.dart';
import 'experiment_evaluation_screen.dart';
import 'experiment_management_screen.dart';
import 'package:intl/intl.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final ExperimentService _experimentService = ExperimentService();
  AppUser? _currentUser;
  bool _isLoading = true;
  bool _isEditing = false;
  late TabController _tabController;
  List<Experiment> _participatedExperiments = [];
  List<Experiment> _createdExperiments = [];
  List<Experiment> _pendingEvaluations = [];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _gradeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
    
    // タブ切り替え時にデータを再読み込み
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _loadUserData();
      }
    });
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 画面に戻ってきた時にデータを再読み込み
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      var user = await _authService.getCurrentAppUser();
      if (user != null) {
        // scheduledExperimentsフィールドが存在しない場合は初期化
        await _userService.initializeScheduledExperimentsField(user.uid);
        
        // 初期化後、最新のユーザー情報を再取得
        user = await _authService.getCurrentAppUser();
        
        if (user != null) {
          // 実験履歴を取得
          final participated = await _experimentService.getUserParticipatedExperiments(user.uid);
          final created = await _experimentService.getUserCreatedExperiments(user.uid);
          final pendingEvals = await _experimentService.getPendingEvaluations(user.uid);
          
          if (mounted) {
            setState(() {
              _currentUser = user;
              _nameController.text = user?.name ?? '';
              _bioController.text = user?.bio ?? '';
              _departmentController.text = user?.department ?? '';
              _gradeController.text = user?.grade ?? '';
              _participatedExperiments = participated;
              _createdExperiments = created;
              _pendingEvaluations = pendingEvals;
              _isLoading = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('ユーザー情報の取得エラー: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _userService.updateUserProfile(
        userId: _currentUser!.uid,
        name: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        department: _departmentController.text.trim(),
        grade: _gradeController.text.trim(),
      );

      await _loadUserData();
      
      if (mounted) {
        setState(() {
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('プロフィールを更新しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('更新に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  String _formatCurrency(int amount) {
    final formatter = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return formatter;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8E1728)),
          ),
        ),
      );
    }

    if (_currentUser == null) {
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
          tabs: [
            const Tab(text: 'プロフィール'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('参加履歴'),
                  if (_pendingEvaluations.length > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_pendingEvaluations.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: '募集履歴'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
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
                          backgroundImage: _currentUser!.photoUrl != null
                              ? NetworkImage(_currentUser!.photoUrl!)
                              : null,
                          child: _currentUser!.photoUrl == null
                              ? Text(
                                  _currentUser!.name[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 36,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: 16),
                        if (_isEditing)
                          Column(
                            children: [
                              SizedBox(
                                width: 200,
                                child: TextField(
                                  controller: _nameController,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '名前を入力',
                                    border: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                    focusedBorder: const UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Color(0xFF8E1728),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TextButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _isEditing = false;
                                        _nameController.text = _currentUser?.name ?? '';
                                        _bioController.text = _currentUser?.bio ?? '';
                                        _departmentController.text = _currentUser?.department ?? '';
                                        _gradeController.text = _currentUser?.grade ?? '';
                                      });
                                    },
                                    icon: const Icon(Icons.close, size: 16),
                                    label: const Text('キャンセル'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton.icon(
                                    onPressed: _saveProfile,
                                    icon: const Icon(Icons.check, size: 16),
                                    label: const Text('保存'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF8E1728),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        else
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _currentUser!.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                color: const Color(0xFF8E1728),
                                tooltip: '名前を編集',
                                onPressed: () {
                                  setState(() {
                                    _isEditing = true;
                                  });
                                },
                              ),
                            ],
                          ),
                        const SizedBox(height: 8),
                        Text(
                          _currentUser!.email,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_currentUser!.isWasedaUser)
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
                              child: Text(
                                '完了実験数: ${_currentUser!.participatedExperiments}',
                                style: const TextStyle(
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
                const SizedBox(height: 16),
                // あなたの活動セクション
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'あなたの活動',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildActivityCard(
                                icon: Icons.campaign,
                                title: '募集中',
                                count: _createdExperiments.where((e) => 
                                  e.recruitmentEndDate != null && 
                                  e.recruitmentEndDate!.isAfter(DateTime.now())
                                ).length,
                                color: const Color(0xFF8E1728),
                                onTap: () {
                                  _tabController.animateTo(2);
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildActivityCard(
                                icon: Icons.science,
                                title: '参加予定',
                                count: _currentUser?.scheduledExperiments ?? 0,
                                color: Colors.blue,
                                onTap: () {
                                  _tabController.animateTo(1);
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // 統計情報カード
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
                                        '${_currentUser!.goodCount}',
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
                                        '${_currentUser!.badCount}',
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
                              if (_currentUser!.goodCount + _currentUser!.badCount > 0)
                                Center(
                                  child: Text(
                                    '評価率: ${((_currentUser!.goodCount / (_currentUser!.goodCount + _currentUser!.badCount)) * 100).toStringAsFixed(1)}%',
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
                                    '¥${_formatCurrency(_currentUser!.totalEarnings)}',
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
                                    '¥${_formatCurrency(_currentUser!.monthlyEarnings)}',
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
                            Row(
                              children: [
                                const Text(
                                  'プロフィール情報',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (!_isEditing)
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 18),
                                    color: const Color(0xFF8E1728),
                                    tooltip: '編集',
                                    onPressed: () {
                                      setState(() {
                                        _isEditing = true;
                                      });
                                    },
                                  ),
                              ],
                            ),
                            if (_isEditing)
                              Row(
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _isEditing = false;
                                        _nameController.text = _currentUser?.name ?? '';
                                        _bioController.text = _currentUser?.bio ?? '';
                                        _departmentController.text = _currentUser?.department ?? '';
                                        _gradeController.text = _currentUser?.grade ?? '';
                                      });
                                    },
                                    child: const Text('キャンセル'),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: _saveProfile,
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
                if (_currentUser!.canCreateExperiment)
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
          _buildParticipatedExperimentsTab(),
          // 募集履歴タブ
          _buildExperimentHistoryTab(_createdExperiments, '募集した実験'),
        ],
      ),
    );
  }

  Widget _buildParticipatedExperimentsTab() {
    // 実験を3つのカテゴリに分類
    final scheduledExperiments = <Experiment>[];
    final waitingEvaluationExperiments = <Experiment>[];
    final completedExperiments = <Experiment>[];
    
    debugPrint('Total participated experiments: ${_participatedExperiments.length}');
    
    for (final experiment in _participatedExperiments) {
      debugPrint('Experiment ${experiment.id}: status=${experiment.status.name}');
      
      // 個別の評価状態をチェック
      final participantEvals = experiment.participantEvaluations ?? {};
      final myEval = participantEvals[_currentUser?.uid] ?? {};
      final mutuallyCompleted = myEval['mutuallyCompleted'] ?? false;
      
      if (mutuallyCompleted) {
        // この参加者との相互評価が完了
        completedExperiments.add(experiment);
      } else if (experiment.hasEvaluated(_currentUser?.uid ?? '') || 
                 experiment.canEvaluate(_currentUser?.uid ?? '')) {
        // 評価待ちまたは評価可能
        waitingEvaluationExperiments.add(experiment);
      } else {
        // まだ実験を実施していない
        scheduledExperiments.add(experiment);
      }
    }
    
    debugPrint('Scheduled: ${scheduledExperiments.length}, Waiting: ${waitingEvaluationExperiments.length}, Completed: ${completedExperiments.length}');
    
    if (_participatedExperiments.isEmpty) {
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
              '参加した実験がありません',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 参加予定セクション
        if (scheduledExperiments.isNotEmpty) ...[
          _buildSectionHeader('参加予定', Icons.schedule, Colors.blue),
          ...scheduledExperiments.map((e) => _buildExperimentCard(e)),
          const SizedBox(height: 16),
        ],
        
        // 評価待ちセクション
        if (waitingEvaluationExperiments.isNotEmpty) ...[
          _buildSectionHeader('評価待ち', Icons.rate_review, Colors.orange),
          ...waitingEvaluationExperiments.map((e) => _buildExperimentCard(e)),
          const SizedBox(height: 16),
        ],
        
        // 完了済みセクション
        if (completedExperiments.isNotEmpty) ...[
          _buildSectionHeader('完了済み', Icons.check_circle, Colors.green),
          ...completedExperiments.map((e) => _buildExperimentCard(e)),
        ],
      ],
    );
  }
  
  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  /// アンケートURL表示ダイアログ
  Future<void> _showSurveyUrlDialog(Experiment experiment) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.assignment, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                experiment.title,
                style: const TextStyle(fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (experiment.surveyUrl != null) ...[
              const Text('アンケートURL:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      experiment.surveyUrl!,
                      style: const TextStyle(fontSize: 14, color: Colors.blue),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: experiment.surveyUrl!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('URLをコピーしました'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy, size: 16),
                            label: const Text('コピー'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final url = Uri.parse(experiment.surveyUrl!);
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url, mode: LaunchMode.externalApplication);
                              }
                            },
                            icon: const Icon(Icons.open_in_new, size: 16),
                            label: const Text('開く'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8E1728),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.amber),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'まだ回答していない場合は、URLから回答してください',
                        style: TextStyle(fontSize: 12, color: Colors.amber),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.chat, size: 20, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'アンケートURL未設定',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '実験者から個別チャットでアンケートの詳細が送られます',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.amber),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'アンケートの詳細は実験者にお問い合わせください',
                        style: TextStyle(fontSize: 12, color: Colors.amber),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  Widget _buildExperimentCard(Experiment experiment) {
    final isMyExperiment = experiment.creatorId == _currentUser?.uid;
    final isParticipant = experiment.participants.contains(_currentUser?.uid ?? '');
    final hasEvaluated = experiment.hasEvaluated(_currentUser?.uid ?? '');
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // カード全体のタップは常に詳細画面へ
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ExperimentDetailScreen(
                experiment: experiment,
                isMyExperiment: isMyExperiment,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: _getTypeColor(experiment.type),
                child: Icon(
                  _getTypeIcon(experiment.type),
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  experiment.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // アンケートアイコン（参加者でアンケートタイプの場合）
                              if (experiment.type == ExperimentType.survey && 
                                  isParticipant && 
                                  !isMyExperiment) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    experiment.surveyUrl != null ? Icons.link : Icons.chat,
                                    size: 16,
                                    color: Colors.purple,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      experiment.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (experiment.isPaid) ...[
                          Icon(Icons.monetization_on, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '¥${experiment.reward}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (experiment.location.isNotEmpty) ...[
                          Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              experiment.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // アクションボタンエリア
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // 未評価の場合は評価ボタン
                  if (!hasEvaluated && experiment.canEvaluate(_currentUser?.uid ?? '')) 
                    Container(
                      margin: const EdgeInsets.only(right: 4, bottom: 4),
                      child: Material(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(20),
                        elevation: 2,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ExperimentEvaluationScreen(
                                  experiment: experiment,
                                ),
                              ),
                            ).then((result) {
                              if (result == true) {
                                _loadUserData();
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.star,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '評価する',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  // アンケートURL確認ボタン
                  if (experiment.type == ExperimentType.survey && 
                      isParticipant && 
                      !isMyExperiment)
                    Container(
                      margin: const EdgeInsets.only(right: 4),
                      child: Material(
                        color: Colors.purple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          onTap: () {
                            _showSurveyUrlDialog(experiment);
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  experiment.surveyUrl != null ? Icons.link : Icons.chat_bubble_outline,
                                  color: Colors.purple,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  experiment.surveyUrl != null ? 'URL' : '詳細',
                                  style: const TextStyle(
                                    color: Colors.purple,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
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
        final isMyExperiment = experiment.creatorId == _currentUser?.uid;
        
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              // 自分が作成した実験で募集中または進行中の場合は管理画面へ
              if (isMyExperiment && 
                  (experiment.status == ExperimentStatus.recruiting || 
                   experiment.status == ExperimentStatus.ongoing)) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ExperimentManagementScreen(
                      experiment: experiment,
                    ),
                  ),
                ).then((_) {
                  // 管理画面から戻ってきた時にデータを再読み込み
                  _loadUserData();
                });
              } 
              // 評価待ちの場合は評価画面へ
              else if (experiment.status == ExperimentStatus.waitingEvaluation &&
                  !experiment.hasEvaluated(_currentUser?.uid ?? '')) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ExperimentEvaluationScreen(
                      experiment: experiment,
                    ),
                  ),
                ).then((result) {
                  // 評価完了後にデータを再読み込み
                  if (result == true) {
                    _loadUserData();
                  }
                });
              } 
              // それ以外は詳細画面へ
              else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ExperimentDetailScreen(
                      experiment: experiment,
                      isMyExperiment: isMyExperiment,
                    ),
                  ),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _getTypeColor(experiment.type),
                    child: Icon(
                      _getTypeIcon(experiment.type),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                experiment.title,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            // ステータスバッジを表示
                            _buildStatusBadge(experiment, isMyExperiment),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          experiment.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
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
                            if (isMyExperiment) ...[
                              const SizedBox(width: 16),
                              Icon(Icons.people, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                '参加者: ${experiment.participants?.length ?? 0}名',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    children: [
                      Container(
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
                      if (isMyExperiment && 
                          (experiment.status == ExperimentStatus.recruiting || 
                           experiment.status == ExperimentStatus.ongoing)) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8E1728).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.settings,
                            size: 16,
                            color: Color(0xFF8E1728),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(Experiment experiment, bool isMyExperiment) {
    final hasEvaluated = experiment.hasEvaluated(_currentUser?.uid ?? '');
    
    // 未評価の場合（ステータスに関わらず）
    if (!hasEvaluated && experiment.canEvaluate(_currentUser?.uid ?? '')) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          '評価可能',
          style: TextStyle(
            fontSize: 11,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    
    // 評価済みだが相手がまだの場合
    if (hasEvaluated && experiment.status == ExperimentStatus.waitingEvaluation) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          '相手の評価待ち',
          style: TextStyle(
            fontSize: 11,
            color: Colors.blue,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    
    // 完了済みの場合
    if (experiment.status == ExperimentStatus.completed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          '完了',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    
    // 進行中の場合
    if (experiment.status == ExperimentStatus.ongoing) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          '進行中',
          style: TextStyle(
            fontSize: 11,
            color: Colors.blue,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    
    // 募集中の場合（デフォルト）
    if (isMyExperiment) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF8E1728).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          '募集中',
          style: TextStyle(
            fontSize: 11,
            color: Color(0xFF8E1728),
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    
    return const SizedBox.shrink();
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

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _bioController.dispose();
    _departmentController.dispose();
    _gradeController.dispose();
    super.dispose();
  }

  Widget _buildActivityCard({
    required IconData icon,
    required String title,
    required int count,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}