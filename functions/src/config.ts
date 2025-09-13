import * as dotenv from "dotenv";
import * as path from "path";

// 環境変数の読み込み
// ローカル開発時は .env.local ファイルから読み込む
if (process.env.NODE_ENV !== "production") {
  dotenv.config({ path: path.join(__dirname, "../.env.local") });
}

/**
 * 環境変数の設定値を取得するヘルパー関数
 * Firebase Functions の新しい環境変数管理方法に対応
 */
export const getConfig = () => {
  // 本番環境では process.env から直接取得
  // ローカル開発では .env.local から読み込まれた値を使用
  return {
    gpt: {
      apiKey: process.env.GPT_API_KEY || "",
      model: process.env.GPT_MODEL_NAME || "gpt-5",
    },
    google: {
      appsScriptUrl: process.env.GOOGLE_APPS_SCRIPT_URL || "",
    },
  };
};

/**
 * 設定値の検証
 */
export const validateConfig = () => {
  const config = getConfig();
  const errors: string[] = [];

  if (!config.gpt.apiKey) {
    errors.push("GPT_API_KEY is not configured");
  }

  if (errors.length > 0) {
    console.error("Configuration errors:", errors);
    return false;
  }

  return true;
};

// エクスポート
export const config = getConfig();