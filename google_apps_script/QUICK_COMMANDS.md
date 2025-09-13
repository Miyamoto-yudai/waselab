# 🚀 クイックコマンド集

## 1️⃣ Google Apps Script側の作業

### コピーするコード
```javascript
// 以下のファイルの内容を全てコピー
/Users/yudaimiyamoto/Desktop/プログラム/flutter/waselab/google_apps_script/forms_api.gs
```

### デプロイ設定
- **実行**: 自分
- **アクセス**: 全員

---

## 2️⃣ ターミナルコマンド（コピペ用）

### Step 1: プロジェクトに移動
```bash
cd /Users/yudaimiyamoto/Desktop/プログラム/flutter/waselab
```

### Step 2: Apps Script URLを設定（URLを置き換えて実行）
```bash
firebase functions:config:set googleappsscript.url="ここにGoogle Apps ScriptのWeb App URLを貼り付け"
```

### Step 3: 設定を確認
```bash
firebase functions:config:get
```

### Step 4: Firebase Functionsをデプロイ
```bash
cd functions && npm run build && npm run deploy
```

---

## 3️⃣ 一括実行コマンド（URLを設定後）

```bash
cd /Users/yudaimiyamoto/Desktop/プログラム/flutter/waselab && \
firebase functions:config:set googleappsscript.url="YOUR_APPS_SCRIPT_URL" && \
cd functions && \
npm run build && \
npm run deploy
```

---

## 4️⃣ 動作確認

### Firebaseログを確認
```bash
firebase functions:log --only createGoogleFormFromTemplate
```

### ローカルテスト（オプション）
```bash
cd functions
npm run serve
```

---

## 5️⃣ エラー時の対処

### 設定をリセット
```bash
firebase functions:config:unset googleappsscript
firebase functions:config:set googleappsscript.url="新しいURL"
firebase deploy --only functions
```

### 強制デプロイ
```bash
firebase deploy --only functions --force
```

---

## 📌 重要なURL

- Google Apps Script: https://script.google.com/
- Google Drive: https://drive.google.com/
- Firebase Console: https://console.firebase.google.com/

---

## ✅ チェックリスト

- [ ] Google Apps Scriptにコードを貼り付けた
- [ ] test関数を実行して権限を承認した
- [ ] Web Appとしてデプロイした
- [ ] Web App URLをコピーした
- [ ] Firebase Functionsに設定した
- [ ] Firebase Functionsをデプロイした
- [ ] アプリでフォーム作成を確認した