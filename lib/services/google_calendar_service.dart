import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;
import 'package:android_intent_plus/android_intent.dart';
import '../models/experiment.dart';
import '../models/experiment_slot.dart';
import 'google_account_service.dart';

class GoogleCalendarService {
  static const String _calendarPermissionKey = 'google_calendar_permission';
  static const String _calendarEnabledKey = 'google_calendar_enabled';

  final GoogleAccountService _accountService = GoogleAccountService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// エラーコールバック（UI層でエラーハンドリングするため）
  Function(String error, bool needsAccountSelection)? onError;
  
  /// カレンダー連携が有効かどうかを取得
  Future<bool> isCalendarEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_calendarEnabledKey) ?? false;
    return enabled;
  }
  
  /// カレンダー連携の有効/無効を設定
  Future<void> setCalendarEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_calendarEnabledKey, enabled);
  }
  
  /// Google認証とカレンダーアクセスの許可を取得（明示的なアカウント選択付き）
  Future<bool> requestCalendarPermission({bool forceAccountSelection = false}) async {
    try {
      // アカウントサービスを初期化
      await _accountService.initialize();

      // アカウントを選択（強制選択オプション付き）
      final account = forceAccountSelection
          ? await _accountService.selectAccount(forceAccountSelection: true)
          : await _accountService.signInSilently() ?? await _accountService.selectAccount();

      if (account == null) {
        onError?.call('Googleアカウントが選択されませんでした', true);
        return false;
      }

      // カレンダー権限をリクエスト
      final hasPermission = await _accountService.requestCalendarPermission();
      if (!hasPermission) {
        onError?.call(
          'Googleカレンダーへのアクセス権限が必要です。\n'
          '選択したアカウント（${account.email}）に編集権限があることを確認してください。',
          false
        );
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_calendarPermissionKey, true);
      await prefs.setString('google_user_email', account.email);
      return true;
    } catch (e) {
      onError?.call('認証エラー: $e', false);
      return false;
    }
  }
  
  /// カレンダーアクセス許可があるかチェック
  Future<bool> hasCalendarPermission() async {
    final prefs = await SharedPreferences.getInstance();
    final hasPermission = prefs.getBool(_calendarPermissionKey) ?? false;

    if (!hasPermission) return false;

    // アカウントサービスを初期化して権限を再確認
    await _accountService.initialize();
    if (_accountService.currentAccount == null) {
      return false;
    }

    // 実際に権限があるか確認
    return await _accountService.hasRequiredPermissions();
  }
  
  /// カレンダー連携を解除
  Future<void> disconnectCalendar() async {
    try {
      await _accountService.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_calendarPermissionKey, false);
      await prefs.setBool(_calendarEnabledKey, false);
      await prefs.remove('google_user_email');
    } catch (e) {
      debugPrint('カレンダー連携解除エラー: $e');
    }
  }

  /// アカウントを切り替える
  Future<bool> switchAccount() async {
    try {
      final account = await _accountService.switchAccount();
      if (account == null) {
        onError?.call('アカウントの切り替えに失敗しました', true);
        return false;
      }

      // カレンダー権限を再確認
      final hasPermission = await _accountService.requestCalendarPermission();
      if (!hasPermission) {
        onError?.call(
          '新しいアカウント（${account.email}）にカレンダーの編集権限がありません',
          false
        );
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('google_user_email', account.email);
      return true;
    } catch (e) {
      onError?.call('アカウント切り替えエラー: $e', false);
      return false;
    }
  }

  /// 現在のGoogleアカウント情報を取得
  Map<String, dynamic>? getCurrentAccountInfo() {
    if (_accountService.currentAccount == null) return null;
    return _accountService.getAccountInfo();
  }
  
  /// 実験予約をGoogleカレンダーに追加（URLスキームを使用）
  Future<String?> addReservationToCalendar({
    required Experiment experiment,
    required ExperimentSlot slot,
    required String reservationId,
  }) async {
    try {
      if (!await isCalendarEnabled()) {
        return null;
      }
      
      final title = '【わせラボ】${experiment.title}';
      final details = _createEventDescription(experiment, slot);
      final location = _getEventLocation(experiment);
      
      // カレンダーを開く
      final result = await _openCalendar(
        title: title,
        details: details,
        location: location,
        startTime: slot.startTime,
        endTime: slot.endTime,
      );
      
      if (result) {
        // Firestoreにカレンダー追加情報を保存
        await _firestore
            .collection('experiment_reservations')
            .doc(reservationId)
            .update({
          'calendarAddedAt': FieldValue.serverTimestamp(),
        });
        
        return reservationId;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
  
  /// イベントIDを指定してGoogleカレンダーからイベントを削除
  Future<bool> removeEventFromCalendar(String eventId) async {
    // URLスキームでは削除ができないため、
    // ユーザーに手動で削除してもらう必要がある
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
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// 新規予約通知受信時にカレンダーに追加するためのクイック追加機能（実験者用）
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

      final title = '【わせラボ】$experimentTitle - $participantName';
      final details = '参加者: $participantName\n\nわせラボで予約された実験です。';

      // カレンダーを開く
      final result = await _openCalendar(
        title: title,
        details: details,
        location: eventLocation,
        startTime: startTime,
        endTime: endTime,
      );

      if (result) {
        return 'quick-add-${DateTime.now().millisecondsSinceEpoch}';
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// 参加者が実験をカレンダーに追加するための機能
  Future<String?> addParticipantExperimentToCalendar({
    required String experimentTitle,
    required DateTime startTime,
    required DateTime endTime,
    String? location,
    String? surveyUrl,
    String? preSurveyUrl,
    ExperimentType type = ExperimentType.onsite,
  }) async {
    try {
      if (!await isCalendarEnabled()) {
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

      final title = '【わせラボ】$experimentTitle';

      // 詳細情報を構築
      var details = 'わせラボで参加予定の実験です。\n';
      if (preSurveyUrl != null && preSurveyUrl.isNotEmpty) {
        details += '\n事前アンケート: $preSurveyUrl';
      }
      if (type == ExperimentType.survey && surveyUrl != null && surveyUrl.isNotEmpty) {
        details += '\nアンケートURL: $surveyUrl';
      } else if (type == ExperimentType.online && surveyUrl != null && surveyUrl.isNotEmpty) {
        details += '\n実験URL: $surveyUrl';
      }
      details += '\n\n実験終了後は相互評価をお忘れなく！';

      // カレンダーを開く
      final result = await _openCalendar(
        title: title,
        details: details,
        location: eventLocation,
        startTime: startTime,
        endTime: endTime,
      );

      if (result) {
        return 'participant-add-${DateTime.now().millisecondsSinceEpoch}';
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
  
  /// カレンダーを開く（プラットフォーム別処理）
  Future<bool> _openCalendar({
    required String title,
    required String details,
    String? location,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      
      if (kIsWeb) {
        // Web環境: ブラウザでGoogleカレンダーを開く
        return await _openCalendarOnWeb(
          title: title,
          details: details,
          location: location,
          startTime: startTime,
          endTime: endTime,
        );
      } else {
        // モバイル環境: プラットフォームに応じた処理
        // Platform.isAndroid/isIOSを使用して判定（より確実）
        if (Platform.isIOS) {
          return await _openCalendarOnIOS(
            title: title,
            details: details,
            location: location,
            startTime: startTime,
            endTime: endTime,
          );
        } else if (Platform.isAndroid) {
          return await _openCalendarOnAndroid(
            title: title,
            details: details,
            location: location,
            startTime: startTime,
            endTime: endTime,
          );
        } else {
          // その他のプラットフォーム（デスクトップなど）
          return await _openCalendarOnWeb(
            title: title,
            details: details,
            location: location,
            startTime: startTime,
            endTime: endTime,
          );
        }
      }
    } catch (e) {
      // エラーが発生した場合はWebブラウザで開く
      return await _openCalendarOnWeb(
        title: title,
        details: details,
        location: location,
        startTime: startTime,
        endTime: endTime,
      );
    }
  }
  
  /// Web環境でカレンダーを開く
  Future<bool> _openCalendarOnWeb({
    required String title,
    required String details,
    String? location,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final calendarUrl = _createGoogleCalendarUrl(
        title: title,
        details: details,
        location: location,
        startTime: startTime,
        endTime: endTime,
      );


      final uri = Uri.parse(calendarUrl);

      // Web環境とモバイル環境で異なるLaunchModeを使用
      LaunchMode mode;
      if (kIsWeb) {
        // Web環境では新しいタブで開く
        mode = LaunchMode.platformDefault;
      } else {
        // モバイル環境では外部アプリケーションとして開く
        mode = LaunchMode.externalApplication;
      }

      try {
        await launchUrl(
          uri,
          mode: mode,
        );
        return true;
      } catch (launchError) {

        // フォールバック: アプリ内ブラウザで開く
        try {
          await launchUrl(
            uri,
            mode: LaunchMode.inAppWebView,
          );
          return true;
        } catch (inAppError) {

          // 最終フォールバック: プラットフォームデフォルト
          try {
            await launchUrl(
              uri,
              mode: LaunchMode.platformDefault,
            );
            return true;
          } catch (finalError) {
            return false;
          }
        }
      }
    } catch (e) {
      return false;
    }
  }
  
  /// iOS環境でカレンダーを開く
  Future<bool> _openCalendarOnIOS({
    required String title,
    required String details,
    String? location,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {

      // GoogleカレンダーのURLを作成
      final calendarUrl = _createGoogleCalendarUrl(
        title: title,
        details: details,
        location: location,
        startTime: startTime,
        endTime: endTime,
      );

      final uri = Uri.parse(calendarUrl);

      // iOSでは、externalNonBrowserApplicationモードを使用して
      // システムにアプリの選択を委ねる
      try {
        await launchUrl(
          uri,
          mode: LaunchMode.externalNonBrowserApplication,
        );
        return true;
      } catch (nonBrowserError) {

        // 通常の外部アプリケーションモードで試す
        try {
          await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
          return true;
        } catch (externalError) {

          // 最終的なフォールバック：Webブラウザで開く
          return await _openCalendarOnWeb(
            title: title,
            details: details,
            location: location,
            startTime: startTime,
            endTime: endTime,
          );
        }
      }
    } catch (e) {
      // エラーが発生した場合はWebブラウザにフォールバック
      return await _openCalendarOnWeb(
        title: title,
        details: details,
        location: location,
        startTime: startTime,
        endTime: endTime,
      );
    }
  }
  
  /// Android環境でカレンダーを開く
  Future<bool> _openCalendarOnAndroid({
    required String title,
    required String details,
    String? location,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {

      // Android Intentを使用してGoogleカレンダーアプリを直接起動
      try {
        // カレンダーイベント作成用のIntentを構築
        final intent = AndroidIntent(
          action: 'android.intent.action.INSERT',
          type: 'vnd.android.cursor.item/event',
          package: 'com.google.android.calendar',
          arguments: <String, dynamic>{
            'title': title,
            'description': details,
            'beginTime': startTime.millisecondsSinceEpoch,
            'endTime': endTime.millisecondsSinceEpoch,
            'allDay': false,
          },
        );

        if (location != null && location.isNotEmpty) {
          intent.arguments!['eventLocation'] = location;
        }

        // Intentを起動
        await intent.launch();
        return true;

      } catch (intentError) {

        // AndroidIntentが失敗した場合、URLを使用
        final calendarUrl = _createGoogleCalendarUrl(
          title: title,
          details: details,
          location: location,
          startTime: startTime,
          endTime: endTime,
        );

        // Googleカレンダーアプリがインストールされている場合、
        // システムがアプリを選択する可能性がある
        final uri = Uri.parse(calendarUrl);

        // まずexternalApplicationモードで試す
        try {
          await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
          return true;
        } catch (urlError) {

          // 最終フォールバック: Webブラウザで開く
          return await _openCalendarOnWeb(
            title: title,
            details: details,
            location: location,
            startTime: startTime,
            endTime: endTime,
          );
        }
      }
    } catch (e) {
      // エラーが発生した場合はWebブラウザにフォールバック
      return await _openCalendarOnWeb(
        title: title,
        details: details,
        location: location,
        startTime: startTime,
        endTime: endTime,
      );
    }
  }
  
  /// GoogleカレンダーURLを生成（アカウント指定付き）
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

    // アカウントサービスを使用してURLを生成（authuser パラメータ付き）
    return _accountService.generateCalendarUrl(
      baseUrl: baseUrl,
      params: params,
    );
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