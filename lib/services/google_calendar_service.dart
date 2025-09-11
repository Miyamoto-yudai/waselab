import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/experiment.dart';
import '../models/experiment_slot.dart';

class GoogleCalendarService {
  static const String _calendarPermissionKey = 'google_calendar_permission';
  static const String _calendarEnabledKey = 'google_calendar_enabled';
  
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
    ],
  );
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// カレンダー連携が有効かどうかを取得
  Future<bool> isCalendarEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_calendarEnabledKey) ?? false;
    debugPrint('GoogleCalendarService.isCalendarEnabled: $enabled');
    return enabled;
  }
  
  /// カレンダー連携の有効/無効を設定
  Future<void> setCalendarEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_calendarEnabledKey, enabled);
    debugPrint('GoogleCalendarService.setCalendarEnabled: $enabled saved');
  }
  
  /// Google認証とカレンダーアクセスの許可を取得
  Future<bool> requestCalendarPermission() async {
    try {
      debugPrint('GoogleCalendarService.requestCalendarPermission: Starting Google Sign In');
      final account = await _googleSignIn.signIn();
      if (account == null) {
        debugPrint('Google認証がキャンセルされました');
        return false;
      }
      
      debugPrint('GoogleCalendarService.requestCalendarPermission: Signed in as ${account.email}');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_calendarPermissionKey, true);
      await prefs.setString('google_user_email', account.email);
      debugPrint('GoogleCalendarService.requestCalendarPermission: Permission saved');
      return true;
    } catch (e) {
      debugPrint('Google認証エラー: $e');
      return false;
    }
  }
  
  /// カレンダーアクセス許可があるかチェック
  Future<bool> hasCalendarPermission() async {
    final prefs = await SharedPreferences.getInstance();
    final hasPermission = prefs.getBool(_calendarPermissionKey) ?? false;
    debugPrint('GoogleCalendarService.hasCalendarPermission: stored permission = $hasPermission');
    
    // SharedPreferencesに保存されたフラグを信頼する
    // サイレントサインインは実際にカレンダーAPIを使用する時に行う
    return hasPermission;
  }
  
  /// カレンダー連携を解除
  Future<void> disconnectCalendar() async {
    try {
      await _googleSignIn.disconnect();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_calendarPermissionKey, false);
      await prefs.setBool(_calendarEnabledKey, false);
    } catch (e) {
      debugPrint('カレンダー連携解除エラー: $e');
    }
  }
  
  /// 実験予約をGoogleカレンダーに追加（URLスキームを使用）
  Future<String?> addReservationToCalendar({
    required Experiment experiment,
    required ExperimentSlot slot,
    required String reservationId,
  }) async {
    try {
      if (!await isCalendarEnabled()) {
        debugPrint('カレンダー連携が無効です');
        return null;
      }
      
      // GoogleカレンダーのURLを生成
      final calendarUrl = _createGoogleCalendarUrl(
        title: '【わせラボ】${experiment.title}',
        details: _createEventDescription(experiment, slot),
        location: _getEventLocation(experiment),
        startTime: slot.startTime,
        endTime: slot.endTime,
      );
      
      // URLを開く
      if (await canLaunchUrl(Uri.parse(calendarUrl))) {
        await launchUrl(
          Uri.parse(calendarUrl),
          mode: LaunchMode.externalApplication,
        );
        
        // Firestoreにカレンダー追加情報を保存
        await _firestore
            .collection('experiment_reservations')
            .doc(reservationId)
            .update({
          'calendarAddedAt': FieldValue.serverTimestamp(),
          'calendarUrl': calendarUrl,
        });
        
        return reservationId; // 予約IDを返す
      } else {
        debugPrint('カレンダーURLを開けませんでした');
        return null;
      }
    } catch (e) {
      debugPrint('カレンダーイベント追加エラー: $e');
      return null;
    }
  }
  
  /// イベントIDを指定してGoogleカレンダーからイベントを削除
  Future<bool> removeEventFromCalendar(String eventId) async {
    // URLスキームでは削除ができないため、
    // ユーザーに手動で削除してもらう必要がある
    debugPrint('カレンダーイベントの削除は手動で行ってください');
    return true;
  }
  
  /// 実験キャンセル時にGoogleカレンダーからイベントを削除
  Future<bool> removeReservationFromCalendar(String reservationId) async {
    // URLスキームでは削除ができないため、
    // Firestoreから情報を削除するのみ
    try {
      await _firestore
          .collection('experiment_reservations')
          .doc(reservationId)
          .update({
        'googleCalendarEventId': FieldValue.delete(),
        'calendarSyncedAt': FieldValue.delete(),
        'calendarAddedAt': FieldValue.delete(),
        'calendarUrl': FieldValue.delete(),
      });
      
      debugPrint('カレンダー情報を削除しました（イベントは手動で削除してください）');
      return true;
    } catch (e) {
      debugPrint('カレンダー情報削除エラー: $e');
      return false;
    }
  }
  
  /// 新規予約通知受信時にカレンダーに追加するためのクイック追加機能
  Future<String?> quickAddReservationToCalendar({
    required String experimentTitle,
    required DateTime startTime,
    required DateTime endTime,
    required String participantName,
    String? location,
    String? surveyUrl,
    ExperimentType type = ExperimentType.onsite,
  }) async {
    try {
      if (!await isCalendarEnabled()) {
        debugPrint('カレンダー連携が無効です');
        return null;
      }
      
      // 場所を取得
      String? eventLocation;
      if (type == ExperimentType.onsite && location != null) {
        eventLocation = location;
      } else if (type == ExperimentType.online) {
        eventLocation = 'オンライン実験';
      } else if (type == ExperimentType.survey && surveyUrl != null) {
        eventLocation = surveyUrl;
      }
      
      // GoogleカレンダーのURLを生成
      final calendarUrl = _createGoogleCalendarUrl(
        title: '【わせラボ】$experimentTitle - $participantName',
        details: '参加者: $participantName\n\nわせラボで予約された実験です。',
        location: eventLocation,
        startTime: startTime,
        endTime: endTime,
      );
      
      // URLを開く
      if (await canLaunchUrl(Uri.parse(calendarUrl))) {
        await launchUrl(
          Uri.parse(calendarUrl),
          mode: LaunchMode.externalApplication,
        );
        return 'quick-add-${DateTime.now().millisecondsSinceEpoch}';
      } else {
        debugPrint('カレンダーURLを開けませんでした');
        return null;
      }
    } catch (e) {
      debugPrint('クイックカレンダーイベント追加エラー: $e');
      return null;
    }
  }
  
  /// GoogleカレンダーURLを生成
  String _createGoogleCalendarUrl({
    required String title,
    required String details,
    String? location,
    required DateTime startTime,
    required DateTime endTime,
  }) {
    final baseUrl = 'https://calendar.google.com/calendar/render';
    final params = <String, String>{
      'action': 'TEMPLATE',
      'text': title,
      'details': details,
      'dates': '${_formatDateTime(startTime)}/${_formatDateTime(endTime)}',
    };
    
    if (location != null && location.isNotEmpty) {
      params['location'] = location;
    }
    
    final queryString = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    
    return '$baseUrl?$queryString';
  }
  
  /// DateTimeをGoogleカレンダーURL形式に変換
  String _formatDateTime(DateTime dateTime) {
    // Google CalendarはUTC時間を使用
    final utc = dateTime.toUtc();
    return '${utc.year}'
        '${utc.month.toString().padLeft(2, '0')}'
        '${utc.day.toString().padLeft(2, '0')}'
        'T'
        '${utc.hour.toString().padLeft(2, '0')}'
        '${utc.minute.toString().padLeft(2, '0')}'
        '${utc.second.toString().padLeft(2, '0')}'
        'Z';
  }
  
  /// イベントの場所を取得
  String? _getEventLocation(Experiment experiment) {
    if (experiment.type == ExperimentType.onsite && experiment.location.isNotEmpty) {
      return experiment.location;
    } else if (experiment.type == ExperimentType.online) {
      return 'オンライン実験';
    } else if (experiment.type == ExperimentType.survey && experiment.surveyUrl != null) {
      return experiment.surveyUrl;
    }
    return null;
  }
  
  /// イベント説明文を作成
  String _createEventDescription(Experiment experiment, ExperimentSlot slot) {
    final buffer = StringBuffer();
    
    buffer.writeln('実験タイトル: ${experiment.title}');
    buffer.writeln();
    
    if (experiment.description.isNotEmpty) {
      buffer.writeln('説明:');
      buffer.writeln(experiment.description);
      buffer.writeln();
    }
    
    buffer.writeln('実験タイプ: ${experiment.type.label}');
    
    if (experiment.type == ExperimentType.onsite && experiment.location.isNotEmpty) {
      buffer.writeln('場所: ${experiment.location}');
    } else if (experiment.type == ExperimentType.online) {
      buffer.writeln('実施方法: オンライン');
    } else if (experiment.type == ExperimentType.survey && experiment.surveyUrl != null) {
      buffer.writeln('アンケートURL: ${experiment.surveyUrl}');
    }
    
    buffer.writeln('報酬: ${experiment.reward}円');
    buffer.writeln();
    buffer.writeln('所要時間: ${experiment.duration}分');
    
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln('わせラボで予約された実験です。');
    
    return buffer.toString();
  }
}