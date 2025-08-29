import 'package:flutter/material.dart';

/// 共通のアプリテーマ設定
/// main.dartとmain_demo.dartで共有される
/// 
/// 重要: このファイルはmainとmain_demoで共有されます。
/// 変更を加える際は両方のエントリーポイントに影響することに注意してください。
class AppTheme {
  static ThemeData get theme {
    return ThemeData(
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
    );
  }

  /// デモモード用の高速化されたテーマ
  static ThemeData get demoTheme {
    return theme.copyWith(
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
    );
  }
}