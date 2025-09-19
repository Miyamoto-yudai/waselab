import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestoreの実験データを確認するテストユーティリティ
class TestFirestore {
  static Future<void> checkExperiments() async {
    final firestore = FirebaseFirestore.instance;
    
    
    try {
      // 1. コレクションの存在確認
      
      // 2. シンプルなクエリで全データ取得
      final allDocs = await firestore.collection('experiments').get();
      
      if (allDocs.docs.isEmpty) {
        return;
      }
      
      // 3. 各ドキュメントの内容を確認
      for (int i = 0; i < allDocs.docs.length && i < 3; i++) {
        final doc = allDocs.docs[i];
        final data = doc.data();
        
        // Timestampかどうかチェック
        if (data['createdAt'] is Timestamp) {
        } else {
        }
      }
      
      // 4. orderByクエリのテスト
      try {
        final orderedDocs = await firestore
            .collection('experiments')
            .orderBy('createdAt', descending: true)
            .limit(10)
            .get();
      } catch (e) {
      }
      
      // 5. statusフィルタのテスト
      final recruitingDocs = await firestore
          .collection('experiments')
          .where('status', isEqualTo: 'recruiting')
          .get();
      
      // 6. 日付フィルタのテスト
      final now = DateTime.now();
      final activeDocs = await firestore
          .collection('experiments')
          .where('recruitmentEndDate', isGreaterThan: Timestamp.fromDate(now))
          .get();
      
    } catch (e) {
    }
    
  }
}