import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Android設定
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS設定
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // 通知タップ時の処理
        _handleNotificationTap(response.payload);
      },
    );

    // Android通知チャンネルの作成
    await _createNotificationChannel();
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      '重要な通知',
      description: 'メッセージや実験の通知',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
      enableLights: true,
      ledColor: Color(0xFF8E1728),
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // FCMメッセージから通知を表示（バイブレーション付き）
  Future<void> showNotificationFromFCM(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    // バイブレーションパターン設定
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'high_importance_channel',
      '重要な通知',
      channelDescription: 'メッセージや実験の通知',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'ticker',
      enableVibration: true,
      playSound: true,
      enableLights: true,
      color: Color(0xFF8E1728),
      ledColor: Color(0xFF8E1728),
      ledOnMs: 1000,
      ledOffMs: 500,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      // iOSはサウンドと同時にバイブレーションが発生
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      message.hashCode,
      notification.title,
      notification.body,
      platformChannelSpecifics,
      payload: message.data.toString(),
    );
  }

  // カスタム通知を表示
  Future<void> showCustomNotification({
    required String title,
    required String body,
    String? payload,
    bool isImportant = false,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'high_importance_channel',
      '重要な通知',
      channelDescription: 'メッセージや実験の通知',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      enableLights: true,
      color: Color(0xFF8E1728),
      ledColor: Color(0xFF8E1728),
      ledOnMs: 1000,
      ledOffMs: 500,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  // 重要な通知用
  Future<void> showImportantNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await showCustomNotification(
      title: title,
      body: body,
      payload: payload,
      isImportant: true,
    );
  }

  // 軽い通知用
  Future<void> showLightNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await showCustomNotification(
      title: title,
      body: body,
      payload: payload,
      isImportant: false,
    );
  }

  void _handleNotificationTap(String? payload) {
    // 通知タップ時の処理
    if (payload != null) {
      debugPrint('通知タップ: $payload');
      // ここで画面遷移などの処理を実装
    }
  }

  // バッジ数を更新（iOS）
  Future<void> updateBadgeCount(int count) async {
    // iOSのバッジ更新
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(badge: true);
  }

  // すべての通知をクリア
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  // 特定の通知をキャンセル
  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }
}