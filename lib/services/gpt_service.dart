import 'package:cloud_functions/cloud_functions.dart';
import '../models/survey_template.dart';

/// GPT-5を使用したアンケート生成サービス
class GPTService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// GPT-5モデル名（環境変数や設定から取得可能にする）
  static const String DEFAULT_MODEL = 'gpt-5';

  /// GPT-5を使用してアンケート雛形を生成
  static Future<Map<String, dynamic>?> generateSurveyTemplate({
    required String experimentTitle,
    required String experimentDescription,
    required String purpose,
    required String targetAudience,
    required String expectedOutcome,
    String? additionalRequirements,
    SurveyCategory? preferredCategory,
    bool isPreSurvey = false,
    String? baseTemplateId,
    int maxQuestions = 15,
    String modelName = DEFAULT_MODEL,
    List<String>? referenceTemplateIds,  // 参考にするテンプレートのID
    String? headerTemplateId,  // 開始部分の固定テンプレート
    String? footerTemplateId,  // 終了部分の固定テンプレート
    String? referenceFormUrl,  // 参考にするGoogle FormsのURL
  }) async {
    try {

      // Firebase Functionsを呼び出し
      final HttpsCallable callable = _functions.httpsCallable(
        'generateSurveyWithGPT',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 120), // GPT-5の処理時間を考慮
        ),
      );

      // リクエストデータの準備
      final requestData = {
        'experimentInfo': {
          'title': experimentTitle,
          'description': experimentDescription,
          'purpose': purpose,
          'targetAudience': targetAudience,
          'expectedOutcome': expectedOutcome,
        },
        'surveyConfig': {
          'isPreSurvey': isPreSurvey,
          'category': preferredCategory?.name,
          'maxQuestions': maxQuestions,
          'additionalRequirements': additionalRequirements,
          'baseTemplateId': baseTemplateId,
          'referenceTemplateIds': referenceTemplateIds,
          'headerTemplateId': headerTemplateId,
          'footerTemplateId': footerTemplateId,
          'referenceFormUrl': referenceFormUrl,
        },
        'modelConfig': {
          'modelName': modelName,
          'temperature': 0.7, // 創造性と一貫性のバランス
          'maxTokens': 4000, // 十分な長さの応答を確保
        },
      };


      // 関数を実行
      final result = await callable.call(requestData);
      final data = result.data as Map<String, dynamic>;

      if (data['success'] == true) {
        return data;
      } else {
        return null;
      }
    } catch (e) {
      if (e is FirebaseFunctionsException) {

        // エラー情報を返す
        return {
          'success': false,
          'error': e.message,
          'code': e.code,
          'details': e.details,
        };
      }
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 生成されたアンケートをプレビュー用のテンプレートに変換
  static SurveyTemplate? convertGPTResponseToTemplate(Map<String, dynamic> gptResponse) {
    try {

      // successがfalseの場合
      if (gptResponse['success'] != true) {
        return null;
      }

      // generatedTemplateまたはquestionsを探す（GPT-5のレスポンス形式に対応）
      Map<String, dynamic>? templateData;

      // まずgeneratedTemplateを探す
      if (gptResponse['generatedTemplate'] != null) {
        templateData = gptResponse['generatedTemplate'] as Map<String, dynamic>;
      }
      // なければ直接questionsがあるか確認（GPT-5形式）
      else if (gptResponse['questions'] != null) {
        templateData = gptResponse;
      }
      // どちらもない場合はエラー
      else {
        return null;
      }


      // 質問項目の変換
      final questions = <SurveyQuestion>[];
      if (templateData['questions'] != null) {
        final questionsList = templateData['questions'] as List<dynamic>;

        for (final q in questionsList) {
          try {
            questions.add(SurveyQuestion.fromJson(q as Map<String, dynamic>));
          } catch (e) {
          }
        }
      }

      // テンプレートの作成

      final template = SurveyTemplate(
        id: 'gpt_generated_${DateTime.now().millisecondsSinceEpoch}',
        title: templateData['title'] ?? 'GPT-5生成アンケート',
        description: templateData['description'] ?? '',
        type: templateData['isPreSurvey'] == true ? SurveyType.pre : SurveyType.experiment,
        category: _parseCategory(templateData['category']),
        questions: questions,
        instructions: templateData['instructions'],
        estimatedMinutes: templateData['estimatedMinutes'] ?? 10,
      );

      return template;
    } catch (e) {
      return null;
    }
  }

  /// カテゴリ文字列をenumに変換
  static SurveyCategory _parseCategory(String? categoryStr) {
    if (categoryStr == null) return SurveyCategory.custom;

    try {
      return SurveyCategory.values.firstWhere(
        (cat) => cat.name == categoryStr,
        orElse: () => SurveyCategory.custom,
      );
    } catch (e) {
      return SurveyCategory.custom;
    }
  }

  /// プロンプトのプレビューを生成（デバッグ用）
  static String generatePromptPreview({
    required String experimentTitle,
    required String purpose,
    required String targetAudience,
    bool isPreSurvey = false,
  }) {
    return '''
【実験情報】
タイトル: $experimentTitle
目的: $purpose
対象者: $targetAudience
アンケートタイプ: ${isPreSurvey ? '事前アンケート' : '実験アンケート'}

【生成依頼】
上記の実験に適したアンケートの質問項目を生成してください。
- 質問は具体的で回答しやすいものにしてください
- 選択肢は適切な数と内容にしてください
- 必須項目は最小限に抑えてください
''';
  }

  /// APIキーの検証（セットアップ時に使用）
  static Future<bool> validateAPIKey(String apiKey) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('validateGPTAPIKey');
      final result = await callable.call({'apiKey': apiKey});
      return result.data['valid'] == true;
    } catch (e) {
      return false;
    }
  }

  /// 利用可能なGPTモデルのリストを取得
  static Future<List<String>> getAvailableModels() async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('getAvailableGPTModels');
      final result = await callable.call();
      final models = result.data['models'] as List<dynamic>?;
      return models?.cast<String>() ?? ['gpt-5'];
    } catch (e) {
      return ['gpt-5']; // デフォルト値
    }
  }
}