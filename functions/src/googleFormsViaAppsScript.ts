import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import fetch from "node-fetch";

// Google Apps Script Web App URLを環境変数から取得
// 注: この機能は既存のテンプレート機能用で、GPT-5機能では使用しません
const APPS_SCRIPT_URL = process.env.GOOGLE_APPS_SCRIPT_URL || "";

// テンプレートデータの型定義
interface TemplateQuestion {
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

interface FormTemplate {
  title: string;
  description: string;
  type: string;
  category: string;
  questions: TemplateQuestion[];
  instructions?: string;
  estimatedMinutes?: number;
  userEmail?: string; // ユーザーメールアドレスを追加
}

// Google Apps Script経由でフォームを作成
export const createGoogleFormViaAppsScript = functions.https.onCall(
  async (data, context) => {
    // 認証チェック
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const template: FormTemplate = data.template;
    const customTitle = data.customTitle || template.title;

    if (!template || !template.questions) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Template with questions is required"
      );
    }

    // Apps Script URLが設定されていない場合
    if (!APPS_SCRIPT_URL) {
      console.error("Google Apps Script URL is not configured");
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Google Apps Script URLが設定されていません。管理者に連絡してください。"
      );
    }

    try {
      console.log("Creating form via Google Apps Script...");
      console.log("Title:", customTitle);
      console.log("Questions count:", template.questions.length);

      // ユーザーのメールアドレスを取得
      const authUserId = context.auth.uid;
      const userDoc = await admin.firestore().collection("users").doc(authUserId).get();
      const userData = userDoc.data();
      const userEmail = userData?.googleEmail || userData?.email || template.userEmail || null;

      // Google Apps Scriptに送信するデータ
      const requestData = {
        action: "createForm",
        template: {
          title: customTitle,
          description: template.description,
          instructions: template.instructions,
          questions: template.questions,
        },
        userEmail: userEmail, // ユーザーのメールアドレスを追加
      };

      // Google Apps Script Web Appを呼び出し
      const response = await fetch(APPS_SCRIPT_URL, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify(requestData),
      });

      if (!response.ok) {
        throw new Error(`Apps Script returned status ${response.status}`);
      }

      const result = await response.json() as any;

      if (!result.success) {
        throw new Error(result.error || "Failed to create form");
      }

      console.log("Form created successfully:", result.formId);

      // ユーザーの実験作成履歴を記録
      const userId = context.auth.uid;
      await admin.firestore().collection("form_creation_logs").add({
        userId: userId,
        formId: result.formId,
        templateTitle: template.title,
        templateCategory: template.category,
        customTitle: customTitle,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        formUrl: result.formUrl,
        editUrl: result.editUrl,
        createdVia: "GoogleAppsScript",
      });

      return {
        success: true,
        formId: result.formId,
        formUrl: result.formUrl,
        editUrl: result.editUrl,
        sharedWith: result.sharedWith || userEmail,
      };

    } catch (error: any) {
      console.error("Error creating form via Apps Script:", error);
      
      let errorMessage = "Google Formの作成に失敗しました";
      let errorCode: any = "internal";
      
      if (error.message) {
        errorMessage += `: ${error.message}`;
      }
      
      throw new functions.https.HttpsError(errorCode, errorMessage);
    }
  }
);