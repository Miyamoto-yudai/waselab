import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import fetch from "node-fetch";
import { config } from "./config";

// ========================================
// 環境変数設定
// ========================================
const GPT_API_KEY = config.gpt.apiKey;
const GPT_MODEL_NAME = config.gpt.model;
const GPT_API_URL = "https://api.openai.com/v1/chat/completions";

// ========================================
// 型定義
// ========================================
interface ExperimentInfo {
  title: string;
  description: string;
  purpose: string;
  targetAudience: string;
  expectedOutcome: string;
}

interface SurveyConfig {
  isPreSurvey: boolean;
  category?: string;
  maxQuestions: number;
  additionalRequirements?: string;
  baseTemplateId?: string;
}

interface ModelConfig {
  modelName: string;
  temperature: number;
  maxTokens: number;
}

interface GeneratedQuestion {
  question: string;
  type: string;
  required: boolean;
  options?: string[];
  scaleMin?: number;
  scaleMax?: number;
  scaleMinLabel?: string;
  scaleMaxLabel?: string;
  placeholder?: string;
}

// ========================================
// メイン関数: GPT-5でアンケートを生成
// ========================================
export const generateSurveyWithGPT = functions.https.onCall(
  async (data, context) => {
    // 認証チェック
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "ユーザー認証が必要です"
      );
    }

    const experimentInfo: ExperimentInfo = data.experimentInfo;
    const surveyConfig: SurveyConfig = data.surveyConfig;
    const modelConfig: ModelConfig = data.modelConfig;

    // 入力検証
    if (!experimentInfo || !experimentInfo.title || !experimentInfo.purpose) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "実験情報（タイトル、目的）は必須です"
      );
    }

    // APIキーチェック
    if (!GPT_API_KEY) {
      console.error("GPT API key is not configured");
      throw new functions.https.HttpsError(
        "failed-precondition",
        "GPT APIキーが設定されていません。管理者に連絡してください。"
      );
    }

    try {
      console.log("=== GPT-5アンケート生成開始 ===");
      console.log("モデル:", modelConfig.modelName || GPT_MODEL_NAME);
      console.log("実験タイトル:", experimentInfo.title);

      // プロンプトの生成
      const systemPrompt = createSystemPrompt();
      const userPrompt = createUserPrompt(experimentInfo, surveyConfig);

      console.log("生成されたプロンプト:", userPrompt.substring(0, 500) + "...");

      // GPT APIを呼び出し（モデル名を確認）
      const selectedModel = modelConfig.modelName || GPT_MODEL_NAME;
      console.log(`Selected model for generation: ${selectedModel}`);

      // モデル名の検証（gpt-5が指定された場合の特別処理）
      let actualModel = selectedModel;
      if (selectedModel === "gpt-5" && !GPT_API_KEY) {
        console.warn("GPT-5 requested but API key not configured, falling back to gpt-4o");
        actualModel = "gpt-4o";
      }

      // GPT-5の場合はtemperatureを1に固定
      const temperature = actualModel.startsWith("gpt-5") ? 1 : (modelConfig.temperature || 0.7);
      console.log(`Using model: ${actualModel} with temperature: ${temperature}`);

      const gptResponse = await callGPTAPI(
        systemPrompt,
        userPrompt,
        actualModel,
        temperature,
        modelConfig.maxTokens || 2000
      );

      // レスポンスをパース
      const parsedQuestions = parseGPTResponse(gptResponse);

      if (!parsedQuestions || parsedQuestions.length === 0) {
        throw new Error("GPTから有効な質問が生成されませんでした");
      }

      console.log(`${parsedQuestions.length}個の質問が生成されました`);

      // Google Formを作成
      const formResult = await createGoogleFormFromQuestions(
        experimentInfo.title,
        experimentInfo.description,
        parsedQuestions
      );

      // ログを記録
      await admin.firestore().collection("gpt_generation_logs").add({
        userId: context.auth.uid,
        experimentTitle: experimentInfo.title,
        questionsGenerated: parsedQuestions.length,
        modelUsed: modelConfig.modelName || GPT_MODEL_NAME,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        formUrl: formResult.formUrl,
        success: true,
      });

      return {
        success: true,
        generatedTemplate: {
          title: experimentInfo.title + " - アンケート",
          description: experimentInfo.description,
          isPreSurvey: surveyConfig.isPreSurvey,
          category: surveyConfig.category || "custom",
          questions: parsedQuestions,
          instructions: "このアンケートは実験の" +
            (surveyConfig.isPreSurvey ? "事前" : "事後") +
            "評価のために作成されました。",
          estimatedMinutes: Math.ceil(parsedQuestions.length * 0.5),
        },
        formUrl: formResult.formUrl,
        editUrl: formResult.editUrl,
        formId: formResult.formId,
        questions: parsedQuestions,
      };

    } catch (error: any) {
      console.error("Error in generateSurveyWithGPT:", error);

      // エラーログを記録
      await admin.firestore().collection("gpt_generation_logs").add({
        userId: context.auth.uid,
        experimentTitle: experimentInfo.title,
        error: error.message,
        modelUsed: modelConfig.modelName || GPT_MODEL_NAME,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        success: false,
      });

      throw new functions.https.HttpsError(
        "internal",
        `アンケート生成中にエラーが発生しました: ${error.message}`
      );
    }
  }
);

