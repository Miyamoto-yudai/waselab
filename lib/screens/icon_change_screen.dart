import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../models/avatar_frame.dart';
import '../models/avatar_design.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../widgets/custom_circle_avatar.dart';
import '../models/avatar_color.dart';

/// アイコン変更画面（フレームとデザインの両方を変更可能）
class IconChangeScreen extends StatefulWidget {
  const IconChangeScreen({super.key});

  @override
  State<IconChangeScreen> createState() => _IconChangeScreenState();
}

class _IconChangeScreenState extends State<IconChangeScreen>
    with TickerProviderStateMixin {
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  
  AppUser? _currentUser;
  bool _isLoading = true;
  late TabController _mainTabController;
  late TabController _frameTabController;
  late TabController _designTabController;
  late TabController _colorTabController;

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 3, vsync: this);
    _frameTabController = TabController(length: 5, vsync: this);
    _designTabController = TabController(length: 8, vsync: this);
    _colorTabController = TabController(length: 4, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    _frameTabController.dispose();
    _designTabController.dispose();
    _colorTabController.dispose();
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
      debugPrint('ユーザー情報の取得エラー: $e');
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
      _showInsufficientPointsDialog(frame.price, frame.name);
      return;
    }

    // 購入確認ダイアログ
    final confirmed = await _showPurchaseConfirmDialog(
      name: frame.name,
      description: frame.description,
      price: frame.price,
      previewWidget: CustomCircleAvatar(
        frameId: frame.id,
        radius: 40,
        designBuilder: _currentUser!.selectedDesign != null
            ? AvatarDesigns.getById(_currentUser!.selectedDesign!).builder
            : null,
        backgroundColor: const Color(0xFF8E1728),
        child: _currentUser!.selectedDesign == null || _currentUser!.selectedDesign == 'default'
            ? const Icon(Icons.person, color: Colors.white, size: 40)
            : null,
      ),
    );
    
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
        _showPurchaseSuccessDialog(frame.name, () => _equipFrame(frame));
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

  /// デザインを購入
  Future<void> _purchaseDesign(AvatarDesign design) async {
    if (_currentUser == null) return;
    
    // ポイント不足チェック
    if (_currentUser!.points < design.price) {
      _showInsufficientPointsDialog(design.price, design.name);
      return;
    }

    // 購入確認ダイアログ
    final confirmed = await _showPurchaseConfirmDialog(
      name: design.name,
      description: '${design.category.label}デザイン',
      price: design.price,
      previewWidget: CustomCircleAvatar(
        frameId: _currentUser!.selectedFrame,
        radius: 40,
        backgroundColor: const Color(0xFF8E1728),
        designBuilder: design.builder,
      ),
    );
    
    if (!confirmed) return;

    try {
      setState(() => _isLoading = true);
      
      await _userService.unlockDesign(
        userId: _currentUser!.uid,
        designId: design.id,
        cost: design.price,
      );
      
      // ユーザー情報を再読み込み
      await _loadUserData();
      
      if (mounted) {
        _showPurchaseSuccessDialog(design.name, () => _equipDesign(design));
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

  /// デザインを装備
  Future<void> _equipDesign(AvatarDesign design) async {
    if (_currentUser == null) return;

    try {
      setState(() => _isLoading = true);
      
      await _userService.selectDesign(
        userId: _currentUser!.uid,
        designId: design.id,
      );
      
      // ユーザー情報を再読み込み
      await _loadUserData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${design.name}を装備しました'),
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

  /// カラーを購入
  Future<void> _purchaseColor(AvatarColor color) async {
    if (_currentUser == null) return;
    
    // ポイント不足チェック
    if (_currentUser!.points < color.price) {
      _showInsufficientPointsDialog(color.price, color.name);
      return;
    }

    // 購入確認ダイアログ
    final confirmed = await _showPurchaseConfirmDialog(
      name: color.name,
      description: color.tier == ColorTier.premium ? 'プレミアムカラー' : '',
      price: color.price,
      previewWidget: CustomCircleAvatar(
        frameId: _currentUser!.selectedFrame,
        radius: 40,
        backgroundColor: color.hasGradient && color.gradientColors != null
            ? color.gradientColors!.first
            : color.color,
        designBuilder: _currentUser!.selectedDesign != null
            ? AvatarDesigns.getById(_currentUser!.selectedDesign!).builder
            : null,
        child: _currentUser!.selectedDesign == null || _currentUser!.selectedDesign == 'default'
            ? const Icon(Icons.person, color: Colors.white, size: 40)
            : null,
      ),
    );
    
    if (!confirmed) return;

    try {
      setState(() => _isLoading = true);
      
      await _userService.unlockColor(
        userId: _currentUser!.uid,
        colorId: color.id,
        cost: color.price,
      );
      
      // ユーザー情報を再読み込み
      await _loadUserData();
      
      if (mounted) {
        _showPurchaseSuccessDialog(color.name, () => _equipColor(color));
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

  /// カラーを装備
  Future<void> _equipColor(AvatarColor color) async {
    if (_currentUser == null) return;

    try {
      setState(() => _isLoading = true);
      
      await _userService.selectColor(
        userId: _currentUser!.uid,
        colorId: color.id,
      );
      
      // ユーザー情報を再読み込み
      await _loadUserData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${color.name}を装備しました'),
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
  void _showInsufficientPointsDialog(int price, String itemName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ポイント不足'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$itemNameの購入には$priceポイント必要です。'),
            const SizedBox(height: 8),
            Text('現在のポイント: ${_currentUser?.points ?? 0}ポイント'),
            Text('不足: ${price - (_currentUser?.points ?? 0)}ポイント'),
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
  Future<bool> _showPurchaseConfirmDialog({
    required String name,
    required String description,
    required int price,
    required Widget previewWidget,
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('購入確認'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            previewWidget,
            const SizedBox(height: 16),
            Text(
              name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              description,
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
                    '$priceポイント',
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
              '残高: ${_currentUser?.points ?? 0} → ${(_currentUser?.points ?? 0) - price}ポイント',
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
  void _showPurchaseSuccessDialog(String itemName, VoidCallback onEquip) {
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
            Text(
              '$itemNameを購入しました！',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                onEquip();
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
          title: const Text('アイコン変更'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('アイコン変更'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(156),
          child: Column(
            children: [
              // ポイント表示
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.amber.withValues(alpha: 0.1),
                child: Column(
                  children: [
                    Row(
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
                    const SizedBox(height: 4),
                    Text(
                      '※ 無償実験への協力でポイント3倍獲得',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // メインタブバー（フレーム/デザイン）
              TabBar(
                controller: _mainTabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                labelStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.normal,
                ),
                tabs: const [
                  Tab(text: 'カラー'),
                  Tab(text: 'デザイン'),
                  Tab(text: 'フレーム'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _mainTabController,
        children: [
          // カラータブ
          Column(
            children: [
              Container(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                child: TabBar(
                  controller: _colorTabController,
                  isScrollable: true,
                  indicatorColor: Theme.of(context).primaryColor,
                  indicatorWeight: 3,
                  labelColor: Theme.of(context).primaryColor,
                  unselectedLabelColor: Colors.grey[600],
                  labelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  tabs: const [
                    Tab(text: '無料'),
                    Tab(text: 'ベーシック'),
                    Tab(text: 'スペシャル'),
                    Tab(text: 'プレミアム'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _colorTabController,
                  children: [
                    _buildColorGrid(ColorTier.free),
                    _buildColorGrid(ColorTier.basic),
                    _buildColorGrid(ColorTier.special),
                    _buildColorGrid(ColorTier.premium),
                  ],
                ),
              ),
            ],
          ),
          // デザインタブ
          Column(
            children: [
              Container(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                child: TabBar(
                  controller: _designTabController,
                  isScrollable: true,
                  indicatorColor: Theme.of(context).primaryColor,
                  indicatorWeight: 3,
                  labelColor: Theme.of(context).primaryColor,
                  unselectedLabelColor: Colors.grey[600],
                  labelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  tabs: [
                    Tab(
                      icon: Icon(AvatarDesignCategory.minimal.icon, size: 20),
                      text: AvatarDesignCategory.minimal.label,
                    ),
                    Tab(
                      icon: Icon(AvatarDesignCategory.geometric.icon, size: 20),
                      text: AvatarDesignCategory.geometric.label,
                    ),
                    Tab(
                      icon: Icon(AvatarDesignCategory.tech.icon, size: 20),
                      text: AvatarDesignCategory.tech.label,
                    ),
                    Tab(
                      icon: Icon(AvatarDesignCategory.initial.icon, size: 20),
                      text: AvatarDesignCategory.initial.label,
                    ),
                    Tab(
                      icon: Icon(AvatarDesignCategory.emoji.icon, size: 20),
                      text: AvatarDesignCategory.emoji.label,
                    ),
                    Tab(
                      icon: Icon(AvatarDesignCategory.kaomoji.icon, size: 20),
                      text: AvatarDesignCategory.kaomoji.label,
                    ),
                    Tab(
                      icon: Icon(AvatarDesignCategory.nature.icon, size: 20),
                      text: AvatarDesignCategory.nature.label,
                    ),
                    Tab(
                      icon: Icon(AvatarDesignCategory.artistic.icon, size: 20),
                      text: AvatarDesignCategory.artistic.label,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _designTabController,
                  children: [
                    _buildDesignGrid(AvatarDesignCategory.minimal),
                    _buildDesignGrid(AvatarDesignCategory.geometric),
                    _buildDesignGrid(AvatarDesignCategory.tech),
                    _buildDesignGrid(AvatarDesignCategory.initial),
                    _buildDesignGrid(AvatarDesignCategory.emoji),
                    _buildDesignGrid(AvatarDesignCategory.kaomoji),
                    _buildDesignGrid(AvatarDesignCategory.nature),
                    _buildDesignGrid(AvatarDesignCategory.artistic),
                  ],
                ),
              ),
            ],
          ),
          // フレームタブ
          Column(
            children: [
              Container(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                child: TabBar(
                  controller: _frameTabController,
                  isScrollable: true,
                  indicatorColor: Theme.of(context).primaryColor,
                  indicatorWeight: 3,
                  labelColor: Theme.of(context).primaryColor,
                  unselectedLabelColor: Colors.grey[600],
                  labelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  tabs: const [
                    Tab(text: '無料'),
                    Tab(text: 'ベーシック'),
                    Tab(text: 'プレミアム'),
                    Tab(text: 'レア'),
                    Tab(text: '限定'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _frameTabController,
                  children: [
                    _buildFrameGrid(FrameTier.free),
                    _buildFrameGrid(FrameTier.basic),
                    _buildFrameGrid(FrameTier.premium),
                    _buildFrameGrid(FrameTier.rare),
                    _buildFrameGrid(FrameTier.limited),
                  ],
                ),
              ),
            ],
          ),
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
                    designBuilder: _currentUser!.selectedDesign != null
                        ? AvatarDesigns.getById(_currentUser!.selectedDesign!).builder
                        : null,
                    child: _currentUser!.selectedDesign == null || _currentUser!.selectedDesign == 'default'
                        ? const Icon(Icons.person, color: Colors.white, size: 35)
                        : null,
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
                      onPressed: (_currentUser?.points ?? 0) >= frame.price
                          ? () => _purchaseFrame(frame)
                          : null,
                      icon: const Icon(Icons.shopping_cart, size: 16),
                      label: Text('${frame.price}P'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (_currentUser?.points ?? 0) >= frame.price
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

  Widget _buildDesignGrid(AvatarDesignCategory category) {
    final designs = AvatarDesigns.getByCategory(category);
    
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: designs.length,
      itemBuilder: (context, index) {
        final design = designs[index];
        final isUnlocked = (_currentUser?.unlockedDesigns.contains(design.id) ?? false) || 
                          design.id == 'default';
        final isEquipped = _currentUser?.selectedDesign == design.id;
        
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
                  _equipDesign(design);
                }
              } else {
                _purchaseDesign(design);
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // デザインプレビュー
                  CustomCircleAvatar(
                    frameId: _currentUser!.selectedFrame,
                    radius: 30,
                    backgroundColor: const Color(0xFF8E1728),
                    designBuilder: design.builder,
                  ),
                  // デザイン名
                  Text(
                    design.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // プレミアムバッジ
                  if (design.isPremium)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, size: 10, color: Colors.amber),
                          SizedBox(width: 2),
                          Text(
                            'プレミアム',
                            style: TextStyle(fontSize: 9, color: Colors.amber),
                          ),
                        ],
                      ),
                    ),
                  // 価格/状態
                  if (isEquipped)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8E1728),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Text(
                        '装備中',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else if (isUnlocked)
                    ElevatedButton(
                      onPressed: () => _equipDesign(design),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        minimumSize: const Size(0, 28),
                      ),
                      child: const Text('装備', style: TextStyle(fontSize: 12)),
                    )
                  else
                    ElevatedButton(
                      onPressed: (_currentUser?.points ?? 0) >= design.price
                          ? () => _purchaseDesign(design)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (_currentUser?.points ?? 0) >= design.price
                            ? Colors.amber
                            : Colors.grey,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        minimumSize: const Size(0, 28),
                      ),
                      child: Text('${design.price}P', style: const TextStyle(fontSize: 12)),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildColorGrid(ColorTier tier) {
    final colors = AvatarColors.getByTier(tier);
    
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: colors.length,
      itemBuilder: (context, index) {
        final color = colors[index];
        final isUnlocked = (_currentUser?.unlockedColors.contains(color.id) ?? false) || 
                          color.id == 'default';
        final isEquipped = _currentUser?.selectedColor == color.id;
        
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
                  _equipColor(color);
                }
              } else {
                _purchaseColor(color);
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // カラープレビュー
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.hasGradient && color.gradientColors != null
                          ? null
                          : color.color,
                      gradient: color.hasGradient && color.gradientColors != null
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: color.gradientColors!,
                            )
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: (color.hasGradient && color.gradientColors != null
                              ? color.gradientColors!.first
                              : color.color).withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: color.hasShimmer
                        ? const Icon(
                            Icons.auto_awesome,
                            color: Colors.white,
                            size: 20,
                          )
                        : null,
                  ),
                  // カラー名
                  Text(
                    color.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // 価格/状態
                  if (isEquipped)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8E1728),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Text(
                        '装備中',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else if (isUnlocked)
                    ElevatedButton(
                      onPressed: () => _equipColor(color),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        minimumSize: const Size(0, 24),
                      ),
                      child: const Text('装備', style: TextStyle(fontSize: 10)),
                    )
                  else
                    ElevatedButton(
                      onPressed: (_currentUser?.points ?? 0) >= color.price
                          ? () => _purchaseColor(color)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (_currentUser?.points ?? 0) >= color.price
                            ? Colors.amber
                            : Colors.grey,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        minimumSize: const Size(0, 24),
                      ),
                      child: Text('${color.price}P', style: const TextStyle(fontSize: 10)),
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