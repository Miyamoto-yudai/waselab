#!/usr/bin/env python3
from PIL import Image

# 高画質の元画像を使用（weselab_icon.png）
img = Image.open('weselab_icon.png')

# RGBA形式に変換
img = img.convert('RGBA')

# 右に1ピクセル移動するための新しい画像を作成
width, height = img.size
final_img = Image.new('RGBA', (width, height), (0, 0, 0, 0))
final_img.paste(img, (1, 0))

# バックアップを保存
current = Image.open('waselab_icon.png')
current.save('waselab_icon_enji_bg.png')

# 元の配色（白背景・えんじフラスコ）を保存
final_img.save('waselab_icon.png')

print("背景を白、フラスコをえんじ色に戻しました（右1px移動を維持）。")
print("えんじ背景版のバックアップ: waselab_icon_enji_bg.png")
print("白背景版: waselab_icon.png")