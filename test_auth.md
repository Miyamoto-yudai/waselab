# 認証永続化テスト手順

## Webブラウザでのテスト手順

1. **アプリを起動**
   - Chrome: http://localhost:50311 でアクセス
   - ブラウザのデベロッパーツール（F12）を開く
   - コンソールタブを選択

2. **デバッグログ確認項目**

   初回起動時に以下のログが表示されるはず：
   - 🚀 [MAIN] App starting...
   - ✅ [MAIN] Firebase initialized
   - 🔄 [MAIN] Attempting to restore auth state...
   - 🔍 [AuthPersistence] Starting auth restoration...
   - 🌐 [AuthPersistence] Reading from SharedPreferences... (Web)
   - 📦 [AuthPersistence] Retrieved stored data
   - 🔐 [AuthWrapper] No user, showing login (初回)

3. **ログイン後の確認**
   - メールアドレスとパスワードでログイン
   - 以下のログを確認：
     - 💾 Email auth state saved
     - 🏠 [AuthWrapper] User authenticated, showing home

4. **ブラウザリロードテスト**
   - ブラウザをリロード（F5）
   - 以下のログを確認：
     - 📦 [AuthPersistence] Retrieved stored data
     - ✅ [AuthWrapper] User restored after Xms
     - 🏠 [AuthWrapper] User authenticated, showing home
   - ホーム画面が表示されることを確認

## Androidでのテスト手順

1. **APKをインストール**
   ```bash
   adb install build/app/outputs/flutter-apk/app-debug.apk
   ```

2. **logcatでログ監視**
   ```bash
   adb logcat | grep -E "AuthDebugService|MAIN|AuthWrapper|AuthPersistence"
   ```

3. **初回起動**
   - アプリを起動
   - ログイン画面が表示される
   - メールとパスワードでログイン

4. **アプリ再起動テスト**
   - アプリを完全に終了
   - アプリを再度起動
   - 以下のログを確認：
     - 📱 [AuthPersistence] Reading from SecureStorage...
     - 🔑 [AuthPersistence] Attempting email/password re-authentication
     - ✅ [AuthPersistence] Auth state restored via email/password
     - 🏠 [AuthWrapper] User authenticated, showing home
   - ホーム画面が直接表示されることを確認

## 期待される結果

### Web (Chrome)
- ブラウザリロード後も自動的にログイン状態が復元
- Firebase Authの自動復元機能により認証維持

### Android
- アプリ再起動後も自動的にログイン状態が復元
- Flutter Secure Storageに保存された認証情報で自動再ログイン
- KeysetManagerエラーを回避して正常動作

## トラブルシューティング

もしログアウトされる場合は以下を確認：
1. デバッグログで「❌」エラーマークがないか
2. 「⚠️ Could not restore auth state」が表示されていないか
3. Android: KeysetManagerエラーが出ていないか