# Firebase Functions 環境変数設定ガイド（2024年版）

## 重要な変更点
⚠️ Firebase Functions の `functions.config()` APIは **2026年3月に廃止** されます。
新しいプロジェクトでは環境変数を使用してください。

## 環境変数の設定方法

### 方法1: Firebase Console経由（本番環境推奨）

1. [Firebase Console](https://console.firebase.google.com/)にアクセス
2. プロジェクトを選択
3. 左メニューから「Functions」を選択
4. 「構成」タブを選択
5. 「環境変数を管理」をクリック
6. 以下の環境変数を追加：

| 変数名 | 説明 | 例 |
|--------|------|-----|
| `GPT_API_KEY` | OpenAI APIキー | `sk-...` |
| `GPT_MODEL_NAME` | 使用するGPTモデル | `gpt-5` |

### 方法2: Firebase CLIでデプロイ時に設定

```bash
# 環境変数を指定してデプロイ
firebase deploy --only functions \
  --set-env-vars GPT_API_KEY="your-api-key",GPT_MODEL_NAME="gpt-5"
```

### 方法3: .env.localファイル（ローカル開発用）

1. `functions/.env.local`ファイルを作成：

```env
# ローカル開発用環境変数
GPT_API_KEY=your-openai-api-key-here
GPT_MODEL_NAME=gpt-5
```

2. **重要**: `.env.local`は`.gitignore`に含まれているか確認

### 方法4: Firebase Functions シークレット（機密情報推奨）

APIキーなどの機密情報には、Firebase Functions Secretsを使用することを推奨：

```bash
# シークレットを作成
firebase functions:secrets:set GPT_API_KEY

# シークレットを使用してデプロイ
firebase deploy --only functions
```

## 環境変数の確認

```bash
# 設定された環境変数を確認
firebase functions:config:get

# ローカルで確認
cd functions
npm run shell
> process.env.GPT_API_KEY
```

## トラブルシューティング

### エラー: "GPT_API_KEY is not configured"

**原因**: 環境変数が設定されていない

**解決方法**:
1. Firebase Consoleで環境変数を設定
2. または、デプロイ時に`--set-env-vars`を使用
3. ローカル開発の場合は`.env.local`を作成

### エラー: "DEPRECATION NOTICE"

**原因**: `functions.config()`を使用している

**解決方法**:
このプロジェクトはすでに新しい環境変数方式に移行済みです。
古いコードがある場合は、`config.ts`を使用するように更新してください。

## 移行ガイド（既存プロジェクトの場合）

### 旧方式（非推奨）
```typescript
// ❌ 非推奨
const apiKey = functions.config().gpt?.api_key;
```

### 新方式（推奨）
```typescript
// ✅ 推奨
import { config } from "./config";
const apiKey = config.gpt.apiKey;
```

## セキュリティのベストプラクティス

1. **APIキーを直接コードに書かない**
2. **`.env.local`ファイルをGitにコミットしない**
3. **本番環境ではFirebase Secretsを使用**
4. **定期的にAPIキーをローテーション**
5. **使用量制限を設定**

## 参考リンク

- [Firebase Functions 環境設定](https://firebase.google.com/docs/functions/config-env)
- [Firebase Secrets管理](https://firebase.google.com/docs/functions/config-env#secret-manager)
- [OpenAI API キー管理](https://platform.openai.com/api-keys)