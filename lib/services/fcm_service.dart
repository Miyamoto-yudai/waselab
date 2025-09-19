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
        await _saveTokenToDatabase(_fcmToken!);
      }

      _messaging.onTokenRefresh.listen((newToken) async {
        _fcmToken = newToken;
        await _saveTokenToDatabase(newToken);
      });

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        
        // フォアグラウンドではローカル通知を表示（バイブレーション付き）
        _localNotificationService.showNotificationFromFCM(message);
        
        _handleMessage(message);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        
        _handleNotificationTap(message);
      });

      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }
    } catch (e) {
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


    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    } else {
    }
  }

  Future<void> _saveTokenToDatabase(String token) async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }

    try {
      // 通常のユーザーコレクションに保存
      await _firestore.collection('users').doc(user.uid).set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        'platform': defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 管理者かどうかをチェックして、管理者の場合はadminsコレクションにも保存
      try {
        final adminDoc = await _firestore.collection('admins').doc(user.uid).get();
        if (adminDoc.exists) {
          await _firestore.collection('admins').doc(user.uid).set({
            'fcmToken': token,
            'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
            'platform': defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
          }, SetOptions(merge: true));
        }
      } catch (e) {
        // 管理者コレクションへのアクセスエラーは無視（通常ユーザーの場合）
      }
    } catch (e) {
      // Firestoreへの書き込みが失敗した場合はCloud Functionsを使用
      try {
        final callable = _functions.httpsCallable('updateUserFCMToken');
        await callable.call({'token': token});
      } catch (e) {
      }
    }
  }

  Future<void> removeToken() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _messaging.deleteToken();

      // usersコレクションから削除
      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': FieldValue.delete(),
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });

      // 管理者の場合はadminsコレクションからも削除
      try {
        final adminDoc = await _firestore.collection('admins').doc(user.uid).get();
        if (adminDoc.exists) {
          await _firestore.collection('admins').doc(user.uid).update({
            'fcmToken': FieldValue.delete(),
            'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
          });
        }
      } catch (e) {
        // 管理者コレクションへのアクセスエラーは無視
      }

      _fcmToken = null;
    } catch (e) {
      // Firestoreへの書き込みが失敗した場合はCloud Functionsを使用
      try {
        final callable = _functions.httpsCallable('removeFCMToken');
        await callable.call();
      } catch (e) {
      }
    }
  }

  void _handleMessage(RemoteMessage message) {
    final type = message.data['type'];

    switch (type) {
      case 'evaluation':
        // 重要な通知なので強いバイブレーション
        _localNotificationService.showImportantNotification(
          title: message.notification?.title ?? '評価が届きました',
          body: message.notification?.body ?? '',
        );
        break;
      case 'message':
        // 通常のバイブレーション
        break;
      case 'support_message':
        // 管理者向けサポートメッセージ通知（最重要）
        _localNotificationService.showImportantNotification(
          title: message.notification?.title ?? '新しいお問い合わせ',
          body: message.notification?.body ?? 'サポートへのお問い合わせがあります',
        );
        break;
      case 'experiment_joined':
        // 重要な通知なので強いバイブレーション
        _localNotificationService.showImportantNotification(
          title: message.notification?.title ?? '実験に参加者が加わりました',
          body: message.notification?.body ?? '',
        );
        break;
      case 'experiment_cancelled':
        // 重要な通知なので強いバイブレーション
        _localNotificationService.showImportantNotification(
          title: message.notification?.title ?? '予約がキャンセルされました',
          body: message.notification?.body ?? '',
        );
        break;
      case 'experiment_completed':
        break;
      case 'admin_message':
        break;
      default:
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
      return;
    }

    switch (type) {
      case 'evaluation':
      case 'experiment_joined':
      case 'experiment_cancelled':
      case 'experiment_completed':
        if (experimentId != null) {
          await NavigationService.navigateToExperiment(experimentId);
        }
        break;
      case 'message':
        if (conversationId != null && senderId != null) {
          await NavigationService.navigateToMessage(conversationId, senderId, senderName);
        }
        break;
      case 'support_message':
        // 管理者向けサポートメッセージは管理画面のサポートチャットへ
        await NavigationService.navigateToAdminSupportChat();
        break;
      default:
        await NavigationService.navigateToNotifications();
    }
  }

  Future<void> sendTestNotification() async {
    try {
      final callable = _functions.httpsCallable('sendTestNotification');
      final result = await callable.call();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
    } catch (e) {
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
    } catch (e) {
    }
  }

  String? get fcmToken => _fcmToken;
}