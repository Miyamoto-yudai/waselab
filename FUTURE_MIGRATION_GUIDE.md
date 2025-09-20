# Firebase Functions 設定の移行ガイド（2026年3月までに対応）

## 現在の警告について
```
⚠ DEPRECATION NOTICE: Action required to deploy after March 2026
```

この警告は **今は無視して問題ありません**。2026年3月まで現在の設定で動作します。

## 移行スケジュール

- **現在〜2026年3月**: 現在の `functions.config()` が使用可能 ✅
- **2026年3月以降**: `.env` ファイルへの移行が必須

## 将来の移行手順（2025年頃に実施推奨）

### 1. 現在の設定を `.env` ファイルに移行

現在の `functions/.env` ファイルに以下を追加：
```bash
# 既存の設定に追加（既に一部は移行済み）
GOOGLE_APPS_SCRIPT_URL="https://script.google.com/macros/s/AKfycb.../exec"
```

### 2. コードの更新

`functions/src/googleFormsViaAppsScript.ts`:
```typescript
// 変更前（現在）
const APPS_SCRIPT_URL = process.env.GOOGLE_APPS_SCRIPT_URL || "";

// 変更後（既に対応済み！）
const APPS_SCRIPT_URL = process.env.GOOGLE_APPS_SCRIPT_URL || "";
```

実は**既に新方式に対応済み**なので、追加の変更は不要です！

### 3. 古い設定の削除（2026年までに）

```bash
# 古い設定を削除
firebase functions:config:unset googleappsscript
firebase functions:config:unset googleapi
firebase functions:config:unset gpt
```

## なぜ今は対応不要か

1. **既に `.env` ファイルを使用している**
   - コードは既に `process.env` から読み込む方式
   - 新旧両方の方法で動作する実装

2. **移行リスクがない**
   - 2026年3月まで十分な時間がある
   - 現在の実装は問題なく動作している

3. **段階的移行が可能**
   - 急いで移行する必要なし
   - 適切なタイミングで計画的に実施可能

## 推奨対応

- **2024年**: 無視して開発続行 ✅
- **2025年後半**: 移行を計画
- **2026年1月**: 移行実施とテスト
- **2026年3月**: 完全移行完了

## まとめ

この警告は将来のための情報提供であり、**今すぐの対応は不要**です。
開発を続行して問題ありません。