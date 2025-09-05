import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/experiment.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/message_service.dart';
import '../utils/test_firestore.dart';
import '../widgets/home_screen_base.dart';
import 'create_experiment_screen.dart';
import 'login_screen.dart';
import 'my_page_screen.dart';
import 'messages_screen.dart';
import 'settings_screen.dart';

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
  final MessageService _messageService = MessageService();
  AppUser? _currentUser;
  List<Experiment> _experiments = [];
  bool _isLoading = true;
  int _unreadMessages = 0;

  @override
  void initState() {
    super.initState();
    // 遅延実行で起動を高速化
    Future.delayed(Duration.zero, () async {
      _loadCurrentUser();
      _loadUnreadMessages();
      
      // デバッグ用：Firestoreの状態を確認
      if (!kReleaseMode) {
        await TestFirestore.checkExperiments();
      }
      
      _loadExperiments();
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
      debugPrint('実験データ取得開始...');
      
      // まず、シンプルなクエリで試す（orderByなし）
      QuerySnapshot snapshot;
      try {
        // orderByを使用したクエリを試す
        snapshot = await _firestore
            .collection('experiments')
            .orderBy('createdAt', descending: true)
            .limit(50)
            .get();
        debugPrint('orderByクエリ成功: ${snapshot.docs.length}件');
      } catch (orderByError) {
        debugPrint('orderByクエリ失敗: $orderByError');
        debugPrint('インデックスなしでクエリを実行します...');
        
        // orderByなしで全データ取得
        snapshot = await _firestore
            .collection('experiments')
            .limit(50)
            .get();
        debugPrint('シンプルクエリ成功: ${snapshot.docs.length}件');
      }
      
      debugPrint('実験データ取得完了: ${snapshot.docs.length}件');
      
      if (mounted) {
        setState(() {
          _experiments = snapshot.docs
              .map((doc) {
                try {
                  final exp = Experiment.fromFirestore(doc);
                  debugPrint('実験解析成功: ${exp.title}');
                  debugPrint('  - ID: ${exp.id}');
                  debugPrint('  - status: ${exp.status.name}');
                  debugPrint('  - creatorId: ${exp.creatorId}');
                  debugPrint('  - recruitmentStartDate: ${exp.recruitmentStartDate}');
                  debugPrint('  - recruitmentEndDate: ${exp.recruitmentEndDate}');
                  return exp;
                } catch (parseError) {
                  debugPrint('実験データ解析エラー (doc.id: ${doc.id}): $parseError');
                  debugPrint('データ内容: ${doc.data()}');
                  return null;
                }
              })
              .where((exp) => exp != null)
              .cast<Experiment>()
              .toList();
          _isLoading = false;
        });
        
        debugPrint('最終的に解析された実験数: ${_experiments.length}');
        
        // createdAtがないデータはソート
        _experiments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
    } catch (e) {
      debugPrint('実験データの取得エラー: $e');
      debugPrint('エラースタックトレース: ${StackTrace.current}');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _experiments = [];
        });
        
        // エラーをユーザーに表示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('実験データの取得に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

  /// 未読メッセージ数を取得
  Future<void> _loadUnreadMessages() async {
    final user = _authService.currentUser;
    if (user != null) {
      final count = await _messageService.getUnreadMessageCount(user.uid);
      if (mounted) {
        setState(() {
          _unreadMessages = count;
        });
      }
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

  /// マイページへ遷移（NavigationScreenを使用している場合は変更が必要）
  void _navigateToMyPage() {
    // NavigationScreenを使用している場合はこの実装を変更する必要があります
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MyPageScreen(),
      ),
    );
  }

  /// メッセージ画面へ遷移（NavigationScreenを使用している場合は変更が必要）
  void _navigateToMessages() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MessagesScreen(),
      ),
    ).then((_) {
      // メッセージ画面から戻ってきたら未読数を再取得
      _loadUnreadMessages();
    });
  }

  /// 設定画面へ遷移
  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
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
      currentUserId: _currentUser?.uid,
      unreadMessages: _unreadMessages,
      onNavigateToMyPage: _navigateToMyPage,
      onNavigateToMessages: _navigateToMessages,
      onNavigateToSettings: _navigateToSettings,
    );
  }
}