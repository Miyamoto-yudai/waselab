# Google Forms 編集権限セットアップガイド

## 概要
このガイドでは、連携したGoogleアカウントでGoogleフォームを編集できるようにするための設定手順を説明します。

## セットアップ手順

### 1. Google Apps Script のデプロイ

1. Google Apps Script にアクセス
   - https://script.google.com/ にアクセス
   - 新しいプロジェクトを作成

2. スクリプトの設置
   - `google_apps_script/forms_api_with_sharing.gs` の内容をコピー
   - Apps Script エディタに貼り付け
   - ファイルを保存（Ctrl+S または Cmd+S）

3. Web アプリとしてデプロイ
   - 右上の「デプロイ」ボタンをクリック
   - 「新しいデプロイ」を選択
   - 種類：「ウェブアプリ」を選択
   - 設定：
     - 説明：「Forms API with Sharing」
     - 次のユーザーとして実行：「自分」
     - アクセスできるユーザー：「全員」
   - 「デプロイ」をクリック

4. Web App URLをコピー
   - デプロイ後に表示される URL をコピー
   - 例：`https://script.google.com/macros/s/AKfyc.../exec`

### 2. Firebase Functions の環境変数設定

```bash
# Firebase Functions に環境変数を設定
firebase functions:config:set google_apps_script.url="YOUR_WEB_APP_URL"

# 設定を確認
firebase functions:config:get

# Functions をデプロイ
firebase deploy --only functions
```

### 3. Firebase Functions のコード確認

`functions/src/googleFormsViaAppsScript.ts` に以下の変更が適用されていることを確認：

- ユーザーのメールアドレスを取得する処理が追加されている
- `userEmail` パラメータが Google Apps Script に送信されている

### 4. Flutter アプリの確認

以下のファイルに変更が適用されていることを確認：

- `lib/services/google_forms_service.dart`
  - 連携したGoogleアカウントのメールアドレスが送信される

- `lib/services/auth_service.dart`
  - `updateGoogleEmail` メソッドが追加されている

- `lib/models/app_user.dart`
  - `googleEmail` フィールドが追加されている

- `lib/screens/settings_screen.dart`
  - Googleアカウント連携時にメールアドレスが保存される

### 5. 動作確認

1. アプリでGoogleアカウントを連携
   - 設定画面から「Googleアカウントを選択」
   - 使用したいGoogleアカウントでログイン

2. アンケート作成をテスト
   - 実験作成画面でアンケートテンプレートを選択
   - 「Googleフォームを作成」ボタンをクリック

3. 編集権限の確認
   - 作成されたGoogleフォームがブラウザで開く
   - 連携したアカウントで編集可能なことを確認

## トラブルシューティング

### エラー：「Google Apps Script URLが設定されていません」
- Firebase Functions の環境変数が正しく設定されているか確認
- `firebase functions:config:get` で URL が表示されるか確認

### エラー：「フォームの作成に失敗しました」
- Google Apps Script のデプロイ設定を確認
- アクセス権限が「全員」になっているか確認

### 編集権限が付与されない
- Google Apps Script のコンソールでエラーログを確認
- メールアドレスが正しく送信されているか確認
- Firestore の users コレクションに `googleEmail` フィールドがあるか確認

## セキュリティ考慮事項

- Google Apps Script は信頼できるドメインからのみアクセス可能にすることを推奨
- 本番環境では適切なアクセス制限を設定
- ユーザーのメールアドレスは暗号化して保存することを検討

## サポート

問題が解決しない場合は、以下の情報と共に報告してください：
- エラーメッセージの完全なテキスト
- Firebase Functions のログ
- Google Apps Script の実行ログ
- ブラウザのコンソールエラー