import 'package:flutter/material.dart';
import 'app_theme.dart';
import '../services/navigation_service.dart';

/// アプリのルートウィジェット（共通）
/// main.dartとmain_demo.dartで共有される
/// 
/// 重要: このファイルはmainとmain_demoで共有されます。
/// 変更を加える際は両方のエントリーポイントに影響することに注意してください。
class WaseLaboApp extends StatelessWidget {
  final Widget home;
  final bool isDemo;

  const WaseLaboApp({
    super.key,
    required this.home,
    this.isDemo = false,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'わせラボ',
      debugShowCheckedModeBanner: false,
      theme: isDemo ? AppTheme.demoTheme : AppTheme.theme,
      navigatorKey: NavigationService.navigatorKey,
      home: home,
    );
  }
}