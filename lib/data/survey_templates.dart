import '../models/survey_template.dart';

/// 組み込みアンケートテンプレート
class SurveyTemplates {
  static const List<SurveyTemplate> templates = [
    // 基本情報収集テンプレート（事前アンケート）
    SurveyTemplate(
      id: 'basic_demographics',
      title: '基本情報アンケート',
      description: '参加者の基本的な属性情報を収集するためのテンプレートです',
      type: SurveyType.pre,
      category: SurveyCategory.demographic,
      estimatedMinutes: 3,
      questions: [
        SurveyQuestion(
          question: '年齢をお答えください',
          type: QuestionType.shortText,
          required: true,
          placeholder: '例: 22',
        ),
        SurveyQuestion(
          question: '性別をお答えください',
          type: QuestionType.multipleChoice,
          required: true,
          options: ['男性', '女性', 'その他', '回答しない'],
        ),
        SurveyQuestion(
          question: '学部・学科をお答えください',
          type: QuestionType.shortText,
          required: true,
          placeholder: '例: 文学部心理学科',
        ),
        SurveyQuestion(
          question: '学年をお答えください',
          type: QuestionType.multipleChoice,
          required: true,
          options: ['学部1年', '学部2年', '学部3年', '学部4年', '修士1年', '修士2年', '博士課程', 'その他'],
        ),
        SurveyQuestion(
          question: '実験参加経験はありますか？',
          type: QuestionType.multipleChoice,
          required: true,
          options: ['初めて', '1-2回', '3-5回', '6回以上'],
        ),
      ],
    ),

    // 健康状態確認テンプレート（事前アンケート）
    SurveyTemplate(
      id: 'health_check',
      title: '健康状態確認アンケート',
      description: '実験参加に必要な健康状態を確認するテンプレートです',
      type: SurveyType.pre,
      category: SurveyCategory.health,
      estimatedMinutes: 2,
      questions: [
        SurveyQuestion(
          question: '現在の健康状態はいかがですか？',
          type: QuestionType.scale,
          required: true,
          scaleMin: 1,
          scaleMax: 5,
          scaleMinLabel: '非常に悪い',
          scaleMaxLabel: '非常に良い',
        ),
        SurveyQuestion(
          question: '視力（矯正視力含む）に問題はありませんか？',
          type: QuestionType.multipleChoice,
          required: true,
          options: ['問題なし', '近視（矯正済み）', '遠視（矯正済み）', '色覚異常', 'その他'],
        ),
        SurveyQuestion(
          question: '聴力に問題はありませんか？',
          type: QuestionType.multipleChoice,
          required: true,
          options: ['問題なし', '軽度の難聴', '補聴器使用', 'その他'],
        ),
        SurveyQuestion(
          question: '現在服用している薬がある場合はお答えください',
          type: QuestionType.longText,
          required: false,
          placeholder: '薬品名と用途を記入してください',
        ),
        SurveyQuestion(
          question: 'アレルギーがある場合はお答えください',
          type: QuestionType.longText,
          required: false,
          placeholder: '該当するアレルギーを記入してください',
        ),
      ],
    ),

    // 心理尺度テンプレート（実験アンケート）
    SurveyTemplate(
      id: 'psychology_scale',
      title: '心理尺度評価アンケート',
      description: '感情や気分を測定する心理学実験用テンプレートです',
      type: SurveyType.experiment,
      category: SurveyCategory.psychology,
      estimatedMinutes: 5,
      instructions: '以下の質問について、現在のあなたの状態に最も当てはまる数字を選んでください。',
      questions: [
        SurveyQuestion(
          question: '現在、どの程度幸せを感じていますか？',
          type: QuestionType.scale,
          required: true,
          scaleMin: 1,
          scaleMax: 7,
          scaleMinLabel: '全く感じない',
          scaleMaxLabel: '非常に感じる',
        ),
        SurveyQuestion(
          question: '現在、どの程度不安を感じていますか？',
          type: QuestionType.scale,
          required: true,
          scaleMin: 1,
          scaleMax: 7,
          scaleMinLabel: '全く感じない',
          scaleMaxLabel: '非常に感じる',
        ),
        SurveyQuestion(
          question: '現在、どの程度リラックスしていますか？',
          type: QuestionType.scale,
          required: true,
          scaleMin: 1,
          scaleMax: 7,
          scaleMinLabel: '全く感じない',
          scaleMaxLabel: '非常に感じる',
        ),
        SurveyQuestion(
          question: '現在、どの程度集中できていますか？',
          type: QuestionType.scale,
          required: true,
          scaleMin: 1,
          scaleMax: 7,
          scaleMinLabel: '全く集中できない',
          scaleMaxLabel: '非常に集中できる',
        ),
        SurveyQuestion(
          question: '実験中に感じたことを自由に記述してください',
          type: QuestionType.longText,
          required: false,
          placeholder: '実験の感想や気づいたことなど',
        ),
      ],
    ),

    // 認知課題評価テンプレート（実験アンケート）
    SurveyTemplate(
      id: 'cognitive_evaluation',
      title: '認知課題評価アンケート',
      description: '認知実験後の主観的評価を収集するテンプレートです',
      type: SurveyType.experiment,
      category: SurveyCategory.cognitive,
      estimatedMinutes: 4,
      questions: [
        SurveyQuestion(
          question: '課題の難易度はどの程度でしたか？',
          type: QuestionType.scale,
          required: true,
          scaleMin: 1,
          scaleMax: 5,
          scaleMinLabel: '非常に簡単',
          scaleMaxLabel: '非常に難しい',
        ),
        SurveyQuestion(
          question: '課題への興味・関心はどの程度でしたか？',
          type: QuestionType.scale,
          required: true,
          scaleMin: 1,
          scaleMax: 5,
          scaleMinLabel: '全く興味なし',
          scaleMaxLabel: '非常に興味深い',
        ),
        SurveyQuestion(
          question: '自分のパフォーマンスをどう評価しますか？',
          type: QuestionType.scale,
          required: true,
          scaleMin: 1,
          scaleMax: 5,
          scaleMinLabel: '非常に悪い',
          scaleMaxLabel: '非常に良い',
        ),
        SurveyQuestion(
          question: '使用した戦略や工夫があれば教えてください',
          type: QuestionType.longText,
          required: false,
          placeholder: '課題を解く際の方法や考え方など',
        ),
        SurveyQuestion(
          question: '疲労度はどの程度ですか？',
          type: QuestionType.scale,
          required: true,
          scaleMin: 1,
          scaleMax: 5,
          scaleMinLabel: '全く疲れていない',
          scaleMaxLabel: '非常に疲れている',
        ),
      ],
    ),

    // UX評価テンプレート（実験アンケート）
    SurveyTemplate(
      id: 'ux_evaluation',
      title: 'ユーザビリティ評価アンケート',
      description: 'システムやアプリのユーザビリティを評価するテンプレートです',
      type: SurveyType.experiment,
      category: SurveyCategory.ux,
      estimatedMinutes: 6,
      questions: [
        SurveyQuestion(
          question: 'システムは使いやすかったですか？',
          type: QuestionType.scale,
          required: true,
          scaleMin: 1,
          scaleMax: 5,
          scaleMinLabel: '非常に使いにくい',
          scaleMaxLabel: '非常に使いやすい',
        ),
        SurveyQuestion(
          question: '操作方法は直感的でしたか？',
          type: QuestionType.scale,
          required: true,
          scaleMin: 1,
          scaleMax: 5,
          scaleMinLabel: '全く直感的でない',
          scaleMaxLabel: '非常に直感的',
        ),
        SurveyQuestion(
          question: '表示される情報は分かりやすかったですか？',
          type: QuestionType.scale,
          required: true,
          scaleMin: 1,
          scaleMax: 5,
          scaleMinLabel: '非常に分かりにくい',
          scaleMaxLabel: '非常に分かりやすい',
        ),
        SurveyQuestion(
          question: '改善すべき点があれば教えてください',
          type: QuestionType.longText,
          required: false,
          placeholder: '具体的な改善案など',
        ),
        SurveyQuestion(
          question: '良かった点があれば教えてください',
          type: QuestionType.longText,
          required: false,
          placeholder: '特に評価できる機能など',
        ),
        SurveyQuestion(
          question: 'このシステムを他の人に勧めたいですか？',
          type: QuestionType.scale,
          required: true,
          scaleMin: 1,
          scaleMax: 5,
          scaleMinLabel: '全く勧めない',
          scaleMaxLabel: '強く勧める',
        ),
      ],
    ),

    // 行動観察テンプレート（実験アンケート）
    SurveyTemplate(
      id: 'behavioral_observation',
      title: '行動観察記録アンケート',
      description: '実験中の行動や反応を記録するテンプレートです',
      type: SurveyType.experiment,
      category: SurveyCategory.behavioral,
      estimatedMinutes: 3,
      questions: [
        SurveyQuestion(
          question: '実験中に取った主な行動を選択してください',
          type: QuestionType.checkbox,
          required: true,
          options: ['観察', '操作', '思考', '記録', '待機', 'その他'],
        ),
        SurveyQuestion(
          question: '行動の頻度はどの程度でしたか？',
          type: QuestionType.multipleChoice,
          required: true,
          options: ['非常に少ない', '少ない', '普通', '多い', '非常に多い'],
        ),
        SurveyQuestion(
          question: '行動に影響を与えた要因があれば教えてください',
          type: QuestionType.longText,
          required: false,
          placeholder: '環境、指示、その他の要因など',
        ),
        SurveyQuestion(
          question: '実験中の集中度はどの程度でしたか？',
          type: QuestionType.scale,
          required: true,
          scaleMin: 1,
          scaleMax: 5,
          scaleMinLabel: '全く集中できなかった',
          scaleMaxLabel: '非常に集中できた',
        ),
      ],
    ),

    // 同意書テンプレート（事前アンケート）
    SurveyTemplate(
      id: 'informed_consent',
      title: '実験参加同意書',
      description: '実験参加への同意を確認するテンプレートです',
      type: SurveyType.pre,
      category: SurveyCategory.demographic,
      estimatedMinutes: 2,
      instructions: '以下の項目をよくお読みいただき、同意いただける場合はチェックをお願いします。',
      questions: [
        SurveyQuestion(
          question: '実験の目的と内容について説明を受け、理解しました',
          type: QuestionType.checkbox,
          required: true,
          options: ['同意します'],
        ),
        SurveyQuestion(
          question: '実験データが研究目的のみに使用されることに同意します',
          type: QuestionType.checkbox,
          required: true,
          options: ['同意します'],
        ),
        SurveyQuestion(
          question: '個人情報が適切に保護されることを理解しました',
          type: QuestionType.checkbox,
          required: true,
          options: ['同意します'],
        ),
        SurveyQuestion(
          question: 'いつでも実験参加を中止できることを理解しました',
          type: QuestionType.checkbox,
          required: true,
          options: ['同意します'],
        ),
        SurveyQuestion(
          question: '氏名（または学籍番号）',
          type: QuestionType.shortText,
          required: true,
          placeholder: '記録用',
        ),
        SurveyQuestion(
          question: '日付',
          type: QuestionType.date,
          required: true,
        ),
      ],
    ),

    // カスタムテンプレート（空のテンプレート）
    SurveyTemplate(
      id: 'custom_blank',
      title: 'カスタムアンケート',
      description: '自由に質問を作成できる空のテンプレートです',
      type: SurveyType.both,
      category: SurveyCategory.custom,
      estimatedMinutes: 0,
      instructions: 'Googleフォームで自由に質問を作成してください',
      questions: [],
    ),
  ];

  /// カテゴリ別にテンプレートを取得
  static List<SurveyTemplate> getTemplatesByCategory(SurveyCategory category) {
    return templates.where((t) => t.category == category).toList();
  }

  /// タイプ別にテンプレートを取得
  static List<SurveyTemplate> getTemplatesByType(SurveyType type) {
    return templates.where((t) => t.type == type || t.type == SurveyType.both).toList();
  }

  /// IDでテンプレートを取得
  static SurveyTemplate? getTemplateById(String id) {
    try {
      return templates.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }
}