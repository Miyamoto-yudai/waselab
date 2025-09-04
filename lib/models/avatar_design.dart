import 'package:flutter/material.dart';

enum AvatarDesignCategory {
  minimal,
  geometric,
  tech,
  initial,
  emoji;

  String get label {
    switch (this) {
      case AvatarDesignCategory.minimal:
        return 'ミニマル';
      case AvatarDesignCategory.geometric:
        return '幾何学';
      case AvatarDesignCategory.tech:
        return 'テック';
      case AvatarDesignCategory.initial:
        return 'イニシャル';
      case AvatarDesignCategory.emoji:
        return 'その他';
    }
  }

  IconData get icon {
    switch (this) {
      case AvatarDesignCategory.minimal:
        return Icons.radio_button_unchecked;
      case AvatarDesignCategory.geometric:
        return Icons.hexagon_outlined;
      case AvatarDesignCategory.tech:
        return Icons.memory;
      case AvatarDesignCategory.initial:
        return Icons.abc;
      case AvatarDesignCategory.emoji:
        return Icons.more_horiz;
    }
  }
}

class AvatarDesign {
  final String id;
  final String name;
  final AvatarDesignCategory category;
  final Widget Function(double size) builder;
  final int price;
  final bool isPremium;

  const AvatarDesign({
    required this.id,
    required this.name,
    required this.category,
    required this.builder,
    this.price = 0,
    this.isPremium = false,
  });
}

