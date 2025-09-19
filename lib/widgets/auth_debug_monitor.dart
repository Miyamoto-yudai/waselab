import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/debug_service.dart';
import 'package:intl/intl.dart';

/// 認証デバッグモニターウィジェット
/// 画面上部に認証状態とログを表示する
class AuthDebugMonitor extends StatefulWidget {
  final Widget child;

  const AuthDebugMonitor({
    super.key,
    required this.child,
  });

  @override
  State<AuthDebugMonitor> createState() => _AuthDebugMonitorState();
}

class _AuthDebugMonitorState extends State<AuthDebugMonitor> {
  bool _isExpanded = false;
  final _debugService = AuthDebugService();

  @override
  void initState() {
    super.initState();
    _debugService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.95),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ヘッダー
                  InkWell(
                    onTap: () => setState(() => _isExpanded = !_isExpanded),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Icon(
                            _isExpanded ? Icons.expand_less : Icons.expand_more,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '🐛 Auth Debug Monitor',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          StreamBuilder<User?>(
                            stream: FirebaseAuth.instance.authStateChanges(),
                            builder: (context, snapshot) {
                              final user = snapshot.data;
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: user != null
                                      ? Colors.green.withOpacity(0.3)
                                      : Colors.red.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: user != null
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      user != null
                                          ? Icons.check_circle
                                          : Icons.cancel,
                                      color: user != null
                                          ? Colors.green
                                          : Colors.red,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      user != null
                                          ? 'Logged In'
                                          : 'Logged Out',
                                      style: TextStyle(
                                        color: user != null
                                            ? Colors.green
                                            : Colors.red,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 展開時の詳細情報
                  if (_isExpanded) ...[
                    const Divider(color: Colors.grey, height: 1),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ユーザー情報
                          StreamBuilder<User?>(
                            stream: FirebaseAuth.instance.authStateChanges(),
                            builder: (context, snapshot) {
                              final user = snapshot.data;
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(8),
                                color: Colors.grey.withOpacity(0.1),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildInfoRow('UID', user?.uid ?? 'null'),
                                    _buildInfoRow('Email', user?.email ?? 'null'),
                                    _buildInfoRow(
                                      'Email Verified',
                                      user?.emailVerified.toString() ?? 'null',
                                    ),
                                    _buildInfoRow(
                                      'Anonymous',
                                      user?.isAnonymous.toString() ?? 'null',
                                    ),
                                    _buildInfoRow(
                                      'Providers',
                                      user?.providerData
                                              .map((p) => p.providerId)
                                              .join(', ') ??
                                          'null',
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                          const Divider(color: Colors.grey, height: 1),

                          // ログリスト
                          Expanded(
                            child: StreamBuilder<List<DebugLog>>(
                              stream: _debugService.logStream,
                              builder: (context, snapshot) {
                                final logs = snapshot.data ?? [];
                                if (logs.isEmpty) {
                                  return const Center(
                                    child: Text(
                                      'No logs yet',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  );
                                }

                                return ListView.separated(
                                  shrinkWrap: true,
                                  padding: const EdgeInsets.all(8),
                                  itemCount: logs.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                                  itemBuilder: (context, index) {
                                    final log = logs[index];
                                    return _buildLogItem(log);
                                  },
                                );
                              },
                            ),
                          ),

                          // アクションボタン
                          Container(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildActionButton(
                                  'Clear Logs',
                                  Icons.clear,
                                  Colors.orange,
                                  () => _debugService.clearLogs(),
                                ),
                                _buildActionButton(
                                  'Export',
                                  Icons.download,
                                  Colors.blue,
                                  () => _exportLogs(context),
                                ),
                                _buildActionButton(
                                  'Force Logout',
                                  Icons.logout,
                                  Colors.red,
                                  () => _forceLogout(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem(DebugLog log) {
    final timeStr = DateFormat('HH:mm:ss').format(log.timestamp);
    Color logColor;

    switch (log.type) {
      case LogType.error:
      case LogType.critical:
        logColor = Colors.red;
        break;
      case LogType.warning:
        logColor = Colors.orange;
        break;
      case LogType.auth:
        logColor = Colors.blue;
        break;
      case LogType.lifecycle:
        logColor = Colors.purple;
        break;
      default:
        logColor = Colors.white70;
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: logColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: logColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                timeStr,
                style: TextStyle(
                  color: logColor,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  log.message,
                  style: TextStyle(
                    color: logColor,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          if (log.data != null) ...[
            const SizedBox(height: 2),
            Text(
              'Data: ${log.data}',
              style: TextStyle(
                color: logColor.withOpacity(0.7),
                fontSize: 10,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14, color: color),
      label: Text(
        label,
        style: TextStyle(color: color, fontSize: 12),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: const Size(0, 0),
      ),
    );
  }

  void _exportLogs(BuildContext context) {
    final logs = _debugService.exportLogs();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug Logs'),
        content: SingleChildScrollView(
          child: SelectableText(
            logs,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _forceLogout() async {
    _debugService.log(
      '⚠️ Force logout triggered from debug monitor',
      type: LogType.critical,
    );
    await FirebaseAuth.instance.signOut();
  }
}