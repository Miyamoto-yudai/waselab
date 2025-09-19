import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Firestoreの実験データをデバッグするユーティリティ
class FirestoreDebugger {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  /// 現在のユーザー情報を表示
  static Future<void> showCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
    } else {
    }
  }
  
  /// すべての実験データを表示（デバッグ用）
  static Future<void> showAllExperiments() async {
    try {
      
      // 生のクエリでデータ取得
      final snapshot = await _firestore.collection('experiments').get();
      
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        
        // すべてのフィールドを表示
        data.forEach((key, value) {
          if (value != null && value.toString().length < 100) {
          }
        });
      }
      
    } catch (e) {
    }
  }
  
  /// 特定のユーザーが作成した実験を表示
  static Future<void> showUserExperiments(String userId) async {
    try {
      
      final snapshot = await _firestore
          .collection('experiments')
          .where('creatorId', isEqualTo: userId)
          .get();
      
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
      }
      
    } catch (e) {
    }
  }
  
  /// 最新の実験を表示（作成日時順）
  static Future<void> showRecentExperiments() async {
    try {
      
      // orderByを使用
      QuerySnapshot snapshot;
      try {
        snapshot = await _firestore
            .collection('experiments')
            .orderBy('createdAt', descending: true)
            .limit(10)
            .get();
      } catch (e) {
        // orderByなしで取得
        snapshot = await _firestore
            .collection('experiments')
            .limit(10)
            .get();
      }
      
      
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final createdAt = data['createdAt'] as Timestamp?;
      }
      
    } catch (e) {
    }
  }
  
  /// Firestoreのインデックス状態を確認
  static Future<void> checkIndexes() async {
    
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
      } catch (e) {
      }
    }
    
  }
  
  /// 完全なデバッグレポートを生成
  static Future<void> generateFullReport() async {
    
    await showCurrentUser();
    await showAllExperiments();
    
    final user = _auth.currentUser;
    if (user != null) {
      await showUserExperiments(user.uid);
    }
    
    await showRecentExperiments();
    await checkIndexes();
    
  }
}