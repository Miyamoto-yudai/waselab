# 📖 Google Forms 完全動作手順（詳細版）

## 🔴 問題の原因
- **App Engineデフォルトサービスアカウント**（waselab-30308@appspot.gserviceaccount.com）は**Google Forms APIをサポートしていません**
- これはGoogleの仕様による制限で、回避できません
- **解決策**: Google Apps Scriptを使用してフォームを作成

---

## 📝 ステップ1: Google Apps Scriptのセットアップ（5分）

### 1-1. Google Apps Scriptプロジェクトを作成

1. **Googleアカウントでログイン**していることを確認
2. ブラウザで [https://script.google.com/](https://script.google.com/) を開く
3. **「新しいプロジェクト」** ボタンをクリック
   ![新規プロジェクト作成](https://i.imgur.com/placeholder1.png)

### 1-2. プロジェクト名を変更

1. 左上の「無題のプロジェクト」をクリック
2. プロジェクト名を **「Forms API Service」** に変更
3. 「OK」をクリック

### 1-3. コードを貼り付け

1. エディタ内の既存コード（`function myFunction() {}`）を**全て選択**（Ctrl+A / Cmd+A）
2. **削除**（Delete / Backspace）
3. 以下のファイルの内容を**全てコピー**:
   ```
   /Users/yudaimiyamoto/Desktop/プログラム/flutter/waselab/google_apps_script/forms_api.gs
   ```
4. エディタに**貼り付け**（Ctrl+V / Cmd+V）
5. **保存**（Ctrl+S / Cmd+S）

### 1-4. テスト実行（権限の承認）

1. エディタ上部の関数選択ドロップダウンから **「test」** を選択
2. **「実行」** ボタン（▶）をクリック
3. **権限の承認**ダイアログが表示される:
   - 「権限を確認」をクリック
   - Googleアカウントを選択
   - 「詳細」をクリック
   - 「Forms API Service（安全ではないページ）に移動」をクリック
   - 「許可」をクリック
4. 実行ログでテストフォームが作成されたことを確認

### 1-5. Web Appとしてデプロイ

1. エディタ右上の **「デプロイ」** ボタンをクリック
2. **「新しいデプロイ」** を選択
3. 歯車アイコン ⚙️ をクリックし、**「ウェブアプリ」** を選択
4. 以下の設定を入力:

   | 項目 | 設定値 |
   |------|--------|
   | **説明** | Forms API v1 |
   | **次のユーザーとして実行** | 自分（あなたのメールアドレス） |
   | **アクセスできるユーザー** | 全員 |

5. **「デプロイ」** ボタンをクリック
6. 表示される **Web App URL** を**コピー**して保存
   ```
   例: https://script.google.com/macros/s/AKfycbwXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX/exec
   ```

---

## 🔧 ステップ2: Firebase Functionsの設定（3分）

### 2-1. ターミナルを開く

1. VSCodeまたはターミナルアプリを開く
2. プロジェクトディレクトリに移動:
   ```bash
   cd /Users/yudaimiyamoto/Desktop/プログラム/flutter/waselab
   ```

### 2-2. Apps Script URLを設定

1. コピーしたWeb App URLを使用して以下のコマンドを実行:
   ```bash
   firebase functions:config:set googleappsscript.url="ここにコピーしたURLを貼り付け"
   ```
   
   **実際の例**:
   ```bash
   firebase functions:config:set googleappsscript.url="https://script.google.com/macros/s/AKfycbwXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX/exec"
   ```

2. 設定が保存されたことを確認:
   ```bash
   firebase functions:config:get
   ```
   
   以下のような出力が表示されればOK:
   ```json
   {
     "googleappsscript": {
       "url": "https://script.google.com/macros/s/..."
     }
   }
   ```

### 2-3. Firebase Functionsを再デプロイ

1. functionsディレクトリに移動:
   ```bash
   cd functions
   ```

2. ビルドを実行:
   ```bash
   npm run build
   ```

3. デプロイを実行:
   ```bash
   npm run deploy
   ```
   
   または
   
   ```bash
   firebase deploy --only functions
   ```

4. デプロイ完了のメッセージを確認:
   ```
   ✔ Deploy complete!
   ```

---

## ✅ ステップ3: 動作確認（2分）

### 3-1. Flutterアプリで確認

1. **Flutterアプリを起動**
2. **実験作成画面**に移動
3. **「Googleフォームを作成」** ボタンをクリック
4. 成功メッセージと共に以下が表示される:
   - フォーム編集URL
   - フォームプレビューURL

### 3-2. ブラウザでテスト（オプション）

1. 以下のファイルをブラウザで開く:
   ```
   /Users/yudaimiyamoto/Desktop/プログラム/flutter/waselab/google_apps_script/test_form_creation.html
   ```

2. **Google Apps Script URL**を入力
3. **「テストフォームを作成」** をクリック
4. 成功メッセージを確認

### 3-3. 作成されたフォームを確認

1. [Google Drive](https://drive.google.com) を開く
2. 「マイドライブ」に作成されたフォームがあることを確認
3. フォームを開いて内容を確認

---

## 🚨 トラブルシューティング

### エラー1: 「Google Apps Script URLが設定されていません」

**原因**: Firebase FunctionsにURLが設定されていない

**解決方法**:
```bash
firebase functions:config:set googleappsscript.url="YOUR_URL"
firebase deploy --only functions
```

### エラー2: 「権限がありません」

**原因**: Google Apps Scriptの権限承認が完了していない

**解決方法**:
1. Google Apps Scriptエディタで「test」関数を実行
2. 権限の承認を完了する

### エラー3: 「500 Internal Server Error」

**原因**: Apps ScriptのデプロイURLが間違っている

**解決方法**:
1. Google Apps Scriptの「デプロイ」→「デプロイを管理」で正しいURLを確認
2. Firebase Functionsの設定を更新:
   ```bash
   firebase functions:config:set googleappsscript.url="正しいURL"
   firebase deploy --only functions
   ```

### エラー4: フォームが作成されない

**原因**: Apps Scriptのコードが正しく保存されていない

**解決方法**:
1. Google Apps Scriptエディタでコードを確認
2. Ctrl+S / Cmd+Sで保存
3. 「デプロイ」→「デプロイを管理」→「編集」→「バージョン」を「新しいバージョン」に
4. 「デプロイ」をクリック

---

## 📊 動作フロー図

```
Flutterアプリ
    ↓ (1) フォーム作成リクエスト
Firebase Functions (createGoogleFormFromTemplate)
    ↓ (2) HTTP POST
Google Apps Script Web App
    ↓ (3) FormApp.create()
Google Forms API
    ↓ (4) フォーム作成
Google Drive
    ↓ (5) URL返却
Firebase Functions
    ↓ (6) レスポンス
Flutterアプリ (URLを表示)
```

---

## 🎯 確認ポイント

✅ Google Apps Scriptが正しくデプロイされている
✅ Web App URLがFirebase Functionsに設定されている
✅ Firebase Functionsが最新版にデプロイされている
✅ Flutterアプリから正常にフォームが作成できる

---

## 📝 メモ

- Google Apps Scriptは**あなたのGoogleアカウント**で実行されます
- 作成されたフォームは**あなたのGoogle Drive**に保存されます
- Firebase FunctionsはApps Scriptを**プロキシ**として使用します
- この方法により、サービスアカウントの制限を回避できます

---

## 🆘 サポート

問題が解決しない場合は、以下の情報を確認してください:

1. **Firebase Functionsのログ**:
   ```bash
   firebase functions:log
   ```

2. **Google Apps Scriptの実行ログ**:
   - Apps Scriptエディタ → 「実行数」→「実行ログ」

3. **ブラウザのコンソールログ**:
   - F12キーでデベロッパーツールを開く
   - Consoleタブを確認