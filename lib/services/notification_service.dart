import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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

      await _firestore.collection(_collection).add(notification.toFirestore());
    } catch (e) {
      print('通知の作成に失敗しました: $e');
      throw e;
    }
  }

  /// ユーザーの通知一覧を取得（リアルタイム）
  Stream<List<AppNotification>> getUserNotifications(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AppNotification.fromFirestore(doc))
          .toList();
    });
  }

  /// 未読通知数を取得
  Future<int> getUnreadNotificationCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();
      
      return snapshot.docs.length;
    } catch (e) {
      print('未読通知数の取得に失敗しました: $e');
      return 0;
    }
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
      throw e;
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
      throw e;
    }
  }

  /// 通知を削除
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection(_collection).doc(notificationId).delete();
    } catch (e) {
      print('通知の削除に失敗しました: $e');
      throw e;
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
  }) async {
    final message = isGood 
      ? '$evaluatorNameさんから「$experimentTitle」に対してGood評価を受けました🎉 +1ポイント獲得！'
      : '$evaluatorNameさんから「$experimentTitle」に対してBad評価を受けました';
    
    await createNotification(
      userId: userId,
      type: NotificationType.evaluation,
      title: isGood ? '評価が届きました（+1P）' : '評価が届きました',
      message: message,
      data: {
        'experimentId': experimentId,
        'evaluatorName': evaluatorName,
        'isGood': isGood,
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
      throw e;
    }
  }
}