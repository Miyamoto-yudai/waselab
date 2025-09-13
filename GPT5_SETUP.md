# GPT-5アンケート生成機能セットアップガイド

## 概要
この機能は、GPT-5（熟考モード）を使用して実験用アンケートの雛形を自動生成します。

## セットアップ手順

### 1. OpenAI APIキーの取得

1. [OpenAI Platform](https://platform.openai.com/)にアクセス
2. アカウントを作成またはログイン
3. API Keysページで新しいAPIキーを生成
4. キーを安全な場所に保存

### 2. Firebase Functions環境変数の設定

#### 方法1: Firebase Consoleで設定（本番環境推奨）

1. [Firebase Console](https://console.firebase.google.com/)にアクセス
2. プロジェクトを選択
3. Functions → Configuration → Environment Variables
4. 以下の環境変数を追加：
   - `GPT_API_KEY`: OpenAI APIキー
   - `GPT_MODEL_NAME`: gpt-5
   - `GOOGLE_APPS_SCRIPT_URL`: Apps Script URL

#### 方法2: .env.localファイルを使用（ローカル開発）

1. `functions/.env.example`を`functions/.env.local`にコピー
2. `.env.local`ファイルを編集：

```env
GPT_API_KEY=your-actual-api-key-here
GPT_MODEL_NAME=gpt-5
GOOGLE_APPS_SCRIPT_URL=your-apps-script-url
```

**重要**: `.env.local`ファイルはGitにコミットしないでください！

#### 方法3: Firebase CLIでデプロイ時に設定

```bash
# 環境変数を指定してデプロイ
firebase deploy --only functions \
  --set-env-vars GPT_API_KEY="your-api-key",GPT_MODEL_NAME="gpt-5",GOOGLE_APPS_SCRIPT_URL="your-url"
```

### 3. Firebase Functionsのデプロイ

```bash
# プロジェクトルートから
firebase deploy --only functions:generateSurveyWithGPT,functions:validateGPTAPIKey,functions:getAvailableGPTModels
```

### 4. 動作確認

1. アプリを起動
2. 実験作成画面でアンケート作成を選択
3. 「AI生成」タブを選択
4. 必要情報を入力して「AIで生成」をクリック

## GPT-5モデル設定

### 利用可能なモデル

- `gpt-5` - GPT-5（熟考モード）※推奨
- `gpt-4-turbo-preview` - GPT-4 Turbo
- `gpt-4` - GPT-4
- `gpt-3.5-turbo` - GPT-3.5 Turbo

### モデル選択のポイント

| モデル | 特徴 | 推奨用途 |
|--------|------|----------|
| gpt-5 | 最高品質、深い思考 | 複雑な実験、専門的なアンケート |
| gpt-4-turbo | 高品質、高速 | 一般的な実験アンケート |
| gpt-3.5-turbo | 高速、低コスト | シンプルなアンケート |

## エラー対処法

### APIキーエラー
```
エラー: APIキーが無効です
```
**対処法**:
1. APIキーが正しいか確認
2. APIキーに十分な利用枠があるか確認
3. 環境変数が正しく設定されているか確認

### 利用制限エラー
```
エラー: API利用制限に達しました
```
**対処法**:
1. 数分待ってから再試行
2. OpenAIダッシュボードで利用状況を確認
3. 必要に応じて利用枠を増やす

### モデルエラー
```
エラー: モデル名が正しくありません
```
**対処法**:
1. モデル名を「gpt-5」に設定
2. アカウントがGPT-5にアクセス可能か確認

## 料金について

### 概算コスト（2024年時点の参考値）

| モデル | 1アンケート生成あたり |
|--------|---------------------|
| gpt-5 | 約$0.10-0.20 |
| gpt-4 | 約$0.05-0.10 |
| gpt-3.5-turbo | 約$0.01-0.02 |

※実際の料金はOpenAIの最新価格をご確認ください

## セキュリティに関する注意

1. **APIキーの管理**
   - 本番環境では必ず環境変数を使用
   - APIキーをソースコードに直接記載しない
   - 定期的にキーをローテーション

2. **利用制限の設定**
   - OpenAIダッシュボードで月額上限を設定
   - 使用量アラートを設定

3. **ユーザー認証**
   - Firebase Authenticationで認証済みユーザーのみが使用可能
   - 必要に応じて追加の権限チェックを実装

## トラブルシューティング

### Functions がデプロイできない
```bash
# Node.jsバージョンを確認（18以上が必要）
node --version

# 依存関係を再インストール
cd functions
rm -rf node_modules
npm install
```

### GPT応答が遅い
- ネットワーク接続を確認
- Firebase Functionsのタイムアウト設定を確認（デフォルト: 120秒）
- より軽量なモデル（gpt-3.5-turbo）を試す

## サポート

問題が解決しない場合は、以下の情報と共に管理者に連絡してください：

1. エラーメッセージの全文
2. 使用しているモデル名
3. Firebase Functionsのログ（`firebase functions:log`）
4. ブラウザのコンソールログ