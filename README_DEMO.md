# わせラボ - デモモードについて

## エントリーポイントの統合

`main_fast.dart`と`main_demo.dart`を統合しました。今後は`main_demo.dart`を使用してください。

## 実行方法

```bash
# デモモード（Firebase不要、高速起動）
flutter run -d chrome -t lib/main_demo.dart

# 本番モード（Firebase必要）
flutter run -d chrome

# Web向けにCORSを無効化して実行
flutter run -d chrome --web-browser-flag "--disable-web-security" -t lib/main_demo.dart
```

## main_demo.dartの特徴

- **Firebase不要**: DemoAuthServiceを使用してFirebaseなしで動作
- **高速起動**: リリースモードでデバッグ出力を無効化
- **最適化されたアニメーション**: プラットフォーム別に最適なページ遷移
- **早稲田カラーテーマ**: えんじ色（#8E1728）を基調とした公式カラー

## 削除可能なファイル

- `lib/main_fast.dart` - main_demo.dartに統合済み