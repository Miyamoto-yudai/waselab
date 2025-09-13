/// アンケートタイプ
enum SurveyType {
  pre('事前アンケート'),
  experiment('実験アンケート'),
  both('両方');

  final String label;
  const SurveyType(this.label);
}

/// アンケートカテゴリ
enum SurveyCategory {
  psychology('心理学実験'),
  cognitive('認知実験'),
  behavioral('行動実験'),
  ux('UX評価'),
  demographic('基本情報'),
  health('健康調査'),
  custom('カスタム');

  final String label;
  const SurveyCategory(this.label);
}

/// 質問タイプ
enum QuestionType {
  shortText('短い回答'),
  longText('長い回答'),
  multipleChoice('ラジオボタン'),
  checkbox('チェックボックス'),
  scale('線形目盛り'),
  date('日付'),
  time('時刻');

  final String label;
  const QuestionType(this.label);
}

/// 質問項目
class SurveyQuestion {
  final String question;
  final QuestionType type;
  final bool required;
  final List<String>? options; // 選択肢（multipleChoice, checkboxの場合）
  final int? scaleMin; // 最小値（scaleの場合）
  final int? scaleMax; // 最大値（scaleの場合）
  final String? scaleMinLabel; // 最小値ラベル（scaleの場合）
  final String? scaleMaxLabel; // 最大値ラベル（scaleの場合）
  final String? placeholder; // プレースホルダー

  const SurveyQuestion({
    required this.question,
    required this.type,
    this.required = false,
    this.options,
    this.scaleMin,
    this.scaleMax,
    this.scaleMinLabel,
    this.scaleMaxLabel,
    this.placeholder,
  });

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'type': type.name,
      'required': required,
      'options': options,
      'scaleMin': scaleMin,
      'scaleMax': scaleMax,
      'scaleMinLabel': scaleMinLabel,
      'scaleMaxLabel': scaleMaxLabel,
      'placeholder': placeholder,
    };
  }

  factory SurveyQuestion.fromJson(Map<String, dynamic> json) {
    return SurveyQuestion(
      question: json['question'],
      type: QuestionType.values.firstWhere((e) => e.name == json['type']),
      required: json['required'] ?? false,
      options: json['options'] != null ? List<String>.from(json['options']) : null,
      scaleMin: json['scaleMin'],
      scaleMax: json['scaleMax'],
      scaleMinLabel: json['scaleMinLabel'],
      scaleMaxLabel: json['scaleMaxLabel'],
      placeholder: json['placeholder'],
    );
  }
}

/// アンケートテンプレート
class SurveyTemplate {
  final String id;
  final String title;
  final String description;
  final SurveyType type;
  final SurveyCategory category;
  final List<SurveyQuestion> questions;
  final String? instructions; // 回答手順説明
  final int? estimatedMinutes; // 予想所要時間
  final Map<String, String>? googleFormParams; // Googleフォーム用パラメータ

