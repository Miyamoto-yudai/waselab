# 手動でのセットアップが必要な項目

## 完了した作業 ✅

### 1. コードの修正と準備
- ✅ Google Apps Script の改善版コード作成 (`forms_api_with_sharing.gs`)
- ✅ Firebase Functions のコード更新（ユーザーメール送信機能追加）
- ✅ Flutter アプリのコード更新（Googleアカウント連携機能）
- ✅ Firebase Functions のビルドとデプロイ（進行中）

### 2. 既存の設定確認
- ✅ Firebase Functions の環境変数に Google Apps Script URL が設定済み
  - URL: `https://script.google.com/macros/s/AKfycbygtwTFvyj3GI7IO5JvEEDPgqmgOZv8RvdMNIyTGInHGlryFhK39wT578GKiIZdGsC8/exec`

## 手動で実行が必要な作業 ⚠️

### 1. Google Apps Script の更新 【重要】

現在のGoogle Apps Scriptは古いバージョンです。編集権限を付与する機能を追加するには：

1. **Google Apps Script にアクセス**
   - https://script.google.com/ を開く
   - 既存のプロジェクトを開く（または URL から直接アクセス）

2. **コードを更新**
   - 現在のコードをバックアップ
   - `google_apps_script/forms_api_with_sharing.gs` の内容で置き換え
   - 主な変更点：
     - `userEmail` パラメータの受け取り
     - `DriveApp.getFileById(form.getId()).addEditor(userEmail)` による編集権限付与

3. **再デプロイ**
   - 「デプロイ」→「デプロイを管理」
   - 「編集」（鉛筆アイコン）をクリック
   - バージョン：「新バージョン」
   - 説明：「編集権限付与機能を追加」
   - 「デプロイ」をクリック

   ⚠️ **重要**: デプロイ後も URL は変わらないので、Firebase Functions の設定変更は不要

### 2. アプリでの動作確認

1. **Googleアカウント連携**
   - アプリの設定画面を開く
   - 「Googleアカウントを選択」をタップ
   - フォーム編集に使用したいGoogleアカウントでログイン

2. **アンケート作成テスト**
   - 実験作成画面でアンケートテンプレートを選択
   - 「Googleフォームを作成」ボタンをクリック
   - 作成されたフォームが開く

3. **編集権限の確認**
   - 作成されたGoogleフォームで「編集」ボタンが表示されることを確認
   - 連携したアカウントで編集可能なことを確認

## トラブルシューティング

### 編集権限が付与されない場合

1. **Google Apps Script のログを確認**
   - Apps Script エディタで「実行」→「実行履歴」
   - エラーがないか確認

2. **Firestore のデータ確認**
   - Firebase Console で users コレクションを確認
   - 該当ユーザーに `googleEmail` フィールドがあるか確認

3. **権限エラーの場合**
   - Google Apps Script の実行権限を確認
   - 「全員」がアクセスできる設定になっているか確認

## なぜ手動作業が必要か

- **Google Apps Script**: Google のセキュリティ制限により、外部からのコード更新やデプロイの自動化ができません
- **OAuth 認証**: ユーザーごとの Google アカウント認証は、ユーザー自身が手動で行う必要があります

## 作業時間の目安

- Google Apps Script の更新：約5分
- 動作確認：約3分
- 合計：約8分