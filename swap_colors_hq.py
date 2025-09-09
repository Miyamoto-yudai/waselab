#!/usr/bin/env python3
from PIL import Image

# オリジナルのアイコンを読み込む
img = Image.open('waselab_icon_original.png')

# RGBA形式に変換
img = img.convert('RGBA')

# ピクセルデータを取得
pixels = img.load()
width, height = img.size

# 新しい画像を作成
new_img = Image.new('RGBA', (width, height), (0, 0, 0, 0))
new_pixels = new_img.load()

# 早稲田のえんじ色
enji_color = (140, 34, 51)

# 各ピクセルを処理
for y in range(height):
    for x in range(width):
        r, g, b, a = pixels[x, y]
        
        if a == 0:  # 完全に透明
            new_pixels[x, y] = (0, 0, 0, 0)
        else:
            # グレースケール値を計算（明度）
            gray = (r + g + b) / 3
            
            # 白に近い（背景）場合
            if gray > 200:
                # えんじ色に変換（アルファ値は保持）
                new_pixels[x, y] = (enji_color[0], enji_color[1], enji_color[2], a)
            # えんじ色に近い（フラスコ）場合
            elif r > g and r > b and gray < 200:
                # 白に変換（アルファ値は保持）
                new_pixels[x, y] = (255, 255, 255, a)
            else:
                # 中間色の場合（エッジ部分）
                # 元の色の明度に応じて白とえんじ色を混ぜる
                if gray > 128:
                    # より白に近い
                    ratio = (gray - 128) / 127
                    new_r = int(enji_color[0] + (255 - enji_color[0]) * ratio)
                    new_g = int(enji_color[1] + (255 - enji_color[1]) * ratio)
                    new_b = int(enji_color[2] + (255 - enji_color[2]) * ratio)
                    new_pixels[x, y] = (new_r, new_g, new_b, a)
                else:
                    # よりえんじ色に近い
                    new_pixels[x, y] = (255, 255, 255, a)

# 右に1ピクセル移動するための新しい画像を作成
final_img = Image.new('RGBA', (width, height), (0, 0, 0, 0))
final_img.paste(new_img, (1, 0))

# アンチエイリアシングを適用（品質向上）
final_img = final_img.resize((width * 2, height * 2), Image.Resampling.LANCZOS)
final_img = final_img.resize((width, height), Image.Resampling.LANCZOS)

# バックアップを保存
current = Image.open('waselab_icon.png')
current.save('waselab_icon_before_hq.png')

# 高品質な色交換後の画像を保存
final_img.save('waselab_icon.png', optimize=True, quality=100)

print("高品質な色交換を実行しました（右1px移動を維持）。")
print("バックアップ: waselab_icon_before_hq.png")
print("変更後: waselab_icon.png")