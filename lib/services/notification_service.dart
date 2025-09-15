import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final String _collection = 'notifications';

  /// 通知を作成
  Future<void> createNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      // 通知設定を確認
      final prefs = await SharedPreferences.getInstance();
      
      // タイプに応じて通知設定を確認
      bool shouldSendNotification = true;

      if (type == NotificationType.experimentJoined ||
          type == NotificationType.experimentCancelled ||
          type == NotificationType.experimentCompleted ||
          type == NotificationType.experimentStarted) {
        shouldSendNotification = prefs.getBool('experiment_notifications') ?? true;
        print('実験通知設定: $shouldSendNotification (type=${type.value})');
      } else if (type == NotificationType.message) {
        shouldSendNotification = prefs.getBool('message_notifications') ?? true;
        print('メッセージ通知設定: $shouldSendNotification');
      }

      // 通知が無効の場合は作成しない
      if (!shouldSendNotification) {
        print('通知設定が無効のため、通知を作成しません: type=${type.value}');
        return;
      }
      
      final notification = AppNotification(
        id: '',
        userId: userId,
        type: type,
        title: title,
        message: message,
        createdAt: DateTime.now(),
        isRead: false,
        data: data,
      );

      print('通知を作成します: type=${type.value}, userId=$userId, title=$title');
      final docRef = await _firestore.collection(_collection).add(notification.toFirestore());
      print('通知が正常に作成されました: docId=${docRef.id}, type=${type.value}, userId=$userId');
    } catch (e) {
      print('通知の作成に失敗しました: $e');
      rethrow;
    }
  }

  /// ユーザーの通知一覧を取得（リアルタイム）- メッセージ通知は除外
  Stream<List<AppNotification>> getUserNotifications(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      // クライアント側でメッセージ通知をフィルタリング
      return snapshot.docs
          .map((doc) => AppNotification.fromFirestore(doc))
          .where((notification) => notification.type != NotificationType.message)
          .toList();
    });
  }

  /// 未読通知数を取得 - メッセージ通知は除外
  Future<int> getUnreadNotificationCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();
      
      // クライアント側でメッセージ通知をフィルタリング
      final count = snapshot.docs
          .map((doc) => AppNotification.fromFirestore(doc))
          .where((notification) => notification.type != NotificationType.message)
          .length;
      
      return count;
    } catch (e) {
      print('未読通知数の取得に失敗しました: $e');
      return 0;
    }
  }

  /// 未読通知数をリアルタイムで取得 - メッセージ通知は除外
  Stream<int> streamUnreadNotificationCount(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      // クライアント側でメッセージ通知をフィルタリング
      return snapshot.docs
          .map((doc) => AppNotification.fromFirestore(doc))
          .where((notification) => notification.type != NotificationType.message)
          .length;
    });
  }

  /// 通知を既読にする
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('通知の既読処理に失敗しました: $e');
      rethrow;
    }
  }

  /// すべての通知を既読にする
  Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      print('すべての通知の既読処理に失敗しました: $e');
      rethrow;
    }
  }

  /// 通知を削除
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection(_collection).doc(notificationId).delete();
    } catch (e) {
      print('通知の削除に失敗しました: $e');
      rethrow;
    }
  }

  /// 古い通知を削除（30日以上前の既読通知）
  Future<void> deleteOldNotifications(String userId) async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: true)
          .where('createdAt', isLessThan: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('古い通知の削除に失敗しました: $e');
    }
  }

  // 評価通知を作成
  Future<void> createEvaluationNotification({
    required String userId,
    required String evaluatorName,
    required String experimentTitle,
    required String experimentId,
    required bool isGood,
    int pointsAwarded = 1,
  }) async {
    final message = isGood 
      ? '$evaluatorNameさんから「$experimentTitle」に対してGood評価を受けました${pointsAwarded > 0 ? ' +$pointsAwarded ポイント獲得' : ''}'
      : '$evaluatorNameさんから「$experimentTitle」に対してBad評価を受けました';
    
    await createNotification(
      userId: userId,
      type: NotificationType.evaluation,
      title: isGood ? '評価が届きました${pointsAwarded > 0 ? '（+$pointsAwarded P）' : ''}' : '評価が届きました',
      message: message,
      data: {
        'experimentId': experimentId,
        'evaluatorName': evaluatorName,
        'isGood': isGood,
        'pointsAwarded': pointsAwarded,
      },
    );
  }

  // メッセージ通知を作成
  Future<void> createMessageNotification({
    required String userId,
    required String senderName,
    required String messagePreview,
    required String conversationId,
  }) async {
    await createNotification(
      userId: userId,
      type: NotificationType.message,
      title: '新しいメッセージ',
      message: '$senderNameさん: $messagePreview',
      data: {
        'conversationId': conversationId,
        'senderName': senderName,
      },
    );
  }

  // 実験参加通知を作成
  Future<void> createExperimentJoinedNotification({
    required String userId,
    required String participantName,
    required String experimentTitle,
    required String experimentId,
  }) async {
    await createNotification(
      userId: userId,
      type: NotificationType.experimentJoined,
      title: '実験に参加者が加わりました',
      message: '$participantNameさんが「$experimentTitle」に参加しました',
      data: {
        'experimentId': experimentId,
        'participantName': participantName,
      },
    );
  }

  /// 日程確定通知を作成（参加者向け）
  Future<void> createScheduleConfirmedNotification({
    required String userId,
    required String experimentTitle,
    required DateTime scheduledDate,
    required String experimentId,
  }) async {
    final notification = AppNotification(
      id: '',
      userId: userId,
      title: '実験日程が確定しました',
      message: '「$experimentTitle」の実施日時が${DateFormat('MM月dd日 HH:mm').format(scheduledDate)}に確定しました',
      type: NotificationType.experimentJoined,
      createdAt: DateTime.now(),
      isRead: false,
      data: {
        'experimentId': experimentId,
        'scheduledDate': scheduledDate.toIso8601String(),
      },
    );
    
    await _firestore.collection(_collection).add(notification.toFirestore());
  }
  
  /// 日程確定通知を作成（実験者向け）
  Future<void> createCreatorScheduleNotification({
    required String creatorId,
    required String experimentTitle,
    required String participantName,
    required DateTime scheduledDate,
    required String experimentId,
    required String participantId,
  }) async {
    final notification = AppNotification(
      id: '',
      userId: creatorId,
      title: '日程が確定しました',
      message: '$participantNameさんとの「$experimentTitle」の日程が${DateFormat('MM月dd日 HH:mm').format(scheduledDate)}に確定しました',
      type: NotificationType.experimentJoined,
      createdAt: DateTime.now(),
      isRead: false,
      data: {
        'experimentId': experimentId,
        'participantId': participantId,
        'participantName': participantName,
        'scheduledDate': scheduledDate.toIso8601String(),
        'isCreatorNotification': true,  // 実験者側の通知であることを示す
      },
    );
    
    await _firestore.collection(_collection).add(notification.toFirestore());
  }
  
  /// 日程キャンセル通知を作成
  Future<void> createScheduleCancelledNotification({
    required String userId,
    required String experimentTitle,
    required String experimentId,
    String? reason,
  }) async {
    final notification = AppNotification(
      id: '',
      userId: userId,
      title: '実験日程がキャンセルされました',
      message: '「$experimentTitle」の実施日程がキャンセルされました${reason != null ? '（理由: $reason）' : ''}',
      type: NotificationType.experimentCancelled,
      createdAt: DateTime.now(),
      isRead: false,
      data: {
        'experimentId': experimentId,
        'reason': reason,
      },
    );
    
    await _firestore.collection(_collection).add(notification.toFirestore());
  }
  
  // 予約キャンセル通知を作成
  Future<void> createExperimentCancelledNotification({
    required String userId,
    required String participantName,
    required String experimentTitle,
    required String experimentId,
    String? reason,
  }) async {
    final message = reason != null && reason.isNotEmpty
        ? '$participantNameさんが「$experimentTitle」の予約をキャンセルしました。理由: $reason'
        : '$participantNameさんが「$experimentTitle」の予約をキャンセルしました';
    
    await createNotification(
      userId: userId,
      type: NotificationType.experimentCancelled,
      title: '予約がキャンセルされました',
      message: message,
      data: {
        'experimentId': experimentId,
        'participantName': participantName,
        'reason': reason,
      },
    );
  }

  // 実験終了通知を作成
  Future<void> createExperimentCompletedNotification({
    required String userId,
    required String experimentTitle,
    required String experimentId,
  }) async {
    await createNotification(
      userId: userId,
      type: NotificationType.experimentCompleted,
      title: '実験が終了しました',
      message: '「$experimentTitle」が終了しました。参加者の評価をお願いします',
      data: {
        'experimentId': experimentId,
      },
    );
  }

  // 運営からのお知らせを作成
  Future<void> createAdminNotification({
    required String userId,
    required String title,
    required String message,
    Map<String, dynamic>? additionalData,
  }) async {
    await createNotification(
      userId: userId,
      type: NotificationType.adminMessage,
      title: title,
      message: message,
      data: additionalData,
    );
  }

  /// プッシュ通知を送信（FCM経由）
  Future<void> sendPushNotification({
    required String token,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Cloud Functionsを使用してプッシュ通知を送信
      final callable = _functions.httpsCallable('sendNotification');
      await callable.call({
        'token': token,
        'title': title,
        'body': body,
        'data': data ?? {},
      });
      print('プッシュ通知を送信しました: $title');
    } catch (e) {
      print('プッシュ通知の送信に失敗しました: $e');
      // エラーが発生してもアプリの動作は継続
    }
  }

  // 全ユーザーに運営からのお知らせを送信
  Future<void> broadcastAdminNotification({
    required String title,
    required String message,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // すべてのユーザーを取得
      final usersSnapshot = await _firestore.collection('users').get();
      
      final batch = _firestore.batch();
      for (final userDoc in usersSnapshot.docs) {
        final notificationRef = _firestore.collection(_collection).doc();
        batch.set(notificationRef, {
          'userId': userDoc.id,
          'type': NotificationType.adminMessage.value,
          'title': title,
          'message': message,
          'createdAt': Timestamp.now(),
          'isRead': false,
          'data': additionalData,
        });
      }
      
      await batch.commit();
    } catch (e) {
      print('全体通知の送信に失敗しました: $e');
      rethrow;
    }
  }
}