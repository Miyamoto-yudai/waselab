import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/fcm_service.dart';
import 'login_screen.dart';
import 'support_chat_screen.dart';
import 'support_donation_screen.dart';

/// 設定画面
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  final FCMService _fcmService = FCMService();
  
  // 通知設定
  bool _experimentNotifications = true;
  bool _messageNotifications = true;
  bool _emailNotifications = false;
  
  /// ログアウト処理
  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ログアウト'),
        content: const Text('ログアウトしてもよろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ログアウト', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _authService.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }
  
  /// お問い合わせを開く
  void _openSupport() {
    // サポートチャット画面に遷移
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SupportChatScreen()),
    );
  }
  
  /// 利用規約を開く
  void _openTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('利用規約'),
        content: const SingleChildScrollView(
          child: Text(
            'わせラボ利用規約\n\n'
            '【重要事項】\n'
            '本アプリケーション「わせラボ」は、早稲田大学の公式アプリケーションではなく、'
            '学生有志により開発・運営されている非公式サービスです。\n\n'
            '第1条（利用規約の適用）\n'
            '本利用規約は、早稲田大学実験協力プラットフォーム「わせラボ」の利用に関する条件を定めるものです。\n\n'
            '第2条（利用資格）\n'
            '本サービスは早稲田大学の学生、教職員、および一般の方にご利用いただけます。\n\n'
            '第3条（禁止事項）\n'
            '・虚偽の情報を登録すること\n'
            '・他者になりすますこと\n'
            '・実験の妨害行為\n'
            '・その他運営が不適切と判断する行為\n\n'
            '第4条（個人情報の取扱い）\n'
            'プライバシーポリシーに従って適切に管理いたします。\n\n'
            '第5条（免責事項）\n'
            '本サービスは有志により提供されており、早稲田大学は本サービスに関する一切の責任を負いません。',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
  
  /// プライバシーポリシーを開く
  void _openPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('プライバシーポリシー'),
        content: const SingleChildScrollView(
          child: Text(
            'プライバシーポリシー\n\n'
            '1. 個人情報の収集\n'
            '実験参加に必要な情報（氏名、メールアドレス、学部学科等）を収集します。\n\n'
            '2. 個人情報の利用目的\n'
            '・実験の円滑な実施\n'
            '・参加者と実験者の連絡\n'
            '・サービスの改善\n\n'
            '3. 個人情報の第三者提供\n'
            '法令に基づく場合を除き、本人の同意なく第三者に提供することはありません。\n\n'
            '4. 個人情報の管理\n'
            '適切なセキュリティ対策を講じて管理します。\n\n'
            '5. Firebaseの利用\n'
            '本アプリはFirebaseを利用しており、以下の情報を自動的に収集します：\n'
            '・利用状況データ（Firebase Analytics）\n'
            '・クラッシュレポート（Firebase Crashlytics）\n'
            'これらのデータはGoogleのサーバーに保存されます。\n\n'
            '6. 外部サービスへのリンク\n'
            '本アプリには外部サービスへのリンクが含まれています。\n'
            '外部サイトのプライバシーポリシーについては各サービスをご確認ください。',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: ListView(
        children: [
          // 通知設定セクション
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              '通知設定',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('実験に関する通知'),
                  subtitle: const Text('新しい実験募集、参加実験の更新など'),
                  value: _experimentNotifications,
                  onChanged: (value) {
                    setState(() {
                      _experimentNotifications = value;
                    });
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('メッセージ通知'),
                  subtitle: const Text('新着メッセージの通知'),
                  value: _messageNotifications,
                  onChanged: (value) {
                    setState(() {
                      _messageNotifications = value;
                    });
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('メール通知'),
                  subtitle: const Text('重要なお知らせをメールで受け取る'),
                  value: _emailNotifications,
                  onChanged: (value) {
                    setState(() {
                      _emailNotifications = value;
                    });
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.notifications_active),
                  title: const Text('プッシュ通知テスト'),
                  subtitle: const Text('プッシュ通知が正常に動作するかテストします'),
                  trailing: const Icon(Icons.send),
                  onTap: () async {
                    try {
                      await _fcmService.sendTestNotification();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('テスト通知を送信しました'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('通知の送信に失敗しました: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // アカウント設定セクション
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'アカウント',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('パスワード変更'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final email = _authService.currentUser?.email;
                    if (email != null) {
                      final result = await _authService.sendPasswordResetEmail(email);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result ?? 'パスワードリセットメールを送信しました'),
                            backgroundColor: result == null ? Colors.green : Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('アカウント削除', style: TextStyle(color: Colors.red)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.red),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('アカウント削除'),
                        content: const Text(
                          'アカウントを削除すると、すべてのデータが失われます。\n'
                          'この操作は取り消すことができません。\n\n'
                          '本当に削除しますか？',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('キャンセル'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('アカウント削除機能は現在準備中です'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            },
                            child: const Text('削除', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // サポートセクション
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'サポート',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('ヘルプ'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('ヘルプ'),
                        content: const Text(
                          'わせラボの使い方\n\n'
                          '1. 実験を探す\n'
                          'ホーム画面から興味のある実験を探しましょう。\n\n'
                          '2. 実験に参加\n'
                          '詳細を確認して「参加する」ボタンから申し込みます。\n\n'
                          '3. メッセージで連絡\n'
                          '実験者とメッセージでやり取りできます。\n\n'
                          'お困りの場合は「お問い合わせ」からご連絡ください。',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('閉じる'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.mail_outline),
                  title: const Text('お問い合わせ'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _openSupport,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.volunteer_activism, color: Color(0xFF8E1728)),
                  title: const Text('支援・開発のご依頼'),
                  subtitle: const Text('サービス運営への支援と開発案件のご相談'),
                  trailing: const Icon(Icons.chevron_right, color: Color(0xFF8E1728)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SupportDonationScreen()),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('利用規約'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _openTermsOfService,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('プライバシーポリシー'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _openPrivacyPolicy,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // その他セクション
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'その他',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('バージョン情報'),
                  subtitle: const Text('Version 1.0.0'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'わせラボ',
                      applicationVersion: '1.0.0',
                      applicationIcon: const Icon(
                        Icons.science,
                        size: 48,
                        color: Color(0xFF8E1728),
                      ),
                      children: const [
                        Text(
                          '早稲田大学実験協力プラットフォーム\n\n'
                          '【重要】\n'
                          'このアプリは早稲田大学の公式アプリではありません。\n'
                          '学生有志により開発・運営されています。\n\n'
                          '© 2024 WaseLab Team',
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('ログアウト', style: TextStyle(color: Colors.red)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.red),
                  onTap: _handleLogout,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}