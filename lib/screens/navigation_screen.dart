import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'my_page_screen.dart';
import 'messages_screen.dart';
import 'settings_screen.dart';
import '../services/message_service.dart';
import '../services/auth_service.dart';
import '../services/experiment_service.dart';
import '../services/user_service.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  int _selectedIndex = 0;
  final MessageService _messageService = MessageService();
  final AuthService _authService = AuthService();
  final ExperimentService _experimentService = ExperimentService();
  final UserService _userService = UserService();
  int _unreadCount = 0;
  int _pendingEvaluations = 0; // 未評価の実験数

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreen(),
      const MessagesScreen(),
      MyPageScreen(key: UniqueKey()), // UniqueKeyで再構築を強制
    ];
    _loadUnreadCount();
    _loadPendingEvaluations();
  }

  Future<void> _loadUnreadCount() async {
    final user = _authService.currentUser;
    if (user != null) {
      final count = await _messageService.getUnreadMessageCount(user.uid);
      if (mounted) {
        setState(() {
          _unreadCount = count;
        });
      }
    }
  }

  Future<void> _loadPendingEvaluations() async {
    try {
      final user = await _authService.getCurrentAppUser();
      if (user == null) return;

      // 参加した実験を取得
      final participatedExperiments = await _experimentService.getUserParticipatedExperiments(user.uid);
      
      // 作成した実験を取得
      final createdExperiments = await _experimentService.getUserCreatedExperiments(user.uid);
      
      // 未評価の実験数をカウント
      int count = 0;
      for (final exp in participatedExperiments) {
        if (!exp.hasEvaluated(user.uid)) {
          count++;
        }
      }
      for (final exp in createdExperiments) {
        if (!exp.hasEvaluated(user.uid)) {
          count++;
        }
      }
      
      if (mounted) {
        setState(() {
          _pendingEvaluations = count;
        });
      }
    } catch (e) {
      debugPrint('Error loading pending evaluations: $e');
    }
  }

  void _openSettings() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
    
    // 設定画面から「お問い合わせ」を開く指示があった場合
    if (result == 'open_support' && mounted) {
      setState(() {
        _selectedIndex = 1; // メッセージ画面に切り替え
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    if (isSmallScreen) {
      return Scaffold(
        appBar: _selectedIndex == 0 ? AppBar(
          title: const Text('わせラボ'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _openSettings,
            ),
          ],
        ) : null,
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
                // マイページに遷移したら画面を再構築して最新状態を表示
                _screens[2] = MyPageScreen(key: UniqueKey());
                _loadPendingEvaluations(); // 評価状態を更新
              }
            });
            if (index == 1) {
              _loadUnreadCount();
            }
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
                label: Text('$_pendingEvaluations'),
                backgroundColor: Colors.orange,
                isLabelVisible: _pendingEvaluations > 0,
                child: const Icon(Icons.person_outline),
              ),
              selectedIcon: Badge(
                label: Text('$_pendingEvaluations'),
                backgroundColor: Colors.orange,
                isLabelVisible: _pendingEvaluations > 0,
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
                    // マイページに遷移したら画面を再構築
                    _screens[2] = MyPageScreen(key: UniqueKey());
                    _loadPendingEvaluations(); // 評価状態を更新
                  }
                });
                if (index == 1) {
                  _loadUnreadCount();
                }
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
                    label: Text('$_pendingEvaluations'),
                    backgroundColor: Colors.orange,
                    isLabelVisible: _pendingEvaluations > 0,
                    child: const Icon(Icons.person_outline),
                  ),
                  selectedIcon: Badge(
                    label: Text('$_pendingEvaluations'),
                    backgroundColor: Colors.orange,
                    isLabelVisible: _pendingEvaluations > 0,
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