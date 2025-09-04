import 'package:flutter/material.dart';

enum AvatarDesignCategory {
  minimal,
  geometric,
  tech,
  initial,
  emoji,
  kaomoji,
  nature,
  artistic;

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
        return '絵文字';
      case AvatarDesignCategory.kaomoji:
        return '顔文字';
      case AvatarDesignCategory.nature:
        return '自然';
      case AvatarDesignCategory.artistic:
        return 'アート';
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
        return Icons.emoji_emotions;
      case AvatarDesignCategory.kaomoji:
        return Icons.face;
      case AvatarDesignCategory.nature:
        return Icons.local_florist;
      case AvatarDesignCategory.artistic:
        return Icons.palette;
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
    
    // 絵文字カテゴリー
    AvatarDesign(
      id: 'smile_emoji',
      name: 'スマイル',
      category: AvatarDesignCategory.emoji,
      builder: (size) => Text('😊', style: TextStyle(fontSize: size * 0.8)),
      price: 3,
    ),
    AvatarDesign(
      id: 'cool_emoji',
      name: 'クール',
      category: AvatarDesignCategory.emoji,
      builder: (size) => Text('😎', style: TextStyle(fontSize: size * 0.8)),
      price: 5,
    ),
    AvatarDesign(
      id: 'rocket_emoji',
      name: 'ロケット',
      category: AvatarDesignCategory.emoji,
      builder: (size) => Text('🚀', style: TextStyle(fontSize: size * 0.8)),
      price: 8,
    ),
    AvatarDesign(
      id: 'sparkles_emoji',
      name: 'キラキラ',
      category: AvatarDesignCategory.emoji,
      builder: (size) => Text('✨', style: TextStyle(fontSize: size * 0.8)),
      price: 6,
    ),
    AvatarDesign(
      id: 'fire_emoji',
      name: '炎',
      category: AvatarDesignCategory.emoji,
      builder: (size) => Text('🔥', style: TextStyle(fontSize: size * 0.8)),
      price: 7,
    ),
    AvatarDesign(
      id: 'rainbow_emoji',
      name: '虹',
      category: AvatarDesignCategory.emoji,
      builder: (size) => Text('🌈', style: TextStyle(fontSize: size * 0.8)),
      price: 10,
    ),
    AvatarDesign(
      id: 'star_emoji',
      name: '星',
      category: AvatarDesignCategory.emoji,
      builder: (size) => Text('⭐', style: TextStyle(fontSize: size * 0.8)),
      price: 4,
    ),
    AvatarDesign(
      id: 'lightning_emoji',
      name: '稲妻',
      category: AvatarDesignCategory.emoji,
      builder: (size) => Text('⚡', style: TextStyle(fontSize: size * 0.8)),
      price: 8,
    ),
    AvatarDesign(
      id: 'gem_emoji',
      name: 'ダイヤ',
      category: AvatarDesignCategory.emoji,
      builder: (size) => Text('💎', style: TextStyle(fontSize: size * 0.8)),
      price: 20,
      isPremium: true,
    ),
    