class AvatarDesigns {
  static final List<AvatarDesign> all = [
    // デフォルト
    AvatarDesign(
      id: 'default',
      name: 'デフォルト',
      category: AvatarDesignCategory.minimal,
      builder: (size) => Icon(Icons.person, color: Colors.white, size: size),
      price: 0,
    ),
    
    // ミニマルカテゴリー
    AvatarDesign(
      id: 'circle',
      name: 'サークル',
      category: AvatarDesignCategory.minimal,
      builder: (size) => Icon(Icons.circle_outlined, color: Colors.white, size: size * 0.8),
      price: 0,
    ),
    AvatarDesign(
      id: 'cross',
      name: 'クロス',
      category: AvatarDesignCategory.minimal,
      builder: (size) => Icon(Icons.close, color: Colors.white, size: size),
      price: 2,
    ),
    AvatarDesign(
      id: 'plus',
      name: 'プラス',
      category: AvatarDesignCategory.minimal,
      builder: (size) => Icon(Icons.add, color: Colors.white, size: size),
      price: 2,
    ),
    AvatarDesign(
      id: 'dot',
      name: 'ドット',
      category: AvatarDesignCategory.minimal,
      builder: (size) => Icon(Icons.fiber_manual_record, color: Colors.white, size: size * 0.4),
      price: 1,
    ),
    AvatarDesign(
      id: 'ring',
      name: 'リング',
      category: AvatarDesignCategory.minimal,
      builder: (size) => Icon(Icons.radio_button_unchecked, color: Colors.white, size: size),
      price: 3,
    ),
    AvatarDesign(
      id: 'infinity',
      name: 'インフィニティ',
      category: AvatarDesignCategory.minimal,
      builder: (size) => Icon(Icons.all_inclusive, color: Colors.white, size: size * 0.9),
      price: 10,
    ),
    
    // 幾何学カテゴリー
    AvatarDesign(
      id: 'hexagon',
      name: 'ヘキサゴン',
      category: AvatarDesignCategory.geometric,
      builder: (size) => Icon(Icons.hexagon_outlined, color: Colors.white, size: size),
      price: 5,
    ),
    AvatarDesign(
      id: 'triangle',
      name: 'トライアングル',
      category: AvatarDesignCategory.geometric,
      builder: (size) => Icon(Icons.change_history, color: Colors.white, size: size * 0.9),
      price: 5,
    ),
    AvatarDesign(
      id: 'square',
      name: 'スクエア',
      category: AvatarDesignCategory.geometric,
      builder: (size) => Icon(Icons.square_outlined, color: Colors.white, size: size * 0.8),
      price: 3,
    ),
    AvatarDesign(
      id: 'diamond',
      name: 'ダイヤモンド',
      category: AvatarDesignCategory.geometric,
      builder: (size) => Transform.rotate(
        angle: 0.785398, // 45度
        child: Icon(Icons.square_outlined, color: Colors.white, size: size * 0.7),
      ),
      price: 8,
    ),
    AvatarDesign(
      id: 'pentagon',
      name: 'ペンタゴン',
      category: AvatarDesignCategory.geometric,
      builder: (size) => Icon(Icons.pentagon_outlined, color: Colors.white, size: size),
      price: 7,
    ),
    AvatarDesign(
      id: 'octagon',
      name: 'オクタゴン',
      category: AvatarDesignCategory.geometric,
      builder: (size) => Icon(Icons.stop_outlined, color: Colors.white, size: size),
      price: 7,
    ),
    
    // テック系カテゴリー
    AvatarDesign(
      id: 'code',
      name: 'コード',
      category: AvatarDesignCategory.tech,
      builder: (size) => Icon(Icons.code, color: Colors.white, size: size),
      price: 10,
    ),
    AvatarDesign(
      id: 'terminal',
      name: 'ターミナル',
      category: AvatarDesignCategory.tech,
      builder: (size) => Icon(Icons.terminal, color: Colors.white, size: size * 0.9),
      price: 12,
    ),
    AvatarDesign(
      id: 'cpu',
      name: 'CPU',
      category: AvatarDesignCategory.tech,
      builder: (size) => Icon(Icons.memory, color: Colors.white, size: size * 0.9),
      price: 15,
    ),
    AvatarDesign(
      id: 'wifi',
      name: 'WiFi',
      category: AvatarDesignCategory.tech,
      builder: (size) => Icon(Icons.wifi, color: Colors.white, size: size * 0.9),
      price: 8,
    ),
    AvatarDesign(
      id: 'qr',
      name: 'QR',
      category: AvatarDesignCategory.tech,
      builder: (size) => Icon(Icons.qr_code_2, color: Colors.white, size: size * 0.9),
      price: 10,
    ),
    AvatarDesign(
      id: 'atom',
      name: 'アトム',
      category: AvatarDesignCategory.tech,
      builder: (size) => Icon(Icons.hub_outlined, color: Colors.white, size: size),
      price: 20,
      isPremium: true,
    ),
    
    // イニシャルカテゴリー
    AvatarDesign(
      id: 'initial_a',
      name: 'A',
      category: AvatarDesignCategory.initial,
      builder: (size) => Text(
        'A',
        style: TextStyle(
          fontSize: size * 0.6,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          fontFamily: 'SF Pro Display',
        ),
      ),
      price: 2,
    ),
    AvatarDesign(
      id: 'initial_x',
      name: 'X',
      category: AvatarDesignCategory.initial,
      builder: (size) => Text(
        'X',
        style: TextStyle(
          fontSize: size * 0.6,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          fontFamily: 'SF Pro Display',
        ),
      ),
      price: 3,
    ),
    AvatarDesign(
      id: 'initial_z',
      name: 'Z',
      category: AvatarDesignCategory.initial,
      builder: (size) => Text(
        'Z',
        style: TextStyle(
          fontSize: size * 0.6,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          fontFamily: 'SF Pro Display',
        ),
      ),
      price: 3,
    ),
    AvatarDesign(
      id: 'initial_s',
      name: 'S',
      category: AvatarDesignCategory.initial,
      builder: (size) => Text(
        'S',
        style: TextStyle(
          fontSize: size * 0.6,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          fontFamily: 'SF Pro Display',
        ),
      ),
      price: 2,
    ),
    AvatarDesign(
      id: 'initial_m',
      name: 'M',
      category: AvatarDesignCategory.initial,
      builder: (size) => Text(
        'M',
        style: TextStyle(
          fontSize: size * 0.6,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          fontFamily: 'SF Pro Display',
        ),
      ),
      price: 2,
    ),
    
    // その他カテゴリー（絵文字・特殊）
    AvatarDesign(
      id: 'star',
      name: 'スター',
      category: AvatarDesignCategory.emoji,
      builder: (size) => Icon(Icons.star, color: Colors.white, size: size),
      price: 5,
    ),
    AvatarDesign(
      id: 'bolt',
      name: 'サンダー',
      category: AvatarDesignCategory.emoji,
      builder: (size) => Icon(Icons.bolt, color: Colors.white, size: size),
      price: 8,
    ),
    AvatarDesign(
      id: 'favorite',
      name: 'ハート',
      category: AvatarDesignCategory.emoji,
      builder: (size) => Icon(Icons.favorite_outline, color: Colors.white, size: size * 0.9),
      price: 5,
    ),
    AvatarDesign(
      id: 'crown',
      name: 'クラウン',
      category: AvatarDesignCategory.emoji,
      builder: (size) => Text('👑', style: TextStyle(fontSize: size * 0.8)),
      price: 50,
      isPremium: true,
    ),
    AvatarDesign(
      id: 'flame',
      name: 'フレイム',
      category: AvatarDesignCategory.emoji,
      builder: (size) => Icon(Icons.local_fire_department_outlined, color: Colors.white, size: size),
      price: 15,
    ),
  ];
  
  static List<AvatarDesign> getByCategory(AvatarDesignCategory category) {
    return all.where((design) => design.category == category).toList();
  }
  
  static AvatarDesign getById(String id) {
    return all.firstWhere(
      (design) => design.id == id,
      orElse: () => all.first,
    );
  }
}