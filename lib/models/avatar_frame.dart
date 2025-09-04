import 'package:flutter/material.dart';

/// アバターフレームの定義
class AvatarFrame {
  final String id;
  final String name;
  final String description;
  final int price;
  final FrameTier tier;
  final FrameStyle style;
  final bool hasAnimation;

  const AvatarFrame({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.tier,
    required this.style,
    this.hasAnimation = false,
  });

  /// フレームの色を取得
  Color get primaryColor {
    switch (style) {
      case FrameStyle.none:
        return Colors.transparent;
      case FrameStyle.simple:
        return Colors.grey.shade400;
      case FrameStyle.classic:
        return Colors.black;
      case FrameStyle.soft:
        return Colors.white;
      case FrameStyle.modern:
        return Colors.blue.shade600;
      case FrameStyle.elegant:
        return const Color(0xFFD4AF37); // ゴールド
      case FrameStyle.pop:
        return Colors.pink.shade400;
      case FrameStyle.gradient:
        return Colors.purple;
      case FrameStyle.neon:
        return Colors.cyan;
      case FrameStyle.japanese:
        return const Color(0xFF8E1728); // 早稲田カラー
      case FrameStyle.cyber:
        return Colors.green.shade400;
      case FrameStyle.floral:
        return Colors.pink.shade300;
      case FrameStyle.diamond:
        return const Color(0xFFE0E0E0); // ダイヤモンドシルバー
      case FrameStyle.fire:
        return Colors.orange.shade700;
      case FrameStyle.water:
        return Colors.blue.shade400;
      case FrameStyle.star:
        return Colors.yellow.shade600;
      case FrameStyle.waseda:
        return const Color(0xFF8E1728);
      case FrameStyle.platinum:
        return const Color(0xFFE5E4E2);
      case FrameStyle.hologram:
        return Colors.purple.shade300;
      case FrameStyle.master:
        return const Color(0xFF2E2E2E);
    }
  }

  /// セカンダリカラー（グラデーション等で使用）
  Color? get secondaryColor {
    switch (style) {
      case FrameStyle.gradient:
        return Colors.orange;
      case FrameStyle.neon:
        return Colors.purple;
      case FrameStyle.hologram:
        return Colors.cyan;
      case FrameStyle.fire:
        return Colors.red;
      case FrameStyle.water:
        return Colors.cyan.shade300;
      case FrameStyle.waseda:
        return Colors.white;
      default:
        return null;
    }
  }
}

/// フレームの階層
enum FrameTier {
  free,
  basic,
  premium,
  rare,
  limited,
}

/// フレームのスタイル
enum FrameStyle {
  none,
  simple,
  classic,
  soft,
  modern,
  elegant,
  pop,
  gradient,
  neon,
  japanese,
  cyber,
  floral,
  diamond,
  fire,
  water,
  star,
  waseda,
  platinum,
  hologram,
  master,
}

