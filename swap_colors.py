#!/usr/bin/env python3
from PIL import Image

# オリジナルのアイコンを読み込む（1px右にシフトされた状態）
img = Image.open('waselab_icon_original.png')

# RGBA形式に変換
img = img.convert('RGBA')

# ピクセルデータを取得
pixels = img.load()
width, height = img.size

# 新しい画像を作成（えんじ色の背景）
new_img = Image.new('RGBA', (width, height), (0, 0, 0, 0))
new_pixels = new_img.load()

# えんじ色と白を定義
enji_color = None  # 最初に見つかったえんじ色を保存
white_color = (255, 255, 255, 255)

# まず、えんじ色を見つける（フラスコの色）
for y in range(height):
    for x in range(width):
        r, g, b, a = pixels[x, y]
        if a > 0 and r > 100 and r < 200 and g < 100 and b < 100:  # えんじ色っぽい色
            enji_color = (r, g, b, a)
            break
    if enji_color:
        break

# デフォルトのえんじ色（見つからなかった場合）
if not enji_color:
    enji_color = (140, 34, 51, 255)  # 早稲田のえんじ色

# 色を入れ替える
for y in range(height):
    for x in range(width):
        r, g, b, a = pixels[x, y]
        
        if a > 0:  # 透明でないピクセル
            # 白っぽい色（背景）をえんじ色に
            if r > 240 and g > 240 and b > 240:
                new_pixels[x, y] = enji_color
            # えんじ色っぽい色（フラスコ）を白に
            elif r > 100 and r < 200 and g < 100 and b < 100:
                new_pixels[x, y] = white_color
            else:
                new_pixels[x, y] = (r, g, b, a)
        else:
            new_pixels[x, y] = (0, 0, 0, 0)

# 右に1ピクセル移動するための新しい画像を作成
final_img = Image.new('RGBA', (width, height), (0, 0, 0, 0))
final_img.paste(new_img, (1, 0))

# バックアップを保存
current = Image.open('waselab_icon.png')
current.save('waselab_icon_before_swap.png')

# 色を入れ替えた画像を保存
final_img.save('waselab_icon.png')

print("フラスコを白、背景をえんじ色に変更しました（右1px移動を維持）。")
print("バックアップ: waselab_icon_before_swap.png")
print("変更後: waselab_icon.png")