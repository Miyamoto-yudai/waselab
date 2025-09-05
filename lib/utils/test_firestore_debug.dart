import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Firestoreの実験データをデバッグするユーティリティ
class FirestoreDebugger {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  /// 現在のユーザー情報を表示
  static Future<void> showCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      debugPrint('===== 現在のユーザー情報 =====');
      debugPrint('UID: ${user.uid}');
      debugPrint('Email: ${user.email}');
      debugPrint('DisplayName: ${user.displayName}');
      debugPrint('EmailVerified: ${user.emailVerified}');
      debugPrint('==========================');
    } else {
      debugPrint('ログインユーザーなし');
    }
  }
  
  /// すべての実験データを表示（デバッグ用）
  static Future<void> showAllExperiments() async {
    try {
      debugPrint('===== Firestoreの全実験データ =====');
      
      // 生のクエリでデータ取得
      final snapshot = await _firestore.collection('experiments').get();
      
      debugPrint('総実験数: ${snapshot.docs.length}件');
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        debugPrint('\n----- 実験ID: ${doc.id} -----');
        debugPrint('タイトル: ${data['title']}');
        debugPrint('作成者ID: ${data['creatorId']}');
        debugPrint('作成者メール: ${data['researcherEmail'] ?? data['contactEmail'] ?? 'なし'}');
        debugPrint('状態: ${data['status']}');
        debugPrint('作成日時: ${data['createdAt']}');
        debugPrint('募集開始: ${data['recruitmentStartDate'] ?? data['recruitmentStart']}');
        debugPrint('募集終了: ${data['recruitmentEndDate'] ?? data['recruitmentEnd']}');
        
        // すべてのフィールドを表示
        debugPrint('全フィールド:');
        data.forEach((key, value) {
          if (value != null && value.toString().length < 100) {
            debugPrint('  $key: $value');
          }
        });
      }
      
      debugPrint('================================');
    } catch (e) {
      debugPrint('エラー: $e');
    }
  }
  
  /// 特定のユーザーが作成した実験を表示
  static Future<void> showUserExperiments(String userId) async {
    try {
      debugPrint('===== ユーザー $userId の実験 =====');
      
      final snapshot = await _firestore
          .collection('experiments')
          .where('creatorId', isEqualTo: userId)
          .get();
      
      debugPrint('該当実験数: ${snapshot.docs.length}件');
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        debugPrint('- ${data['title']} (ID: ${doc.id})');
      }
      
      debugPrint('================================');
    } catch (e) {
      debugPrint('エラー: $e');
    }
  }
  
  /// 最新の実験を表示（作成日時順）
  static Future<void> showRecentExperiments() async {
    try {
      debugPrint('===== 最新の実験（作成日時順） =====');
      
      // orderByを使用
      QuerySnapshot snapshot;
      try {
        snapshot = await _firestore
            .collection('experiments')
            .orderBy('createdAt', descending: true)
            .limit(10)
            .get();
        debugPrint('orderByクエリ成功');
      } catch (e) {
        debugPrint('orderByクエリ失敗: $e');
        // orderByなしで取得
        snapshot = await _firestore
            .collection('experiments')
            .limit(10)
            .get();
        debugPrint('単純クエリで取得');
      }
      
      debugPrint('取得数: ${snapshot.docs.length}件');
      
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final createdAt = data['createdAt'] as Timestamp?;
        debugPrint('- ${data['title']}');
        debugPrint('  作成: ${createdAt?.toDate()}');
        debugPrint('  作成者: ${data['creatorId']}');
      }
      
      debugPrint('================================');
    } catch (e) {
      debugPrint('エラー: $e');
    }
  }
  
  /// Firestoreのインデックス状態を確認
  static Future<void> checkIndexes() async {
    debugPrint('===== インデックス確認 =====');
    
    // 各種クエリを試してインデックスの必要性を確認
    final queries = [
      {
        'name': 'createdAt降順',
        'query': () => _firestore
            .collection('experiments')
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get(),
      },
      {
        'name': 'status + createdAt',
        'query': () => _firestore
            .collection('experiments')
            .where('status', isEqualTo: 'recruiting')
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get(),
      },
      {
        'name': 'creatorId条件',
        'query': () => _firestore
            .collection('experiments')
            .where('creatorId', isEqualTo: 'test')
            .limit(1)
            .get(),
      },
    ];
    
    for (final test in queries) {
      try {
        await (test['query'] as Function)();
        debugPrint('✅ ${test['name']}: 成功');
      } catch (e) {
        debugPrint('❌ ${test['name']}: 失敗 - $e');
      }
    }
    
    debugPrint('================================');
  }
  
  /// 完全なデバッグレポートを生成
  static Future<void> generateFullReport() async {
    debugPrint('\n\n========== Firestore完全デバッグレポート ==========\n');
    
    await showCurrentUser();
    await showAllExperiments();
    
    final user = _auth.currentUser;
    if (user != null) {
      await showUserExperiments(user.uid);
    }
    
    await showRecentExperiments();
    await checkIndexes();
    
    debugPrint('\n========== レポート終了 ==========\n\n');
  }
}