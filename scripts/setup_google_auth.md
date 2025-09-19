# Google Forms API 認証設定手順

Google Forms APIを使用してフォームを自動作成するには、以下の手順で認証設定を行ってください。

## 手順

### 1. Google Cloud Consoleでプロジェクトを作成

1. [Google Cloud Console](https://console.cloud.google.com/) にアクセス
2. 新しいプロジェクトを作成、または既存のプロジェクトを選択

### 2. Google Forms APIを有効化

1. [API ライブラリ](https://console.cloud.google.com/apis/library) にアクセス
2. 「Google Forms API」を検索
3. 「有効にする」をクリック

### 3. 認証情報の作成

1. [認証情報](https://console.cloud.google.com/apis/credentials) ページに移動
2. 「認証情報を作成」→「OAuth クライアント ID」を選択
3. アプリケーションの種類で「デスクトップ」を選択
4. 名前を入力（例：「わせラボフォーム作成」）
5. 「作成」をクリック

### 4. 認証情報のダウンロード

1. 作成したOAuthクライアントの右側の「ダウンロード」アイコンをクリック
2. JSONファイルをダウンロード
3. ダウンロードしたファイルを `credentials.json` にリネーム
4. `/Users/yudaimiyamoto/Desktop/プログラム/flutter/waselab/scripts/` フォルダに配置

### 5. スクリプトの実行

```bash
cd /Users/yudaimiyamoto/Desktop/プログラム/flutter/waselab/scripts
python create_google_form.py
```

初回実行時：
- ブラウザが開き、Googleアカウントでのログインを求められます
- 権限を許可してください
- 認証が完了すると、`token.json` が自動生成されます

## 注意事項

- `credentials.json` と `token.json` は機密情報です。Gitには追加しないでください
- `.gitignore` に以下を追加することを推奨：
  ```
  scripts/credentials.json
  scripts/token.json
  scripts/form_urls.txt
  ```

## トラブルシューティング

### エラー: "Google Forms API has not been used in project..."
→ Google Cloud ConsoleでForms APIを有効化してください

### エラー: "credentials.json not found"
→ 認証情報をダウンロードして、正しいファイル名で配置してください

### エラー: "Access blocked: Authorization Error"
→ OAuth同意画面の設定が必要な場合があります。Cloud Consoleで設定してください