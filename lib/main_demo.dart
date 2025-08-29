import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'screens/login_screen_demo.dart';
import 'screens/navigation_screen_demo.dart';
import 'services/demo_auth_service.dart';
import 'shared/app_wrapper.dart';

/// デモモード用のエントリーポイント
/// Firebaseを使わずにアプリをテストできる（高速起動版）
/// 
/// 重要: 共通コンポーネントはshared/フォルダに配置されています
/// main.dartとmain_demo.dartで共有される部分は必ずshared/に配置してください
void main() {
  // リリースモードではデバッグツールを無効化して高速化
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }
  
  runApp(const WaseLaboApp(
    home: AuthWrapperDemo(),
    isDemo: true,
  ));
}

/// 認証状態に応じて表示する画面を切り替えるラッパー（デモ版）
class AuthWrapperDemo extends StatefulWidget {
  const AuthWrapperDemo({super.key});

  @override
  State<AuthWrapperDemo> createState() => _AuthWrapperDemoState();
}

class _AuthWrapperDemoState extends State<AuthWrapperDemo> {
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
      return NavigationScreenDemo(
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