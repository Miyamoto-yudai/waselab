import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../models/avatar_frame.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../widgets/custom_circle_avatar.dart';

/// フレームショップ画面
class FrameShopScreen extends StatefulWidget {
  const FrameShopScreen({super.key});

  @override
  State<FrameShopScreen> createState() => _FrameShopScreenState();
}

class _FrameShopScreenState extends State<FrameShopScreen>
    with TickerProviderStateMixin {
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  
  AppUser? _currentUser;
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _authService.getCurrentAppUser();
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// フレームを購入
  Future<void> _purchaseFrame(AvatarFrame frame) async {
    if (_currentUser == null) return;
    
    // ポイント不足チェック
    if (_currentUser!.points < frame.price) {
      _showInsufficientPointsDialog(frame);
      return;
    }

    // 購入確認ダイアログ
    final confirmed = await _showPurchaseConfirmDialog(frame);
    if (!confirmed) return;

    try {
      setState(() => _isLoading = true);
      
      await _userService.unlockFrame(
        userId: _currentUser!.uid,
        frameId: frame.id,
        cost: frame.price,
      );
      
      // ユーザー情報を再読み込み
      await _loadUserData();
      
      if (mounted) {
        _showPurchaseSuccessDialog(frame);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('購入に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// フレームを装備
  Future<void> _equipFrame(AvatarFrame frame) async {
    if (_currentUser == null) return;

    try {
      setState(() => _isLoading = true);
      
      await _userService.selectFrame(
        userId: _currentUser!.uid,
        frameId: frame.id,
      );
      
      // ユーザー情報を再読み込み
      await _loadUserData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${frame.name}を装備しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('装備に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// ポイント不足ダイアログ
  void _showInsufficientPointsDialog(AvatarFrame frame) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ポイント不足'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${frame.name}の購入には${frame.price}ポイント必要です。'),
            const SizedBox(height: 8),
            Text('現在のポイント: ${_currentUser?.points ?? 0}ポイント'),
            Text('不足: ${frame.price - (_currentUser?.points ?? 0)}ポイント'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lightbulb, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Good評価を獲得してポイントを貯めましょう！',
                      style: TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ],
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

  /// 購入確認ダイアログ
  Future<bool> _showPurchaseConfirmDialog(AvatarFrame frame) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('フレーム購入確認'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomCircleAvatar(
              frameId: frame.id,
              radius: 40,
              backgroundColor: const Color(0xFF8E1728),
              child: const Icon(Icons.person, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              frame.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              frame.description,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.monetization_on, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text(
                    '${frame.price}ポイント',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '残高: ${_currentUser?.points ?? 0} → ${(_currentUser?.points ?? 0) - frame.price}ポイント',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8E1728),
            ),
            child: const Text('購入する'),
          ),
        ],
      ),
    ) ?? false;
  }

  /// 購入成功ダイアログ
  void _showPurchaseSuccessDialog(AvatarFrame frame) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('購入完了'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomCircleAvatar(
              frameId: frame.id,
              radius: 40,
              backgroundColor: const Color(0xFF8E1728),
              child: const Icon(Icons.person, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              '${frame.name}を購入しました！',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _equipFrame(frame);
              },
              icon: const Icon(Icons.auto_awesome),
              label: const Text('今すぐ装備する'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8E1728),
              ),
            ),
          ],
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
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('フレームショップ'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('フレームショップ'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // ポイント表示
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.amber.withValues(alpha: 0.1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.stars, color: Colors.amber, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      '${_currentUser?.points ?? 0}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                    const Text(
                      ' ポイント',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
              // タブバー
              TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                labelStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
                tabs: const [
                  Tab(text: '無料'),
                  Tab(text: 'ベーシック'),
                  Tab(text: 'プレミアム'),
                  Tab(text: 'レア'),
                  Tab(text: '限定'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFrameGrid(FrameTier.free),
          _buildFrameGrid(FrameTier.basic),
          _buildFrameGrid(FrameTier.premium),
          _buildFrameGrid(FrameTier.rare),
          _buildFrameGrid(FrameTier.limited),
        ],
      ),
    );
  }

  Widget _buildFrameGrid(FrameTier tier) {
    final frames = AvatarFrames.getByTier(tier);
    
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: frames.length,
      itemBuilder: (context, index) {
        final frame = frames[index];
        // 無料フレームは常に解放済みとして扱う
        final freeFrames = ['none', 'simple'];
        final isUnlocked = (_currentUser?.unlockedFrames.contains(frame.id) ?? false) || 
                          freeFrames.contains(frame.id);
        final isEquipped = _currentUser?.selectedFrame == frame.id;
        
        return Card(
          elevation: isEquipped ? 8 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isEquipped
                ? const BorderSide(color: Color(0xFF8E1728), width: 2)
                : BorderSide.none,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              if (isUnlocked) {
                if (!isEquipped) {
                  _equipFrame(frame);
                }
              } else {
                _purchaseFrame(frame);
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // フレームプレビュー
                  CustomCircleAvatar(
                    frameId: frame.id,
                    radius: 35,
                    backgroundColor: const Color(0xFF8E1728),
                    child: const Icon(Icons.person, color: Colors.white, size: 35),
                  ),
                  // フレーム名
                  Text(
                    frame.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  // 説明
                  Text(
                    frame.description,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // アニメーションバッジ
                  if (frame.hasAnimation)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome, size: 12, color: Colors.purple),
                          SizedBox(width: 4),
                          Text(
                            'アニメーション',
                            style: TextStyle(fontSize: 10, color: Colors.purple),
                          ),
                        ],
                      ),
                    ),
                  // 価格/状態
                  if (isEquipped)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8E1728),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '装備中',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else if (isUnlocked)
                    ElevatedButton(
                      onPressed: () => _equipFrame(frame),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      ),
                      child: const Text('装備する'),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: _currentUser!.points >= frame.price
                          ? () => _purchaseFrame(frame)
                          : null,
                      icon: const Icon(Icons.shopping_cart, size: 16),
                      label: Text('${frame.price}P'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _currentUser!.points >= frame.price
                            ? Colors.amber
                            : Colors.grey,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}