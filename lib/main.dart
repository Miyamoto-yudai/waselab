import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
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

  // 並列で初期化処理を実行
  await Future.wait([
    // Firebaseの初期化
    Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ),
    // 日本語ロケールを初期化
    initializeDateFormatting('ja_JP', null),
  ]);

  // FCMサービスの初期化
  await FCMService().initialize();

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

class _AuthWrapperState extends State<AuthWrapper> {

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    // Firebase Authの認証状態を監視
    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // 接続待ちの場合はローディング表示
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('アプリを起動中...'),
                ],
              ),
            ),
          );
        }

        // エラーが発生した場合
        if (snapshot.hasError) {
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
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      // アプリを再起動（実際にはウィジェットの再構築）
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AuthWrapper(),
                        ),
                      );
                    },
                    child: const Text('再試行'),
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
          if (!user.emailVerified) {
            // メール未認証の場合は認証画面を表示
            return const EmailVerificationScreen();
          } else {
            // メール認証済みの場合はナビゲーション画面を表示
            return const NavigationScreen();
          }
        } else {
          // 未ログイン：ログイン画面を表示
          return const LoginScreen();
        }
      },
    );
  }
}