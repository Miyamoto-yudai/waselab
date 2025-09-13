import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/survey_template.dart';
import '../data/survey_templates.dart';
import 'package:flutter/services.dart';

/// Google Forms関連の機能を提供するサービス
class GoogleFormsService {
  static const String _baseFormUrl = 'https://docs.google.com/forms/create';
  
  /// Firebase Functions経由でGoogleフォームを自動作成して開く
  static Future<Map<String, dynamic>?> createAndOpenGoogleForm({
    required SurveyTemplate template,
    String? customTitle,
  }) async {
    try {
      // Firebase Functionsを呼び出し
      final HttpsCallable callable = FirebaseFunctions.instance
          .httpsCallable('createGoogleFormFromTemplate');
      
      // テンプレートデータを準備
      final templateData = {
        'title': customTitle ?? '${template.title}_${DateTime.now().millisecondsSinceEpoch}',
        'description': template.description,
        'type': template.type.name,
        'category': template.category.name,
        'questions': template.questions.map((q) => {
          'question': q.question,
          'type': q.type.name,
          'required': q.required,
          'options': q.options,
          'scaleMin': q.scaleMin,
          'scaleMax': q.scaleMax,
          'scaleMinLabel': q.scaleMinLabel,
          'scaleMaxLabel': q.scaleMaxLabel,
          'placeholder': q.placeholder,
        }).toList(),
        'instructions': template.instructions,
        'estimatedMinutes': template.estimatedMinutes,
      };
      
      // Functionsを実行
      final result = await callable.call({
        'template': templateData,
        'customTitle': customTitle,
      });
      
      final data = result.data as Map<String, dynamic>;
      
      if (data['success'] == true && data['formUrl'] != null) {
        // 作成されたフォームを開く
        final formUrl = Uri.parse(data['formUrl']);
        if (await canLaunchUrl(formUrl)) {
          await launchUrl(
            formUrl,
            mode: LaunchMode.externalApplication,
          );
        }
        return data;
      }
      
      return null;
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Firebase Functions Error: ${e.code} - ${e.message}');
      debugPrint('Details: ${e.details}');
      
      // エラー情報を返す（UIで表示するため）
      return {
        'success': false,
        'error': e.message,
        'code': e.code,
        'details': e.details,
      };
    } catch (e) {
      debugPrint('Error creating Google Form via Functions: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  /// テンプレートを使用してGoogleフォームを開く（従来の手動方式）
  static Future<bool> openGoogleFormWithTemplate(SurveyTemplate template) async {
    try {
      // テンプレートから生成したURLを開く
      final url = Uri.parse(template.generateGoogleFormUrl());
      
      if (await canLaunchUrl(url)) {
        // クリップボードに質問項目をコピー
        await _copyQuestionsToClipboard(template);
        
        // Googleフォームを開く
        await launchUrl(
          url, 
          mode: LaunchMode.externalApplication,
        );
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error opening Google Form: $e');
      return false;
    }
  }
  
  /// 新規Googleフォームを開く（テンプレートなし）
  static Future<bool> openNewGoogleForm() async {
    try {
      final url = Uri.parse(_baseFormUrl);
      
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error opening new Google Form: $e');
      return false;
    }
  }
  
  /// 既存のGoogleフォームURLを開く
  static Future<bool> openExistingForm(String formUrl) async {
    try {
      // URLの検証
      if (!_isValidGoogleFormUrl(formUrl)) {
        return false;
      }
      
      final url = Uri.parse(formUrl);
      
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error opening existing form: $e');
      return false;
    }
  }
  
  /// 質問項目をクリップボードにコピー
  static Future<void> _copyQuestionsToClipboard(SurveyTemplate template) async {
    try {
      final questionsText = template.exportQuestionsAsText();
      await Clipboard.setData(ClipboardData(text: questionsText));
    } catch (e) {
      debugPrint('Error copying to clipboard: $e');
    }
  }
  
  /// URLがGoogleフォームのURLかどうかを検証
  static bool _isValidGoogleFormUrl(String url) {
    if (url.isEmpty) return false;
    
    // GoogleフォームのURLパターンをチェック
    final patterns = [
      RegExp(r'https?://docs\.google\.com/forms/'),
      RegExp(r'https?://forms\.gle/'),
    ];
    
    return patterns.any((pattern) => pattern.hasMatch(url));
  }
  
  /// テンプレートIDからテンプレートを取得
  static SurveyTemplate? getTemplateById(String templateId) {
    return SurveyTemplates.getTemplateById(templateId);
  }
  
  /// カテゴリ別にテンプレートを取得
  static List<SurveyTemplate> getTemplatesByCategory(SurveyCategory category) {
    return SurveyTemplates.getTemplatesByCategory(category);
  }
  
  /// タイプ別にテンプレートを取得
  static List<SurveyTemplate> getTemplatesByType(SurveyType type) {
    return SurveyTemplates.getTemplatesByType(type);
  }
  
  /// すべてのテンプレートを取得
  static List<SurveyTemplate> getAllTemplates() {
    return SurveyTemplates.templates;
  }
  
  /// 推奨テンプレートを取得（実験タイプに基づく）
  static List<SurveyTemplate> getRecommendedTemplates({
    required bool isPreSurvey,
    SurveyCategory? preferredCategory,
  }) {
    final type = isPreSurvey ? SurveyType.pre : SurveyType.experiment;
    var templates = getTemplatesByType(type);
    
    // カテゴリフィルタリング
    if (preferredCategory != null) {
      templates = templates
          .where((t) => t.category == preferredCategory)
          .toList();
    }
    
    // 推奨順にソート（質問数が適度なものを優先）
    templates.sort((a, b) {
      // カスタムテンプレートは最後に
      if (a.category == SurveyCategory.custom) return 1;
      if (b.category == SurveyCategory.custom) return -1;
      
      // 質問数が5〜10個のものを優先
      final aScore = (a.questions.length - 7).abs();
      final bScore = (b.questions.length - 7).abs();
      return aScore.compareTo(bScore);
    });
    
    return templates;
  }
  
  /// GoogleフォームのプレフィルURLを生成
  /// 実験情報を事前入力した状態でフォームを開くためのURL
  static String generatePrefilledFormUrl({
    required String baseFormUrl,
    Map<String, String>? prefillData,
  }) {
    if (prefillData == null || prefillData.isEmpty) {
      return baseFormUrl;
    }
    
    final uri = Uri.parse(baseFormUrl);
    final queryParams = Map<String, String>.from(uri.queryParameters);
    
    // プレフィルデータを追加
    prefillData.forEach((key, value) {
      queryParams['entry.$key'] = value;
    });
    
    return uri.replace(queryParameters: queryParams).toString();
  }
  
  /// テンプレートの説明文を生成（LLM連携用の準備）
  static String generateTemplateDescription(SurveyTemplate template) {
    final buffer = StringBuffer();
    
    buffer.writeln('【${template.title}】');
    buffer.writeln('タイプ: ${template.type.label}');
    buffer.writeln('カテゴリ: ${template.category.label}');
    buffer.writeln('予想所要時間: ${template.estimatedMinutes ?? "未設定"}分');
    buffer.writeln();
    buffer.writeln('説明: ${template.description}');
    
    if (template.instructions != null) {
      buffer.writeln();
      buffer.writeln('回答手順: ${template.instructions}');
    }
    
    buffer.writeln();
    buffer.writeln('質問数: ${template.questions.length}');
    
    return buffer.toString();
  }
}