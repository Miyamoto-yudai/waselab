import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'local_notification_service.dart';
import 'navigation_service.dart';
import 'auth_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('バックグラウンドメッセージを受信: ${message.messageId}');
  print('タイトル: ${message.notification?.title}');
  print('本文: ${message.notification?.body}');
  print('データ: ${message.data}');
}

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final LocalNotificationService _localNotificationService = LocalNotificationService();

  String? _fcmToken;

  Future<void> initialize() async {
    try {
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // ローカル通知サービスを初期化
      await _localNotificationService.initialize();

      await _requestPermission();

      // Androidの通知チャンネルを設定
      await _createNotificationChannel();

      _fcmToken = await _messaging.getToken();
      if (_fcmToken != null) {
        print('FCMトークン: $_fcmToken');
        await _saveTokenToDatabase(_fcmToken!);
      }

      _messaging.onTokenRefresh.listen((newToken) async {
        print('FCMトークンが更新されました: $newToken');
        _fcmToken = newToken;
        await _saveTokenToDatabase(newToken);
      });

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('フォアグラウンドメッセージを受信:');
        print('タイトル: ${message.notification?.title}');
        print('本文: ${message.notification?.body}');
        print('データ: ${message.data}');
        
        // フォアグラウンドではローカル通知を表示（バイブレーション付き）
        _localNotificationService.showNotificationFromFCM(message);
        
        _handleMessage(message);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('通知タップでアプリを開きました:');
        print('データ: ${message.data}');
        
        _handleNotificationTap(message);
      });

      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        print('アプリが終了状態から通知で起動されました');
        _handleNotificationTap(initialMessage);
      }
    } catch (e) {
      print('FCM初期化エラー: $e');
    }
  }

  Future<void> _createNotificationChannel() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      // Androidの通知チャンネルを作成
      const channel = {
        'id': 'high_importance_channel',
        'name': '重要な通知',
        'description': 'メッセージや実験の通知',
        'importance': 5,
        'sound': true,
        'vibration': true,
        'badge': true,
      };
      print('Android通知チャンネルを設定');
    }
  }

  Future<void> _requestPermission() async {
    if (kIsWeb) {
      return;
    }

    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('通知権限の状態: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('ユーザーが通知を許可しました');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('ユーザーが仮の通知を許可しました');
    } else {
      print('ユーザーが通知を拒否しました');
    }
  }

  Future<void> _saveTokenToDatabase(String token) async {
    final user = _auth.currentUser;
    if (user == null) {
      print('ユーザーがログインしていません');
      return;
    }

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        'platform': defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print('FCMトークンをFirestoreに保存しました');
      print('ユーザーUID: ${user.uid}');
      print('プラットフォーム: ${defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android'}');
    } catch (e) {
      print('FCMトークンの保存に失敗しました: $e');
      
      try {
        final callable = _functions.httpsCallable('updateUserFCMToken');
        await callable.call({'token': token});
        print('Cloud Functions経由でFCMトークンを保存しました');
      } catch (e) {
        print('Cloud Functions経由でもFCMトークンの保存に失敗しました: $e');
      }
    }
  }

  Future<void> removeToken() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _messaging.deleteToken();
      
      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': FieldValue.delete(),
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });
      
      _fcmToken = null;
      print('FCMトークンを削除しました');
    } catch (e) {
      print('FCMトークンの削除に失敗しました: $e');
      
      try {
        final callable = _functions.httpsCallable('removeFCMToken');
        await callable.call();
        print('Cloud Functions経由でFCMトークンを削除しました');
      } catch (e) {
        print('Cloud Functions経由でもFCMトークンの削除に失敗しました: $e');
      }
    }
  }

  void _handleMessage(RemoteMessage message) {
    final type = message.data['type'];
    
    switch (type) {
      case 'evaluation':
        print('評価通知を処理します');
        // 重要な通知なので強いバイブレーション
        _localNotificationService.showImportantNotification(
          title: message.notification?.title ?? '評価が届きました',
          body: message.notification?.body ?? '',
        );
        break;
      case 'message':
        print('メッセージ通知を処理します');
        // 通常のバイブレーション
        break;
      case 'experiment_joined':
        print('実験参加通知を処理します');
        // 重要な通知なので強いバイブレーション
        _localNotificationService.showImportantNotification(
          title: message.notification?.title ?? '実験に参加者が加わりました',
          body: message.notification?.body ?? '',
        );
        break;
      case 'experiment_cancelled':
        print('予約キャンセル通知を処理します');
        // 重要な通知なので強いバイブレーション
        _localNotificationService.showImportantNotification(
          title: message.notification?.title ?? '予約がキャンセルされました',
          body: message.notification?.body ?? '',
        );
        break;
      case 'experiment_completed':
        print('実験終了通知を処理します');
        break;
      case 'admin_message':
        print('運営からのお知らせを処理します');
        break;
      default:
        print('未知の通知タイプ: $type');
    }
  }

  void _handleNotificationTap(RemoteMessage message) async {
    final type = message.data['type'];
    final experimentId = message.data['experimentId'];
    final conversationId = message.data['conversationId'];
    final senderId = message.data['senderId'];
    final senderName = message.data['senderName'] ?? 'ユーザー';
    
    // ユーザーがログインしているか確認
    final authService = AuthService();
    final currentUser = authService.currentUser;
    if (currentUser == null) {
      print('ユーザーがログインしていません');
      return;
    }
    
    switch (type) {
      case 'evaluation':
      case 'experiment_joined':
      case 'experiment_cancelled':
      case 'experiment_completed':
        if (experimentId != null) {
          print('実験詳細画面に遷移: $experimentId');
          await NavigationService.navigateToExperiment(experimentId);
        }
        break;
      case 'message':
        if (conversationId != null && senderId != null) {
          print('メッセージ画面に遷移: $conversationId');
          await NavigationService.navigateToMessage(conversationId, senderId, senderName);
        }
        break;
      default:
        print('通知画面に遷移');
        await NavigationService.navigateToNotifications();
    }
  }

  Future<void> sendTestNotification() async {
    try {
      final callable = _functions.httpsCallable('sendTestNotification');
      final result = await callable.call();
      print('テスト通知送信結果: ${result.data}');
    } catch (e) {
      print('テスト通知の送信に失敗しました: $e');
      rethrow;
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      print('トピック「$topic」に登録しました');
    } catch (e) {
      print('トピック登録に失敗しました: $e');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      print('トピック「$topic」から登録解除しました');
    } catch (e) {
      print('トピック登録解除に失敗しました: $e');
    }
  }

  String? get fcmToken => _fcmToken;
}