/// 利用可能なフレーム一覧
class AvatarFrames {
  static const List<AvatarFrame> all = [
    // 無料フレーム
    AvatarFrame(
      id: 'none',
      name: 'なし',
      description: 'フレームを表示しません',
      price: 0,
      tier: FrameTier.free,
      style: FrameStyle.none,
    ),
    AvatarFrame(
      id: 'simple',
      name: 'シンプル',
      description: '細い灰色の控えめなフレーム',
      price: 0,
      tier: FrameTier.free,
      style: FrameStyle.simple,
    ),

    // ベーシックフレーム（5-10ポイント）
    AvatarFrame(
      id: 'classic',
      name: 'クラシック',
      description: 'しっかりとした黒い太線のフレーム',
      price: 5,
      tier: FrameTier.basic,
      style: FrameStyle.classic,
    ),
    AvatarFrame(
      id: 'soft',
      name: 'ソフト',
      description: 'ぼかし効果のある優しい白枠',
      price: 5,
      tier: FrameTier.basic,
      style: FrameStyle.soft,
    ),
    AvatarFrame(
      id: 'modern',
      name: 'モダン',
      description: '角が丸い現代的な青枠',
      price: 8,
      tier: FrameTier.basic,
      style: FrameStyle.modern,
    ),
    AvatarFrame(
      id: 'elegant',
      name: 'エレガント',
      description: '高級感のある金色の細線',
      price: 10,
      tier: FrameTier.basic,
      style: FrameStyle.elegant,
    ),
    AvatarFrame(
      id: 'pop',
      name: 'ポップ',
      description: 'カラフルで楽しげなドット柄',
      price: 10,
      tier: FrameTier.basic,
      style: FrameStyle.pop,
    ),

    // プレミアムフレーム（15-25ポイント）
    AvatarFrame(
      id: 'gradient',
      name: 'グラデーション',
      description: '美しい虹色のグラデーション',
      price: 15,
      tier: FrameTier.premium,
      style: FrameStyle.gradient,
    ),
    AvatarFrame(
      id: 'neon',
      name: 'ネオン',
      description: '光るネオン効果',
      price: 20,
      tier: FrameTier.premium,
      style: FrameStyle.neon,
      hasAnimation: true,
    ),
    AvatarFrame(
      id: 'japanese',
      name: '和風',
      description: '日本の伝統的な和柄デザイン',
      price: 20,
      tier: FrameTier.premium,
      style: FrameStyle.japanese,
    ),
    AvatarFrame(
      id: 'cyber',
      name: 'サイバー',
      description: 'デジタル風の点線パターン',
      price: 25,
      tier: FrameTier.premium,
      style: FrameStyle.cyber,
      hasAnimation: true,
    ),
    AvatarFrame(
      id: 'floral',
      name: 'フローラル',
      description: '優雅な花柄の装飾',
      price: 25,
      tier: FrameTier.premium,
      style: FrameStyle.floral,
    ),

    // レアフレーム（30-50ポイント）
    AvatarFrame(
      id: 'diamond',
      name: 'ダイヤモンド',
      description: 'キラキラと輝くダイヤモンド効果',
      price: 30,
      tier: FrameTier.rare,
      style: FrameStyle.diamond,
      hasAnimation: true,
    ),
    AvatarFrame(
      id: 'fire',
      name: '炎',
      description: '燃える炎のエフェクト',
      price: 35,
      tier: FrameTier.rare,
      style: FrameStyle.fire,
      hasAnimation: true,
    ),
    AvatarFrame(
      id: 'water',
      name: '水',
      description: '涼しげな波紋エフェクト',
      price: 35,
      tier: FrameTier.rare,
      style: FrameStyle.water,
      hasAnimation: true,
    ),
    AvatarFrame(
      id: 'star',
      name: '星',
      description: '星が回転するアニメーション',
      price: 40,
      tier: FrameTier.rare,
      style: FrameStyle.star,
      hasAnimation: true,
    ),
    AvatarFrame(
      id: 'waseda',
      name: '早稲田',
      description: '早稲田カラーの特別枠',
      price: 50,
      tier: FrameTier.rare,
      style: FrameStyle.waseda,
    ),

    // 限定フレーム（100ポイント）
    AvatarFrame(
      id: 'platinum',
      name: 'プラチナ',
      description: '最高級のプラチナ枠',
      price: 100,
      tier: FrameTier.limited,
      style: FrameStyle.platinum,
    ),
    AvatarFrame(
      id: 'hologram',
      name: 'ホログラム',
      description: '虹色に光る特殊効果',
      price: 100,
      tier: FrameTier.limited,
      style: FrameStyle.hologram,
      hasAnimation: true,
    ),
    AvatarFrame(
      id: 'master',
      name: 'マスター',
      description: '全実績達成者限定の究極デザイン',
      price: 100,
      tier: FrameTier.limited,
      style: FrameStyle.master,
      hasAnimation: true,
    ),
  ];

  /// IDからフレームを取得
  static AvatarFrame? getById(String id) {
    try {
      return all.firstWhere((frame) => frame.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 階層別にフレームを取得
  static List<AvatarFrame> getByTier(FrameTier tier) {
    return all.where((frame) => frame.tier == tier).toList();
  }

  /// 価格帯別にフレームを取得
  static List<AvatarFrame> getByPriceRange(int minPrice, int maxPrice) {
    return all.where((frame) => frame.price >= minPrice && frame.price <= maxPrice).toList();
  }
}