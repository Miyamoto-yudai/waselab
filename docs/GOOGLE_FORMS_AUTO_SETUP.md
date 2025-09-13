# Google Forms 完全自動作成機能のセットアップガイド

## 概要
Firebase Functionsを使用してサーバーサイドでGoogleフォームを自動作成する機能のセットアップ手順です。

## セットアップ手順

### 1. Google Cloud Console でプロジェクトを設定

1. [Google Cloud Console](https://console.cloud.google.com/) にアクセス
2. Firebaseプロジェクトを選択（または新規作成）
3. 左メニューから「APIとサービス」→「ライブラリ」を選択

### 2. Google Forms API を有効化

1. 検索バーで「Google Forms API」を検索
2. 「Google Forms API」をクリック
3. 「有効にする」ボタンをクリック

### 3. サービスアカウントを作成

1. 左メニューから「IAMと管理」→「サービスアカウント」を選択
2. 「サービスアカウントを作成」をクリック
3. 以下の情報を入力：
   - サービスアカウント名: `forms-creator`
   - サービスアカウントID: 自動生成されるものを使用
   - 説明: `Google Forms自動作成用`
4. 「作成して続行」をクリック
5. ロールは設定不要なので「続行」をクリック
6. 「完了」をクリック

### 4. サービスアカウントキーを作成

1. 作成したサービスアカウントをクリック
2. 「キー」タブを選択
3. 「鍵を追加」→「新しい鍵を作成」をクリック
4. 「JSON」を選択して「作成」をクリック
5. JSONファイルがダウンロードされます（重要：このファイルは安全に保管）

### 5. Firebase プロジェクトに認証情報を設定

#### 方法1: 環境変数として設定（推奨）

```bash
# Firebase Functionsのディレクトリに移動
cd functions

# サービスアカウントキーを環境変数として設定
firebase functions:config:set googleapi.client_email="YOUR_CLIENT_EMAIL"
firebase functions:config:set googleapi.private_key="YOUR_PRIVATE_KEY"
firebase functions:config:set googleapi.project_id="YOUR_PROJECT_ID"
```

#### 方法2: Application Default Credentials を使用

```bash
# ローカル開発用
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account-key.json"

# または、Firebase Functionsにデプロイ時に自動的に使用される
# （Firebase プロジェクトのデフォルトサービスアカウントを使用）
```

### 6. Firebase Functions をデプロイ

```bash
# Functionsディレクトリで実行
cd functions
npm run build
firebase deploy --only functions:createGoogleFormFromTemplate,functions:createQuickGoogleForm
```

### 7. Google Forms へのアクセス権限を設定

**重要**: サービスアカウントがGoogle Formsを作成できるようにするため、以下の設定が必要です：

1. Google Workspace管理コンソールにアクセス（管理者権限が必要）
2. 「セキュリティ」→「APIコントロール」→「ドメイン全体の委任」を選択
3. 「APIクライアントを管理」をクリック
4. サービスアカウントのクライアントIDを追加
5. OAuth スコープに以下を追加：
   - `https://www.googleapis.com/auth/forms.body`
   - `https://www.googleapis.com/auth/drive.file`

**注意**: 個人のGoogleアカウントの場合、この設定は不要ですが、作成されたフォームの所有者がサービスアカウントになります。

### 8. Flutter アプリから使用

アプリはFirebase Functionsを呼び出すだけで、自動的にGoogleフォームが作成されます：

```dart
// Firebase Functions を呼び出し
final result = await FirebaseFunctions.instance
    .httpsCallable('createGoogleFormFromTemplate')
    .call({
  'template': templateData,
  'customTitle': 'アンケート_${DateTime.now().millisecondsSinceEpoch}',
});

// 作成されたフォームを開く
final formUrl = result.data['formUrl'];
await launchUrl(Uri.parse(formUrl));
```

## トラブルシューティング

### エラー: "Google Forms APIへのアクセス権限がありません"
- Google Forms APIが有効になっているか確認
- サービスアカウントの権限を確認

### エラー: "認証エラーです"
- サービスアカウントキーが正しく設定されているか確認
- 環境変数が正しく設定されているか確認

### フォームが作成されない
- Firebase Functionsのログを確認：
  ```bash
  firebase functions:log
  ```

## セキュリティに関する注意事項

1. **サービスアカウントキーの管理**
   - JSONキーファイルは絶対にGitにコミットしない
   - 環境変数またはSecret Managerを使用

2. **アクセス制限**
   - Firebase Functionsは認証済みユーザーのみ呼び出し可能に設定済み
   - 必要に応じてレート制限を追加

3. **ログ記録**
   - すべてのフォーム作成はFirestoreに記録される
   - 不正使用の監視が可能

## まとめ

この設定により、ユーザーは：
1. テンプレートを選択
2. 「フォームを作成」ボタンをクリック
3. 自動的に設定済みのGoogleフォームが開く

という3ステップで完全自動化されたフォーム作成が可能になります。