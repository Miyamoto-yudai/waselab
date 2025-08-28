import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/experiment.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../widgets/home_screen_base.dart';
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
  List<Experiment> _experiments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // 遅延実行で起動を高速化
    Future.delayed(Duration.zero, () {
      _loadCurrentUser();
      _loadExperiments();
      _createSampleData();
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

  /// 実験データを読み込み
  Future<void> _loadExperiments() async {
    try {
      final snapshot = await _firestore
          .collection('experiments')
          .orderBy('createdAt', descending: true)
          .limit(30)
          .get();
      
      if (mounted) {
        setState(() {
          _experiments = snapshot.docs
              .map((doc) => Experiment.fromFirestore(doc))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('実験データの取得エラー: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
      // サンプルデータ作成後、再読み込み
      _loadExperiments();
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

  /// 実験作成画面へ遷移
  void _navigateToCreateExperiment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateExperimentScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              const Color(0xFF8E1728),
            ),
          ),
        ),
      );
    }

    return HomeScreenBase(
      title: 'わせラボ',
      experiments: _experiments,
      canCreateExperiment: _currentUser?.canCreateExperiment ?? false,
      userName: _currentUser?.name,
      isWasedaUser: _currentUser?.isWasedaUser ?? false,
      onLogout: _handleLogout,
      onCreateExperiment: _navigateToCreateExperiment,
    );
  }
}