  const SurveyTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.category,
    required this.questions,
    this.instructions,
    this.estimatedMinutes,
    this.googleFormParams,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'category': category.name,
      'questions': questions.map((q) => q.toJson()).toList(),
      'instructions': instructions,
      'estimatedMinutes': estimatedMinutes,
      'googleFormParams': googleFormParams,
    };
  }

  factory SurveyTemplate.fromJson(Map<String, dynamic> json) {
    return SurveyTemplate(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: SurveyType.values.firstWhere((e) => e.name == json['type']),
      category: SurveyCategory.values.firstWhere((e) => e.name == json['category']),
      questions: (json['questions'] as List)
          .map((q) => SurveyQuestion.fromJson(q))
          .toList(),
      instructions: json['instructions'],
      estimatedMinutes: json['estimatedMinutes'],
      googleFormParams: json['googleFormParams'] != null 
          ? Map<String, String>.from(json['googleFormParams'])
          : null,
    );
  }

  /// Googleフォーム作成用のURLを生成
  String generateGoogleFormUrl() {
    // Googleフォームの新規作成URL
    var url = 'https://docs.google.com/forms/create';
    
    // テンプレートパラメータがある場合は追加
    if (googleFormParams != null && googleFormParams!.isNotEmpty) {
      final params = googleFormParams!.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
      url += '?$params';
    }
    
    return url;
  }

  /// 質問項目をGoogleフォーム用のテキストに変換
  String exportQuestionsAsText() {
    final buffer = StringBuffer();
    
    // フォームタイトル
    buffer.writeln('=== フォームタイトル ===');
    buffer.writeln(title);
    buffer.writeln();
    
    // フォーム説明
    buffer.writeln('=== フォーム説明 ===');
    buffer.writeln(description);
    if (instructions != null) {
      buffer.writeln();
      buffer.writeln(instructions);
    }
    buffer.writeln();
    buffer.writeln('=== 質問項目 ===');
    buffer.writeln();
    
    // 質問項目（Googleフォームに貼り付けやすい形式）
    for (int i = 0; i < questions.length; i++) {
      final q = questions[i];
      final requiredMark = q.required ? ' *必須' : '';
      
      // 質問文
      buffer.writeln('${q.question}$requiredMark');
      
      // 質問タイプごとの情報
      switch (q.type) {
        case QuestionType.multipleChoice:
          buffer.writeln('[ラジオボタン]');
          if (q.options != null) {
            for (final option in q.options!) {
              buffer.writeln(option);
            }
          }
          break;
        case QuestionType.checkbox:
          buffer.writeln('[チェックボックス]');
          if (q.options != null) {
            for (final option in q.options!) {
              buffer.writeln(option);
            }
          }
          break;
        case QuestionType.scale:
          final min = q.scaleMin ?? 1;
          final max = q.scaleMax ?? 5;
          final minLabel = q.scaleMinLabel ?? '';
          final maxLabel = q.scaleMaxLabel ?? '';
          buffer.writeln('[均等目盛: $min～$max]');
          if (minLabel.isNotEmpty) buffer.writeln('最小値ラベル: $minLabel');
          if (maxLabel.isNotEmpty) buffer.writeln('最大値ラベル: $maxLabel');
          break;
        case QuestionType.shortText:
          buffer.writeln('[記述式（短文）]');
          if (q.placeholder != null) buffer.writeln('ヒント: ${q.placeholder}');
          break;
        case QuestionType.longText:
          buffer.writeln('[記述式（長文）]');
          if (q.placeholder != null) buffer.writeln('ヒント: ${q.placeholder}');
          break;
        case QuestionType.date:
          buffer.writeln('[日付]');
          break;
        case QuestionType.time:
          buffer.writeln('[時刻]');
          break;
      }
      
      buffer.writeln(); // 質問間の空行
    }
    
    return buffer.toString();
  }
  
  /// GoogleフォームAPI用のJSON形式でエクスポート
  Map<String, dynamic> exportAsGoogleFormsJson() {
    return {
      'title': title,
      'description': description,
      'documentTitle': title,
      'confirmationMessage': '回答を送信しました。ご協力ありがとうございます。',
      'items': questions.map((q) => _questionToGoogleFormsItem(q)).toList(),
    };
  }
  
  /// 質問をGoogleフォームのアイテム形式に変換
  Map<String, dynamic> _questionToGoogleFormsItem(SurveyQuestion q) {
    final item = {
      'title': q.question,
      'description': q.placeholder ?? '',
      'required': q.required,
    };
    
    switch (q.type) {
      case QuestionType.multipleChoice:
        item['questionItem'] = {
          'question': {
            'required': q.required,
            'choiceQuestion': {
              'type': 'RADIO',
              'options': q.options?.map((opt) => {'value': opt}).toList() ?? [],
            }
          }
        };
        break;
      case QuestionType.checkbox:
        item['questionItem'] = {
          'question': {
            'required': q.required,
            'choiceQuestion': {
              'type': 'CHECKBOX',
              'options': q.options?.map((opt) => {'value': opt}).toList() ?? [],
            }
          }
        };
        break;
      case QuestionType.scale:
        item['questionItem'] = {
          'question': {
            'required': q.required,
            'scaleQuestion': {
              'low': q.scaleMin ?? 1,
              'high': q.scaleMax ?? 5,
              'lowLabel': q.scaleMinLabel ?? '',
              'highLabel': q.scaleMaxLabel ?? '',
            }
          }
        };
        break;
      case QuestionType.shortText:
        item['questionItem'] = {
          'question': {
            'required': q.required,
            'textQuestion': {
              'paragraph': false,
            }
          }
        };
        break;
      case QuestionType.longText:
        item['questionItem'] = {
          'question': {
            'required': q.required,
            'textQuestion': {
              'paragraph': true,
            }
          }
        };
        break;
      case QuestionType.date:
        item['questionItem'] = {
          'question': {
            'required': q.required,
            'dateQuestion': {
              'includeTime': false,
              'includeYear': true,
            }
          }
        };
        break;
      case QuestionType.time:
        item['questionItem'] = {
          'question': {
            'required': q.required,
            'timeQuestion': {
              'duration': false,
            }
          }
        };
        break;
    }
    
    return item;
  }
  
  /// 構造化されたMarkdown形式でエクスポート
  String exportAsMarkdown() {
    final buffer = StringBuffer();
    
    buffer.writeln('# $title');
    buffer.writeln();
    buffer.writeln('## 概要');
    buffer.writeln('- **説明**: $description');
    buffer.writeln('- **タイプ**: ${type.label}');
    buffer.writeln('- **カテゴリ**: ${category.label}');
    if (estimatedMinutes != null) {
      buffer.writeln('- **予想所要時間**: 約$estimatedMinutes分');
    }
    buffer.writeln();
    
    if (instructions != null) {
      buffer.writeln('## 回答手順');
      buffer.writeln(instructions);
      buffer.writeln();
    }
    
    buffer.writeln('## 質問項目');
    buffer.writeln();
    
    for (int i = 0; i < questions.length; i++) {
      final q = questions[i];
      final num = i + 1;
      final requiredMark = q.required ? ' *(必須)*' : '';
      
      buffer.writeln('### $num. ${q.question}$requiredMark');
      buffer.writeln();
      
      // 質問タイプの情報
      buffer.write('**形式**: ');
      switch (q.type) {
        case QuestionType.multipleChoice:
          buffer.writeln('ラジオボタン（単一選択）');
          if (q.options != null) {
            buffer.writeln('**選択肢**:');
            for (final option in q.options!) {
              buffer.writeln('- [ ] $option');
            }
          }
          break;
        case QuestionType.checkbox:
          buffer.writeln('チェックボックス（複数選択可）');
          if (q.options != null) {
            buffer.writeln('**選択肢**:');
            for (final option in q.options!) {
              buffer.writeln('- [ ] $option');
            }
          }
          break;
        case QuestionType.scale:
          final min = q.scaleMin ?? 1;
          final max = q.scaleMax ?? 5;
          buffer.writeln('線形目盛り（$min～$max）');
          if (q.scaleMinLabel != null || q.scaleMaxLabel != null) {
            buffer.writeln('**ラベル**:');
            if (q.scaleMinLabel != null) buffer.writeln('- 最小値: ${q.scaleMinLabel}');
            if (q.scaleMaxLabel != null) buffer.writeln('- 最大値: ${q.scaleMaxLabel}');
          }
          break;
        case QuestionType.shortText:
          buffer.writeln('記述式（短文回答）');
          if (q.placeholder != null) {
            buffer.writeln('**ヒント**: ${q.placeholder}');
          }
          break;
        case QuestionType.longText:
          buffer.writeln('記述式（長文回答）');
          if (q.placeholder != null) {
            buffer.writeln('**ヒント**: ${q.placeholder}');
          }
          break;
        case QuestionType.date:
          buffer.writeln('日付選択');
          break;
        case QuestionType.time:
          buffer.writeln('時刻選択');
          break;
      }
      
      buffer.writeln();
    }
    
    return buffer.toString();
  }
}