import 'package:flutter/material.dart';

enum ColorTier {
  free,
  basic,
  special,
  premium,
}

class AvatarColor {
  final String id;
  final String name;
  final Color color;
  final ColorTier tier;
  final int price;
  final bool hasGradient;
  final List<Color>? gradientColors;
  final bool hasShimmer;

  const AvatarColor({
    required this.id,
    required this.name,
    required this.color,
    required this.tier,
    required this.price,
    this.hasGradient = false,
    this.gradientColors,
    this.hasShimmer = false,
  });
}

class AvatarColors {
  static final List<AvatarColor> all = [
    // 無料色
    const AvatarColor(
      id: 'default',
      name: 'デフォルト',
      color: Color(0xFF8E1728),
      tier: ColorTier.free,
      price: 0,
    ),
    
    // 基本色（1ポイント）
    const AvatarColor(
      id: 'red',
      name: 'レッド',
      color: Colors.red,
      tier: ColorTier.basic,
      price: 1,
    ),
    const AvatarColor(
      id: 'blue',
      name: 'ブルー',
      color: Colors.blue,
      tier: ColorTier.basic,
      price: 1,
    ),
    const AvatarColor(
      id: 'green',
      name: 'グリーン',
      color: Colors.green,
      tier: ColorTier.basic,
      price: 1,
    ),
    const AvatarColor(
      id: 'orange',
      name: 'オレンジ',
      color: Colors.orange,
      tier: ColorTier.basic,
      price: 1,
    ),
    const AvatarColor(
      id: 'purple',
      name: 'パープル',
      color: Colors.purple,
      tier: ColorTier.basic,
      price: 1,
    ),
    const AvatarColor(
      id: 'pink',
      name: 'ピンク',
      color: Colors.pink,
      tier: ColorTier.basic,
      price: 1,
    ),
    const AvatarColor(
      id: 'teal',
      name: 'ティール',
      color: Colors.teal,
      tier: ColorTier.basic,
      price: 1,
    ),
    const AvatarColor(
      id: 'amber',
      name: 'アンバー',
      color: Colors.amber,
      tier: ColorTier.basic,
      price: 1,
    ),
    const AvatarColor(
      id: 'indigo',
      name: 'インディゴ',
      color: Colors.indigo,
      tier: ColorTier.basic,
      price: 1,
    ),
    const AvatarColor(
      id: 'grey',
      name: 'グレー',
      color: Colors.grey,
      tier: ColorTier.basic,
      price: 1,
    ),
    
    // 特殊色（3ポイント）
    const AvatarColor(
      id: 'cyan',
      name: 'シアン',
      color: Colors.cyan,
      tier: ColorTier.special,
      price: 3,
    ),
    const AvatarColor(
      id: 'lime',
      name: 'ライム',
      color: Colors.lime,
      tier: ColorTier.special,
      price: 3,
    ),
    const AvatarColor(
      id: 'deep_orange',
      name: 'ディープオレンジ',
      color: Colors.deepOrange,
      tier: ColorTier.special,
      price: 3,
    ),
    const AvatarColor(
      id: 'deep_purple',
      name: 'ディープパープル',
      color: Colors.deepPurple,
      tier: ColorTier.special,
      price: 3,
    ),
    const AvatarColor(
      id: 'light_blue',
      name: 'ライトブルー',
      color: Colors.lightBlue,
      tier: ColorTier.special,
      price: 3,
    ),
    const AvatarColor(
      id: 'light_green',
      name: 'ライトグリーン',
      color: Colors.lightGreen,
      tier: ColorTier.special,
      price: 3,
    ),
    const AvatarColor(
      id: 'brown',
      name: 'ブラウン',
      color: Colors.brown,
      tier: ColorTier.special,
      price: 3,
    ),
    const AvatarColor(
      id: 'black',
      name: 'ブラック',
      color: Colors.black87,
      tier: ColorTier.special,
      price: 3,
    ),
    const AvatarColor(
      id: 'white',
      name: 'ホワイト',
      color: Colors.white,
      tier: ColorTier.special,
      price: 3,
    ),
    
    // プレミアム色（5ポイント - グラデーション）
    AvatarColor(
      id: 'gradient_sunset',
      name: 'サンセット',
      color: Colors.orange,
      tier: ColorTier.premium,
      price: 5,
      hasGradient: true,
      gradientColors: [Colors.orange, Colors.pink, Colors.purple],
    ),
    AvatarColor(
      id: 'gradient_ocean',
      name: 'オーシャン',
      color: Colors.blue,
      tier: ColorTier.premium,
      price: 5,
      hasGradient: true,
      gradientColors: [Colors.blue[300]!, Colors.blue[600]!, Colors.blue[900]!],
    ),
    AvatarColor(
      id: 'gradient_forest',
      name: 'フォレスト',
      color: Colors.green,
      tier: ColorTier.premium,
      price: 5,
      hasGradient: true,
      gradientColors: [Colors.lightGreen, Colors.green, Colors.green[900]!],
    ),
    AvatarColor(
      id: 'gradient_rainbow',
      name: 'レインボー',
      color: Colors.red,
      tier: ColorTier.premium,
      price: 10,
      hasGradient: true,
      gradientColors: [
        Colors.red,
        Colors.orange,
        Colors.yellow,
        Colors.green,
        Colors.blue,
        Colors.indigo,
        Colors.purple,
      ],
    ),
    AvatarColor(
      id: 'gradient_gold',
      name: 'ゴールド',
      color: Colors.amber,
      tier: ColorTier.premium,
      price: 8,
      hasGradient: true,
      gradientColors: [Colors.amber[300]!, Colors.amber, Colors.orange[900]!],
      hasShimmer: true,
    ),
    AvatarColor(
      id: 'gradient_silver',
      name: 'シルバー',
      color: Colors.grey,
      tier: ColorTier.premium,
      price: 8,
      hasGradient: true,
      gradientColors: [Colors.grey[300]!, Colors.grey[600]!, Colors.blueGrey[900]!],
      hasShimmer: true,
    ),
  ];
  
  static List<AvatarColor> getByTier(ColorTier tier) {
    return all.where((color) => color.tier == tier).toList();
  }
  
  static AvatarColor getById(String id) {
    return all.firstWhere(
      (color) => color.id == id,
      orElse: () => all.first,
    );
  }
  
  static Color getColorValue(AvatarColor avatarColor) {
    if (avatarColor.hasGradient && avatarColor.gradientColors != null) {
      return avatarColor.gradientColors!.first;
    }
    return avatarColor.color;
  }
}