import 'package:flutter/material.dart';
import '../models/app_user.dart';

/// メッセージテンプレートのデータクラス
class MessageTemplate {
  final String title;
  final String template;
  final IconData icon;
  final Color color;

  const MessageTemplate({
    required this.title,
    required this.template,
    required this.icon,
    required this.color,
  });
}

/// メッセージテンプレート選択ウィジェット
class MessageTemplatesSheet extends StatelessWidget {
  final String? experimentTitle;
  final String? otherUserName;
  final AppUser? currentUser;
  final Function(String) onTemplateSelected;

  const MessageTemplatesSheet({
    super.key,
    this.experimentTitle,
    this.otherUserName,
    this.currentUser,
    required this.onTemplateSelected,
  });

  List<MessageTemplate> _getTemplates() {
    final experiment = experimentTitle ?? '[実験名]';
    final userName = otherUserName ?? '実験者';
    
    // ユーザー情報から自己紹介文を構築
    String userInfo = '[お名前]';
    String affiliation = '';
    
    if (currentUser != null) {
      userInfo = currentUser!.name;
      
      // 所属情報を構築
      if (currentUser!.isWasedaUser) {
        affiliation = '早稲田大学';
        if (currentUser!.department != null) {
          affiliation += currentUser!.department!;
        }
        if (currentUser!.grade != null) {
          affiliation += currentUser!.grade!;
        }
        affiliation += 'の';
      }
    }
    
    return [
      MessageTemplate(
        title: 'フォーマルな自己紹介',
        template: 'お世話になっております。\n'
            '$affiliation$userInfoと申します。\n\n'
            '「$experiment」の実験を拝見し、大変興味を持ちました。\n'
            'ぜひ参加させていただきたく、ご連絡差し上げました。\n\n'
            '実験の詳細について、いくつかお伺いしたいことがございます。\n'
            'お忙しいところ恐れ入りますが、ご教示いただけますと幸いです。\n\n'
            'どうぞよろしくお願いいたします。',
        icon: Icons.person_outline,
        color: const Color(0xFF8E1728),
      ),
      MessageTemplate(
        title: '実験についての質問',
        template: 'お世話になっております。$userInfoです。\n\n'
            '「$experiment」の実験について、以下の点をお伺いできますでしょうか。\n\n'
            '1. \n'
            '2. \n\n'
            'お手数をおかけしますが、ご回答いただけますと幸いです。\n'
            'よろしくお願いいたします。',
        icon: Icons.help_outline,
        color: Colors.orange,
      ),
      MessageTemplate(
        title: '日程調整のご相談',
        template: 'お世話になっております。$userInfoです。\n\n'
            '「$experiment」の実験に参加させていただきたく存じます。\n\n'
            '私の参加可能な日時は以下の通りです：\n'
            '・\n'
            '・\n\n'
            '上記の中でご都合のよろしい日時はございますでしょうか。\n'
            'ご検討のほど、よろしくお願いいたします。',
        icon: Icons.calendar_today,
        color: Colors.green,
      ),
      MessageTemplate(
        title: '参加条件の確認',
        template: 'お世話になっております。$userInfoです。\n\n'
            '「$experiment」の実験への参加を検討しております。\n'
            '参加条件について、以下の点を確認させていただけますでしょうか。\n\n'
            '・\n\n'
            'ご確認のほど、よろしくお願いいたします。',
        icon: Icons.checklist,
        color: Colors.purple,
      ),
      MessageTemplate(
        title: '場所・アクセスの確認',
        template: 'お世話になっております。$userInfoです。\n\n'
            '「$experiment」の実験会場へのアクセスについて、\n'
            '詳細を教えていただけますでしょうか。\n\n'
            '最寄り駅からの道順など、ご教示いただけますと助かります。\n'
            'よろしくお願いいたします。',
        icon: Icons.location_on,
        color: Colors.red,
      ),
      MessageTemplate(
        title: '実験後のお礼',
        template: 'お世話になっております。$userInfoです。\n\n'
            '先日は「$experiment」の実験でお世話になり、\n'
            '誠にありがとうございました。\n\n'
            '貴重な経験をさせていただき、大変勉強になりました。\n'
            '今後ともどうぞよろしくお願いいたします。',
        icon: Icons.favorite,
        color: Colors.pink,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final templates = _getTemplates();
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // ハンドル
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // タイトル
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(
                  Icons.text_snippet,
                  color: Color(0xFF8E1728),
                ),
                const SizedBox(width: 8),
                const Text(
                  'メッセージテンプレート',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // テンプレートリスト
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: templates.length,
              itemBuilder: (context, index) {
                final template = templates[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  elevation: 1,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: template.color.withValues(alpha: 0.2),
                      child: Icon(
                        template.icon,
                        color: template.color,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      template.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      template.template,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey,
                    ),
                    onTap: () {
                      onTemplateSelected(template.template);
                      Navigator.pop(context);
                    },
                  ),
                );
              },
            ),
          ),
          // 注意書き
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'テンプレートは編集可能です。送信前に内容をご確認ください。',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
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

/// 初回メッセージの案内ウィジェット
class FirstMessageGuide extends StatefulWidget {
  final VoidCallback onShowTemplates;

  const FirstMessageGuide({
    super.key,
    required this.onShowTemplates,
  });

  @override
  State<FirstMessageGuide> createState() => _FirstMessageGuideState();
}

class _FirstMessageGuideState extends State<FirstMessageGuide>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _arrowAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _arrowAnimation = Tween<double>(
      begin: 0,
      end: 20,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 上部のメッセージ
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(
                Icons.waving_hand,
                color: Color(0xFF8E1728),
                size: 40,
              ),
              const SizedBox(height: 12),
              const Text(
                'まずはテンプレートから\n始めましょう',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'フォーマルな自己紹介文を\n簡単に作成できます',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // 矢印アニメーション
        AnimatedBuilder(
          animation: _arrowAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _arrowAnimation.value),
              child: Column(
                children: [
                  Icon(
                    Icons.arrow_downward,
                    color: const Color(0xFF8E1728).withValues(alpha: 0.6),
                    size: 32,
                  ),
                  Icon(
                    Icons.arrow_downward,
                    color: const Color(0xFF8E1728).withValues(alpha: 0.4),
                    size: 32,
                  ),
                  Icon(
                    Icons.arrow_downward,
                    color: const Color(0xFF8E1728).withValues(alpha: 0.2),
                    size: 32,
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        
        // 下部の説明
        Text(
          '左下のボタンを押してください',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}