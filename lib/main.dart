import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/auth_persistence_service.dart';
import 'services/fcm_service.dart';
import 'screens/login_screen.dart';
import 'screens/navigation_screen.dart';
import 'screens/email_verification_screen.dart';
import 'shared/app_wrapper.dart';

/// アプリのエントリーポイント
/// Firebaseの初期化を行ってからアプリを起動する
///
/// 重要: 共通コンポーネントはshared/フォルダに配置されています
/// main.dartとmain_demo.dartで共有される部分は必ずshared/に配置してください
void main() async {
  // Flutter Engineの初期化を確実に行う
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('[main.dart] ========= APP START =========');
  debugPrint('[main.dart] Starting at: ${DateTime.now().toIso8601String()}');
  debugPrint('[main.dart] Platform: ${defaultTargetPlatform.name}');
  debugPrint('[main.dart] Initializing Firebase...');

  // Firebaseの初期化を最優先で実行
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  debugPrint('[main.dart] Firebase initialized at: ${DateTime.now().toIso8601String()}');

  // 自動再ログインをメインの認証復元メカニズムとして使用
  debugPrint('[main.dart] ========= AUTO RE-LOGIN MAIN MODE =========');
  debugPrint('[main.dart] Using auto re-login as primary auth restoration method');
  debugPrint('[main.dart] Firebase Auth native restoration will be ignored');

  // 即座に自動再ログインを試みる（待機時間なし）
  debugPrint('[main.dart] Attempting immediate auto re-login...');

  try {
    final restored = await AuthPersistenceService().restoreAuthState();

    if (restored) {
      final userAfterRestore = FirebaseAuth.instance.currentUser;
      debugPrint('[main.dart] ✅ User successfully restored via auto re-login: ${userAfterRestore?.uid} (${userAfterRestore?.email})');
      debugPrint('[main.dart] Email verified: ${userAfterRestore?.emailVerified}');

      // ユーザー情報を最新に更新
      if (userAfterRestore != null) {
        try {
          await userAfterRestore.reload();
          final reloadedUser = FirebaseAuth.instance.currentUser;
          debugPrint('[main.dart] User state after reload: ${reloadedUser?.uid} (emailVerified: ${reloadedUser?.emailVerified})');
        } catch (e) {
          debugPrint('[main.dart] User reload failed (non-critical): $e');
        }
      }
    } else {
      debugPrint('[main.dart] No saved credentials found - user needs to log in');
      debugPrint('[main.dart] This is expected for: first launch, after logout, or Google login users');
    }
  } catch (e) {
    debugPrint('[main.dart] Auto re-login error: $e');
    debugPrint('[main.dart] User will need to log in manually');
  }

  debugPrint('[main.dart] =============================================');

  // その他の初期化処理を並列実行
  await Future.wait([
    // 日本語ロケールを初期化
    initializeDateFormatting('ja_JP', null),
    // FCMサービスの初期化
    FCMService().initialize(),
  ]);

  debugPrint('[main.dart] All initialization completed');
  debugPrint('[main.dart] Final user state: ${FirebaseAuth.instance.currentUser?.uid} (${FirebaseAuth.instance.currentUser?.email})');
  final startupDuration = DateTime.now().difference(DateTime.parse(DateTime.now().toIso8601String().split('T')[0] + 'T00:00:00'));
  debugPrint('[main.dart] Total startup time: $startupDuration');

  // 初期化完了後にアプリを起動
  runApp(const WaseLaboApp(
    home: AuthWrapper(),
    isDemo: false,
  ));
}

/// 認証状態に応じて表示する画面を切り替えるラッパー
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> with WidgetsBindingObserver {
  final authService = AuthService();
  final bool _isCheckingAuth = false; // 自動再ログインがメインなので初期チェック不要
  User? _initialUser;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 自動再ログインがメインなので、即座に現在のユーザーを使用
    _initialUser = FirebaseAuth.instance.currentUser;
    debugPrint('[AuthWrapper] Initial user from auto re-login: ${_initialUser?.uid}');
    _setupAuthStateMonitoring();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('[AuthWrapper] App lifecycle state changed: $state');
    if (state == AppLifecycleState.resumed) {
      // アプリがフォアグラウンドに戻ったとき
      final currentUser = FirebaseAuth.instance.currentUser;
      debugPrint('[AuthWrapper] App resumed - current user: ${currentUser?.uid}');
    }
  }

  void _setupAuthStateMonitoring() {
    // authStateChangesを監視してデバッグログを出力
    FirebaseAuth.instance.authStateChanges().listen(
      (User? user) {
        debugPrint('[AuthWrapper Monitor] Auth state changed: ${user?.uid} (${user?.email}) at ${DateTime.now().toIso8601String()}');
      },
      onError: (error) {
        debugPrint('[AuthWrapper Monitor] Auth state error: $error');
      },
    );

    // userChangesも監視（より詳細な変更を検知）
    FirebaseAuth.instance.userChanges().listen(
      (User? user) {
        debugPrint('[AuthWrapper Monitor] User changed: ${user?.uid} (emailVerified: ${user?.emailVerified}) at ${DateTime.now().toIso8601String()}');
      },
      onError: (error) {
        debugPrint('[AuthWrapper Monitor] User change error: $error');
      },
    );
  }

  // 削除: 自動再ログインがメインなので不要

  @override
  Widget build(BuildContext context) {
    // 初期認証チェック中
    if (_isCheckingAuth) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('認証状態を確認中...'),
            ],
          ),
        ),
      );
    }

    // Firebase Authの認証状態を監視（userChangesを使用してより詳細な変更を検知）
    return StreamBuilder<User?>(
      stream: authService.userChanges,
      initialData: _initialUser, // 初期値として復元したユーザーを設定
      builder: (context, snapshot) {
        debugPrint('[AuthWrapper StreamBuilder] Connection: ${snapshot.connectionState}');
        debugPrint('[AuthWrapper StreamBuilder] Has data: ${snapshot.hasData}');
        debugPrint('[AuthWrapper StreamBuilder] User: ${snapshot.data?.uid} (${snapshot.data?.email})');

        // 接続待ちの場合はローディング表示
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // エラーが発生した場合
        if (snapshot.hasError) {
          debugPrint('[AuthWrapper StreamBuilder] Error: ${snapshot.error}');
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'エラーが発生しました',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        // 認証状態に応じて画面を表示
        if (snapshot.hasData && snapshot.data != null) {
          // ログイン済み
          final user = snapshot.data!;
          debugPrint('[AuthWrapper] User logged in: ${user.uid} (Verified: ${user.emailVerified})');

          if (!user.emailVerified) {
            // メール未認証の場合は認証画面を表示
            return const EmailVerificationScreen();
          } else {
            // メール認証済みの場合はナビゲーション画面を表示
            return const NavigationScreen();
          }
        } else {
          // 未ログイン：ログイン画面を表示
          debugPrint('[AuthWrapper] No user - showing login screen');
          return const LoginScreen();
        }
      },
    );
  }
}