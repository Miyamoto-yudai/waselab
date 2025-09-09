#!/usr/bin/env python3
from PIL import Image

# オリジナルのアイコンを読み込む
img = Image.open('waselab_icon_original.png')

# 右に1ピクセル移動するための新しい画像を作成
width, height = img.size
new_img = Image.new('RGBA', (width, height), (0, 0, 0, 0))

# 画像を右に1ピクセルシフトして貼り付け
new_img.paste(img, (1, 0))

# 新しい画像を保存
new_img.save('waselab_icon.png')

print("アイコンを1px右に移動しました（5px-4px=1px）。")
print("調整後: waselab_icon.png")