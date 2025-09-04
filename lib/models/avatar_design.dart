import 'package:flutter/material.dart';

enum AvatarDesignCategory {
  animal,
  initial,
  emoji,
  iconDesign,
  pattern;

  String get label {
    switch (this) {
      case AvatarDesignCategory.animal:
        return '動物';
      case AvatarDesignCategory.initial:
        return 'イニシャル';
      case AvatarDesignCategory.emoji:
        return '絵文字';
      case AvatarDesignCategory.iconDesign:
        return 'アイコン';
      case AvatarDesignCategory.pattern:
        return 'パターン';
    }
  }

  IconData get icon {
    switch (this) {
      case AvatarDesignCategory.animal:
        return Icons.pets;
      case AvatarDesignCategory.initial:
        return Icons.abc;
      case AvatarDesignCategory.emoji:
        return Icons.emoji_emotions;
      case AvatarDesignCategory.iconDesign:
        return Icons.star;
      case AvatarDesignCategory.pattern:
        return Icons.grid_3x3;
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
      category: AvatarDesignCategory.iconDesign,
      builder: (size) => Icon(Icons.person, color: Colors.white, size: size),
      price: 0,
    ),
    
    // 動物カテゴリー
    AvatarDesign(
      id: 'cat',
      name: 'ネコ',
      category: AvatarDesignCategory.animal,
      builder: (size) => Text('🐱', style: TextStyle(fontSize: size * 0.8)),
      price: 5,
    ),
    AvatarDesign(
      id: 'dog',
      name: 'イヌ',
      category: AvatarDesignCategory.animal,
      builder: (size) => Text('🐶', style: TextStyle(fontSize: size * 0.8)),
      price: 5,
    ),
    AvatarDesign(
      id: 'rabbit',
      name: 'ウサギ',
      category: AvatarDesignCategory.animal,
      builder: (size) => Text('🐰', style: TextStyle(fontSize: size * 0.8)),
      price: 5,
    ),
    AvatarDesign(
      id: 'bear',
      name: 'クマ',
      category: AvatarDesignCategory.animal,
      builder: (size) => Text('🐻', style: TextStyle(fontSize: size * 0.8)),
      price: 10,
    ),
    AvatarDesign(
      id: 'panda',
      name: 'パンダ',
      category: AvatarDesignCategory.animal,
      builder: (size) => Text('🐼', style: TextStyle(fontSize: size * 0.8)),
      price: 15,
    ),
    AvatarDesign(
      id: 'unicorn',
      name: 'ユニコーン',
      category: AvatarDesignCategory.animal,
      builder: (size) => Text('🦄', style: TextStyle(fontSize: size * 0.8)),
      price: 30,
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
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      price: 3,
    ),
    AvatarDesign(
      id: 'initial_k',
      name: 'K',
      category: AvatarDesignCategory.initial,
      builder: (size) => Text(
        'K',
        style: TextStyle(
          fontSize: size * 0.6,
          fontWeight: FontWeight.bold,
          color: Colors.white,
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
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      price: 3,
    ),
    AvatarDesign(
      id: 'initial_t',
      name: 'T',
      category: AvatarDesignCategory.initial,
      builder: (size) => Text(
        'T',
        style: TextStyle(
          fontSize: size * 0.6,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      price: 3,
    ),
    AvatarDesign(
      id: 'initial_m',
      name: 'M',
      category: AvatarDesignCategory.initial,
      builder: (size) => Text(
        'M',
        style: TextStyle(
          fontSize: size * 0.6,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      price: 3,
    ),
    
    // 絵文字カテゴリー
    AvatarDesign(
      id: 'smile',
      name: 'スマイル',
      category: AvatarDesignCategory.emoji,
      builder: (size) => Text('😊', style: TextStyle(fontSize: size * 0.8)),
      price: 5,
    ),
    AvatarDesign(
      id: 'cool',
      name: 'クール',
      category: AvatarDesignCategory.emoji,
      builder: (size) => Text('😎', style: TextStyle(fontSize: size * 0.8)),
      price: 8,
    ),
    AvatarDesign(
      id: 'star_eyes',
      name: 'キラキラ',
      category: AvatarDesignCategory.emoji,
      builder: (size) => Text('🤩', style: TextStyle(fontSize: size * 0.8)),
      price: 10,
    ),
    AvatarDesign(
      id: 'heart_eyes',
      name: 'ハート',
      category: AvatarDesignCategory.emoji,
      builder: (size) => Text('😍', style: TextStyle(fontSize: size * 0.8)),
      price: 10,
    ),
    AvatarDesign(
      id: 'fire',
      name: 'ファイア',
      category: AvatarDesignCategory.emoji,
      builder: (size) => Text('🔥', style: TextStyle(fontSize: size * 0.8)),
      price: 20,
      isPremium: true,
    ),
    
    // アイコンカテゴリー
    AvatarDesign(
      id: 'star',
      name: 'スター',
      category: AvatarDesignCategory.iconDesign,
      builder: (size) => Icon(Icons.star, color: Colors.amber, size: size),
      price: 10,
    ),
    AvatarDesign(
      id: 'diamond',
      name: 'ダイヤモンド',
      category: AvatarDesignCategory.iconDesign,
      builder: (size) => Icon(Icons.diamond, color: Colors.cyan, size: size),
      price: 25,
      isPremium: true,
    ),
    AvatarDesign(
      id: 'crown',
      name: 'クラウン',
      category: AvatarDesignCategory.iconDesign,
      builder: (size) => Text('👑', style: TextStyle(fontSize: size * 0.8)),
      price: 50,
      isPremium: true,
    ),
    AvatarDesign(
      id: 'rocket',
      name: 'ロケット',
      category: AvatarDesignCategory.iconDesign,
      builder: (size) => Text('🚀', style: TextStyle(fontSize: size * 0.8)),
      price: 20,
    ),
    
    // パターンカテゴリー
    AvatarDesign(
      id: 'gradient',
      name: 'グラデーション',
      category: AvatarDesignCategory.pattern,
      builder: (size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.purple, Colors.blue],
          ),
        ),
      ),
      price: 15,
    ),
    AvatarDesign(
      id: 'rainbow',
      name: 'レインボー',
      category: AvatarDesignCategory.pattern,
      builder: (size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.red,
              Colors.orange,
              Colors.yellow,
              Colors.green,
              Colors.blue,
              Colors.indigo,
              Colors.purple,
            ],
          ),
        ),
      ),
      price: 30,
      isPremium: true,
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