# 即座にGoogle Formsを動作させる手順

## 🚨 重要: App Engineデフォルトサービスアカウントの制限
現在使用している `waselab-30308@appspot.gserviceaccount.com` はApp Engineのデフォルトサービスアカウントであり、**Google Forms APIをサポートしていません**。これは仕様上の制限です。

## ✅ 即座に動作する解決策: Google Apps Script

### 手順1: Google Apps Scriptをデプロイ (3分)

1. **Google Apps Scriptプロジェクトを開く**
   - [https://script.google.com/](https://script.google.com/) にアクセス
   - 「新しいプロジェクト」をクリック

2. **コードを貼り付け**
   - デフォルトのコードを全て削除
   - `google_apps_script/forms_api.gs` の内容を全てコピーして貼り付け
   - Ctrl+S (またはCmd+S) で保存

3. **Web Appとしてデプロイ**
   - 右上の「デプロイ」ボタン → 「新しいデプロイ」
   - 設定:
     - 種類: **ウェブアプリ**
     - 説明: **Forms API Service**
     - 次のユーザーとして実行: **自分**
     - アクセスできるユーザー: **全員**
   - 「デプロイ」をクリック
   - **表示されるWeb App URLをコピー**

### 手順2: Firebase FunctionsにURLを設定 (1分)

コピーしたURLを以下のコマンドで設定:

```bash
firebase functions:config:set googleappsscript.url="コピーしたURL"
```

### 手順3: Firebase Functionsを再デプロイ (2分)

```bash
cd functions
npm run deploy
```

## ✅ 動作確認

1. アプリでGoogle Form作成ボタンをクリック
2. フォームが正常に作成される
3. 編集URLとプレビューURLが表示される

## なぜこの方法が確実に動作するか

1. **サービスアカウント不要**: Google Apps Scriptはあなたのアカウントで直接実行
2. **権限問題なし**: Forms APIの制限を回避
3. **即座に利用可能**: 5分以内にセットアップ完了

## トラブルシューティング

もしエラーが出る場合:

1. **Apps Scriptの実行権限を確認**
   - 初回実行時に権限の承認が必要な場合があります
   - Apps Scriptエディタで「test」関数を実行して権限を確認

2. **URLが正しく設定されているか確認**
   ```bash
   firebase functions:config:get
   ```

3. **デプロイステータスを確認**
   - Google Apps Script: デプロイ管理から「アクティブ」を確認
   - Firebase Functions: デプロイログを確認

## 完了！
これで確実にGoogle Formsが作成できるようになります。