import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Firestoreの実験データを確認するテストユーティリティ
class TestFirestore {
  static Future<void> checkExperiments() async {
    final firestore = FirebaseFirestore.instance;
    
    debugPrint('========== Firestore実験データチェック開始 ==========');
    
    try {
      // 1. コレクションの存在確認
      debugPrint('1. experiments コレクションを確認中...');
      
      // 2. シンプルなクエリで全データ取得
      debugPrint('2. 全実験データを取得中...');
      final allDocs = await firestore.collection('experiments').get();
      debugPrint('   → 実験データ総数: ${allDocs.docs.length}件');
      
      if (allDocs.docs.isEmpty) {
        debugPrint('   ⚠️ 実験データが1件も存在しません！');
        debugPrint('   → 管理者画面からテストデータを作成してください');
        return;
      }
      
      // 3. 各ドキュメントの内容を確認
      debugPrint('3. 各実験データの内容を確認中...');
      for (int i = 0; i < allDocs.docs.length && i < 3; i++) {
        final doc = allDocs.docs[i];
        final data = doc.data();
        debugPrint('   実験 ${i + 1} (ID: ${doc.id}):');
        debugPrint('     - title: ${data['title']}');
        debugPrint('     - status: ${data['status']}');
        debugPrint('     - createdAt: ${data['createdAt']}');
        debugPrint('     - creatorId: ${data['creatorId']}');
        debugPrint('     - recruitmentStartDate: ${data['recruitmentStartDate']}');
        debugPrint('     - recruitmentEndDate: ${data['recruitmentEndDate']}');
        
        // Timestampかどうかチェック
        if (data['createdAt'] is Timestamp) {
          debugPrint('     ✓ createdAtはTimestamp型です');
        } else {
          debugPrint('     ⚠️ createdAtはTimestamp型ではありません: ${data['createdAt'].runtimeType}');
        }
      }
      
      // 4. orderByクエリのテスト
      debugPrint('4. orderByクエリをテスト中...');
      try {
        final orderedDocs = await firestore
            .collection('experiments')
            .orderBy('createdAt', descending: true)
            .limit(10)
            .get();
        debugPrint('   → orderByクエリ成功: ${orderedDocs.docs.length}件取得');
      } catch (e) {
        debugPrint('   ⚠️ orderByクエリ失敗: $e');
        debugPrint('   → インデックスの作成が必要かもしれません');
      }
      
      // 5. statusフィルタのテスト
      debugPrint('5. status=recruitingの実験を確認中...');
      final recruitingDocs = await firestore
          .collection('experiments')
          .where('status', isEqualTo: 'recruiting')
          .get();
      debugPrint('   → recruiting状態の実験: ${recruitingDocs.docs.length}件');
      
      // 6. 日付フィルタのテスト
      debugPrint('6. 募集期間中の実験を確認中...');
      final now = DateTime.now();
      final activeDocs = await firestore
          .collection('experiments')
          .where('recruitmentEndDate', isGreaterThan: Timestamp.fromDate(now))
          .get();
      debugPrint('   → 募集期間中の実験: ${activeDocs.docs.length}件');
      
    } catch (e, stack) {
      debugPrint('エラー発生: $e');
      debugPrint('スタックトレース: $stack');
    }
    
    debugPrint('========== Firestoreチェック完了 ==========');
  }
}