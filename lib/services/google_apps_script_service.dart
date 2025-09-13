import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/survey_template.dart';

/// Google Apps Script Web App と連携するサービス
class GoogleAppsScriptService {
  // TODO: Google Apps Script をデプロイ後、実際のURLに置き換える
  static const String _scriptUrl = 'https://script.google.com/macros/s/YOUR_SCRIPT_ID/exec';
  
  /// テンプレート一覧を取得
  static Future<List<Map<String, dynamic>>> getAvailableTemplates() async {
    try {
      final response = await http.get(
        Uri.parse('$_scriptUrl?action=list'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['templates']);
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching templates: $e');
      return [];
    }
  }
  
  /// テンプレートからフォームを作成
  static Future<Map<String, dynamic>?> createFormFromTemplate({
    required String templateId,
    required String title,
    String? description,
  }) async {
    try {
      final params = {
        'action': 'create',
        'templateId': templateId,
        'title': title,
        if (description != null) 'description': description,
      };
      
      final uri = Uri.parse(_scriptUrl).replace(queryParameters: params);
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error creating form from template: $e');
      return null;
    }
  }
  
  /// JSONデータからフォームを作成
  static Future<Map<String, dynamic>?> createFormFromJson({
    required SurveyTemplate template,
    String? customTitle,
  }) async {
    try {
      final formData = template.exportAsGoogleFormsJson();
      if (customTitle != null) {
        formData['title'] = customTitle;
      }
      
      final response = await http.post(
        Uri.parse(_scriptUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': 'createFromJson',
          'formData': formData,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error creating form from JSON: $e');
      return null;
    }
  }
  
  /// テンプレートフォームをクローン
  static Future<Map<String, dynamic>?> cloneTemplateForm({
    required String templateId,
    required String title,
    String? description,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_scriptUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': 'cloneTemplate',
          'templateId': templateId,
          'title': title,
          if (description != null) 'description': description,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error cloning template form: $e');
      return null;
    }
  }
  
  /// スクリプトURLが設定されているかチェック
  static bool isConfigured() {
    return !_scriptUrl.contains('YOUR_SCRIPT_ID');
  }
  
  /// 設定手順を返す
  static String getSetupInstructions() {
    return '''
Google Apps Scriptのセットアップ手順:

1. Google Apps Script にアクセス
   https://script.google.com/

2. 新しいプロジェクトを作成

3. google_apps_script/google_forms_templates.gs の内容をコピー＆ペースト

4. テンプレートフォームのIDを設定
   - 各テンプレート用のGoogleフォームを作成
   - フォームのURLからIDを取得（/d/と/editの間の文字列）
   - TEMPLATE_FORMSオブジェクトのIDを更新

5. デプロイ
   - 「デプロイ」→「新しいデプロイ」を選択
   - 種類：「ウェブアプリ」
   - 実行ユーザー：「自分」
   - アクセスできるユーザー：「全員」
   - デプロイをクリック

6. デプロイURLをコピー
   - 表示されたURLをコピー
   - lib/services/google_apps_script_service.dart の _scriptUrl を更新

7. 権限を承認
   - 初回実行時に権限承認が必要
   - 「詳細」→「安全でないページに移動」→「許可」

これで自動フォーム作成機能が使用可能になります！
''';
  }
}