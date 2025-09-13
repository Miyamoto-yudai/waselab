import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {google} from "googleapis";
import {JWT} from "google-auth-library";

const forms = google.forms("v1");

// サービスアカウントの認証情報
const SERVICE_ACCOUNT = {
  type: "service_account",
  project_id: "waselab-30308",
  private_key_id: "35808007a91d0beb832746d7216d880f828c4f86",
  private_key: "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQC4SZp6Vgb6QyHc\nMSmZ7yCfcFL5d70RjOXu6GgsAi4NqfA5ZQ3tWwD3QJnhQo7vPUdqLXQ87iJNholQ\newZ+UD6SJKOaHApHrPJdq1qivbNNEJ5OepbfSW+NwOseUvmd2SHzsfzRQME7DOFy\nsqV8eyswmqdwngugWw45zPHxJeHoq3ovFAHi0Rsyyv7iR/BznRZ3mb9j/x8B4hmu\nTP1NDe6qBXSn9WsqoJ1MIusfHmdl1me8YPM4drV0khLFo425bxHY+tWbegiply+V\n2hzLyLGgYrD5QkQF9Iv0kV/crJ0iLk+F/I0I6UTGJDa6Vm5dBwny6BwzpZamkR93\nckf5k7lzAgMBAAECggEASc3caosibz7MhDlCLm54s7HR4Svlke5KNbRo59sVo44/\n8VR5z+mmyN7b4b18re5uN+UtTKuYHFE5k/w5PQQZEwFObg01xr/KLt5NxahQcxgp\nNkfdPV5VKUGuR+42HtPTR5wsIoea+3GspnlKUkCnqub9ENqS0G03FMnxyUCBKWM3\n6DohC//MRVqxmxb7Ih5qdTN414Y7ftJaWeWe6vtcTgbY9BdAAdy+ujX0RvZM1ls5\nKbTFYNZd4CeECKo/7zmaABfQzA+9pGW/MfWfIEqfcWQEeavcMw0I56meRANi5+pW\nvjN2NNbF6kt3tjJImR1X0nre+Lbgi6LCeX22srJ8oQKBgQD3tXFliatXDLCI9mJ2\nZo1a6dHNqZHzmbzONug7i/ysfuvJLzf8KqzGtPSQJmz1vhmLKEVpvt7qQjWszgMk\nKZ3nfRPW8c+ZVyVxZ+68ozRJweRaAZQOPn+hUtLaxD6Uv7Hyu4TLP4kT2uJIKZRc\ncrM4AypmbFE4NesAPjHfv5cGIQKBgQC+dLgPsGuL2V8aQOxbFkS5QDXvpBb8X8EN\n9QzvvySqXjfD1kGcEgsJWCGqerp80liadYLLJTxgEmOxNdZzn3nqpWNrLvROp9bA\nSL5syRa3rvCYfGuCwswKrjROWgMYHA1Uc3uDVzMIsHLo8hwQd8kfkpitAl19rlLG\nkyoARwulEwKBgHsYt9l1qKgBrljh19xu6iAbwh8p/VXJOIJh1taAong2OoYn6PJv\nYpz8n+xirBMS/S6iPJxoNe7EKFhPqE/4PngjOBDA6iGRpRHOTF2B3SIqMIhp8GGD\nvXk154K/sznIaW3usfcvA7fSNlEWGJw4g8d6C0AK4/HDGZ1tSuueEjcBAoGBALqP\n0QElWqP6QSuRbzVmodkpaewdu5pqHc0TPyHWBg+RDWUbitdb4U288/VwFR9SWRKs\ni3t9NSASw28Cgtht3loYukNzEkO+KyHd4BLmBAfYKLvmHNZRBNhtfrVFfQRv7irM\nmK+2ijo3xcgj6ZPEEtKHomDPEU+cpF76J0lwTprbAoGBANce0auOQokJgc5fncnv\n02RG1SZtKFkugDIzArtjcUQg7EaUggF/BeQiIqw8+w2edDs7xbbqOMFGpLgewJ7I\n30GTrLFWnNcp79gFyI3FIB6UVFQWlTazs027nfXv6yKs2uW8AQZvBwMEFJNt1RsE\n64FmpgSdZdr4ePBZ77iC5rN7\n-----END PRIVATE KEY-----\n",
  client_email: "waselab-30308@appspot.gserviceaccount.com",
  client_id: "116779452105013545070",
  auth_uri: "https://accounts.google.com/o/oauth2/auth",
  token_uri: "https://oauth2.googleapis.com/token",
  auth_provider_x509_cert_url: "https://www.googleapis.com/oauth2/v1/certs",
  client_x509_cert_url: "https://www.googleapis.com/robot/v1/metadata/x509/waselab-30308%40appspot.gserviceaccount.com",
  universe_domain: "googleapis.com"
};

// JWT認証クライアントを作成
function createJWTClient(): JWT {
  console.log("Creating JWT client for:", SERVICE_ACCOUNT.client_email);
  
  const jwtClient = new JWT({
    email: SERVICE_ACCOUNT.client_email,
    key: SERVICE_ACCOUNT.private_key,
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

// Googleフォームを作成する関数（改善版）
export const createGoogleFormFromTemplate = functions.https.onCall(
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

    let retryCount = 0;
    const maxRetries = 3;
    
    while (retryCount < maxRetries) {
      try {
        console.log(`Attempt ${retryCount + 1} - Starting form creation for:`, customTitle);
        console.log("Template questions count:", template.questions.length);
        
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
        });

        return {
          success: true,
          formId: formId,
          formUrl: responderUri,
          editUrl: editUrl,
        };
        
      } catch (error: any) {
        console.error(`Attempt ${retryCount + 1} failed:`, error);
        console.error("Error details:", {
          message: error.message,
          code: error.code,
          status: error.status,
          response: error.response?.data,
        });
        
        retryCount++;
        
        if (retryCount >= maxRetries) {
          // 最終的なエラー処理
          let errorMessage = "Google Formの作成に失敗しました";
          let errorCode: any = "internal";
          
          if (error.response && error.response.status) {
            console.error("API Error Status:", error.response.status);
            console.error("API Error Data:", error.response.data);
            
            if (error.response.status === 403) {
              errorMessage = "Google Forms APIへのアクセス権限がありません。管理者に連絡してください。";
              errorCode = "permission-denied";
            } else if (error.response.status === 401) {
              errorMessage = "認証エラーです。管理者に連絡してください。";
              errorCode = "unauthenticated";
            } else if (error.response.status === 400) {
              errorMessage = "リクエストが不正です。テンプレートデータを確認してください。";
              errorCode = "invalid-argument";
            } else if (error.response.status === 500) {
              errorMessage = "Google Forms APIのサーバーエラーです。しばらく待ってから再試行してください。";
              errorCode = "internal";
            }
          } else if (error.message) {
            errorMessage += `: ${error.message}`;
          }
          
          throw new functions.https.HttpsError(errorCode, errorMessage);
        }
        
        // リトライ前に少し待機
        console.log(`Waiting 2 seconds before retry...`);
        await new Promise(resolve => setTimeout(resolve, 2000));
      }
    }
    
    // ここには到達しないはずだが、念のため
    throw new functions.https.HttpsError(
      "internal",
      "予期しないエラーが発生しました"
    );
  }
);