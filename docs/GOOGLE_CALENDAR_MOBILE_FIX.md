# Googleカレンダー連携 - モバイル対応修正

## 対応内容

### 問題
- スマホアプリから「日程を追加」ボタンが反応しない
- Chromeブラウザからは正常に動作する

### 原因
- モバイルアプリでは`https://calendar.google.com`のWebURLが適切に処理されない
- ネイティブアプリのURLスキームが必要

### 解決策

#### 1. プラットフォーム判定の実装
```dart
if (kIsWeb) {
  // Web環境: ブラウザでGoogleカレンダーを開く
} else {
  // モバイル環境: ネイティブアプリまたはブラウザを開く
}
```

#### 2. モバイル用URLスキーム
- **Googleカレンダーアプリ**: `googlecalendar://add?...`
- **iOS標準カレンダー**: `calshow:...`
- **フォールバック**: Webブラウザ

#### 3. 優先順位
1. Googleカレンダーアプリ（iOS/Android共通）
2. iOS標準カレンダーアプリ（iOSのみ）
3. Webブラウザ（最終手段）

## 実装詳細

### GoogleCalendarService
- `_openCalendarOnMobile()`メソッドを追加
- 複数のURLスキームを順番に試行
- エラーハンドリングとフォールバック処理

### NotificationScreen
- InkWellをMaterialでラップ
- タップ領域のパディングを拡大（6→8px）
- スプラッシュエフェクトを追加

## 動作確認

### iOS
1. Googleカレンダーアプリがインストールされている場合
   - アプリが起動し、イベント追加画面が表示される

2. Googleカレンダーアプリがない場合
   - 標準カレンダーアプリが起動する
   - または、SafariでGoogleカレンダーが開く

### Android
1. Googleカレンダーアプリがインストールされている場合
   - アプリが起動し、イベント追加画面が表示される

2. Googleカレンダーアプリがない場合
   - ChromeなどのブラウザでGoogleカレンダーが開く

### Web（Chrome等）
- 従来通り、新しいタブでGoogleカレンダーが開く

## テスト方法

```bash
# iOS実機でテスト
flutter run -d [device_id]

# Androidエミュレータでテスト
flutter run -d emulator

# Webでテスト
flutter run -d chrome
```

## 注意事項

1. **iOS標準カレンダー**
   - `calshow`スキームは読み取り専用
   - イベント作成は手動で行う必要がある

2. **権限設定**
   - iOS: Info.plistにURLスキームの設定が必要な場合がある
   - Android: 特別な権限設定は不要

3. **エラーハンドリング**
   - アプリがインストールされていない場合は自動的にフォールバック
   - 全ての方法が失敗した場合はエラーメッセージを表示

## 今後の改善案

1. **カスタムURLスキーム**
   - アプリ独自のURLスキームを実装
   - ディープリンクによる連携強化

2. **カレンダーAPI直接統合**
   - Google Calendar APIを使用した直接的な統合
   - OAuth2.0認証の実装

3. **ローカル通知**
   - カレンダー連携が失敗した場合の代替手段
   - アプリ内リマインダー機能