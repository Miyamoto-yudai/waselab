import 'package:flutter/material.dart';
import 'home_screen_demo.dart';
import 'my_page_screen_demo.dart';
import 'messages_screen_demo.dart';
import '../services/demo_auth_service.dart';

/// デモモード用のナビゲーション画面
/// 重要: main_demo.dartで使用されるデモ版画面です
class NavigationScreenDemo extends StatefulWidget {
  final DemoAuthService authService;
  final VoidCallback onLogout;

  const NavigationScreenDemo({
    super.key,
    required this.authService,
    required this.onLogout,
  });

  @override
  State<NavigationScreenDemo> createState() => _NavigationScreenDemoState();
}

class _NavigationScreenDemoState extends State<NavigationScreenDemo> {
  int _selectedIndex = 0;
  final int _unreadCount = 3; // デモ用の固定値
  int _activityNotifications = 2; // デモ用の活動通知数

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreenDemo(
        authService: widget.authService,
        onLogout: widget.onLogout,
      ),
      MessagesScreenDemo(authService: widget.authService),
      MyPageScreenDemo(
        authService: widget.authService,
        onLogout: widget.onLogout,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    if (isSmallScreen) {
      return Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() {
              _selectedIndex = index;
              if (index == 2) {
                // マイページに遷移したら通知をクリア
                _activityNotifications = 0;
              }
            });
          },
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFF8E1728).withValues(alpha: 0.2),
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: Color(0xFF8E1728)),
              label: 'ホーム',
            ),
            NavigationDestination(
              icon: Badge(
                label: Text('$_unreadCount'),
                isLabelVisible: _unreadCount > 0,
                child: const Icon(Icons.message_outlined),
              ),
              selectedIcon: Badge(
                label: Text('$_unreadCount'),
                isLabelVisible: _unreadCount > 0,
                child: const Icon(Icons.message, color: Color(0xFF8E1728)),
              ),
              label: 'メッセージ',
            ),
            NavigationDestination(
              icon: Badge(
                label: Text('$_activityNotifications'),
                isLabelVisible: _activityNotifications > 0,
                child: const Icon(Icons.person_outline),
              ),
              selectedIcon: Badge(
                label: Text('$_activityNotifications'),
                isLabelVisible: _activityNotifications > 0,
                child: const Icon(Icons.person, color: Color(0xFF8E1728)),
              ),
              label: 'マイページ',
            ),
          ],
        ),
      );
    } else {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                  if (index == 2) {
                    // マイページに遷移したら通知をクリア
                    _activityNotifications = 0;
                  }
                });
              },
              backgroundColor: Colors.white,
              indicatorColor: const Color(0xFF8E1728).withValues(alpha: 0.2),
              labelType: NavigationRailLabelType.all,
              destinations: [
                const NavigationRailDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home, color: Color(0xFF8E1728)),
                  label: Text('ホーム'),
                ),
                NavigationRailDestination(
                  icon: Badge(
                    label: Text('$_unreadCount'),
                    isLabelVisible: _unreadCount > 0,
                    child: const Icon(Icons.message_outlined),
                  ),
                  selectedIcon: Badge(
                    label: Text('$_unreadCount'),
                    isLabelVisible: _unreadCount > 0,
                    child: const Icon(Icons.message, color: Color(0xFF8E1728)),
                  ),
                  label: const Text('メッセージ'),
                ),
                NavigationRailDestination(
                  icon: Badge(
                    label: Text('$_activityNotifications'),
                    isLabelVisible: _activityNotifications > 0,
                    child: const Icon(Icons.person_outline),
                  ),
                  selectedIcon: Badge(
                    label: Text('$_activityNotifications'),
                    isLabelVisible: _activityNotifications > 0,
                    child: const Icon(Icons.person, color: Color(0xFF8E1728)),
                  ),
                  label: const Text('マイページ'),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: _screens[_selectedIndex],
            ),
          ],
        ),
      );
    }
  }
}