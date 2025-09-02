# Firebase認証メールのテンプレート設定ガイド

## 概要
アカウント作成時の認証メールが迷惑メールと誤解されないよう、日本語と英語の併記でテンプレートを設定します。

## Firebase Consoleでの設定手順

### 1. Firebase Consoleにアクセス
1. [Firebase Console](https://console.firebase.google.com)にログイン
2. プロジェクト「experiment-cooperation-app」を選択
3. 左側メニューから「Authentication」をクリック

### 2. メールテンプレートの編集
1. 「Templates」タブを選択
2. 「Email verification」を選択
3. 「Edit template」をクリック

### 3. 推奨テンプレート設定

#### 件名（Subject）
```
【重要/Important】メールアドレスの確認 / Email Verification - 実験協力アプリ
```

#### 送信者名（Sender name）
```
実験協力アプリ / Experiment Cooperation App
```

#### メッセージ本文（Message）
```html
<p>実験協力アプリをご利用いただきありがとうございます。</p>
<p>Thank you for using the Experiment Cooperation App.</p>

<p>以下のリンクをクリックして、メールアドレスの確認を完了してください。</p>
<p>Please click the link below to verify your email address.</p>

<p><a href="%LINK%" style="background-color: #4CAF50; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; display: inline-block;">メールアドレスを確認 / Verify Email</a></p>

<p>このリンクは1時間後に無効になります。</p>
<p>This link will expire in 1 hour.</p>

<hr style="margin: 20px 0;">

<p><strong>注意事項 / Important Notes:</strong></p>
<ul>
  <li>このメールは実験協力アプリからの自動送信メールです。</li>
  <li>This is an automated email from the Experiment Cooperation App.</li>
  <li>心当たりがない場合は、このメールを無視してください。</li>
  <li>If you did not create an account, please ignore this email.</li>
  <li>返信は受け付けておりません。</li>
  <li>Please do not reply to this email.</li>
</ul>

<p style="margin-top: 30px; color: #666;">
実験協力アプリ運営チーム<br>
Experiment Cooperation App Team
</p>
```

### 4. その他の認証メールテンプレート

#### パスワードリセット（Password reset）

**件名:**
```
【パスワードリセット/Password Reset】実験協力アプリ
```

**本文:**
```html
<p>パスワードリセットのリクエストを受け付けました。</p>
<p>We received a request to reset your password.</p>

<p>以下のリンクをクリックして、新しいパスワードを設定してください。</p>
<p>Please click the link below to set a new password.</p>

<p><a href="%LINK%" style="background-color: #2196F3; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; display: inline-block;">パスワードをリセット / Reset Password</a></p>

<p>このリンクは1時間後に無効になります。</p>
<p>This link will expire in 1 hour.</p>

<p>心当たりがない場合は、このメールを無視してください。</p>
<p>If you did not request this, please ignore this email.</p>
```

### 5. 設定の保存
1. 各テンプレートの編集後、「Save」をクリック
2. 変更が反映されたことを確認

## 注意事項

- Firebase Authenticationの無料プランでは、メール送信元のドメインはFirebaseのものになります
- カスタムドメインを使用する場合は、Firebase Authentication with SendGridなどの設定が必要です
- HTMLメールとプレーンテキストメールの両方を設定することを推奨します

## テスト方法

1. アプリで新規アカウントを作成
2. 認証メールが送信されることを確認
3. メールの表示と内容を確認
4. リンクをクリックして認証が完了することを確認

## トラブルシューティング

### メールが届かない場合
- 迷惑メールフォルダを確認
- Firebaseコンソールで送信状況を確認
- メールアドレスが正しいか確認

### カスタマイズが反映されない場合
- Firebase Consoleで保存が完了しているか確認
- キャッシュをクリアして再度確認
- 数分待ってから再度確認