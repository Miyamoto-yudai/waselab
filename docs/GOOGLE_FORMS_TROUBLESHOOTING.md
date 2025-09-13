# Google Forms 自動作成機能 トラブルシューティング

## よくあるエラーと解決方法

### 1. 「Google Forms APIへのアクセス権限がありません」（403エラー）

**原因**: Google Forms APIが有効化されていない

**解決方法**:
1. [Google Cloud Console](https://console.cloud.google.com/)にアクセス
2. プロジェクトを選択（Firebase プロジェクトと同じもの）
3. 「APIとサービス」→「ライブラリ」
4. 「Google Forms API」を検索
5. 「有効にする」をクリック

### 2. 「認証エラーです」（401エラー）

**原因**: サービスアカウントの認証情報が設定されていない

**解決方法**:

#### 方法A: Firebase プロジェクトのデフォルトサービスアカウントを使用（推奨）
```bash
# Firebase Functionsを再デプロイ
cd functions
firebase deploy --only functions:createGoogleFormFromTemplate
```

#### 方法B: カスタムサービスアカウントを使用
1. サービスアカウントを作成
2. JSONキーをダウンロード
3. 環境変数を設定:
```bash
firebase functions:config:set \
  googleapi.client_email="your-service-account@project.iam.gserviceaccount.com" \
  googleapi.private_key="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n" \
  googleapi.project_id="your-project-id"
```
4. Functionsを再デプロイ:
```bash
firebase deploy --only functions:createGoogleFormFromTemplate
```

### 3. 「フォームの作成に失敗しました」（一般的なエラー）

**考えられる原因と解決方法**:

1. **Firebase Functionsが正しくデプロイされていない**
   ```bash
   # 関数の状態を確認
   firebase functions:list | grep createGoogleFormFromTemplate
   
   # 再デプロイ
   cd functions
   npm run build
   firebase deploy --only functions:createGoogleFormFromTemplate
   ```

2. **ネットワークの問題**
   - インターネット接続を確認
   - VPNを使用している場合は一時的に無効化

3. **Firebase プロジェクトの設定**
   ```bash
   # 現在のプロジェクトを確認
   firebase projects:list
   
   # 正しいプロジェクトを選択
   firebase use your-project-id
   ```

### 4. デバッグ方法

**Firebase Functions のログを確認**:
```bash
# リアルタイムログを表示
firebase functions:log --only createGoogleFormFromTemplate

# 最新の50件を表示
firebase functions:log --only createGoogleFormFromTemplate -n 50
```

**Flutter側のログを確認**:
```bash
# Flutterアプリのデバッグログを表示
flutter run --verbose
```

### 5. 権限の確認

**必要な権限**:
- Google Forms API: 有効
- Google Drive API: 有効（オプション）
- サービスアカウントのロール:
  - 最小限: なし（Application Default Credentialsを使用）
  - カスタム: Forms編集権限

**権限を確認**:
1. [Google Cloud Console](https://console.cloud.google.com/)
2. 「IAMと管理」→「IAM」
3. サービスアカウントを探す
4. ロールを確認

### 6. よくある質問

**Q: 作成されたフォームの所有者は誰になりますか？**
A: サービスアカウント（またはFirebaseプロジェクトのデフォルトサービスアカウント）が所有者になります。

**Q: 作成されたフォームを別のユーザーと共有できますか？**
A: はい、作成後にGoogle Formsの共有設定から共有できます。

**Q: 一度に大量のフォームを作成できますか？**
A: APIのレート制限があるため、適度な間隔を空けて作成することを推奨します。

### 7. それでも解決しない場合

1. **Firebase Functionsを完全に再デプロイ**:
   ```bash
   cd functions
   rm -rf node_modules
   npm install
   npm run build
   firebase deploy --only functions
   ```

2. **Flutter側のキャッシュをクリア**:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

3. **エラーログの詳細を確認**:
   - Firebase Console → Functions → ログ
   - エラーメッセージ全体をコピーして検索

## サポート

問題が解決しない場合は、以下の情報と共に報告してください：
- エラーメッセージの全文
- Firebase Functionsのログ
- 実行した手順
- プロジェクトID（機密情報は除く）