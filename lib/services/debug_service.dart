import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

/// 認証状態デバッグサービス
/// すべての認証関連イベントを記録し、問題の原因を特定する
class AuthDebugService {
  static final AuthDebugService _instance = AuthDebugService._internal();
  factory AuthDebugService() => _instance;
  AuthDebugService._internal();

  final List<DebugLog> _logs = [];
  final _logController = StreamController<List<DebugLog>>.broadcast();

  Stream<List<DebugLog>> get logStream => _logController.stream;
  List<DebugLog> get logs => List.unmodifiable(_logs);

  static const int _maxLogs = 500;
  bool _initialized = false;

  /// デバッグサービスを初期化
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Firebase Auth状態の監視開始
    _startAuthStateMonitoring();

    // 過去のログを読み込み
    await _loadPersistedLogs();
  }

  /// ログを記録
  void log(String message, {
    LogType type = LogType.info,
    Map<String, dynamic>? data,
    StackTrace? stackTrace,
  }) {
    final log = DebugLog(
      timestamp: DateTime.now(),
      message: message,
      type: type,
      data: data,
      stackTrace: stackTrace?.toString(),
    );

    _logs.insert(0, log);

    // ログの最大数を制限
    if (_logs.length > _maxLogs) {
      _logs.removeRange(_maxLogs, _logs.length);
    }

    _logController.add(logs);

    // コンソールにも出力
    final timeStr = DateFormat('HH:mm:ss.SSS').format(log.timestamp);
    final emoji = _getEmoji(type);
    print('[$timeStr] $emoji $message');
    if (data != null) {
      print('  Data: $data');
    }
    if (stackTrace != null && type == LogType.error) {
      print('  Stack: $stackTrace');
    }

    // エラーの場合は永続化
    if (type == LogType.error || type == LogType.critical) {
      _persistLog(log);
    }
  }


  /// Firebase Auth状態の監視
  void _startAuthStateMonitoring() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        log('✅ Auth state: User logged in (${user.uid})',
          type: LogType.auth
        );
      } else {
        log('❌ Auth state: User logged out',
          type: LogType.auth,
          stackTrace: StackTrace.current
        );
      }
    });
  }


  /// ログを永続化
  Future<void> _persistLog(DebugLog log) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logs = prefs.getStringList('auth_debug_logs') ?? [];
      logs.insert(0, log.toJson());

      // 最大100件まで保存
      if (logs.length > 100) {
        logs.removeRange(100, logs.length);
      }

      await prefs.setStringList('auth_debug_logs', logs);
    } catch (e) {
      print('Failed to persist log: $e');
    }
  }

  /// 永続化されたログを読み込み
  Future<void> _loadPersistedLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logs = prefs.getStringList('auth_debug_logs') ?? [];

      for (final logJson in logs.reversed) {
        try {
          _logs.add(DebugLog.fromJson(logJson));
        } catch (e) {
          print('Failed to parse log: $e');
        }
      }

      if (logs.isNotEmpty) {
        log('📜 Loaded ${logs.length} persisted logs', type: LogType.system);
      }
    } catch (e) {
      log('❌ Failed to load persisted logs',
        type: LogType.error,
        data: {'error': e.toString()}
      );
    }
  }

  /// すべてのログをクリア
  Future<void> clearLogs() async {
    _logs.clear();
    _logController.add(logs);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_debug_logs');

    log('🧹 All logs cleared', type: LogType.system);
  }

  /// ログをエクスポート
  String exportLogs() {
    final buffer = StringBuffer();
    buffer.writeln('=== Auth Debug Logs ===');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total logs: ${_logs.length}');
    buffer.writeln('');

    for (final log in _logs) {
      final timeStr = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(log.timestamp);
      final emoji = _getEmoji(log.type);
      buffer.writeln('[$timeStr] $emoji ${log.message}');

      if (log.data != null) {
        buffer.writeln('  Data: ${log.data}');
      }

      if (log.stackTrace != null) {
        buffer.writeln('  Stack trace:');
        buffer.writeln('  ${log.stackTrace!.replaceAll('\n', '\n  ')}');
      }

      buffer.writeln('');
    }

    return buffer.toString();
  }

  String _getEmoji(LogType type) {
    switch (type) {
      case LogType.info:
        return 'ℹ️';
      case LogType.warning:
        return '⚠️';
      case LogType.error:
        return '❌';
      case LogType.critical:
        return '🚨';
      case LogType.auth:
        return '🔐';
      case LogType.system:
        return '⚙️';
      case LogType.lifecycle:
        return '🔄';
    }
  }

  void dispose() {
    _logController.close();
  }
}


/// ログタイプ
enum LogType {
  info,
  warning,
  error,
  critical,
  auth,
  system,
  lifecycle,
}

/// デバッグログ
class DebugLog {
  final DateTime timestamp;
  final String message;
  final LogType type;
  final Map<String, dynamic>? data;
  final String? stackTrace;

  DebugLog({
    required this.timestamp,
    required this.message,
    required this.type,
    this.data,
    this.stackTrace,
  });

  String toJson() {
    return '${timestamp.toIso8601String()}|${type.index}|$message|${data ?? {}}|${stackTrace ?? ''}';
  }

  static DebugLog fromJson(String json) {
    final parts = json.split('|');
    return DebugLog(
      timestamp: DateTime.parse(parts[0]),
      type: LogType.values[int.parse(parts[1])],
      message: parts[2],
      data: parts[3].isEmpty || parts[3] == '{}' ? null : {'raw': parts[3]},
      stackTrace: parts[4].isEmpty ? null : parts[4],
    );
  }
}