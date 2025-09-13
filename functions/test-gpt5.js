// GPT-5 テストスクリプト
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const functions = require('firebase-functions');
const https = require('https');

// Firebase Functionsの直接テスト
async function testGPT5() {
  const testData = {
    experimentInfo: {
      title: "色彩が感情に与える影響の研究",
      description: "異なる色彩環境での感情変化を測定する実験",
      purpose: "色彩心理学の基礎研究",
      targetAudience: "大学生（18-25歳）",
      expectedOutcome: "色彩と感情の相関関係の解明"
    },
    surveyConfig: {
      isPreSurvey: false,
      category: "psychology",
      maxQuestions: 10,
      additionalRequirements: "感情評価スケールを含める"
    },
    modelConfig: {
      modelName: "gpt-5",
      temperature: 1,  // GPT-5は1のみサポート
      maxTokens: 2000
    }
  };

  console.log("=== GPT-5 テスト開始 ===");
  console.log("テストデータ:", JSON.stringify(testData, null, 2));

  try {
    // ローカルでテスト関数を呼び出し
    const result = await admin.functions().httpsCallable('generateSurveyWithGPT')(testData);
    console.log("=== テスト成功 ===");
    console.log("結果:", JSON.stringify(result, null, 2));
  } catch (error) {
    console.error("=== テスト失敗 ===");
    console.error("エラー:", error.message);
    console.error("詳細:", error);
  }
}

// テスト実行
testGPT5().then(() => {
  console.log("テスト完了");
  process.exit(0);
}).catch(error => {
  console.error("テストエラー:", error);
  process.exit(1);
});