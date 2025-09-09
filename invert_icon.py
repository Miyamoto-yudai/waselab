#!/usr/bin/env python3
from PIL import Image

# オリジナルのアイコンを読み込む
img = Image.open('waselab_icon_original.png')

# RGBA形式に変換
img = img.convert('RGBA')

# ピクセルデータを取得
pixels = img.load()
width, height = img.size

# 各ピクセルの色を反転
for y in range(height):
    for x in range(width):
        r, g, b, a = pixels[x, y]
        
        # アルファチャンネルは保持しつつ、色を反転
        # 白(255,255,255) -> 赤っぽい色
        # 赤っぽい色 -> 白
        if a > 0:  # 透明でないピクセルのみ処理
            # 色を反転
            pixels[x, y] = (255 - r, 255 - g, 255 - b, a)

# バックアップを保存
original = Image.open('waselab_icon.png')
original.save('waselab_icon_before_invert.png')

# 反転した画像を保存
img.save('waselab_icon.png')

print("アイコンの色を反転しました。")
print("バックアップ: waselab_icon_before_invert.png")
print("反転後: waselab_icon.png")