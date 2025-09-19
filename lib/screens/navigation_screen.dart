import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'my_page_screen.dart';
import 'messages_screen.dart';
import 'settings_screen.dart';
import 'notification_screen.dart';
import 'history_screen.dart';
import '../services/message_service.dart';
import '../services/auth_service.dart';
import '../services/experiment_service.dart';
import '../services/user_service.dart';
import '../services/notification_service.dart';
import '../services/admin_service.dart';
import '../models/app_user.dart';
import 'support_donation_screen.dart';
import 'admin/admin_dashboard_screen.dart';

class NavigationScreen extends StatefulWidget {
  
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => NavigationScreenState();
}

class NavigationScreenState extends State<NavigationScreen> {
  int _selectedIndex = 0;
  final MessageService _messageService = MessageService();
  final AuthService _authService = AuthService();
  final ExperimentService _experimentService = ExperimentService();
  final UserService _userService = UserService();
  final NotificationService _notificationService = NotificationService();
  final AdminService _adminService = AdminService();
  int _unreadCount = 0;
  int _pendingEvaluations = 0; // 未評価の実験数
  int _pendingSurveys = 0; // 未送信の事後アンケート数
  int _unreadNotifications = 0; // 未読通知数
  AppUser? _currentUser;
  bool _hasAdminPrivileges = false;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreen(),
      const MessagesScreen(),
      const NotificationScreen(),
      const HistoryScreen(),
      MyPageScreen(key: UniqueKey()), // UniqueKeyで再構築を強制
      const SupportDonationScreen(),
    ];
    _loadUnreadCount();
    _loadPendingEvaluations();
    _loadPendingSurveys();
    _loadUnreadNotifications();
    _loadCurrentUser();
    // 管理者権限チェックを遅延実行（画面が完全に読み込まれ、認証状態が安定した後）
    // より長い遅延にすることで、Firebase Authの状態に影響を与えないようにする
    // 特にメール認証の場合、認証状態の復元に時間がかかることがある
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _checkAdminPrivileges();
      }
    });
    _setupRealtimeListeners();
  }

  Future<void> _checkAdminPrivileges() async {
    try {
      // 現在のユーザーが存在することを確認
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        if (mounted) {
          setState(() {
            _hasAdminPrivileges = false;
          });
        }
        return;
      }

      // 管理者権限チェック（エラーハンドリング強化済み）
      final hasAdmin = await _adminService.hasAdminPrivileges();
      if (mounted) {
        setState(() {
          _hasAdminPrivileges = hasAdmin;
        });
      }
    } catch (e) {
      // エラーが発生した場合は管理者権限なしとして扱う
      if (mounted) {
        setState(() {
          _hasAdminPrivileges = false;
        });
      }
    }
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

  Future<void> _loadUnreadNotifications() async {
    final user = _authService.currentUser;
    if (user != null) {
      final count = await _notificationService.getUnreadNotificationCount(user.uid);
      if (mounted) {
        setState(() {
          _unreadNotifications = count;
        });
      }
    }
  }

  Future<void> _loadPendingEvaluations() async {
    try {
      final user = await _authService.getCurrentAppUser();
      if (user == null) return;

      // 参加した実験の評価待ち数を取得（実施前は除外）
      final participatedExperiments = await _experimentService.getUserParticipatedExperiments(user.uid);
      int participatedUnevaluated = 0;
      for (final exp in participatedExperiments) {
        if (exp.canEvaluate(user.uid) && 
            !exp.hasEvaluated(user.uid) &&
            !exp.isScheduledFuture(user.uid)) {
          participatedUnevaluated++;
        }
      }
      
      // 作成した実験の未評価参加者数を取得（実施前は除外）
      final createdExperiments = await _experimentService.getUserCreatedExperiments(user.uid);
      int createdUnevaluated = 0;
      for (final exp in createdExperiments) {
        // 参加者ごとの評価状態をチェック
        for (final participantId in exp.participants) {
          final participantEvals = exp.participantEvaluations ?? {};
          final participantEval = participantEvals[participantId] ?? {};
          final creatorEvaluated = participantEval['creatorEvaluated'] ?? false;
          
          // 実験者による評価が済んでいない、かつ実験が実施前でない場合のみカウント
          if (!creatorEvaluated && !exp.isScheduledFuture(participantId)) {
            createdUnevaluated++;
          }
        }
      }
      
      // 合計（参加した実験の評価待ち + 作成した実験の未評価参加者数）
      final totalCount = participatedUnevaluated + createdUnevaluated;
      
      if (mounted) {
        setState(() {
          _pendingEvaluations = totalCount;
        });
      }
    } catch (e) {
    }
  }

  Future<void> _loadPendingSurveys() async {
    try {
      final user = await _authService.getCurrentAppUser();
      if (user == null) return;

      // 作成した実験の事後アンケート未送信数を取得
      final createdExperiments = await _experimentService.getUserCreatedExperiments(user.uid);
      int pendingSurveyCount = 0;

      for (final exp in createdExperiments) {
        // 事後アンケートURLが設定されている実験のみチェック
        if (exp.postSurveyUrl != null && exp.postSurveyUrl!.isNotEmpty) {
          // 参加者ごとの送信状態をチェック
          for (final participantId in exp.participants) {
            final participantEvals = exp.participantEvaluations ?? {};
            final participantEval = participantEvals[participantId] ?? {};
            final postSurveyUrlSent = participantEval['postSurveyUrlSent'] ?? false;

            // 事後アンケートが未送信の場合のみカウント
            if (!postSurveyUrlSent) {
              pendingSurveyCount++;
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _pendingSurveys = pendingSurveyCount;
        });
      }
    } catch (e) {
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
  
  Future<void> _loadCurrentUser() async {
    final user = await _authService.getCurrentAppUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
    }
  }
  
  void setSelectedIndex(int index) {
    if (mounted) {
      setState(() {
        _selectedIndex = index;
        if (index == 4) {
          // マイページに遷移したら画面を再構築して最新状態を表示
          _screens[4] = MyPageScreen(key: UniqueKey());
          _loadPendingEvaluations(); // 評価状態を更新
        }
      });
      if (index == 1) {
        _loadUnreadCount();
      } else if (index == 3) {
        // 履歴画面に遷移したら再構築して最新状態を表示
        _screens[3] = const HistoryScreen();
      }
    }
  }

  void _setupRealtimeListeners() {
    final user = _authService.currentUser;
    if (user == null) return;

    // メッセージの未読数をリアルタイムで監視
    _messageService.streamUnreadMessageCount(user.uid).listen((count) {
      if (mounted) {
        setState(() {
          _unreadCount = count;
        });
      }
    });

    // 通知の未読数をリアルタイムで監視
    _notificationService.streamUnreadNotificationCount(user.uid).listen((count) {
      if (mounted) {
        setState(() {
          _unreadNotifications = count;
        });
      }
    });

    // 評価待ちと事後アンケート未送信数を定期的に更新（5秒ごと）
    Stream.periodic(const Duration(seconds: 5)).listen((_) {
      if (mounted) {
        _loadPendingEvaluations();
        _loadPendingSurveys();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    if (isSmallScreen) {
      return Scaffold(
        appBar: _hasAdminPrivileges && _selectedIndex == 0
            ? AppBar(
                backgroundColor: Colors.black87,
                title: const Text(
                  'ユーザーモード',
                  style: TextStyle(fontSize: 14),
                ),
                actions: [
                  TextButton.icon(
                    onPressed: () {
                      // 管理者モードをONにして管理者画面へ
                      _adminService.setAdminMode(true);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminDashboardScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.admin_panel_settings, color: Colors.red),
                    label: const Text(
                      '管理者画面へ',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              )
            : null,
        body: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
        bottomNavigationBar: Theme(
          data: Theme.of(context).copyWith(
            navigationBarTheme: NavigationBarThemeData(
              labelTextStyle: WidgetStateProperty.all(
                const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          child: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
                if (index == 4) {
                  // マイページに遷移したら画面を再構築して最新状態を表示
                  _screens[4] = MyPageScreen(key: UniqueKey());
                  _loadPendingEvaluations(); // 評価状態を更新
                  _loadPendingSurveys(); // アンケート送信状態を更新
                }
              });
              if (index == 1) {
                _loadUnreadCount();
              } else if (index == 3) {
                // 履歴画面に遷移したら再構築して最新状態を表示
                _screens[3] = const HistoryScreen();
              }
            },
            backgroundColor: Colors.white,
            indicatorColor: const Color(0xFF8E1728).withValues(alpha: 0.2),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
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
                alignment: AlignmentDirectional.topEnd,
                child: const Icon(Icons.message_outlined),
              ),
              selectedIcon: Badge(
                label: Text('$_unreadCount'),
                isLabelVisible: _unreadCount > 0,
                alignment: AlignmentDirectional.topEnd,
                child: const Icon(Icons.message, color: Color(0xFF8E1728)),
              ),
              label: 'メッセージ',
            ),
            NavigationDestination(
              icon: Badge(
                label: Text('$_unreadNotifications'),
                isLabelVisible: _unreadNotifications > 0,
                alignment: AlignmentDirectional.topEnd,
                child: const Icon(Icons.notifications_outlined),
              ),
              selectedIcon: Badge(
                label: Text('$_unreadNotifications'),
                isLabelVisible: _unreadNotifications > 0,
                alignment: AlignmentDirectional.topEnd,
                child: const Icon(Icons.notifications, color: Color(0xFF8E1728)),
              ),
              label: '通知',
            ),
            NavigationDestination(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.history_outlined),
                  if (_pendingEvaluations > 0)
                    Positioned(
                      right: -8,
                      top: -8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 12,
                          minHeight: 12,
                        ),
                        child: Text(
                          '$_pendingEvaluations',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  if (_pendingSurveys > 0)
                    Positioned(
                      left: -8,
                      top: -8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 12,
                          minHeight: 12,
                        ),
                        child: Text(
                          '$_pendingSurveys',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              selectedIcon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.history, color: Color(0xFF8E1728)),
                  if (_pendingEvaluations > 0)
                    Positioned(
                      right: -8,
                      top: -8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 12,
                          minHeight: 12,
                        ),
                        child: Text(
                          '$_pendingEvaluations',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  if (_pendingSurveys > 0)
                    Positioned(
                      left: -8,
                      top: -8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 12,
                          minHeight: 12,
                        ),
                        child: Text(
                          '$_pendingSurveys',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              label: '履歴',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: Color(0xFF8E1728)),
              label: 'マイページ',
            ),
            const NavigationDestination(
              icon: Icon(Icons.favorite_outline),
              selectedIcon: Icon(Icons.favorite, color: Color(0xFF8E1728)),
              label: '支援・依頼',
            ),
          ],
          ),
        ),
      );
    } else {
      return Scaffold(
        appBar: _hasAdminPrivileges
            ? AppBar(
                backgroundColor: Colors.black87,
                title: const Text(
                  'ユーザーモード',
                  style: TextStyle(fontSize: 14),
                ),
                actions: [
                  TextButton.icon(
                    onPressed: () {
                      // 管理者モードをONにして管理者画面へ
                      _adminService.setAdminMode(true);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminDashboardScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.admin_panel_settings, color: Colors.red),
                    label: const Text(
                      '管理者画面へ',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              )
            : null,
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                  if (index == 4) {
                    // マイページに遷移したら画面を再構築
                    _screens[4] = MyPageScreen(key: UniqueKey());
                    _loadPendingEvaluations(); // 評価状態を更新
                    _loadPendingSurveys(); // アンケート送信状態を更新
                  }
                });
                if (index == 1) {
                  _loadUnreadCount();
                } else if (index == 2) {
                  // 通知画面に遷移したら未読数を更新
                  _loadUnreadNotifications();
                } else if (index == 3) {
                  // 履歴画面に遷移したら再構築して最新状態を表示
                  _screens[3] = const HistoryScreen();
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
                    label: Text('$_unreadNotifications'),
                    isLabelVisible: _unreadNotifications > 0,
                    child: const Icon(Icons.notifications_outlined),
                  ),
                  selectedIcon: Badge(
                    label: Text('$_unreadNotifications'),
                    isLabelVisible: _unreadNotifications > 0,
                    child: const Icon(Icons.notifications, color: Color(0xFF8E1728)),
                  ),
                  label: const Text('通知'),
                ),
                NavigationRailDestination(
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.history_outlined),
                      if (_pendingEvaluations > 0)
                        Positioned(
                          right: -8,
                          top: -8,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 12,
                              minHeight: 12,
                            ),
                            child: Text(
                              '$_pendingEvaluations',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      if (_pendingSurveys > 0)
                        Positioned(
                          left: -8,
                          top: -8,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 12,
                              minHeight: 12,
                            ),
                            child: Text(
                              '$_pendingSurveys',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  selectedIcon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.history, color: Color(0xFF8E1728)),
                      if (_pendingEvaluations > 0)
                        Positioned(
                          right: -8,
                          top: -8,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 12,
                              minHeight: 12,
                            ),
                            child: Text(
                              '$_pendingEvaluations',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      if (_pendingSurveys > 0)
                        Positioned(
                          left: -8,
                          top: -8,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 12,
                              minHeight: 12,
                            ),
                            child: Text(
                              '$_pendingSurveys',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  label: const Text('履歴'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person, color: Color(0xFF8E1728)),
                  label: Text('マイページ'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.favorite_outline),
                  selectedIcon: Icon(Icons.favorite, color: Color(0xFF8E1728)),
                  label: Text('支援・依頼'),
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