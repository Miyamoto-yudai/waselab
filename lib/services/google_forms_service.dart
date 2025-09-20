import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import '../models/survey_template.dart';
import '../data/survey_templates.dart';
import 'package:flutter/services.dart';
import 'google_account_service.dart';

/// Google Forms関連の機能を提供するサービス
class GoogleFormsService {
  static const String _baseFormUrl = 'https://docs.google.com/forms/create';
  static final GoogleAccountService _accountService = GoogleAccountService();

  /// エラーコールバック（UI層でエラーハンドリングするため）
  static Function(String error, bool needsAccountSelection)? onError;
  
  /// Firebase Functions経由でGoogleフォームを自動作成して開く（アカウント選択機能付き）
  static Future<Map<String, dynamic>?> createAndOpenGoogleForm({
    required SurveyTemplate template,
    String? customTitle,
    bool forceAccountSelection = false,
  }) async {
    try {
      // アカウントサービスを初期化
      await _accountService.initialize();

      // アカウントを確認・選択
      if (_accountService.currentAccount == null || forceAccountSelection) {
        final account = await _accountService.selectAccount(
          forceAccountSelection: forceAccountSelection
        );
        if (account == null) {
          onError?.call(
            'Googleフォームを作成するには、Googleアカウントとの連携が必要です。\n'
            '設定画面からGoogleアカウントを連携してください。',
            true
          );
          return {
            'success': false,
            'error': 'Googleアカウントが連携されていません',
            'needsGoogleAuth': true,
            'needsAccountSelection': true,
          };
        }
      }

      // フォーム作成権限を確認
      final hasPermission = await _accountService.requestFormsPermission();
      if (!hasPermission) {
        onError?.call(
          'Google Formsへのアクセス権限が必要です。\n'
          '選択したアカウント（${_accountService.currentEmail}）に編集権限があることを確認してください。',
          false
        );
        return {
          'success': false,
          'error': 'フォーム作成権限がありません',
          'needsPermission': true,
        };
      }

      // Firebase Functionsを呼び出し
      final HttpsCallable callable = FirebaseFunctions.instance
          .httpsCallable('createGoogleFormFromTemplate');

      // テンプレートデータを準備（アカウント情報を含む）
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
        'userEmail': _accountService.currentEmail, // 連携したGoogleアカウントのメールアドレス
      };

      // Functionsを実行
      final result = await callable.call({
        'template': templateData,
        'customTitle': customTitle,
      });

      final data = result.data as Map<String, dynamic>;

      if (data['success'] == true && data['formUrl'] != null) {
        // 作成されたフォームを開く（アカウント指定付きURL）
        final formUrlWithAccount = _accountService.generateFormsUrl(
          baseUrl: data['formUrl'],
          params: {},
        );
        final formUrl = Uri.parse(formUrlWithAccount);
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
      debugPrint('Firebase Functions エラー: ${e.message}');

      // 権限エラーの場合は特別な処理
      if (e.code == 'permission-denied' || e.message?.contains('permission') == true) {
        onError?.call(
          'Google Formsの作成権限がありません。\n別のGoogleアカウントを選択してください。',
          true
        );
        return {
          'success': false,
          'error': e.message,
          'code': e.code,
          'details': e.details,
          'needsAccountSelection': true,
        };
      }

      // その他のエラー情報を返す
      return {
        'success': false,
        'error': e.message,
        'code': e.code,
        'details': e.details,
      };
    } catch (e) {
      debugPrint('フォーム作成エラー: $e');
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
      return false;
    }
  }
  
  /// 新規Googleフォームを開く（テンプレートなし、アカウント指定付き）
  static Future<bool> openNewGoogleForm({bool forceAccountSelection = false}) async {
    try {
      // アカウントサービスを初期化
      await _accountService.initialize();

      // アカウントを確認・選択
      if (_accountService.currentAccount == null || forceAccountSelection) {
        final account = await _accountService.selectAccount(
          forceAccountSelection: forceAccountSelection
        );
        if (account == null) {
          onError?.call(
            'Googleフォームを作成するには、Googleアカウントとの連携が必要です。\n'
            '設定画面からGoogleアカウントを連携してください。',
            true
          );
          return false;
        }
      }

      // アカウント指定付きURLを生成
      final urlWithAccount = _accountService.generateFormsUrl(
        baseUrl: _baseFormUrl,
        params: {},
      );
      final url = Uri.parse(urlWithAccount);

      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('新規フォーム作成エラー: $e');
      onError?.call('フォームの作成に失敗しました: $e', false);
      return false;
    }
  }
  
  /// 既存のGoogleフォームURLを開く（アカウント指定付き）
  static Future<bool> openExistingForm(String formUrl, {bool forceAccountSelection = false}) async {
    try {
      // URLの検証
      if (!_isValidGoogleFormUrl(formUrl)) {
        onError?.call('無効なGoogle FormsのURLです', false);
        return false;
      }

      // アカウントサービスを初期化
      await _accountService.initialize();

      // アカウントを確認・選択（必要な場合）
      if (_accountService.currentAccount == null || forceAccountSelection) {
        final account = await _accountService.selectAccount(
          forceAccountSelection: forceAccountSelection
        );
        if (account == null) {
          onError?.call(
            'Googleフォームを編集するには、Googleアカウントとの連携が必要です。\n'
            '設定画面からGoogleアカウントを連携してください。',
            true
          );
          return false;
        }
      }

      // アカウント指定付きURLを生成
      final urlWithAccount = _accountService.generateFormsUrl(
        baseUrl: formUrl,
        params: {},
      );
      final url = Uri.parse(urlWithAccount);

      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('既存フォームを開くエラー: $e');
      onError?.call('フォームを開くことができませんでした: $e', false);
      return false;
    }
  }
  
  /// 質問項目をクリップボードにコピー
  static Future<void> _copyQuestionsToClipboard(SurveyTemplate template) async {
    try {
      final questionsText = template.exportQuestionsAsText();
      await Clipboard.setData(ClipboardData(text: questionsText));
    } catch (e) {
      // クリップボードのコピーに失敗しても処理を続行
      debugPrint('Failed to copy to clipboard: $e');
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

  /// アカウントを切り替える
  static Future<bool> switchAccount() async {
    try {
      final account = await _accountService.switchAccount();
      if (account == null) {
        onError?.call('アカウントの切り替えに失敗しました', true);
        return false;
      }

      // フォーム権限を再確認
      final hasPermission = await _accountService.requestFormsPermission();
      if (!hasPermission) {
        onError?.call(
          '新しいアカウント（${account.email}）にGoogle Formsの編集権限がありません',
          false
        );
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('アカウント切り替えエラー: $e');
      onError?.call('アカウント切り替えエラー: $e', false);
      return false;
    }
  }

  /// 現在のGoogleアカウント情報を取得
  static Map<String, dynamic>? getCurrentAccountInfo() {
    if (_accountService.currentAccount == null) return null;
    return _accountService.getAccountInfo();
  }

  /// アカウントをリセット（サインアウト）
  static Future<void> resetAccount() async {
    await _accountService.signOut();
  }
}