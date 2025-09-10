# iOS プッシュ通知設定手順

## 1. Apple Developer Console での設定

### A. APNs認証キーの作成（推奨方法）

1. [Apple Developer Console](https://developer.apple.com/account) にログイン

2. 「Certificates, Identifiers & Profiles」を選択

3. 左メニューから「Keys」を選択

4. 「+」ボタンをクリックして新しいキーを作成

5. 以下を設定：
   - Key Name: `WaseLab Push Notifications`（任意の名前）
   - ✅ Apple Push Notifications service (APNs) にチェック

6. 「Continue」→「Register」をクリック

7. **重要**: 生成された`.p8`ファイルをダウンロード
   - **Key ID** をメモ（例：`ABC123DEFG`）
   - **Team ID** をメモ（例：`1234567890`）
   - ⚠️ このファイルは一度しかダウンロードできません！

### B. App IDの確認

1. 「Identifiers」を選択

2. アプリのBundle ID（`com.example.experimentCooperationApp`など）を確認

3. Push Notificationsが有効になっているか確認
   - 無効の場合は「Edit」→「Push Notifications」にチェック→「Save」

## 2. Firebase Console での設定

1. [Firebase Console](https://console.firebase.google.com) にアクセス

2. プロジェクト「waselab-30308」を選択

3. ⚙️ → 「プロジェクトの設定」をクリック

4. 「Cloud Messaging」タブを選択

5. 「Apple アプリの構成」セクションで：

### APNs認証キー（.p8）をアップロード：

1. 「APNs認証キー」の「アップロード」をクリック

2. 以下を入力：
   - **APNs認証キー**: ダウンロードした`.p8`ファイルを選択
   - **キーID**: Apple Developerでメモした Key ID
   - **チームID**: Apple Developerでメモした Team ID

3. 「アップロード」をクリック

## 3. Xcodeでの追加設定

### A. Capabilityの追加

1. Xcodeでプロジェクトを開く：
```bash
cd /Users/yudaimiyamoto/Desktop/プログラム/flutter/experiment_cooperation_app/ios
open Runner.xcworkspace
```

2. プロジェクトナビゲーターで「Runner」を選択

3. 「Signing & Capabilities」タブを選択

4. 「+ Capability」をクリック

5. 以下を追加：
   - ✅ Push Notifications
   - ✅ Background Modes
     - ✅ Remote notifications
     - ✅ Background fetch

### B. Deployment Targetの確認

1. 「General」タブで「Minimum Deployments」が iOS 12.0 以上であることを確認

## 4. テスト方法

### A. 実機でのテスト（シミュレータではプッシュ通知は動作しません）

1. iPhoneを Mac に接続

2. Xcodeで実機を選択してビルド＆実行
```bash
flutter run -d [device-id]
```

3. アプリ起動時に通知許可ダイアログが表示されることを確認

4. 「許可」をタップ

5. アプリの設定画面で「プッシュ通知テスト」をタップ

6. 通知が届くことを確認

### B. Firebase Consoleからのテスト

1. Firebase Console → Cloud Messaging → 「最初のキャンペーンを作成」

2. 「Firebase Notification messages」を選択

3. 以下を入力：
   - 通知タイトル: テスト通知
   - 通知テキスト: これはテスト通知です

4. 「テストメッセージを送信」をクリック

5. FCMトークンを入力（アプリのコンソールログから取得）

## 5. トラブルシューティング

### 通知が届かない場合のチェックリスト：

- [ ] 実機でテストしているか（シミュレータは不可）
- [ ] APNs認証キーが正しくFirebaseにアップロードされているか
- [ ] Bundle IDが一致しているか
- [ ] プッシュ通知の権限を許可したか
- [ ] バックグラウンドモードが有効か
- [ ] FCMトークンが正しく取得・保存されているか

### デバッグログの確認：

Xcodeのコンソールで以下を確認：
- `FCM registration token: ` でトークンが表示される
- `FCMトークンをFirestoreに保存しました` が表示される

## 6. 本番環境への移行

本番リリース前に：
1. Production環境でのAPNs設定を確認
2. Info.plistの設定を再確認
3. 実機での最終テスト実施

---

⚠️ **重要な注意事項**：
- APNs認証キー（.p8ファイル）は安全に保管してください
- Key IDとTeam IDは後で必要になるので記録しておいてください
- シミュレータではプッシュ通知をテストできません（必ず実機を使用）