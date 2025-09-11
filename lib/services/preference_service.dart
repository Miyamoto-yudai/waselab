import 'package:shared_preferences/shared_preferences.dart';

/// 表示頻度やユーザー設定を管理するサービス
class PreferenceService {
  static const String _keyFirstLaunchDate = 'first_launch_date';
  static const String _keySupportBannerLastShown = 'support_banner_last_shown';
  static const String _keySupportBannerDismissed = 'support_banner_dismissed';
  static const String _keySupportBannerNeverShow = 'support_banner_never_show';
  static const String _keyDonationCardCollapsed = 'donation_card_collapsed';
  static const String _keyExperimentCompletedCount = 'experiment_completed_count';
  static const String _keyFirstReservationMade = 'first_reservation_made';
  static const String _keyFirstExperimentCreated = 'first_experiment_created';
  static const String _keyCalendarPromptShown = 'calendar_prompt_shown';
  
  /// 初回起動日を記録
  static Future<void> recordFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_keyFirstLaunchDate)) {
      await prefs.setString(_keyFirstLaunchDate, DateTime.now().toIso8601String());
    }
  }
  
  /// 初回起動から7日以上経過しているか確認
  static Future<bool> isAfterInitialPeriod() async {
    final prefs = await SharedPreferences.getInstance();
    final firstLaunchStr = prefs.getString(_keyFirstLaunchDate);
    if (firstLaunchStr == null) {
      await recordFirstLaunch();
      return false;
    }
    
    final firstLaunch = DateTime.parse(firstLaunchStr);
    final daysSinceFirstLaunch = DateTime.now().difference(firstLaunch).inDays;
    return daysSinceFirstLaunch >= 7;
  }
  
  /// サポートバナーを表示すべきか判定
  static Future<bool> shouldShowSupportBanner() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 「今後表示しない」が選択されている場合
    if (prefs.getBool(_keySupportBannerNeverShow) ?? false) {
      return false;
    }
    
    // 初回起動から7日経過していない場合
    if (!await isAfterInitialPeriod()) {
      return false;
    }
    
    // 最後に表示してから30日経過しているか確認
    final lastShownStr = prefs.getString(_keySupportBannerLastShown);
    if (lastShownStr == null) {
      return true; // まだ一度も表示していない
    }
    
    final lastShown = DateTime.parse(lastShownStr);
    final daysSinceLastShown = DateTime.now().difference(lastShown).inDays;
    return daysSinceLastShown >= 30; // 30日に1回の頻度
  }
  
  /// サポートバナーの表示を記録
  static Future<void> recordSupportBannerShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySupportBannerLastShown, DateTime.now().toIso8601String());
  }
  
  /// サポートバナーを一時的に非表示にする
  static Future<void> dismissSupportBanner() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySupportBannerDismissed, true);
    await recordSupportBannerShown(); // 次回表示まで30日待つ
  }
  
  /// サポートバナーを今後表示しない設定
  static Future<void> neverShowSupportBanner() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySupportBannerNeverShow, true);
  }
  
  /// 寄付カードの折りたたみ状態を取得
  static Future<bool> isDonationCardCollapsed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDonationCardCollapsed) ?? false;
  }
  
  /// 寄付カードの折りたたみ状態を保存
  static Future<void> setDonationCardCollapsed(bool collapsed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDonationCardCollapsed, collapsed);
  }
  
  /// 実験完了回数を取得
  static Future<int> getExperimentCompletedCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyExperimentCompletedCount) ?? 0;
  }
  
  /// 実験完了回数を増やす
  static Future<void> incrementExperimentCompletedCount() async {
    final prefs = await SharedPreferences.getInstance();
    final currentCount = await getExperimentCompletedCount();
    await prefs.setInt(_keyExperimentCompletedCount, currentCount + 1);
  }
  
  /// 実験を3回以上完了しているか
  static Future<bool> hasCompletedMultipleExperiments() async {
    final count = await getExperimentCompletedCount();
    return count >= 3;
  }
  
  /// 初回予約かどうかをチェック
  static Future<bool> isFirstReservation() async {
    final prefs = await SharedPreferences.getInstance();
    return !prefs.containsKey(_keyFirstReservationMade);
  }
  
  /// 初回予約を記録
  static Future<void> recordFirstReservation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFirstReservationMade, true);
  }
  
  /// 初回実験作成かどうかをチェック
  static Future<bool> isFirstExperimentCreated() async {
    final prefs = await SharedPreferences.getInstance();
    return !prefs.containsKey(_keyFirstExperimentCreated);
  }
  
  /// 初回実験作成を記録
  static Future<void> recordFirstExperimentCreated() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFirstExperimentCreated, true);
  }
  
  /// カレンダー連携プロンプトを表示したかどうか
  static Future<bool> hasShownCalendarPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyCalendarPromptShown) ?? false;
  }
  
  /// カレンダー連携プロンプトを表示したことを記録
  static Future<void> recordCalendarPromptShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyCalendarPromptShown, true);
  }
  
  /// すべての設定をリセット（デバッグ用）
  static Future<void> resetAllPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}