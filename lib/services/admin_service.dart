import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/admin.dart';
import '../models/app_user.dart';
import '../models/message.dart';
import '../models/conversation.dart';
import '../models/experiment.dart';
import 'notification_service.dart';
import 'debug_service.dart';

/// 管理者サービスクラス
class AdminService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // 現在の管理者情報
  Admin? _currentAdmin;
  Admin? get currentAdmin => _currentAdmin;

  // 管理者モードフラグ（管理者権限を持つユーザーが通常画面を表示している場合はfalse）
  bool _isAdminMode = true;
  bool get isAdminMode => _isAdminMode;

  /// 管理者モードの切り替え
  void setAdminMode(bool mode) {
    _isAdminMode = mode;
  }

  /// 現在のユーザーが管理者権限を持っているか確認
  /// 認証状態に影響を与えないよう、慎重にエラーハンドリングを行う
  Future<bool> hasAdminPrivileges() async {
    try {
      // 現在のユーザーを取得
      final user = _auth.currentUser;
      if (user == null) {
        // ユーザーがログインしていない場合
        return false;
      }

      // ユーザーの認証状態が不安定な場合はチェックをスキップ
      // reload()を呼ばないことで、認証状態への影響を最小限にする
      if (user.emailVerified == null && user.email != null && !user.email!.contains('@gmail.com')) {
        // メール認証ユーザーで検証状態が不明な場合は、安全のためfalseを返す
        return false;
      }

      // タイムアウトを設定して、権限チェックが長引かないようにする
      try {
        final adminDoc = await _firestore
            .collection('admins')
            .doc(user.uid)
            .get()
            .timeout(
              const Duration(seconds: 2), // タイムアウトを短縮
              onTimeout: () {
                // タイムアウトした場合は権限なしとして扱う
                throw TimeoutException('Admin check timeout');
              },
            );

        // ドキュメントが存在すれば管理者
        return adminDoc.exists;
      } on FirebaseException catch (e) {
        // 権限エラーの場合は false を返す（通常のユーザー）
        if (e.code == 'permission-denied') {
          // 権限エラーは通常のユーザーなので、静かに false を返す
          return false;
        }
        // その他のFirebaseエラーも権限なしとして扱う
        return false;
      } on TimeoutException {
        // タイムアウトエラーの場合も権限なしとして扱う
        return false;
      }
    } catch (e) {
      // その他の予期しないエラーは権限なしとして扱う
      // 認証状態に影響を与えないようにする
      return false;
    }
  }

  /// 管理者情報を再読み込み
  Future<void> reloadAdminInfo() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final adminDoc = await _firestore
          .collection('admins')
          .doc(user.uid)
          .get();

      if (adminDoc.exists) {
        _currentAdmin = Admin.fromFirestore(adminDoc);
      }
    } catch (e) {
    }
  }

  /// 未読のサポートメッセージ数を取得
  Stream<int> getUnreadSupportMessageCount() {
    return _firestore
        .collection('messages')
        .where('receiverId', isEqualTo: 'support_team')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// 管理者ログイン
  Future<String?> signInAsAdmin({
    required String email,
    required String password,
  }) async {
    try {
      // デバッグ情報

      // まず、通常のユーザーとしてログインを試みる

      // Firebaseで認証
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        // 注意: ここでsignOut()を呼ばないことで、通常ユーザーの認証状態への影響を防ぐ
        return '認証に失敗しました';
      }


      // 管理者権限を確認
      
      DocumentSnapshot adminDoc;
      try {
        adminDoc = await _firestore
            .collection('admins')
            .doc(userCredential.user!.uid)
            .get();
      } catch (firestoreError) {
        // 管理者権限確認失敗時もsignOut()を呼ばない
        // 通常のユーザーがログインしたままにしておく
        return 'Firestore権限エラー: $firestoreError';
      }

      
      if (adminDoc.exists) {
        final data = adminDoc.data();
      }

      if (!adminDoc.exists) {

        // デバッグ用：adminsコレクションの読み取りは権限エラーになる可能性があるため削除
        // 代わりにUIDのみを出力

        // 管理者でない場合も、通常ユーザーとしてログインしたままにしておく
        // これにより、通常ユーザーが管理者ログインを試みてもログアウトされない
        return '管理者権限がありません\nUID: ${userCredential.user!.uid}\nadminsコレクションにこのUIDのドキュメントが見つかりません';
      }

      final admin = Admin.fromFirestore(adminDoc);
      
      if (!admin.isActive) {
        // 無効化された管理者の場合も、通常ユーザーとしてログインしたままにしておく
        return '管理者アカウントが無効化されています';
      }

      // 最終ログイン日時を更新
      await _firestore.collection('admins').doc(admin.uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });

      _currentAdmin = admin;

      // FCMトークンを管理者ドキュメントに保存
      await _saveAdminFCMToken(admin.uid);

      // 管理者ログイン履歴を記録
      await _logAdminActivity(
        adminId: admin.uid,
        action: 'login',
        details: {'ip': 'unknown'}, // 実際にはIPアドレスを取得
      );

      return null; // 成功
    } on FirebaseAuthException catch (e) {

      // Firebase認証エラーの場合もsignOut()を呼ばない
      // これにより、管理者ログインの失敗が通常ユーザーの認証に影響しない
      
      switch (e.code) {
        case 'user-not-found':
          return 'ユーザーが見つかりません\nメール: $email';
        case 'wrong-password':
          return 'パスワードが間違っています';
        case 'invalid-email':
          return 'メールアドレスの形式が正しくありません';
        case 'invalid-credential':
          return 'メールアドレスまたはパスワードが正しくありません';
        case 'user-disabled':
          return 'このユーザーアカウントは無効化されています';
        case 'too-many-requests':
          return 'ログイン試行回数が多すぎます。しばらく待ってから再試行してください';
        default:
          return 'エラーが発生しました\nコード: ${e.code}\n詳細: ${e.message}';
      }
    } catch (e) {

      // エラーが発生した場合もsignOut()を呼ばない
      // 管理者ログインの失敗が通常ユーザーの認証状態に影響しないようにする
      
      return 'エラーが発生しました: $e';
    }
  }

  /// 管理者のFCMトークンを保存
  Future<void> _saveAdminFCMToken(String adminId) async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        await _firestore.collection('admins').doc(adminId).update({
          'fcmToken': fcmToken,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
    }
  }

  /// すべての管理者のFCMトークンを取得
  Future<List<String>> getAllAdminFCMTokens() async {
    try {
      final adminsSnapshot = await _firestore
          .collection('admins')
          .where('isActive', isEqualTo: true)
          .where('fcmToken', isNotEqualTo: null)
          .get();

      final tokens = <String>[];
      for (final doc in adminsSnapshot.docs) {
        final token = doc.data()['fcmToken'] as String?;
        if (token != null && token.isNotEmpty) {
          tokens.add(token);
        }
      }
      return tokens;
    } catch (e) {
      return [];
    }
  }

  /// サポートメッセージが送信されたときに管理者に通知を送る
  /// Cloud Functionsで自動的にプッシュ通知が送信されるため、
  /// ここではFirestoreへの通知記録のみを行う（重複送信を防ぐ）
  Future<void> notifyAdminsOfSupportMessage({
    required String senderName,
    required String message,
  }) async {
    try {
      // Cloud Functionsがmessagesコレクションの変更を検知して
      // 自動的に管理者にプッシュ通知を送信するため、
      // ここではログ記録のみ行う

      return;
    } catch (e) {
    }
  }

  /// 管理者ログアウト
  Future<void> signOut() async {
    // デバッグログ記録
    AuthDebugService().log(
      '🔴 AdminService.signOut() called',
      type: LogType.critical,
      stackTrace: StackTrace.current,
      data: {
        'currentAdmin': _currentAdmin?.uid,
        'currentUser': _auth.currentUser?.uid,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    if (_currentAdmin != null) {
      // FCMトークンをクリア
      try {
        await _firestore.collection('admins').doc(_currentAdmin!.uid).update({
          'fcmToken': FieldValue.delete(),
          'fcmTokenUpdatedAt': FieldValue.delete(),
        });
      } catch (e) {
      }

      await _logAdminActivity(
        adminId: _currentAdmin!.uid,
        action: 'logout',
        details: {},
      );
    }
    _currentAdmin = null;
    await _auth.signOut();
  }

  /// 管理者権限チェック
  Future<bool> checkAdminPermission(String permission) async {
    if (_currentAdmin == null) return false;
    return _currentAdmin!.hasPermission(permission);
  }

  /// 全ユーザー一覧を取得
  Future<List<AppUser>> getAllUsers({
    int limit = 50,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore.collection('users')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => AppUser.fromFirestore(doc)).toList();
    } catch (e) {
      return [];
    }
  }

  /// ユーザー検索
  Future<List<AppUser>> searchUsers(String query) async {
    try {
      // 名前で検索
      final nameSnapshot = await _firestore
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: '$query\uf8ff')
          .limit(20)
          .get();

      // メールアドレスで検索
      final emailSnapshot = await _firestore
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('email', isLessThan: '${query.toLowerCase()}\uf8ff')
          .limit(20)
          .get();

      // 重複を除いて結合
      final Map<String, AppUser> usersMap = {};
      for (final doc in nameSnapshot.docs) {
        usersMap[doc.id] = AppUser.fromFirestore(doc);
      }
      for (final doc in emailSnapshot.docs) {
        usersMap[doc.id] = AppUser.fromFirestore(doc);
      }

      return usersMap.values.toList();
    } catch (e) {
      return [];
    }
  }

  /// ユーザー詳細情報を取得
  Future<Map<String, dynamic>?> getUserDetails(String userId) async {
    try {
      // ユーザー基本情報
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return null;

      final user = AppUser.fromFirestore(userDoc);

      // 実験参加履歴
      final experimentsSnapshot = await _firestore
          .collection('experiments')
          .where('participants', arrayContains: userId)
          .orderBy('createdAt', descending: true)
          .get();

      final experiments = experimentsSnapshot.docs
          .map((doc) => Experiment.fromFirestore(doc))
          .toList();

      // チャット履歴数を取得
      final conversationsSnapshot = await _firestore
          .collection('conversations')
          .where('participantIds', arrayContains: userId)
          .get();

      return {
        'user': user,
        'experiments': experiments,
        'conversationCount': conversationsSnapshot.docs.length,
      };
    } catch (e) {
      return null;
    }
  }

  /// ユーザーのチャット履歴を取得
  Future<List<Map<String, dynamic>>> getUserChatHistory(String userId) async {
    try {
      // ユーザーが参加している会話を取得
      final conversationsSnapshot = await _firestore
          .collection('conversations')
          .where('participantIds', arrayContains: userId)
          .orderBy('lastMessageTime', descending: true)
          .get();

      List<Map<String, dynamic>> chatHistory = [];

      for (final conversationDoc in conversationsSnapshot.docs) {
        final conversation = Conversation.fromFirestore(conversationDoc);
        
        // 会話のメッセージを取得（最新20件）
        final messagesSnapshot = await _firestore
            .collection('messages')
            .where('conversationId', isEqualTo: conversationDoc.id)
            .orderBy('createdAt', descending: true)
            .limit(20)
            .get();

        final messages = messagesSnapshot.docs
            .map((doc) => Message.fromFirestore(doc))
            .toList();

        chatHistory.add({
          'conversation': conversation,
          'messages': messages,
        });
      }

      return chatHistory;
    } catch (e) {
      return [];
    }
  }

  /// 全チャット履歴を取得（監視用）
  Stream<List<Map<String, dynamic>>> getAllChatHistory({
    int limit = 50,
  }) {
    return _firestore
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> chatData = [];
      
      for (final doc in snapshot.docs) {
        final message = Message.fromFirestore(doc);
        
        // サポートチームの特別処理
        String senderName = 'Unknown';
        String receiverName = 'Unknown';
        
        // 送信者の名前を取得
        if (message.senderId == 'support_team') {
          senderName = 'わせラボサポート';
        } else {
          final senderDoc = await _firestore
              .collection('users')
              .doc(message.senderId)
              .get();
          if (senderDoc.exists) {
            final data = senderDoc.data();
            senderName = data?['name'] ?? data?['displayName'] ?? data?['email']?.split('@')[0] ?? 'ユーザー';
          } else {
            senderName = 'ユーザー (${message.senderId.substring(0, 8)}...)';
          }
        }
        
        // 受信者の名前を取得
        if (message.receiverId == 'support_team') {
          receiverName = 'わせラボサポート';
        } else {
          final receiverDoc = await _firestore
              .collection('users')
              .doc(message.receiverId)
              .get();
          if (receiverDoc.exists) {
            final data = receiverDoc.data();
            receiverName = data?['name'] ?? data?['displayName'] ?? data?['email']?.split('@')[0] ?? 'ユーザー';
          } else {
            receiverName = 'ユーザー (${message.receiverId.substring(0, 8)}...)';
          }
        }

        chatData.add({
          'message': message,
          'senderName': senderName,
          'receiverName': receiverName,
        });
      }
      
      return chatData;
    });
  }

  /// ユーザーステータスを更新
  Future<bool> updateUserStatus(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).update(updates);
      
      // 管理者活動ログを記録
      await _logAdminActivity(
        adminId: _currentAdmin?.uid ?? 'unknown',
        action: 'update_user_status',
        details: {
          'userId': userId,
          'updates': updates,
        },
      );
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// サポートメッセージを送信
  Future<bool> sendSupportMessage({
    required String userId,
    required String message,
  }) async {
    try {
      // システムメッセージとして送信
      await _notificationService.createAdminNotification(
        userId: userId,
        title: 'サポートからのメッセージ',
        message: message,
        additionalData: {
          'type': 'support',
          'adminId': _currentAdmin?.uid,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      // 管理者活動ログを記録
      await _logAdminActivity(
        adminId: _currentAdmin?.uid ?? 'unknown',
        action: 'send_support_message',
        details: {
          'userId': userId,
          'messagePreview': message.length > 50 ? '${message.substring(0, 50)}...' : message,
        },
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 全ユーザーへのお知らせを送信
  Future<bool> sendAnnouncement({
    required String title,
    required String message,
    String? imageUrl,
  }) async {
    try {
      await _notificationService.broadcastAdminNotification(
        title: title,
        message: message,
        additionalData: {
          'type': 'announcement',
          'adminId': _currentAdmin?.uid,
          'imageUrl': imageUrl,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      // お知らせ履歴を保存
      await _firestore.collection('announcements').add({
        'title': title,
        'message': message,
        'imageUrl': imageUrl,
        'adminId': _currentAdmin?.uid,
        'adminName': _currentAdmin?.name,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 管理者活動ログを記録
      await _logAdminActivity(
        adminId: _currentAdmin?.uid ?? 'unknown',
        action: 'send_announcement',
        details: {
          'title': title,
          'messagePreview': message.length > 50 ? '${message.substring(0, 50)}...' : message,
        },
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 統計情報を取得
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      // ユーザー数
      final usersSnapshot = await _firestore.collection('users').get();
      final totalUsers = usersSnapshot.docs.length;
      
      // アクティブユーザー数（30日以内にログイン）
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final activeUsersSnapshot = await _firestore
          .collection('users')
          .where('lastLoginAt', isGreaterThan: Timestamp.fromDate(thirtyDaysAgo))
          .get();
      final activeUsers = activeUsersSnapshot.docs.length;

      // 実験数
      final experimentsSnapshot = await _firestore.collection('experiments').get();
      final totalExperiments = experimentsSnapshot.docs.length;

      // 今月の新規ユーザー数
      final firstDayOfMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
      final newUsersSnapshot = await _firestore
          .collection('users')
          .where('createdAt', isGreaterThan: Timestamp.fromDate(firstDayOfMonth))
          .get();
      final newUsersThisMonth = newUsersSnapshot.docs.length;

      return {
        'totalUsers': totalUsers,
        'activeUsers': activeUsers,
        'totalExperiments': totalExperiments,
        'newUsersThisMonth': newUsersThisMonth,
      };
    } catch (e) {
      return {
        'totalUsers': 0,
        'activeUsers': 0,
        'totalExperiments': 0,
        'newUsersThisMonth': 0,
      };
    }
  }

  /// 管理者活動ログを記録
  Future<void> _logAdminActivity({
    required String adminId,
    required String action,
    required Map<String, dynamic> details,
  }) async {
    try {
      await _firestore.collection('admin_logs').add({
        'adminId': adminId,
        'action': action,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
    }
  }

  /// 管理者権限を確認（静的メソッド）
  static Future<bool> isAdmin(String userId) async {
    try {
      final adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(userId)
          .get();
      
      if (!adminDoc.exists) return false;
      
      final admin = Admin.fromFirestore(adminDoc);
      return admin.isActive;
    } catch (e) {
      return false;
    }
  }
}