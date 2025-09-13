# Google Forms 自動作成機能 - セットアップ手順

## 🚨 重要：以下の手順を必ず実行してください

Google Forms APIを使用するには、サービスアカウントの設定が必要です。以下の手順のいずれかを実行してください。

---

## 方法1: サービスアカウントキーを作成して設定（推奨）

### ステップ1: Google Cloud Consoleでサービスアカウントキーを作成

1. **Google Cloud Console にアクセス**
   ```
   https://console.cloud.google.com/iam-admin/serviceaccounts?project=waselab-30308
   ```

2. **既存のサービスアカウントを選択または新規作成**
   - `waselab-30308@appspot.gserviceaccount.com` (Firebaseデフォルト)
   - または「サービスアカウントを作成」をクリック

3. **キーを作成**
   - サービスアカウントをクリック
   - 「キー」タブを選択
   - 「鍵を追加」→「新しい鍵を作成」
   - 「JSON」を選択→「作成」
   - **JSONファイルがダウンロードされます（重要：安全に保管）**

### ステップ2: Firebase Functions に設定

#### オプションA: Firebase環境変数として設定

```bash
# JSONファイルの内容から以下の値をコピー
firebase functions:config:set \
  googleapi.client_email="waselab-30308@appspot.gserviceaccount.com" \
  googleapi.private_key="-----BEGIN PRIVATE KEY-----\n実際のプライベートキー\n-----END PRIVATE KEY-----\n" \
  googleapi.project_id="waselab-30308"
```

#### オプションB: 環境変数として設定（より簡単）

```bash
# JSONファイル全体を環境変数として設定
export GOOGLE_SERVICE_ACCOUNT=$(cat ~/Downloads/サービスアカウントキー.json)

# またはFirebase Functionsのシークレットとして設定
firebase functions:secrets:set GOOGLE_SERVICE_ACCOUNT
# プロンプトが表示されたら、JSONファイルの内容全体を貼り付け
```

### ステップ3: Google Forms API を有効化

1. **API ライブラリにアクセス**
   ```
   https://console.cloud.google.com/apis/library?project=waselab-30308
   ```

2. **以下のAPIを検索して有効化**
   - ✅ Google Forms API
   - ✅ Google Drive API

### ステップ4: Firebase Functions を再デプロイ

```bash
cd functions
npm run build
firebase deploy --only functions:createGoogleFormFromTemplate
```

---

## 方法2: サービスアカウントに直接権限を付与（上級者向け）

### ステップ1: サービスアカウントに編集者権限を付与

1. **IAMページにアクセス**
   ```
   https://console.cloud.google.com/iam-admin/iam?project=waselab-30308
   ```

2. **サービスアカウントを探す**
   - `waselab-30308@appspot.gserviceaccount.com`

3. **ロールを編集**
   - 「編集」アイコンをクリック
   - 「別のロールを追加」
   - 「編集者」または「オーナー」を選択
   - 「保存」

### ステップ2: Domain-wide Delegation を設定（Google Workspaceの場合のみ）

Google Workspace を使用している場合は、ドメイン全体の委任を設定する必要があります。

---

## 🔍 動作確認

### 1. ログを確認

```bash
# Firebase Functionsのログを確認
firebase functions:log --only createGoogleFormFromTemplate -n 50
```

以下のログが表示されれば成功：
- `Getting auth client...`
- `Using configured service account: ...` または
- `Using GOOGLE_SERVICE_ACCOUNT environment variable`

### 2. アプリで試す

1. アプリを開く
2. 実験作成画面でアンケートテンプレートを選択
3. 「Googleフォームを作成」ボタンをクリック
4. フォームが自動的に作成されて開く

---

## ❌ エラーが出た場合

### エラー: "Google Forms APIへのアクセス権限がありません"
→ Google Forms APIが有効化されていません。上記ステップ3を実行してください。

### エラー: "認証エラーです"
→ サービスアカウントキーが正しく設定されていません。ステップ1-2を再確認してください。

### エラー: "internal"
→ Firebase Functionsのログを確認：
```bash
firebase functions:log --only createGoogleFormFromTemplate -n 100
```

---

## 📝 チェックリスト

- [ ] サービスアカウントキー（JSON）をダウンロードした
- [ ] Firebase Functions に環境変数を設定した
- [ ] Google Forms API を有効化した
- [ ] Google Drive API を有効化した
- [ ] Firebase Functions を再デプロイした
- [ ] ログに認証成功のメッセージが表示された

---

## 🆘 サポート

すべての手順を実行してもエラーが続く場合は、以下の情報を提供してください：

1. `firebase functions:log` の出力
2. エラーメッセージの全文
3. 実行した手順

---

## 🔐 セキュリティ注意事項

- **JSONキーファイルは絶対にGitにコミットしない**
- **他人と共有しない**
- **使用後は安全な場所に保管またはFirebase Secretsを使用**