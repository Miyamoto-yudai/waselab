import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/experiment.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import 'experiment_detail_screen.dart';
import 'create_experiment_screen.dart';
import 'login_screen.dart';

/// ホーム画面（実験一覧画面）
/// Firestoreから実験データを取得して一覧表示する
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  AppUser? _currentUser;

  // フィルター用の変数
  ExperimentType? _selectedType = null;  // 選択された種別（null = すべて）
  bool? _isPaidFilter;

  @override
  void initState() {
    super.initState();
    // 遅延実行で起動を高速化
    Future.delayed(Duration.zero, () {
      _loadCurrentUser(); // 現在のユーザー情報を取得
      _createSampleData(); // 初回起動時にサンプルデータを作成
    });
  }

  /// 現在のユーザー情報を取得
  Future<void> _loadCurrentUser() async {
    try {
      final user = await _authService.getCurrentAppUser();
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    } catch (e) {
      debugPrint('ユーザー情報の取得エラー: $e');
    }
  }

  /// サンプルデータの作成（デモ用）
  Future<void> _createSampleData() async {
    try {
      final collection = _firestore.collection('experiments');
      
      // 既存のデータがあるか確認
      final snapshot = await collection.limit(1).get();
      if (snapshot.docs.isNotEmpty) return;

      // サンプルデータを追加
      final sampleExperiments = [
        {
          'title': '視覚認知実験への参加者募集',
          'description': '画面に表示される図形を見て、特定のパターンを見つける実験です。所要時間は約30分です。',
          'reward': 1500,
          'location': '早稲田大学 戸山キャンパス 33号館',
          'type': 'onsite',
          'isPaid': true,
          'creatorId': 'sample_user_1',
          'createdAt': FieldValue.serverTimestamp(),
          'experimentDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))),
          'endDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 14))),
          'labName': '認知科学研究室',
          'duration': 30,
          'maxParticipants': 20,
          'requirements': ['視力矯正後1.0以上', '色覚正常'],
        },
        {
          'title': 'オンラインアンケート調査',
          'description': '大学生の生活習慣に関するアンケート調査です。スマートフォンからも回答可能です。',
          'reward': 500,
          'location': 'オンライン（Zoomリンクを送付）',
          'type': 'survey',
          'isPaid': true,
          'creatorId': 'sample_user_2',
          'createdAt': FieldValue.serverTimestamp(),
          'experimentDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 3))),
          'endDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 10))),
          'labName': '社会心理学研究室',
          'duration': 15,
          'maxParticipants': 100,
          'requirements': ['早稲田大学の学部生'],
        },
        {
          'title': '心理学実験の被験者募集（無償）',
          'description': '簡単な認知課題を行っていただきます。研究室の卒業論文のデータ収集にご協力ください。',
          'reward': 0,
          'location': '早稲田大学 西早稲田キャンパス 51号館',
          'type': 'onsite',
          'isPaid': false,
          'creatorId': 'sample_user_3',
          'createdAt': FieldValue.serverTimestamp(),
          'experimentDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 5))),
          'endDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 12))),
          'labName': '実験心理学研究室',
          'duration': 45,
          'maxParticipants': 15,
          'requirements': ['日本語ネイティブスピーカー'],
        },
      ];

      // バッチ書き込み
      final batch = _firestore.batch();
      for (final data in sampleExperiments) {
        final docRef = collection.doc();
        batch.set(docRef, data);
      }
      await batch.commit();
      
      debugPrint('サンプルデータを作成しました');
    } catch (e) {
      debugPrint('サンプルデータの作成に失敗: $e');
    }
  }

  /// ログアウト処理
  Future<void> _handleLogout() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('わせラボ'),
        actions: [
          // ユーザー情報表示
          if (_currentUser != null) ...[   
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Row(
                  children: [
                    if (_currentUser!.isWasedaUser)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '早稲田',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Text(
                      _currentUser!.name.split(' ')[0], // 名前の最初の部分のみ表示
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      // 実験作成ボタン（Googleユーザーには無効化して表示）
      floatingActionButton: _currentUser != null
          ? SizedBox(
              height: 64,
              child: FloatingActionButton.extended(
                onPressed: (_currentUser?.canCreateExperiment ?? false)
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CreateExperimentScreen(),
                          ),
                        );
                      }
                    : () {
                        // Googleログインユーザー向けのメッセージ
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('実験募集は早稲田大学のメールアカウントでログインした方のみご利用いただけます'),
                            backgroundColor: Colors.orange,
                            duration: Duration(seconds: 3),
                          ),
                        );
                      },
                icon: Icon(
                  Icons.add,
                  size: 24,
                  color: (_currentUser?.canCreateExperiment ?? false)
                      ? Colors.white
                      : Colors.white70,
                ),
                label: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '実験を募集',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: (_currentUser?.canCreateExperiment ?? false)
                            ? Colors.white
                            : Colors.white70,
                      ),
                    ),
                    if (!(_currentUser?.canCreateExperiment ?? false))
                      const Text(
                        '早稲田メール限定',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white70,
                        ),
                      ),
                  ],
                ),
                backgroundColor: (_currentUser?.canCreateExperiment ?? false)
                    ? const Color(0xFF8E1728)
                    : Colors.grey,
                elevation: (_currentUser?.canCreateExperiment ?? false) ? 6 : 2,
              ),
            )
          : null,
      body: Column(
        children: [
          // 種別切り替えボタン（常に表示）
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF8E1728),
                  const Color(0xFF7F3143),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8E1728).withValues(alpha: 0.3),
                  spreadRadius: 0,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // すべてボタン
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Material(
                        color: _selectedType == null 
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          onTap: () => setState(() => _selectedType = null),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            child: Text(
                              'すべて',
                              style: TextStyle(
                                fontWeight: _selectedType == null ? FontWeight.bold : FontWeight.w500,
                                color: _selectedType == null 
                                  ? const Color(0xFF8E1728)
                                  : Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // 各種別ボタン
                    ...ExperimentType.values.map((type) {
                      final isSelected = _selectedType == type;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Material(
                          color: isSelected 
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            onTap: () => setState(() {
                              _selectedType = isSelected ? null : type;
                            }),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getTypeIcon(type),
                                    size: 18,
                                    color: isSelected 
                                      ? const Color(0xFF8E1728)
                                      : Colors.white,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    type.label,
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      color: isSelected 
                                        ? const Color(0xFF8E1728)
                                        : Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
          
          // 有償/無償フィルター表示
          if (_isPaidFilter != null)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey[200],
              child: Row(
                children: [
                  const Text('フィルター: '),
                  Chip(
                    label: Text(_isPaidFilter! ? '有償' : '無償'),
                    onDeleted: () => setState(() => _isPaidFilter = null),
                  ),
                ],
              ),
            ),
          
          // 実験リスト
          Expanded(
            child: Container(
              color: const Color(0xFFF5F5F5),
              child: StreamBuilder<QuerySnapshot>(
                stream: _buildQuery().limit(20).snapshots(), // 最初は20件のみ取得
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('エラーが発生しました: ${snapshot.error}'),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          const Color(0xFF8E1728),
                        ),
                      ),
                    );
                  }

                  final experiments = snapshot.data!.docs
                      .map((doc) => Experiment.fromFirestore(doc))
                      .toList();

                  if (experiments.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.science_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '実験がありません',
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    itemCount: experiments.length,
                    itemBuilder: (context, index) {
                      final experiment = experiments[index];
                      return _buildExperimentCard(experiment);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// クエリの構築（フィルター適用）
  Query<Map<String, dynamic>> _buildQuery() {
    Query<Map<String, dynamic>> query = _firestore.collection('experiments')
        .orderBy('createdAt', descending: true);

    if (_selectedType != null) {
      query = query.where('type', isEqualTo: _selectedType!.name);
    }

    if (_isPaidFilter != null) {
      query = query.where('isPaid', isEqualTo: _isPaidFilter);
    }

    return query;
  }

  /// 実験カードのウィジェット
  Widget _buildExperimentCard(Experiment experiment) {
    // 締切までの残り日数を計算
    final daysLeft = experiment.endDate != null 
      ? experiment.endDate!.difference(DateTime.now()).inDays 
      : null;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
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
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 上部: 報酬・締切タグ
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 締切表示
                  if (daysLeft != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                    )
                  else
                    const SizedBox(),
                  // 報酬表示
                  if (experiment.isPaid) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF8E1728),
                            const Color(0xFF7F3143),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8E1728).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '¥${experiment.reward.toString().replaceAllMapped(
                          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                          (Match m) => '${m[1]},')
                        }',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '無償',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              
              const SizedBox(height: 14),
              
              // タイトルと研究室名
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    experiment.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2C2C2C),
                      height: 1.3,
                    ),
                  ),
                  if (experiment.labName != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8E1728).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.school,
                            size: 18,
                            color: Color(0xFF8E1728),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            experiment.labName!,
                            style: const TextStyle(
                              fontSize: 15,
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
              
              const SizedBox(height: 12),
              
              // 説明文
              Text(
                experiment.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[700],
                  height: 1.5,
                  letterSpacing: 0.2,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // 情報グリッド
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F9F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.grey.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    // 種別
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            _getTypeIcon(experiment.type),
                            size: 20,
                            color: _getTypeColor(experiment.type),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            experiment.type.label,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _getTypeColor(experiment.type),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 所要時間
                    if (experiment.duration != null) ...[
                      Container(
                        width: 1,
                        height: 24,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(width: 14),
                      Icon(Icons.timer_outlined, size: 20, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Text(
                        '${experiment.duration}分',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(width: 14),
                    ],
                    // 参加者数
                    if (experiment.maxParticipants != null) ...[
                      Container(
                        width: 1,
                        height: 24,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(width: 14),
                      Icon(Icons.group_outlined, size: 20, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Text(
                        '募集${experiment.maxParticipants}名',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 10),
              
              // 場所情報
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                    Icon(Icons.location_on_outlined, size: 18, color: Colors.blue[700]),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        experiment.location,
                        style: TextStyle(
                          fontSize: 14,
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
    );
  }

}