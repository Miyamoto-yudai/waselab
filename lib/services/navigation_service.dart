import 'package:flutter/material.dart';
import '../screens/chat_screen.dart';
import '../screens/experiment_detail_screen.dart';
import '../screens/notification_screen.dart';
import '../screens/navigation_screen.dart';
import '../services/experiment_service.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  static Future<void> navigateToMessage(String conversationId, String otherUserId, String otherUserName) async {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    
    // まずホーム画面に戻る
    Navigator.of(context).popUntil((route) => route.isFirst);
    
    // チャット画面に遷移
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          conversationId: conversationId,
          otherUserId: otherUserId,
          otherUserName: otherUserName,
        ),
      ),
    );
  }
  
  static Future<void> navigateToExperiment(String experimentId) async {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    
    try {
      // 実験データを取得
      final experimentService = ExperimentService();
      final experiment = await experimentService.getExperiment(experimentId);
      
      if (experiment == null) {
        return;
      }
      
      // まずホーム画面に戻る
      Navigator.of(context).popUntil((route) => route.isFirst);
      
      // 実験詳細画面に遷移
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ExperimentDetailScreen(
            experiment: experiment,
          ),
        ),
      );
    } catch (e) {
    }
  }
  
  static Future<void> navigateToNotifications() async {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    // まずホーム画面に戻る
    Navigator.of(context).popUntil((route) => route.isFirst);

    // NavigationScreenの通知タブに切り替え
    if (context.widget is NavigationScreen) {
      final navigationState = context.findAncestorStateOfType<NavigationScreenState>();
      navigationState?.setSelectedIndex(2); // 通知タブのインデックス（0:ホーム, 1:メッセージ, 2:通知）
    } else {
      // 通知画面に直接遷移
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const NotificationScreen(),
        ),
      );
    }
  }

  static Future<void> navigateToAdminSupportChat() async {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    // まずホーム画面に戻る
    Navigator.of(context).popUntil((route) => route.isFirst);

    // 管理者サポートチャット画面に遷移
    // TODO: 管理者用のサポートチャット画面へのナビゲーションを実装
    // 現在は通常のメッセージ画面にリダイレクト
    if (context.widget is NavigationScreen) {
      final navigationState = context.findAncestorStateOfType<NavigationScreenState>();
      navigationState?.setSelectedIndex(1); // メッセージタブのインデックス
    }
  }
}