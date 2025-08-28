import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

/// アプリのエントリーポイント
/// Firebaseの初期化を行ってからアプリを起動する
void main() async {
  // Flutter Engineの初期化を確実に行う
  WidgetsFlutterBinding.ensureInitialized();
  
  // アプリを先に起動（ローディング画面を表示）
  runApp(const MyApp());
}

/// アプリのルートウィジェット
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'わせラボ',
      debugShowCheckedModeBanner: false, // デバッグバナーを非表示
      theme: ThemeData(
        // 早稲田大学のえんじ色をベースにしたテーマカラー
        primaryColor: const Color(0xFF8E1728), // 早稲田えんじ色 RGB(142, 23, 40)
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8E1728), // 早稲田えんじ色
          primary: const Color(0xFF8E1728),
          secondary: const Color(0xFF7F3143), // やや明るいえんじ色 RGB(127, 49, 67)
          surface: const Color(0xFFFAFAFA),
          error: Colors.red[700]!,
        ),
        useMaterial3: true, // Material Design 3を使用
        
        // AppBarのテーマを設定
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 3,
          backgroundColor: Color(0xFF8E1728),
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        // ElevatedButtonのテーマを設定
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8E1728),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        
        // FloatingActionButtonのテーマ
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF8E1728),
          foregroundColor: Colors.white,
          elevation: 6,
        ),
      ),
      home: const AuthWrapper(), // 認証状態に応じて画面を切り替え
    );
  }
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
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
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
          // ログイン済み：ホーム画面を表示
          return const HomeScreen();
        } else {
          // 未ログイン：ログイン画面を表示
          return const LoginScreen();
        }
      },
    );
  }
}