    // 顔文字カテゴリー
    AvatarDesign(
      id: 'happy_kaomoji',
      name: 'ハッピー',
      category: AvatarDesignCategory.kaomoji,
      builder: (size) => Text(
        '(◕‿◕)',
        style: TextStyle(
          fontSize: size * 0.4,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      price: 3,
    ),
    AvatarDesign(
      id: 'excited_kaomoji',
      name: 'ワクワク',
      category: AvatarDesignCategory.kaomoji,
      builder: (size) => Text(
        '٩(◕‿◕)۶',
        style: TextStyle(
          fontSize: size * 0.35,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      price: 5,
    ),
    AvatarDesign(
      id: 'cool_kaomoji',
      name: 'クール',
      category: AvatarDesignCategory.kaomoji,
      builder: (size) => Text(
        '(⌐■_■)',
        style: TextStyle(
          fontSize: size * 0.35,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      price: 6,
    ),
    AvatarDesign(
      id: 'kawaii_kaomoji',
      name: 'カワイイ',
      category: AvatarDesignCategory.kaomoji,
      builder: (size) => Text(
        '(´｡• ᵕ •｡`)',
        style: TextStyle(
          fontSize: size * 0.3,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      price: 4,
    ),
    AvatarDesign(
      id: 'wink_kaomoji',
      name: 'ウインク',
      category: AvatarDesignCategory.kaomoji,
      builder: (size) => Text(
        '(･ω<)',
        style: TextStyle(
          fontSize: size * 0.4,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      price: 3,
    ),
    AvatarDesign(
      id: 'star_kaomoji',
      name: 'キラキラ',
      category: AvatarDesignCategory.kaomoji,
      builder: (size) => Text(
        '✧◝(⁰▿⁰)◜✧',
        style: TextStyle(
          fontSize: size * 0.28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      price: 8,
    ),
    AvatarDesign(
      id: 'love_kaomoji',
      name: 'ラブ',
      category: AvatarDesignCategory.kaomoji,
      builder: (size) => Text(
        '♡(˶ᵔ ᵕ ᵔ˶)',
        style: TextStyle(
          fontSize: size * 0.32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      price: 7,
    ),
    AvatarDesign(
      id: 'peace_kaomoji',
      name: 'ピース',
      category: AvatarDesignCategory.kaomoji,
      builder: (size) => Text(
        '✌(ﾟ∀ﾟ)✌',
        style: TextStyle(
          fontSize: size * 0.35,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      price: 5,
    ),
    AvatarDesign(
      id: 'magic_kaomoji',
      name: 'マジック',
      category: AvatarDesignCategory.kaomoji,
      builder: (size) => Text(
        '(∩^o^)⊃━☆',
        style: TextStyle(
          fontSize: size * 0.3,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      price: 10,
    ),
    
    // 自然カテゴリー
    AvatarDesign(
      id: 'flower',
      name: 'フラワー',
      category: AvatarDesignCategory.nature,
      builder: (size) => Icon(Icons.local_florist, color: Colors.white, size: size * 0.9),
      price: 5,
    ),
    AvatarDesign(
      id: 'sun',
      name: '太陽',
      category: AvatarDesignCategory.nature,
      builder: (size) => Icon(Icons.wb_sunny, color: Colors.white, size: size * 0.9),
      price: 4,
    ),
    AvatarDesign(
      id: 'moon',
      name: '月',
      category: AvatarDesignCategory.nature,
      builder: (size) => Icon(Icons.nightlight_round, color: Colors.white, size: size * 0.9),
      price: 6,
    ),
    AvatarDesign(
      id: 'cloud',
      name: 'クラウド',
      category: AvatarDesignCategory.nature,
      builder: (size) => Icon(Icons.cloud_outlined, color: Colors.white, size: size * 0.9),
      price: 3,
    ),
    AvatarDesign(
      id: 'water',
      name: '水滴',
      category: AvatarDesignCategory.nature,
      builder: (size) => Icon(Icons.water_drop, color: Colors.white, size: size * 0.9),
      price: 4,
    ),
    AvatarDesign(
      id: 'leaf',
      name: 'リーフ',
      category: AvatarDesignCategory.nature,
      builder: (size) => Icon(Icons.eco, color: Colors.white, size: size * 0.9),
      price: 5,
    ),
    AvatarDesign(
      id: 'butterfly',
      name: 'バタフライ',
      category: AvatarDesignCategory.nature,
      builder: (size) => Text('🦋', style: TextStyle(fontSize: size * 0.8)),
      price: 8,
    ),
    AvatarDesign(
      id: 'rainbow',
      name: 'レインボー',
      category: AvatarDesignCategory.nature,
      builder: (size) => Text('🌈', style: TextStyle(fontSize: size * 0.8)),
      price: 10,
    ),
    
    // アートカテゴリー
    AvatarDesign(
      id: 'brush',
      name: 'ブラシ',
      category: AvatarDesignCategory.artistic,
      builder: (size) => Icon(Icons.brush, color: Colors.white, size: size * 0.9),
      price: 5,
    ),
    AvatarDesign(
      id: 'palette',
      name: 'パレット',
      category: AvatarDesignCategory.artistic,
      builder: (size) => Icon(Icons.palette, color: Colors.white, size: size * 0.9),
      price: 6,
    ),
    AvatarDesign(
      id: 'music',
      name: 'ミュージック',
      category: AvatarDesignCategory.artistic,
      builder: (size) => Icon(Icons.music_note, color: Colors.white, size: size * 0.9),
      price: 5,
    ),
    AvatarDesign(
      id: 'camera',
      name: 'カメラ',
      category: AvatarDesignCategory.artistic,
      builder: (size) => Icon(Icons.camera_alt, color: Colors.white, size: size * 0.9),
      price: 6,
    ),
    AvatarDesign(
      id: 'theater',
      name: 'シアター',
      category: AvatarDesignCategory.artistic,
      builder: (size) => Icon(Icons.theater_comedy, color: Colors.white, size: size * 0.9),
      price: 7,
    ),
    AvatarDesign(
      id: 'sparkle',
      name: 'スパークル',
      category: AvatarDesignCategory.artistic,
      builder: (size) => Icon(Icons.auto_awesome, color: Colors.white, size: size * 0.9),
      price: 8,
    ),
    AvatarDesign(
      id: 'gradient',
      name: 'グラデーション',
      category: AvatarDesignCategory.artistic,
      builder: (size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.8),
              Colors.white.withValues(alpha: 0.4),
            ],
          ),
        ),
        child: Icon(Icons.gradient, color: Colors.white, size: size * 0.6),
      ),
      price: 15,
      isPremium: true,
    ),
    AvatarDesign(
      id: 'abstract',
      name: 'アブストラクト',
      category: AvatarDesignCategory.artistic,
      builder: (size) => Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: 0.5,
            child: Icon(Icons.square_outlined, color: Colors.white.withValues(alpha: 0.5), size: size * 0.7),
          ),
          Icon(Icons.circle_outlined, color: Colors.white.withValues(alpha: 0.7), size: size * 0.6),
          Icon(Icons.change_history, color: Colors.white, size: size * 0.4),
        ],
      ),
      price: 20,
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