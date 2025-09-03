import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
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
  
  // アプリを先に起動（ローディング画面を表示）
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
  bool _isInitialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    try {
      // Firebaseが既に初期化されているか確認
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Firebase初期化中
    if (!_isInitialized && _error == null) {
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
    if (_error != null) {
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
                _error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                  });
                  _initializeFirebase();
                },
                child: const Text('再試行'),
              ),
            ],
          ),
        ),
      );
    }
    
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