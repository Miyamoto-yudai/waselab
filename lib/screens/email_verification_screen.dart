import 'package:flutter/material.dart';
import 'dart:async';
import '../services/auth_service.dart';
import 'navigation_screen.dart';

/// メール認証待機画面
/// 新規登録後、メール認証が完了するまで表示される画面
class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final AuthService _authService = AuthService();
  Timer? _timer;
  bool _isResending = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _startEmailVerificationCheck();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  /// メール認証状態を定期的にチェック
  void _startEmailVerificationCheck() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      final isVerified = await _authService.checkEmailVerification();
      
      if (isVerified && mounted) {
        timer.cancel();
        // 認証完了：ナビゲーション画面へ遷移
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const NavigationScreen(),
            transitionDuration: const Duration(milliseconds: 300),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          ),
        );
      }
    });
  }

  /// 認証メールを再送信
  Future<void> _resendVerificationEmail() async {
    if (_resendCooldown > 0) return;

    setState(() => _isResending = true);

    final result = await _authService.sendEmailVerification();

    setState(() => _isResending = false);

    if (mounted) {
      if (result == null) {
        // 成功
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('認証メールを再送信しました'),
            backgroundColor: Colors.green,
          ),
        );
        
        // クールダウン開始（60秒）
        setState(() => _resendCooldown = 60);
        _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _resendCooldown--;
            if (_resendCooldown <= 0) {
              timer.cancel();
            }
          });
        });
      } else {
        // エラー
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// ログアウト処理
  Future<void> _logout() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final email = user?.email ?? '';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // アイコン
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mail_outline,
                    size: 64,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 32),

                // タイトル
                Text(
                  'メールアドレスの認証',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF8E1728),
                  ),
                ),
                const SizedBox(height: 16),

                // 説明文
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Text(
                          '認証メールを送信しました',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          email,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '上記のメールアドレスに認証メールを送信しました。\nメール内のリンクをクリックして認証を完了してください。',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 進行状況インジケーター
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '認証待機中...',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 再送信ボタン
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: (_isResending || _resendCooldown > 0) 
                      ? null 
                      : _resendVerificationEmail,
                    icon: const Icon(Icons.refresh),
                    label: Text(
                      _resendCooldown > 0
                        ? '再送信可能まで $_resendCooldown 秒'
                        : 'メールを再送信',
                    ),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ログアウトボタン
                TextButton(
                  onPressed: _logout,
                  child: const Text(
                    'ログアウトして戻る',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 24),

                // 迷惑メール警告
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '重要: 迷惑メールフォルダもご確認ください',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ヘルプテキスト
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'メールが届かない場合',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• 迷惑メール/プロモーションフォルダを確認\n'
                        '• noreply@experiment-cooperation-app.firebaseapp.com を\n'
                        '  連絡先に追加してから再送信\n'
                        '• メールアドレスが正しいか確認\n'
                        '• 数分待ってから再送信してください',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}