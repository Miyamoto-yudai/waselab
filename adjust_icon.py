#!/usr/bin/env python3
from PIL import Image
import numpy as np

# 元のアイコンを読み込む
img = Image.open('waselab_icon.png')
img_array = np.array(img)

# 新しい画像を作成（同じサイズ）
height, width = img_array.shape[:2]
new_img_array = np.zeros_like(img_array)

# 右に10ピクセル移動（調整可能）
shift_pixels = 10

# 画像を右にシフト
for y in range(height):
    for x in range(width):
        new_x = x - shift_pixels
        if 0 <= new_x < width:
            new_img_array[y, x] = img_array[y, new_x]
        else:
            # 透明にする（アルファチャンネルがある場合）
            if len(img_array.shape) == 3:
                if img_array.shape[2] == 4:
                    new_img_array[y, x] = [0, 0, 0, 0]
                else:
                    new_img_array[y, x] = img_array[y, 0]  # 右端の色で埋める
            else:
                new_img_array[y, x] = img_array[y, 0]

# 新しい画像を保存
new_img = Image.fromarray(new_img_array)
new_img.save('waselab_icon_adjusted.png')

# オリジナルをバックアップ
img.save('waselab_icon_backup.png')

# 調整した画像で元のファイルを上書き
new_img.save('waselab_icon.png')

print("アイコンをわずかに右に移動しました。")
print("バックアップ: waselab_icon_backup.png")
print("調整後: waselab_icon.png")