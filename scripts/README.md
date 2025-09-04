# 管理者アカウント設定ガイド

## セットアップ手順

### 1. サービスアカウントキーの取得

1. [Firebase Console](https://console.firebase.google.com) にアクセス
2. プロジェクトを選択
3. 左メニューの歯車アイコン → **プロジェクト設定**
4. **サービスアカウント** タブを選択
5. **新しい秘密鍵の生成** をクリック
6. ダウンロードしたJSONファイルを `scripts/serviceAccountKey.json` として保存

⚠️ **重要**: `serviceAccountKey.json` は機密情報なので、絶対にGitにコミットしないでください！

### 2. 依存関係のインストール

```bash
cd scripts
npm install
```

### 3. 管理者情報の設定

`setup_admin.js` ファイルを編集して、管理者情報を設定：

```javascript
const adminEmail = 'admin@example.com'; // あなたのメールアドレスに変更
const adminPassword = 'your-secure-password'; // 安全なパスワードに変更
const adminName = 'システム管理者'; // 管理者名を設定
```

### 4. スクリプトの実行

```bash
npm run setup-admin
```

または

```bash
node setup_admin.js
```

## 手動で設定する場合

### Firebase Authenticationで設定

1. Firebase Console → Authentication → Users
2. 「ユーザーを追加」をクリック
3. メールアドレスとパスワードを設定
4. 作成されたユーザーのUIDをコピー

### Firestoreで設定

1. Firebase Console → Firestore Database
2. 「コレクションを開始」をクリック
3. コレクションID: `admins`
4. ドキュメントID: コピーしたUID
5. 以下のフィールドを追加：

| フィールド | タイプ | 値 |
|---------|-------|-----|
| uid | string | コピーしたUID |
| email | string | 管理者のメールアドレス |
| name | string | 管理者名 |
| role | string | super_admin |
| permissions | array | ["view_users", "edit_users", "view_chats", "send_support_messages", "send_announcements", "view_experiments", "edit_experiments", "view_statistics", "manage_admins"] |
| createdAt | timestamp | サーバータイムスタンプ |
| isActive | boolean | true |

## ログイン方法

1. アプリのログイン画面を開く
2. 画面下部の控えめな「管理者」ボタンをクリック
3. 設定したメールアドレスとパスワードでログイン

## セキュリティ注意事項

- 管理者パスワードは十分に強力なものを使用してください
- サービスアカウントキーは安全に管理してください
- 本番環境では2要素認証の導入を検討してください
- 管理者アカウントへのアクセスログは定期的に確認してください

## トラブルシューティング

### ログインできない場合

1. Firestoreで `admins` コレクションが正しく作成されているか確認
2. ドキュメントIDがAuthenticationのUIDと一致しているか確認
3. `isActive` フィールドが `true` になっているか確認

### 権限エラーが出る場合

1. `permissions` 配列に必要な権限が含まれているか確認
2. `role` フィールドが設定されているか確認