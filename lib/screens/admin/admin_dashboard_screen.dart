import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../utils/create_test_data.dart';
import '../../utils/create_test_data_fixed.dart';
import '../test_debug_screen.dart';
import 'admin_user_management_screen.dart';
import 'admin_chat_monitor_screen.dart';
import 'admin_support_message_screen.dart';
import 'admin_announcement_screen.dart';
import 'admin_support_chat_management_screen_v2.dart';
import '../login_screen.dart';
import '../navigation_screen.dart';

/// 管理者ダッシュボード画面
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  Map<String, dynamic> _statistics = {};
  bool _isLoading = true;
  int _unreadSupportMessages = 0;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _loadStatistics();
    _listenToUnreadMessages();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _listenToUnreadMessages() {
    _adminService.getUnreadSupportMessageCount().listen((count) {
      if (mounted) {
        setState(() {
          _unreadSupportMessages = count;
        });
        // 新着メッセージがある場合はアニメーションを開始
        if (count > 0) {
          _animationController.repeat(reverse: true);
        } else {
          _animationController.stop();
        }
      }
    });
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);
    
    final stats = await _adminService.getStatistics();
    
    if (mounted) {
      setState(() {
        _statistics = stats;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text(
          'ログアウト',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '管理者コンソールからログアウトしますか？',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('ログアウト'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _adminService.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('管理者ダッシュボード'),
        actions: [
          // ユーザー画面切り替えボタン
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              // 管理者モードをOFFにしてユーザー画面へ
              _adminService.setAdminMode(false);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const NavigationScreen(),
                ),
              );
            },
            tooltip: 'ユーザー画面へ切り替え',
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TestDebugScreen()),
              );
            },
            tooltip: 'デバッグツール',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatistics,
            tooltip: '統計を更新',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'ログアウト',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStatistics,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ようこそメッセージ
                    Card(
                      color: Colors.black87,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.admin_panel_settings,
                              color: Colors.red,
                              size: 32,
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ようこそ、管理者様',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '管理者権限でログイン中',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 統計情報
                    Text(
                      '統計情報',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: isSmallScreen ? 1 : 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: isSmallScreen ? 2.5 : 1.5,
                      children: [
                        _buildStatCard(
                          title: '総ユーザー数',
                          value: '${_statistics['totalUsers'] ?? 0}',
                          icon: Icons.people,
                          color: Colors.blue,
                          isSmallScreen: isSmallScreen,
                        ),
                        _buildStatCard(
                          title: 'アクティブユーザー',
                          value: '${_statistics['activeUsers'] ?? 0}',
                          subtitle: '(30日以内)',
                          icon: Icons.trending_up,
                          color: Colors.green,
                          isSmallScreen: isSmallScreen,
                        ),
                        _buildStatCard(
                          title: '総実験数',
                          value: '${_statistics['totalExperiments'] ?? 0}',
                          icon: Icons.science,
                          color: Colors.orange,
                          isSmallScreen: isSmallScreen,
                        ),
                        _buildStatCard(
                          title: '今月の新規登録',
                          value: '${_statistics['newUsersThisMonth'] ?? 0}',
                          icon: Icons.person_add,
                          color: Colors.purple,
                          isSmallScreen: isSmallScreen,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // 管理機能メニュー
                    Text(
                      '管理機能',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildMenuCard(
                      title: 'ユーザー管理',
                      subtitle: 'ユーザー情報の閲覧・編集',
                      icon: Icons.supervised_user_circle,
                      color: Colors.blue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminUserManagementScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildMenuCard(
                      title: 'チャット監視',
                      subtitle: '全ユーザーのチャット履歴確認',
                      icon: Icons.chat_bubble,
                      color: Colors.green,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminChatMonitorScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildMenuCard(
                      title: 'サポートチャット管理',
                      subtitle: 'ユーザーからのお問い合わせ対応',
                      icon: Icons.support_agent,
                      color: Colors.teal,
                      hasNotification: _unreadSupportMessages > 0,
                      notificationCount: _unreadSupportMessages,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminSupportChatManagementScreenV2(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildMenuCard(
                      title: 'サポートメッセージ',
                      subtitle: '個別ユーザーへのメッセージ送信',
                      icon: Icons.support_agent,
                      color: Colors.orange,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminSupportMessageScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildMenuCard(
                      title: 'お知らせ配信',
                      subtitle: '全ユーザーへのお知らせ送信',
                      icon: Icons.campaign,
                      color: Colors.purple,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminAnnouncementScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),

                    // クイックアクション
                    Text(
                      'クイックアクション',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              // テストデータ作成確認ダイアログ
                              final option = await showDialog<String>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: Colors.grey[850],
                                  title: const Text(
                                    'テストデータ作成',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: const [
                                      Text(
                                        '作成するテストデータを選択してください：',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        '• サンプル（3件）',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        '  基本的な実験データ',
                                        style: TextStyle(color: Colors.white70, fontSize: 12),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        '• フル（30件）',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        '  多様な実験形式のデータ',
                                        style: TextStyle(color: Colors.white70, fontSize: 12),
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        '実験者は「宮本雄大」で設定されます。',
                                        style: TextStyle(color: Colors.white60, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, null),
                                      child: const Text('キャンセル'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(context, 'sample'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                      ),
                                      child: const Text('3件作成'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(context, 'full'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                      ),
                                      child: const Text('30件作成'),
                                    ),
                                  ],
                                ),
                              );
                              
                              if (option != null) {
                                // ローディング表示
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => Center(
                                    child: Card(
                                      child: Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const CircularProgressIndicator(),
                                            const SizedBox(height: 16),
                                            Text(option == 'sample' 
                                              ? '3件のテストデータを作成中...'
                                              : '30件のテストデータを作成中...'),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                                
                                try {
                                  if (option == 'sample') {
                                    // 修正版を使用（正確に3件のみ作成）
                                    await TestDataCreatorFixed.createExactThreeExperiments();
                                  } else {
                                    await TestDataCreator.createTestExperiments();
                                  }
                                  
                                  if (mounted) {
                                    Navigator.pop(context); // ローディングダイアログを閉じる
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(option == 'sample'
                                          ? '3件のサンプルデータを作成しました！'
                                          : '30件のテストデータを作成しました！'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    _loadStatistics(); // 統計を更新
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    Navigator.pop(context); // ローディングダイアログを閉じる
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('エラー: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                            icon: const Icon(Icons.science),
                            label: const Text('テストデータ'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // TODO: ログ確認機能
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('ログ確認機能は実装予定です'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.description),
                            label: const Text('ログ確認'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color color,
    bool isSmallScreen = false,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: isSmallScreen
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Icon(icon, color: color, size: isSmallScreen ? 28 : 32),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            value,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 20 : 24,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                        const SizedBox(height: 2),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 14,
                            color: Colors.grey[700],
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildMenuCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool hasNotification = false,
    int notificationCount = 0,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (hasNotification)
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) => Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        notificationCount > 99 ? '99+' : notificationCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}