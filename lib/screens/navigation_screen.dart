import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'my_page_screen.dart';
import 'messages_screen.dart';
import '../services/message_service.dart';
import '../services/auth_service.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  int _selectedIndex = 0;
  final MessageService _messageService = MessageService();
  final AuthService _authService = AuthService();
  int _unreadCount = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const MessagesScreen(),
    const MyPageScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
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
            const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: Color(0xFF8E1728)),
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
                const NavigationRailDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person, color: Color(0xFF8E1728)),
                  label: Text('マイページ'),
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