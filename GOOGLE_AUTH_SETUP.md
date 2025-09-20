# Google認証の設定ガイド

## 「このアプリはGoogleで確認されていません」の警告について

### 🎯 なぜこの警告が表示されるのか

Googleは、ユーザーのプライバシーを保護するため、以下のような「センシティブなスコープ」を使用するアプリに対して厳格な審査を要求します：
- Googleカレンダーへのアクセス
- Google Formsへのアクセス
- Google Driveへのアクセス

### 🚀 開発中の対処法

#### 方法1: テストユーザーとして登録（推奨）

1. [Google Cloud Console](https://console.cloud.google.com)にアクセス
2. プロジェクト「waselab-30308」を選択
3. 左メニュー → 「APIとサービス」 → 「OAuth同意画面」
4. 「テストユーザー」セクションで「+ ADD USERS」をクリック
5. 使用するGoogleアカウントのメールアドレスを追加
   - yudai61104@gmail.com
   - その他、テストに使用するアカウント

#### 方法2: 警告を一時的に回避

1. 警告画面で「詳細」をクリック
2. 「安全でないページに移動」を選択
3. アプリへのアクセスを許可

**注意**: この方法は開発者本人のアカウントでのみ使用してください。

### 📝 本番環境での対処法

#### オプション1: Google認証の審査を申請

1. OAuth同意画面で「公開ステータス」を「本番環境」に変更
2. 必要な情報を入力：
   - アプリケーションのホームページ
   - プライバシーポリシーURL
   - 利用規約URL
   - 承認済みドメイン
3. 審査を申請（1-2週間かかる場合があります）

#### オプション2: センシティブなスコープを使用しない実装（現在採用）

現在のコードは、センシティブなスコープを回避する実装に変更されています：

- **Googleカレンダー**: URLスキームを使用してカレンダーアプリを開く
- **Google Forms**: URLスキームを使用してブラウザでフォームを開く
- **認証**: 基本的なプロフィール情報のみ取得

### 🔧 設定ファイルの確認

#### 1. OAuth 2.0 クライアントID

`web/index.html`で設定されているクライアントIDを確認：
```html
<meta name="google-signin-client_id" content="YOUR_CLIENT_ID.apps.googleusercontent.com">
```

#### 2. Firebase設定

`lib/firebase_options.dart`で正しいプロジェクトが設定されているか確認

### 🛠 トラブルシューティング

#### 問題: 警告が消えない

**解決策**:
1. ブラウザのキャッシュをクリア
2. シークレットモードで再度テスト
3. 別のGoogleアカウントでテスト

#### 問題: 権限エラーが発生する

**解決策**:
1. Google Cloud Consoleで有効なAPIを確認
   - Google Calendar API
   - Google Forms API
   - Google Drive API
2. OAuth同意画面のスコープを確認

### 📚 参考リンク

- [Google OAuth 2.0 ガイド](https://developers.google.com/identity/protocols/oauth2)
- [OAuth同意画面の設定](https://support.google.com/cloud/answer/6158849)
- [センシティブなスコープ](https://developers.google.com/identity/protocols/oauth2/scopes)

### ✅ チェックリスト

- [ ] テストユーザーとして登録済み
- [ ] OAuth同意画面の設定完了
- [ ] 必要なAPIが有効化されている
- [ ] クライアントIDが正しく設定されている

## 連絡先

問題が解決しない場合は、開発者（yudai61104@gmail.com）までご連絡ください。