// ========================================
// ヘルパー関数
// ========================================

// システムプロンプトの作成
function createSystemPrompt(): string {
  return `あなたは心理学実験や行動研究のための専門的なアンケート作成アシスタントです。
与えられた実験情報に基づいて、適切で効果的なアンケート質問を生成してください。

重要な指針：
1. 質問は明確で曖昧さがないようにする
2. 回答者の負担を最小限にする
3. バイアスを避け、中立的な表現を使う
4. 適切な質問タイプ（選択式、記述式、尺度など）を選ぶ
5. 論理的な質問の順序を保つ

出力形式：
重要: 必ず正確なJSON配列形式で質問リストを返してください。余計なテキストや説明を含めず、データ構造のみを出力してください。

必須フィールド:
- question (文字列): 質問文
- type (文字列): "multipleChoice", "checkbox", "scale", "shortText", "longText", "date", "time" のいずれか
- required (真偽値): 必須かどうか

オプションフィールド:
- options (配列): multipleChoiceまたはcheckboxの場合のみ必須
- scaleMin, scaleMax (数値): scaleの場合のみ
- scaleMinLabel, scaleMaxLabel (文字列): scaleの場合のみ
- placeholder (文字列): shortTextまたはlongTextの場合のみ

出力例:
[
  {
    "question": "あなたの年齢を教えてください",
    "type": "shortText",
    "required": true,
    "placeholder": "例: 25"
  },
  {
    "question": "性別を選択してください",
    "type": "multipleChoice",
    "required": true,
    "options": ["男性", "女性", "その他", "回答しない"]
  },
  {
    "question": "実験の満足度を評価してください",
    "type": "scale",
    "required": true,
    "scaleMin": 1,
    "scaleMax": 5,
    "scaleMinLabel": "非常に不満",
    "scaleMaxLabel": "非常に満足"
  }
]`;
}

