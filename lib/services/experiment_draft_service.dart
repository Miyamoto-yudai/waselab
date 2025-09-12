import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 実験作成の下書きを管理するサービス
class ExperimentDraftService {
  static const String _draftKey = 'experiment_draft';
  static const String _draftTimestampKey = 'experiment_draft_timestamp';
  static const String _currentStepKey = 'experiment_draft_step';
  
  /// 下書きデータを保存
  static Future<void> saveDraft({
    required Map<String, dynamic> draftData,
    required int currentStep,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 現在のタイムスタンプを追加
      draftData['lastModified'] = DateTime.now().toIso8601String();
      
      // JSONエンコードして保存
      final jsonString = json.encode(draftData);
      await prefs.setString(_draftKey, jsonString);
      await prefs.setInt(_currentStepKey, currentStep);
      await prefs.setString(_draftTimestampKey, DateTime.now().toIso8601String());
    } catch (e) {
      print('下書き保存エラー: $e');
    }
  }
  
  /// 下書きデータを取得
  static Future<Map<String, dynamic>?> loadDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_draftKey);
      
      if (jsonString == null) {
        return null;
      }
      
      final draftData = json.decode(jsonString) as Map<String, dynamic>;
      
      // 24時間以上経過した下書きは無効とする
      final timestampString = draftData['lastModified'] as String?;
      if (timestampString != null) {
        final lastModified = DateTime.parse(timestampString);
        final now = DateTime.now();
        if (now.difference(lastModified).inHours > 24) {
          await clearDraft();
          return null;
        }
      }
      
      return draftData;
    } catch (e) {
      print('下書き読み込みエラー: $e');
      return null;
    }
  }
  
  /// 現在のステップを取得
  static Future<int> getCurrentStep() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_currentStepKey) ?? 0;
  }
  
  /// 下書きが存在するかチェック
  static Future<bool> hasDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_draftKey);
    
    if (jsonString == null) {
      return false;
    }
    
    // タイムスタンプチェック
    final timestampString = prefs.getString(_draftTimestampKey);
    if (timestampString != null) {
      final timestamp = DateTime.parse(timestampString);
      final now = DateTime.now();
      // 24時間以内の下書きのみ有効
      if (now.difference(timestamp).inHours <= 24) {
        return true;
      }
    }
    
    // 古い下書きは削除
    await clearDraft();
    return false;
  }
  
  /// 下書きの最終更新時刻を取得
  static Future<DateTime?> getLastModified() async {
    final prefs = await SharedPreferences.getInstance();
    final timestampString = prefs.getString(_draftTimestampKey);
    
    if (timestampString != null) {
      return DateTime.parse(timestampString);
    }
    return null;
  }
  
  /// 下書きをクリア
  static Future<void> clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);
    await prefs.remove(_currentStepKey);
    await prefs.remove(_draftTimestampKey);
  }
  
  /// 下書きから実験データの基本情報を構築
  static Map<String, dynamic> extractBasicInfo(Map<String, dynamic> draftData) {
    return {
      'title': draftData['title'] ?? '',
      'description': draftData['description'] ?? '',
      'experimentType': draftData['experimentType'],
      'location': draftData['location'] ?? '',
      'isPaid': draftData['isPaid'] ?? false,
      'reward': draftData['reward'],
      'duration': draftData['duration'],
      'maxParticipants': draftData['maxParticipants'],
      'requirements': draftData['requirements'] ?? [],
      'tags': draftData['tags'] ?? [],
    };
  }
}