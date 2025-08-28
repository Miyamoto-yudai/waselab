import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'screens/login_screen_demo.dart';
import 'screens/home_screen_demo.dart';
import 'services/demo_auth_service.dart';

/// デモモード用のエントリーポイント
/// Firebaseを使わずにアプリをテストできる（高速起動版）
void main() {
  // リリースモードではデバッグツールを無効化して高速化
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }
  
  runApp(const MyApp());
}

/// アプリのルートウィジェット
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'わせラボ',
      debugShowCheckedModeBanner: false,
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
        useMaterial3: true,
        // アニメーションを高速化
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          },
        ),
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
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF8E1728),
          foregroundColor: Colors.white,
          elevation: 6,
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

/// 認証状態に応じて表示する画面を切り替えるラッパー（デモ版）
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final DemoAuthService _authService = DemoAuthService();

  void _checkAuthState() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // デモモード：ログイン状態に応じて画面を切り替え
    if (_authService.isLoggedIn) {
      return HomeScreenDemo(
        authService: _authService,
        onLogout: () {
          _authService.signOut();
          _checkAuthState();
        },
      );
    } else {
      return LoginScreenDemo(
        authService: _authService,
        onLoginSuccess: _checkAuthState,
      );
    }
  }
}