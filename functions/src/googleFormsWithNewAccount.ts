import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {google} from "googleapis";
import {JWT} from "google-auth-library";

const forms = google.forms("v1");

// 新しいサービスアカウントの認証情報
// 手動で作成した新しいサービスアカウントのJSONキーをここに設定
const NEW_SERVICE_ACCOUNT = {
  // TODO: 新しいサービスアカウントのJSONキーの内容をここに貼り付け
  type: "service_account",
  project_id: "waselab-30308",
  private_key_id: "YOUR_NEW_KEY_ID",
  private_key: "YOUR_NEW_PRIVATE_KEY",
  client_email: "forms-api-service@waselab-30308.iam.gserviceaccount.com",
  client_id: "YOUR_NEW_CLIENT_ID",
  auth_uri: "https://accounts.google.com/o/oauth2/auth",
  token_uri: "https://oauth2.googleapis.com/token",
  auth_provider_x509_cert_url: "https://www.googleapis.com/oauth2/v1/certs",
  client_x509_cert_url: "YOUR_NEW_CERT_URL",
  universe_domain: "googleapis.com"
};

// JWT認証クライアントを作成
function createJWTClient(): JWT {
  console.log("Creating JWT client for new service account:", NEW_SERVICE_ACCOUNT.client_email);
  
  const jwtClient = new JWT({
    email: NEW_SERVICE_ACCOUNT.client_email,
    key: NEW_SERVICE_ACCOUNT.private_key,
    scopes: [
      "https://www.googleapis.com/auth/forms.body",
      "https://www.googleapis.com/auth/drive.file",
      "https://www.googleapis.com/auth/drive",
    ],
  });

  return jwtClient;
}

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
}

// 質問タイプをGoogle Forms APIの形式に変換
function convertQuestionToGoogleFormItem(q: TemplateQuestion): any {
  const item: any = {
    title: q.question,
    description: q.placeholder || "",
    questionItem: {
      question: {
        required: q.required,
      },
    },
  };

  switch (q.type) {
    case "multipleChoice":
      item.questionItem.question.choiceQuestion = {
        type: "RADIO",
        options: q.options?.map((opt) => ({value: opt})) || [],
        shuffle: false,
      };
      break;

    case "checkbox":
      item.questionItem.question.choiceQuestion = {
        type: "CHECKBOX",
        options: q.options?.map((opt) => ({value: opt})) || [],
        shuffle: false,
      };
      break;

    case "scale":
      item.questionItem.question.scaleQuestion = {
        low: q.scaleMin || 1,
        high: q.scaleMax || 5,
        lowLabel: q.scaleMinLabel || "",
        highLabel: q.scaleMaxLabel || "",
      };
      break;

    case "shortText":
      item.questionItem.question.textQuestion = {
        paragraph: false,
      };
      break;

    case "longText":
      item.questionItem.question.textQuestion = {
        paragraph: true,
      };
      break;

    case "date":
      item.questionItem.question.dateQuestion = {
        includeTime: false,
        includeYear: true,
      };
      break;

    case "time":
      item.questionItem.question.timeQuestion = {
        duration: false,
      };
      break;

    default:
      item.questionItem.question.textQuestion = {
        paragraph: false,
      };
  }

  return item;
}

// 新しいサービスアカウントでGoogleフォームを作成
export const createGoogleFormWithNewAccount = functions.https.onCall(
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

    // サービスアカウントが設定されているか確認
    if (NEW_SERVICE_ACCOUNT.private_key_id === "YOUR_NEW_KEY_ID") {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "新しいサービスアカウントが設定されていません。管理者に連絡してください。"
      );
    }

    try {
      console.log("Starting form creation with new service account...");
      console.log("Title:", customTitle);
      console.log("Questions count:", template.questions.length);
      
      // JWT認証クライアントを作成
      const jwtClient = createJWTClient();
      
      // 認証を実行
      console.log("Authorizing JWT client...");
      await jwtClient.authorize();
      console.log("JWT client authorized successfully");
      
      // Google Forms APIを初期化
      google.options({auth: jwtClient});
      
      // 1. フォームを作成
      console.log("Creating form via API...");
      const createResponse = await forms.forms.create({
        requestBody: {
          info: {
            title: customTitle,
            documentTitle: customTitle,
          },
        },
      });

      console.log("Form created with ID:", createResponse.data.formId);

      const formId = createResponse.data.formId;
      if (!formId) {
        throw new Error("Failed to create form - no formId returned");
      }

      // 2. フォームの説明とアイテムを更新
      const requests: any[] = [];

      // フォームの説明を設定
      if (template.description || template.instructions) {
        const fullDescription = [
          template.description,
          template.instructions,
        ]
          .filter(Boolean)
          .join("\n\n");

        requests.push({
          updateFormInfo: {
            info: {
              description: fullDescription,
            },
            updateMask: "description",
          },
        });
      }

      // 質問項目を追加
      template.questions.forEach((question, index) => {
        const item = convertQuestionToGoogleFormItem(question);
        requests.push({
          createItem: {
            item: item,
            location: {index: index},
          },
        });
      });

      // バッチ更新を実行
      if (requests.length > 0) {
        console.log(`Updating form with ${requests.length} requests...`);
        await forms.forms.batchUpdate({
          formId: formId,
          requestBody: {
            includeFormInResponse: false,
            requests: requests,
          },
        });
        console.log("Form updated successfully");
      }

      // 3. フォームのレスポンダーURIを取得
      const formResponse = await forms.forms.get({
        formId: formId,
      });

      const responderUri = formResponse.data.responderUri || "";
      const editUrl = `https://docs.google.com/forms/d/${formId}/edit`;

      console.log(`Form created successfully: ${formId}`);

      // ユーザーの実験作成履歴を記録
      const userId = context.auth.uid;
      await admin.firestore().collection("form_creation_logs").add({
        userId: userId,
        formId: formId,
        templateTitle: template.title,
        templateCategory: template.category,
        customTitle: customTitle,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        formUrl: responderUri,
        editUrl: editUrl,
        createdVia: "NewServiceAccount",
      });

      return {
        success: true,
        formId: formId,
        formUrl: responderUri,
        editUrl: editUrl,
      };
      
    } catch (error: any) {
      console.error("Error with new service account:", error);
      
      let errorMessage = "Google Formの作成に失敗しました";
      let errorCode: any = "internal";
      
      if (error.response && error.response.status) {
        console.error("API Error Status:", error.response.status);
        console.error("API Error Data:", error.response.data);
        
        if (error.response.status === 403) {
          errorMessage = "新しいサービスアカウントに権限がありません。IAM設定を確認してください。";
          errorCode = "permission-denied";
        } else if (error.response.status === 401) {
          errorMessage = "新しいサービスアカウントの認証に失敗しました。";
          errorCode = "unauthenticated";
        } else if (error.response.status === 500) {
          errorMessage = "Google Forms APIのサーバーエラーです。";
          errorCode = "internal";
        }
      } else if (error.message) {
        errorMessage += `: ${error.message}`;
      }
      
      throw new functions.https.HttpsError(errorCode, errorMessage);
    }
  }
);