import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/constants.dart';

/// 支援・開発依頼画面
class SupportDonationScreen extends StatelessWidget {
  const SupportDonationScreen({super.key});

  /// 外部URLを開く
  Future<void> _launchUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    
    // 外部サイトへの移動を確認
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('外部サイトへ移動'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(AppConstants.externalLinkWarning),
            const SizedBox(height: 8),
            Text(
              url,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('移動する'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('URLを開けませんでした'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('エラーが発生しました: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('支援・開発のご依頼'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 支援セクション
            Container(
              color: const Color(0xFF8E1728).withValues(alpha: 0.05),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.favorite,
                    size: 48,
                    color: Color(0xFF8E1728),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'サービス運営への支援',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    AppConstants.donationMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _launchUrl(context, AppConstants.payPayDonationUrl),
                        icon: const Icon(Icons.payment),
                        label: const Text('PayPayで支援'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00B900),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => _launchUrl(context, AppConstants.githubSponsorsUrl),
                        icon: const Icon(Icons.code),
                        label: const Text('GitHub'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 開発依頼セクション
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.code,
                        size: 32,
                        color: Color(0xFF8E1728),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        '開発のご依頼',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    AppConstants.developmentServiceMessage,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // サービス内容カード
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '承っている開発案件',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildServiceItem(
                            Icons.science,
                            '研究用システムの開発',
                            '実験管理、データ収集、分析ツールなど',
                          ),
                          _buildServiceItem(
                            Icons.work,
                            '就活用マイページの作成',
                            'ポートフォリオサイト、自己PR用Webページなど',
                          ),
                          _buildServiceItem(
                            Icons.web,
                            'Webアプリケーション開発',
                            'Webサービス、管理画面、APIの構築など',
                          ),
                          _buildServiceItem(
                            Icons.phone_android,
                            'モバイルアプリ開発',
                            'iOS/Android対応のネイティブ・クロスプラットフォームアプリ',
                          ),
                          _buildServiceItem(
                            Icons.more_horiz,
                            'その他の開発案件',
                            'お客様のニーズに合わせた柔軟な対応が可能です',
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // お問い合わせボタン
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _launchUrl(context, AppConstants.developmentRequestFormUrl),
                      icon: const Icon(Icons.mail_outline),
                      label: const Text(
                        '開発のご相談・お見積もり（無料）',
                        style: TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8E1728),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // 注意事項
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: Colors.blue[700],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'お問い合わせフォームは外部サイト（Googleフォーム）へ移動します。'
                            'ご相談・お見積もりは無料です。お気軽にお問い合わせください。',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // フッター
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Divider(),
                  const SizedBox(height: 12),
                  Text(
                    '© 2024 ${AppConstants.teamName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'わせラボは早稲田大学の公式サービスではありません',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 24,
            color: const Color(0xFF8E1728),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}