// ユーザープロンプトの作成
function createUserPrompt(
  experimentInfo: ExperimentInfo,
  surveyConfig: SurveyConfig
): string {
  let prompt = `以下の実験に対する${surveyConfig.isPreSurvey ? "事前" : "事後"}アンケートを作成してください。

【実験情報】
タイトル: ${experimentInfo.title}
説明: ${experimentInfo.description}
目的: ${experimentInfo.purpose}
対象者: ${experimentInfo.targetAudience}
期待される成果: ${experimentInfo.expectedOutcome}

【要件】
- 最大${surveyConfig.maxQuestions}問まで
- カテゴリ: ${surveyConfig.category || "一般"}`;

  if (surveyConfig.additionalRequirements) {
    prompt += `\n- 追加要件: ${surveyConfig.additionalRequirements}`;
  }

  if (surveyConfig.isPreSurvey) {
    prompt += `\n\n事前アンケートとして、以下の点を含めてください：
- 参加者の基本情報（必要に応じて）
- 実験テーマに関する事前知識や経験
- 期待や動機
- 関連する背景情報`;
  } else {
    prompt += `\n\n事後アンケートとして、以下の点を含めてください：
- 実験体験の評価
- 学習効果や気づき
- 改善提案
- 全体的な満足度`;
  }

  prompt += `\n\n重要な注意事項:
1. 質問はすべて日本語で作成してください
2. 必ずJSON配列形式で出力してください
3. JSON以外のテキストや説明を含めないでください
4. 各質問オブジェクトは必ず"question", "type", "required"フィールドを含むこと
5. typeに応じて適切な追加フィールドを含めること`;

  return prompt;
}

