import 'package:cloud_firestore/cloud_firestore.dart';

/// 既存の実験データを修正するユーティリティ
class ExistingDataFixer {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// requirements フィールドが文字列になっているデータを配列に変換
  static Future<int> fixRequirementsField() async {
    try {
      
      final snapshot = await _firestore.collection('experiments').get();
      int fixedCount = 0;
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final requirements = data['requirements'];
        
        // requirementsが文字列の場合、配列に変換
        if (requirements is String) {
          
          // 改行で分割して配列に変換
          final requirementsList = requirements
              .split('\n')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
          
          // Firestoreを更新
          await doc.reference.update({
            'requirements': requirementsList,
          });
          
          fixedCount++;
        }
      }
      
      return fixedCount;
    } catch (e) {
      rethrow;
    }
  }
  
  /// すべての実験データのフィールドを検証
  static Future<void> validateAllExperiments() async {
    try {
      
      final snapshot = await _firestore.collection('experiments').get();
      int validCount = 0;
      int invalidCount = 0;
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        bool isValid = true;
        List<String> issues = [];
        
        // requirements のチェック
        if (data['requirements'] != null && data['requirements'] is! List) {
          issues.add('requirements が配列ではない');
          isValid = false;
        }
        
        // creatorId のチェック
        if (data['creatorId'] == null || data['creatorId'].toString().isEmpty) {
          issues.add('creatorId が空');
          isValid = false;
        }
        
        // 必須フィールドのチェック
        final requiredFields = ['title', 'description', 'createdAt'];
        for (final field in requiredFields) {
          if (data[field] == null) {
            issues.add('$field が null');
            isValid = false;
          }
        }
        
        if (isValid) {
          validCount++;
        } else {
          invalidCount++;
          for (final issue in issues) {
          }
        }
      }
      
    } catch (e) {
    }
  }
}