# Firebase Authentication メールテンプレート設定ガイド

## 重要：迷惑メール対策のための設定

Firebase Consoleでメールテンプレートを日本語にカスタマイズし、迷惑メールに振り分けられにくくする設定を行ってください。

## 設定手順

### 1. Firebase Consoleにアクセス
1. [Firebase Console](https://console.firebase.google.com/) にログイン
2. プロジェクト「experiment-cooperation-app」を選択
3. 左メニューから「Authentication」を選択
4. 上部タブから「Templates」を選択

### 2. メール認証テンプレートの設定

「Email verification」を選択し、以下の設定を行ってください：

#### 件名（Subject）
```
【わせラボ】メールアドレスの確認をお願いします
```

#### 本文（Message）
```html
<p>わせラボをご利用いただきありがとうございます。</p>

<p>以下のボタンをクリックして、メールアドレスの確認を完了してください。</p>

<p style="text-align: center;">
  <a href="%LINK%" style="background-color: #8E1728; color: white; padding: 12px 24px; text-decoration: none; border-radius: 4px; display: inline-block;">
    メールアドレスを確認する
  </a>
</p>

<p>ボタンが機能しない場合は、以下のURLをブラウザにコピー＆ペーストしてください：<br>
%LINK%</p>

<p><strong>このメールに心当たりがない場合：</strong><br>
他の方が誤ってあなたのメールアドレスを入力した可能性があります。このメールは無視していただいて構いません。</p>

<p>---<br>
わせラボ - 早稲田大学実験協力プラットフォーム<br>
運営チーム</p>

<p style="font-size: 12px; color: #666;">
※このメールは送信専用アドレスから送信されています。返信はできません。<br>
※メールが正しく表示されない場合は、迷惑メールフォルダもご確認ください。
</p>
```

### 3. パスワードリセットテンプレートの設定

「Password reset」を選択し、以下の設定を行ってください：

#### 件名（Subject）
```
【わせラボ】パスワードリセットのご案内
```

#### 本文（Message）
```html
<p>わせラボをご利用いただきありがとうございます。</p>

<p>パスワードリセットのリクエストを受け付けました。以下のボタンをクリックして、新しいパスワードを設定してください。</p>

<p style="text-align: center;">
  <a href="%LINK%" style="background-color: #8E1728; color: white; padding: 12px 24px; text-decoration: none; border-radius: 4px; display: inline-block;">
    パスワードをリセットする
  </a>
</p>

<p>ボタンが機能しない場合は、以下のURLをブラウザにコピー＆ペーストしてください：<br>
%LINK%</p>

<p><strong>このメールに心当たりがない場合：</strong><br>
第三者があなたのアカウントへのアクセスを試みている可能性があります。パスワードリセットを行っていない場合は、このメールを無視してください。あなたのパスワードは変更されません。</p>

<p>---<br>
わせラボ - 早稲田大学実験協力プラットフォーム<br>
運営チーム</p>

<p style="font-size: 12px; color: #666;">
※このメールは送信専用アドレスから送信されています。返信はできません。<br>
※メールが正しく表示されない場合は、迷惑メールフォルダもご確認ください。
</p>
```

### 4. 送信者情報の設定

Firebase Consoleの「Settings」タブで以下を設定：

#### Sender name（送信者名）
```
わせラボ運営チーム
```

#### Reply-to email（返信先メールアドレス）
```
support@waselabo.com
```
※実際のサポートメールアドレスを設定してください

### 5. カスタムドメインの設定（推奨）

迷惑メール判定を避けるため、カスタムドメインの設定を強く推奨します：

1. 「Settings」タブの「Custom domain」セクションへ
2. 「Customize domain」をクリック
3. ドメイン（例：`auth.waselabo.com`）を入力
4. DNSレコードの設定指示に従う

### 6. SPF/DKIM/DMARCの設定（カスタムドメイン使用時）

メール配信の信頼性を高めるため、以下のDNSレコードを設定：

#### SPFレコード
```
v=spf1 include:_spf.firebasemail.com ~all
```

#### DKIMレコード
Firebase Consoleに表示される指示に従って設定

#### DMARCレコード
```
v=DMARC1; p=quarantine; rua=mailto:dmarc@waselabo.com
```

## ユーザーへの案内

アプリ内で以下の案内を表示することを推奨：

1. **新規登録時の注意事項**
   - 早稲田大学のメールアドレスを使用
   - 迷惑メールフォルダを確認
   - `noreply@experiment-cooperation-app.firebaseapp.com`を連絡先に追加

2. **メールが届かない場合の対処法**
   - 迷惑メール/プロモーションフォルダを確認
   - メールアドレスの入力ミスを確認
   - 数分待ってから再送信

## トラブルシューティング

### メールが届かない場合
1. Firebase Consoleの「Authentication」→「Users」でユーザーのメール認証状態を確認
2. メール送信ログを確認（Firebase Console → Authentication → Usage）
3. 送信制限に達していないか確認（1日あたりの送信数制限あり）

### 迷惑メール判定される場合
1. カスタムドメインの設定を確認
2. SPF/DKIM/DMARCレコードが正しく設定されているか確認
3. メール本文に過度なリンクや画像が含まれていないか確認

## 注意事項

- Firebaseの無料プランでは1日あたりのメール送信数に制限があります（100通/日）
- 本番環境では必ずカスタムドメインを使用することを推奨
- メールテンプレートの変更は即座に反映されます