// GPT API呼び出し（リトライ機能付き）
async function callGPTAPI(
  systemPrompt: string,
  userPrompt: string,
  model: string,
  temperature: number,
  maxTokens: number
): Promise<string> {
  const maxRetries = 3;
  let lastError: Error | null = null;

  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      console.log(`Calling AI API with model: ${model} (attempt ${attempt}/${maxRetries})`);

      // GPT-5用のリクエストボディを構築
      const requestBody: any = {
        model: model,
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: userPrompt }
        ]
      };

      // GPT-5の場合、特別な設定を使用
      if (model.startsWith("gpt-5")) {
        console.log("=== GPT-5 Configuration ===");
        console.log("Model:", model);
        console.log("Temperature: 1 (GPT-5 only supports default value)");
        console.log("Max Completion Tokens:", maxTokens);

        // GPT-5はtemperature=1のみサポート
        requestBody.temperature = 1;
        // GPT-5ではmax_tokensではなくmax_completion_tokensを使用
        requestBody.max_completion_tokens = maxTokens;
        // response_formatは使用しない（JSONはプロンプトで指示）

        console.log("Request body for GPT-5:", JSON.stringify(requestBody, null, 2));
      } else {
        // GPT-4oやその他のモデルではmax_tokensとresponse_formatを使用
        console.log(`=== ${model} Configuration ===`);
        console.log("Model:", model);
        console.log("Temperature:", temperature);
        console.log("Max Tokens:", maxTokens);

        requestBody.temperature = temperature;
        requestBody.max_tokens = maxTokens;
        requestBody.response_format = { type: "json_object" };
      }

      const response = await fetch(GPT_API_URL, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${GPT_API_KEY}`
        },
        body: JSON.stringify(requestBody)
      });

      if (!response.ok) {
        const errorText = await response.text();
        console.error(`GPT API Error (attempt ${attempt}): ${response.status} - ${errorText}`);

        if (response.status === 401) {
          throw new Error("APIキーが無効です");
        } else if (response.status === 429) {
          if (attempt < maxRetries) {
            console.log(`Rate limit hit, waiting ${attempt * 2} seconds before retry...`);
            await new Promise(resolve => setTimeout(resolve, attempt * 2000));
            continue;
          }
          throw new Error("API利用制限に達しました。しばらく待ってから再試行してください");
        } else if (response.status === 400) {
          // エラーの詳細を確認
          const errorDetail = errorText.toLowerCase();

          // GPT-5でパラメータエラーの場合の詳細ログ
          if (model.startsWith("gpt-5")) {
            console.error("GPT-5 parameter error details:", errorText);

            if (errorDetail.includes("temperature")) {
              console.error("Temperature error detected. GPT-5 only supports temperature=1");
            }
            if (errorDetail.includes("max_tokens")) {
              console.error("Max tokens error detected. GPT-5 requires max_completion_tokens");
            }

            // フォールバックを試みる前に、エラーの詳細を記録
            if (attempt === 1) {
              console.log("GPT-5 failed with 400, trying with fallback to gpt-4o...");
              return await callGPTAPI(systemPrompt, userPrompt, "gpt-4o", 0.7, maxTokens);
            }
          }

          throw new Error(`リクエストが不正です: ${errorText}`);
        }

        throw new Error(`GPT API エラー: ${response.status}`);
      }

      const result = await response.json() as any;

      if (!result.choices || result.choices.length === 0) {
        throw new Error("GPTから応答が得られませんでした");
      }

      console.log(`Successfully received response from ${model}`);
      const content = result.choices[0].message.content;

      // GPT-5の応答が空の場合の処理
      if (!content || content.trim() === '') {
        console.error("GPT-5 returned empty response, result:", JSON.stringify(result, null, 2));
        if (model.startsWith("gpt-5") && attempt === 1) {
          console.log("GPT-5 returned empty response, trying with gpt-4o...");
          return await callGPTAPI(systemPrompt, userPrompt, "gpt-4o", 0.7, maxTokens);
        }
        throw new Error("GPTから空の応答が返されました");
      }

      return content;

    } catch (error: any) {
      lastError = error;
      console.error(`Attempt ${attempt} failed:`, error.message);

      if (attempt < maxRetries && !error.message.includes("APIキーが無効")) {
        console.log(`Retrying in ${attempt} seconds...`);
        await new Promise(resolve => setTimeout(resolve, attempt * 1000));
      } else {
        break;
      }
    }
  }

  throw lastError || new Error("GPT API呼び出しに失敗しました");
}

// GPTレスポンスのパース（柔軟な処理）
function parseGPTResponse(gptResponse: string): GeneratedQuestion[] {
  try {
    console.log("Parsing GPT response...");

    // 空の応答の場合のエラー
    if (!gptResponse || gptResponse.trim() === '') {
      console.error("Empty GPT response received");
      throw new Error("GPTから空の応答が返されました");
    }

    // JSONとしてパース
    let parsed: any;
    try {
      parsed = JSON.parse(gptResponse);
    } catch (e) {
      // JSONパースに失敗した場合、配列を探す
      const match = gptResponse.match(/\[[\s\S]*\]/);
      if (match) {
        parsed = JSON.parse(match[0]);
      } else {
        // 単一オブジェクトの場合も試す
        const objMatch = gptResponse.match(/\{[\s\S]*\}/);
        if (objMatch) {
          const singleObj = JSON.parse(objMatch[0]);
          // 単一の質問オブジェクトを配列に変換
          if (singleObj.question && singleObj.type) {
            console.log("Found single question object, converting to array");
            parsed = [singleObj];
          } else {
            parsed = singleObj;
          }
        } else {
          console.log("Raw response that failed to parse:", gptResponse.substring(0, 500));
          throw new Error("有効なJSONが見つかりません");
        }
      }
    }

    // 配列でない場合の処理
    let questions: any[];
    if (Array.isArray(parsed)) {
      questions = parsed;
    } else if (parsed.questions && Array.isArray(parsed.questions)) {
      questions = parsed.questions;
    } else if (parsed.question && parsed.type) {
      // 単一の質問オブジェクトの場合
      console.log("Converting single question to array");
      questions = [parsed];
    } else {
      // オブジェクトの値を配列として取得を試みる
      const values = Object.values(parsed);
      if (values.length > 0 && Array.isArray(values[0])) {
        questions = values[0] as any[];
      } else {
        console.log("Response structure:", JSON.stringify(parsed, null, 2));
        throw new Error("質問の配列が見つかりません。レスポンス形式を確認してください");
      }
    }

    console.log(`Found ${questions.length} questions to process`);

    // 各質問を検証してクリーンアップ
    return questions.map((q: any, index: number) => {
      // 必須フィールドの検証
      if (!q.question || !q.type) {
        console.warn(`質問${index + 1}に必須フィールドがありません`);
        return null;
      }

      // タイプの正規化
      const validTypes = ["multipleChoice", "checkbox", "scale", "shortText", "longText", "date", "time"];
      if (!validTypes.includes(q.type)) {
        console.warn(`質問${index + 1}の質問タイプが無効です: ${q.type}`);
        q.type = "shortText"; // デフォルトに設定
      }

      // 各質問タイプに応じた検証
      const cleanQuestion: GeneratedQuestion = {
        question: q.question,
        type: q.type,
        required: q.required === true,
      };

      if (q.type === "multipleChoice" || q.type === "checkbox") {
        if (Array.isArray(q.options) && q.options.length > 0) {
          cleanQuestion.options = q.options;
        } else {
          // オプションがない場合、デフォルトを設定
          cleanQuestion.options = ["はい", "いいえ", "わからない"];
        }
      }

      if (q.type === "scale") {
        cleanQuestion.scaleMin = q.scaleMin || 1;
        cleanQuestion.scaleMax = q.scaleMax || 5;
        cleanQuestion.scaleMinLabel = q.scaleMinLabel || "";
        cleanQuestion.scaleMaxLabel = q.scaleMaxLabel || "";
      }

      if (q.type === "shortText" || q.type === "longText") {
        cleanQuestion.placeholder = q.placeholder || "";
      }

      return cleanQuestion;
    }).filter((q): q is GeneratedQuestion => q !== null); // nullを除外

  } catch (error: any) {
    console.error("Error parsing GPT response:", error);
    console.error("Raw response:", gptResponse.substring(0, 1000));

    // エラーが発生した場合、デフォルトの質問を返す
    console.log("Response parsing failed, returning default questions");
    return getDefaultQuestions(gptResponse.includes("事前"));
  }
}

// デフォルトの質問を返すヘルパー関数
function getDefaultQuestions(isPreSurvey: boolean): GeneratedQuestion[] {
  if (isPreSurvey) {
    return [
      {
        question: "あなたの年齢を教えてください。",
        type: "shortText",
        required: true,
        placeholder: "例: 25"
      },
      {
        question: "性別を選択してください。",
        type: "multipleChoice",
        required: true,
        options: ["男性", "女性", "その他", "回答しない"]
      },
      {
        question: "この実験に参加した理由を教えてください。",
        type: "longText",
        required: true,
        placeholder: "自由に記述してください"
      },
      {
        question: "実験テーマに関する事前知識はありますか？",
        type: "multipleChoice",
        required: true,
        options: ["はい", "いいえ", "わからない"]
      },
      {
        question: "何を期待してこの実験に参加しましたか？",
        type: "longText",
        required: false,
        placeholder: "期待していることを記述してください"
      }
    ];
  } else {
    return [
      {
        question: "実験の内容は理解できましたか？",
        type: "scale",
        required: true,
        scaleMin: 1,
        scaleMax: 5,
        scaleMinLabel: "全く理解できなかった",
        scaleMaxLabel: "完全に理解できた"
      },
      {
        question: "実験の難易度はどうでしたか？",
        type: "multipleChoice",
        required: true,
        options: ["非常に簡単", "簡単", "ちょうどよい", "難しい", "非常に難しい"]
      },
      {
        question: "実験を通して新しい知識や気づきはありましたか？",
        type: "longText",
        required: true,
        placeholder: "具体的に記述してください"
      },
      {
        question: "実験の改善点があれば教えてください。",
        type: "longText",
        required: false,
        placeholder: "自由に記述してください"
      },
      {
        question: "全体的な満足度を評価してください。",
        type: "scale",
        required: true,
        scaleMin: 1,
        scaleMax: 5,
        scaleMinLabel: "非常に不満",
        scaleMaxLabel: "非常に満足"
      }
    ];
  }
}

// Google Form作成（Google Apps Script経由）
async function createGoogleFormFromQuestions(
  title: string,
  description: string,
  questions: GeneratedQuestion[]
): Promise<any> {
  console.log(`Creating Google Form with ${questions.length} questions`);

  const APPS_SCRIPT_URL = config.google.appsScriptUrl;

  // Apps Script URLが設定されていない場合はダミーデータを返す
  if (!APPS_SCRIPT_URL) {
    console.warn("Google Apps Script URL is not configured, returning mock data");
    return {
      formId: `gpt_generated_${Date.now()}`,
      formUrl: null,
      editUrl: null,
      generatedQuestions: questions,
      message: "Google Apps Script URLが設定されていません。管理者に連絡してください。",
    };
  }

  try {
    // Google Apps Scriptに送信するデータを準備
    const requestData = {
      action: "createForm",
      template: {
        title: title + " - アンケート",
        description: description || "GPT-5により自動生成されたアンケートです",
        instructions: "以下の質問にお答えください。",
        questions: questions.map((q, index) => ({
          ...q,
          order: index + 1,
        })),
      },
    };

    console.log("Calling Google Apps Script to create form...");

    // Google Apps Script Web Appを呼び出し
    const response = await fetch(APPS_SCRIPT_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(requestData),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error(`Apps Script error: ${response.status} - ${errorText}`);
      throw new Error(`Google Forms作成エラー: ${response.status}`);
    }

    const result = await response.json() as any;

    if (!result.success) {
      console.error("Form creation failed:", result.error);
      throw new Error(result.error || "Google Forms作成に失敗しました");
    }

    console.log("Form created successfully:", result.formId);
    console.log("Form URL:", result.formUrl);
    console.log("Edit URL:", result.editUrl);

    return {
      formId: result.formId,
      formUrl: result.formUrl,
      editUrl: result.editUrl,
      generatedQuestions: questions,
      message: "Google Formsが正常に作成されました",
    };

  } catch (error: any) {
    console.error("Error creating Google Form:", error);

    // エラーが発生してもアンケートデータは返す
    return {
      formId: `gpt_generated_${Date.now()}`,
      formUrl: null,
      editUrl: null,
      generatedQuestions: questions,
      message: `Google Forms作成エラー: ${error.message}`,
      error: error.message,
    };
  }
}

// ========================================
// 補助関数
// ========================================

// APIキーの検証
export const validateGPTAPIKey = functions.https.onCall(
  async (data, context) => {
    const apiKey = data.apiKey;

    if (!apiKey) {
      return { valid: false, error: "APIキーが提供されていません" };
    }

    try {
      // 簡単なテストリクエストを送信
      const response = await fetch(GPT_API_URL, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${apiKey}`
        },
        body: JSON.stringify({
          model: "gpt-3.5-turbo", // テスト用に安いモデルを使用
          messages: [{ role: "user", content: "test" }],
          max_tokens: 1
        })
      });

      if (response.status === 401) {
        return { valid: false, error: "無効なAPIキーです" };
      }

      if (response.ok) {
        return { valid: true };
      }

      return { valid: false, error: `検証エラー: ${response.status}` };
    } catch (error: any) {
      return { valid: false, error: error.message };
    }
  }
);

// 利用可能なモデルの取得
export const getAvailableGPTModels = functions.https.onCall(
  async (data, context) => {
    // 現在利用可能なGPTモデルのリスト
    // GPT-5は2025年8月にリリースされた最新モデル
    const models = [
      "gpt-5", // GPT-5 (最新モデル - 2025年8月リリース)
      "gpt-5-mini", // GPT-5 mini (コスト効率版)
      "gpt-5-nano", // GPT-5 nano (最速版)
      "gpt-4o", // GPT-4o (安定版フォールバック)
      "gpt-4o-mini", // GPT-4o mini
      "gpt-4-turbo",
      "gpt-3.5-turbo",
    ];

    return { models };
  }
);