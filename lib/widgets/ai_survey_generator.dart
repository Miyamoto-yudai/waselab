import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/gpt_service.dart';
import '../services/google_forms_service.dart';
import '../models/survey_template.dart';

/// AIによるアンケート生成ウィジェット
class AISurveyGenerator extends StatefulWidget {
  final bool isPreSurvey;
  final String? experimentTitle;
  final String? experimentDescription;
  final Function(String url)? onFormCreated;
  final SurveyTemplate? baseTemplate;

  const AISurveyGenerator({
    super.key,
    required this.isPreSurvey,
    this.experimentTitle,
    this.experimentDescription,
    this.onFormCreated,
    this.baseTemplate,
  });

  @override
  State<AISurveyGenerator> createState() => _AISurveyGeneratorState();
}

class _AISurveyGeneratorState extends State<AISurveyGenerator> {
  final _formKey = GlobalKey<FormState>();

  // 入力コントローラー
  final _purposeController = TextEditingController();
  final _targetAudienceController = TextEditingController();
  final _expectedOutcomeController = TextEditingController();
  final _additionalRequirementsController = TextEditingController();
  final _experimentContextController = TextEditingController();
  final _referenceFormUrlController = TextEditingController();  // Google Forms URL参照用

  // 状態管理
  bool _isGenerating = false;
  double _generationProgress = 0.0;
  String _statusMessage = '';
  SurveyTemplate? _generatedTemplate;
  SurveyCategory _selectedCategory = SurveyCategory.custom;
  int _maxQuestions = 10;

  // テンプレート参照・固定設定
  final List<String> _referenceTemplateIds = [];  // 参考にするテンプレート
  String? _headerTemplateId;  // 開始部分の固定テンプレート
  String? _footerTemplateId;  // 終了部分の固定テンプレート
  bool _useReferenceTemplates = false;  // 参考テンプレート使用フラグ
  bool _useFixedTemplates = false;  // 固定テンプレート使用フラグ
  bool _useReferenceFormUrl = false;  // Google Forms URL参照フラグ

  // テンプレート選択用
  List<SurveyTemplate> _allTemplates = [];
  SurveyCategory? _templateFilterCategory;

  // Google Forms関連
  Map<String, dynamic>? _generationResult;
  String? _formUrl;
  String? _editUrl;
  String? _formId;

  // エラー管理
  String? _errorMessage;
  int _retryCount = 0;
  static const int _maxRetries = 3;

  @override
  void initState() {
    super.initState();
    // 既存の実験情報があれば、関連フィールドを自動入力
    if (widget.experimentTitle != null) {
      _purposeController.text = '${widget.experimentTitle}に関する${widget.isPreSurvey ? '事前' : '事後'}評価';
    }
    // 実験コンテキスト情報を設定
    if (widget.experimentDescription != null && widget.experimentDescription!.isNotEmpty) {
      _experimentContextController.text = widget.experimentDescription!;
    }
    // 利用可能なテンプレートを読み込み
    _loadTemplates();
  }

  void _loadTemplates() {
    setState(() {
      _allTemplates = GoogleFormsService.getAllTemplates();
    });
  }

  @override
  void dispose() {
    _purposeController.dispose();
    _targetAudienceController.dispose();
    _expectedOutcomeController.dispose();
    _additionalRequirementsController.dispose();
    _experimentContextController.dispose();
    _referenceFormUrlController.dispose();
    super.dispose();
  }

  // AIでアンケートを生成
  Future<void> _generateSurvey() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isGenerating = true;
      _generationProgress = 0.1;
      _statusMessage = 'AIに接続中...';
      _errorMessage = null;
    });

    try {
      // プログレス更新のシミュレーション
      _updateProgress(0.3, 'プロンプトを生成中...');
      await Future.delayed(const Duration(milliseconds: 500));

      _updateProgress(0.5, 'AIで質問を生成中...');

      // GPTサービスを呼び出し
      final result = await GPTService.generateSurveyTemplate(
        experimentTitle: widget.experimentTitle ?? '実験',
        experimentDescription: _experimentContextController.text.isNotEmpty
            ? _experimentContextController.text
            : widget.experimentDescription ?? '',
        purpose: _purposeController.text,
        targetAudience: _targetAudienceController.text,
        expectedOutcome: _expectedOutcomeController.text,
        additionalRequirements: _additionalRequirementsController.text.isNotEmpty
            ? _additionalRequirementsController.text
            : null,
        preferredCategory: _selectedCategory,
        isPreSurvey: widget.isPreSurvey,
        baseTemplateId: widget.baseTemplate?.id,
        maxQuestions: _maxQuestions,
        modelName: 'gpt-5',  // 運営側で管理
        referenceTemplateIds: _useReferenceTemplates ? _referenceTemplateIds : null,
        headerTemplateId: _useFixedTemplates ? _headerTemplateId : null,
        footerTemplateId: _useFixedTemplates ? _footerTemplateId : null,
        referenceFormUrl: _useReferenceFormUrl ? _referenceFormUrlController.text.trim() : null,
      );

      if (result == null || result['success'] != true) {
        throw Exception(result?['error'] ?? '生成に失敗しました');
      }

      _updateProgress(0.8, 'テンプレートを作成中...');
      await Future.delayed(const Duration(milliseconds: 500));

      // 生成されたテンプレートを変換
      final template = GPTService.convertGPTResponseToTemplate(result);
      if (template == null) {
        throw Exception('テンプレートの変換に失敗しました');
      }

      _updateProgress(0.9, 'Googleフォームを作成中...');

      // フォームURLがある場合は通知
      if (result['formUrl'] != null) {
        widget.onFormCreated?.call(result['formUrl']);
      }

      setState(() {
        _generatedTemplate = template;
        _generationResult = result;
        _formUrl = result['formUrl'];
        _editUrl = result['editUrl'];
        _formId = result['formId'];
        _generationProgress = 1.0;
        _statusMessage = '生成完了！';
        _isGenerating = false;
      });

      // 成功メッセージを表示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'アンケートが生成されました（${template.questions.length}問）',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }

    } catch (e) {

      // リトライロジック
      if (_retryCount < _maxRetries) {
        setState(() {
          _retryCount++;
          _statusMessage = 'エラーが発生しました。再試行中... ($_retryCount/$_maxRetries)';
        });
        await Future.delayed(const Duration(seconds: 2));
        return _generateSurvey(); // 再試行
      }

      setState(() {
        _isGenerating = false;
        _generationProgress = 0.0;
        _errorMessage = _parseErrorMessage(e.toString());
        _statusMessage = '';
      });

      // エラーダイアログを表示
      if (mounted) {
        _showErrorDialog(_errorMessage!);
      }
    }
  }

  // プログレス更新
  void _updateProgress(double value, String message) {
    if (mounted) {
      setState(() {
        _generationProgress = value;
        _statusMessage = message;
      });
    }
  }

  // エラーメッセージのパース
  String _parseErrorMessage(String error) {
    if (error.contains('401') || error.contains('無効なAPIキー')) {
      return 'APIキーが無効です。管理者に連絡してください。';
    } else if (error.contains('429') || error.contains('利用制限')) {
      return 'API利用制限に達しました。しばらく待ってから再試行してください。';
    } else if (error.contains('timeout')) {
      return 'タイムアウトしました。ネットワーク接続を確認してください。';
    } else if (error.contains('model')) {
      return 'AIモデルの設定に問題があります。管理者に連絡してください。';
    } else {
      return 'エラーが発生しました: $error';
    }
  }

  // エラーダイアログ表示
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('生成エラー'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 16),
            const Text(
              '対処法:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (message.contains('APIキー'))
              const Text('• 環境変数にGPT_API_KEYを設定')
            else if (message.contains('利用制限'))
              const Text('• 数分待ってから再試行')
            else if (message.contains('モデル'))
              const Text('• 管理者に連絡してモデル設定を確認')
            else
              const Text('• 入力内容を確認して再試行'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _retryCount = 0; // リトライカウントをリセット
              });
            },
            child: const Text('再試行'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  // URLを開く機能
  Future<void> _launchUrl(String urlString) async {
    try {
      final Uri url = Uri.parse(urlString);
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
          webOnlyWindowName: '_blank',
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('URLを開けませんでした'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラー: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー
            _buildHeader(isMobile),
            const SizedBox(height: 16),

            // 生成中の場合
            if (_isGenerating) ...[
              _buildGeneratingView(),
            ]
            // 生成完了の場合
            else if (_generatedTemplate != null) ...[
              _buildGeneratedView(),
            ]
            // 入力フォーム
            else ...[
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInstructions(),
                      const SizedBox(height: 16),
                      _buildInputFields(isMobile),
                      const SizedBox(height: 16),
                      _buildAdvancedSettings(isMobile),
                    ],
                  ),
                ),
              ),
              _buildActionButtons(isMobile),
            ],
          ],
        ),
      ),
    );
  }

  // ヘッダー部分
  Widget _buildHeader(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.auto_awesome,
              color: Theme.of(context).primaryColor,
              size: isMobile ? 24 : 28,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'AI アンケート生成',
                style: TextStyle(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          widget.isPreSurvey
            ? '事前アンケートをAIが自動生成します'
            : '実験アンケートをAIが自動生成します',
          style: TextStyle(
            fontSize: isMobile ? 14 : 16,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // 使用説明
  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                'AI による自動生成',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '実験の詳細情報を入力すると、AIが最適なアンケート項目を自動生成します。',
            style: TextStyle(fontSize: 14, color: Colors.blue.shade700),
          ),
          const SizedBox(height: 4),
          Text(
            '最大質問数: $_maxQuestions問',
            style: TextStyle(fontSize: 12, color: Colors.blue.shade600),
          ),
        ],
      ),
    );
  }

  // 入力フィールド
  Widget _buildInputFields(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 実験の目的
        TextFormField(
          controller: _purposeController,
          decoration: InputDecoration(
            labelText: '実験の目的 *',
            hintText: '例: ユーザーインターフェースの使いやすさを評価する',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.flag),
            helperText: '何を測定・評価したいか具体的に記述',
            helperMaxLines: 2,
          ),
          maxLines: 2,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '実験の目的を入力してください';
            }
            if (value.trim().length < 10) {
              return 'もう少し詳しく記述してください（10文字以上）';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // 対象者
        TextFormField(
          controller: _targetAudienceController,
          decoration: InputDecoration(
            labelText: '対象者 *',
            hintText: '例: 大学生、20-30代の社会人',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.people),
            helperText: '実験に参加する人の属性',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '対象者を入力してください';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // 期待する成果
        TextFormField(
          controller: _expectedOutcomeController,
          decoration: InputDecoration(
            labelText: '期待する成果 *',
            hintText: '例: UIの問題点を特定し、改善案を得る',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.insights),
            helperText: '実験から何を得たいか',
          ),
          maxLines: 2,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '期待する成果を入力してください';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // 追加要件（オプション）
        TextFormField(
          controller: _additionalRequirementsController,
          decoration: InputDecoration(
            labelText: '追加要件（任意）',
            hintText: '例: 5段階評価を多く含める、自由記述欄を設ける',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.add_comment),
            helperText: 'アンケートに含めたい特別な要件',
            helperMaxLines: 2,
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16),

        // 実験情報（折りたたみ式）
        ExpansionTile(
          title: const Text('実験情報（AIが参考にする情報）'),
          leading: const Icon(Icons.science),
          initiallyExpanded: false,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextFormField(
                controller: _experimentContextController,
                decoration: const InputDecoration(
                  labelText: '実験の詳細情報',
                  hintText: '実験の概要、詳細、条件など',
                  border: OutlineInputBorder(),
                  helperText: 'AIがアンケート生成時に参考にする実験の詳細情報です。必要に応じて編集できます。',
                  helperMaxLines: 2,
                ),
                maxLines: 5,
                minLines: 3,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 詳細設定
  Widget _buildAdvancedSettings(bool isMobile) {
    return Column(
      children: [
        // 基本設定
        ExpansionTile(
          title: const Text('基本設定'),
          leading: const Icon(Icons.tune),
          initiallyExpanded: true,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // カテゴリ選択
                  const Text('カテゴリ', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: SurveyCategory.values.map((category) {
                      return ChoiceChip(
                        label: Text(category.label),
                        selected: _selectedCategory == category,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                        selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // 最大質問数
                  Row(
                    children: [
                      const Text('最大質問数:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Slider(
                          value: _maxQuestions.toDouble(),
                          min: 5,
                          max: 20,
                          divisions: 15,
                          label: '$_maxQuestions問',
                          onChanged: (value) {
                            setState(() {
                              _maxQuestions = value.round();
                            });
                          },
                        ),
                      ),
                      Text('$_maxQuestions問'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        // テンプレート参照設定
        ExpansionTile(
          title: const Text('テンプレート参照設定'),
          leading: const Icon(Icons.library_books),
          subtitle: const Text('既存テンプレートを参考にAIが生成'),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    title: const Text('テンプレートを参考にする'),
                    subtitle: const Text('選択したテンプレートの構造や質問形式を参考にします'),
                    value: _useReferenceTemplates,
                    onChanged: (value) {
                      setState(() {
                        _useReferenceTemplates = value;
                      });
                    },
                  ),
                  if (_useReferenceTemplates) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '選択したテンプレートの質問形式や構造を参考にしながら、実験内容に合わせた新しいアンケートを生成します',
                              style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTemplateReferenceSelector(),
                  ],
                ],
              ),
            ),
          ],
        ),

        // 固定テンプレート設定
        ExpansionTile(
          title: const Text('固定テンプレート設定'),
          leading: const Icon(Icons.anchor),
          subtitle: const Text('開始・終了部分に固定のテンプレートを配置'),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    title: const Text('固定テンプレートを使用'),
                    subtitle: const Text('アンケートの最初や最後に固定の質問を配置します'),
                    value: _useFixedTemplates,
                    onChanged: (value) {
                      setState(() {
                        _useFixedTemplates = value;
                      });
                    },
                  ),
                  if (_useFixedTemplates) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.tips_and_updates, size: 16, color: Colors.amber.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '基本情報や同意確認など、必須の質問を固定配置し、中間部分をAIが生成します',
                              style: TextStyle(fontSize: 12, color: Colors.amber.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFixedTemplateSelectors(),
                  ],
                ],
              ),
            ),
          ],
        ),

        // 外部フォーム参照設定（新規追加）
        ExpansionTile(
          title: const Text('外部フォーム参照設定'),
          leading: const Icon(Icons.link),
          subtitle: const Text('既存のGoogle Formsのスタイルを参考にする'),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    title: const Text('Google FormsのURLを参照'),
                    subtitle: const Text('既存フォームのスタイルをAIが参考にします'),
                    value: _useReferenceFormUrl,
                    onChanged: (value) {
                      setState(() {
                        _useReferenceFormUrl = value;
                      });
                    },
                  ),
                  if (_useReferenceFormUrl) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lightbulb_outline, size: 16, color: Colors.green.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '既存のGoogle Formsの質問形式やデザインをAIが参考にして、統一感のあるアンケートを生成します',
                              style: TextStyle(fontSize: 12, color: Colors.green.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _referenceFormUrlController,
                      decoration: InputDecoration(
                        labelText: 'Google Forms URL',
                        hintText: 'https://forms.google.com/...',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.link),
                        helperText: '参考にしたいGoogle FormsのURLを入力',
                      ),
                      keyboardType: TextInputType.url,
                      validator: (value) {
                        if (_useReferenceFormUrl && (value == null || value.trim().isEmpty)) {
                          return 'URLを入力してください';
                        }
                        if (_useReferenceFormUrl && value != null && !value.contains('forms.google.com')) {
                          return 'Google FormsのURLを入力してください';
                        }
                        return null;
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // テンプレート参照選択UI
  Widget _buildTemplateReferenceSelector() {
    // カテゴリフィルタを適用
    final filteredTemplates = _templateFilterCategory == null
        ? _allTemplates
        : _allTemplates.where((t) => t.category == _templateFilterCategory).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // カテゴリフィルター
        const Text('カテゴリでフィルター:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            ChoiceChip(
              label: const Text('すべて', style: TextStyle(fontSize: 11)),
              selected: _templateFilterCategory == null,
              onSelected: (selected) {
                setState(() {
                  _templateFilterCategory = null;
                });
              },
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            ),
            ...SurveyCategory.values.map((category) {
              return ChoiceChip(
                label: Text(category.label, style: const TextStyle(fontSize: 11)),
                selected: _templateFilterCategory == category,
                onSelected: (selected) {
                  setState(() {
                    _templateFilterCategory = selected ? category : null;
                  });
                },
                selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              );
            }),
          ],
        ),
        const SizedBox(height: 12),

        // 選択済みテンプレート表示
        if (_referenceTemplateIds.isNotEmpty) ...[
          const Text('選択済み:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: _referenceTemplateIds.map((id) {
              final template = _allTemplates.firstWhere((t) => t.id == id);
              return Chip(
                label: Text(template.title, style: const TextStyle(fontSize: 11)),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  setState(() {
                    _referenceTemplateIds.remove(id);
                  });
                },
                backgroundColor: Colors.blue.shade100,
                padding: const EdgeInsets.all(4),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],

        // テンプレートリスト
        Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.builder(
            itemCount: filteredTemplates.length,
            itemBuilder: (context, index) {
              final template = filteredTemplates[index];
              final isSelected = _referenceTemplateIds.contains(template.id);

              return CheckboxListTile(
                title: Text(template.title, style: const TextStyle(fontSize: 13)),
                subtitle: Text(
                  '${template.questions.length}問 - ${template.description}',
                  style: const TextStyle(fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                value: isSelected,
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _referenceTemplateIds.add(template.id);
                    } else {
                      _referenceTemplateIds.remove(template.id);
                    }
                  });
                },
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
              );
            },
          ),
        ),
      ],
    );
  }

  // 固定テンプレート選択UI
  Widget _buildFixedTemplateSelectors() {
    // 事前アンケート向けのテンプレートをフィルター
    final preTemplates = _allTemplates
        .where((t) => t.type == SurveyType.pre || t.type == SurveyType.both)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ヘッダーテンプレート選択
        const Text('開始部分のテンプレート:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _headerTemplateId,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            hintText: '選択してください',
          ),
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('なし', style: TextStyle(fontSize: 13)),
            ),
            ...preTemplates.map((template) {
              return DropdownMenuItem(
                value: template.id,
                child: Text(
                  '${template.title} (${template.questions.length}問)',
                  style: const TextStyle(fontSize: 13),
                ),
              );
            }),
          ],
          onChanged: (value) {
            setState(() {
              _headerTemplateId = value;
            });
          },
        ),
        const SizedBox(height: 16),

        // フッターテンプレート選択
        const Text('終了部分のテンプレート:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _footerTemplateId,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            hintText: '選択してください',
          ),
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('なし', style: TextStyle(fontSize: 13)),
            ),
            ...preTemplates.map((template) {
              return DropdownMenuItem(
                value: template.id,
                child: Text(
                  '${template.title} (${template.questions.length}問)',
                  style: const TextStyle(fontSize: 13),
                ),
              );
            }),
          ],
          onChanged: (value) {
            setState(() {
              _footerTemplateId = value;
            });
          },
        ),

        // プレビュー表示
        if (_headerTemplateId != null || _footerTemplateId != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('構成プレビュー:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (_headerTemplateId != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.vertical_align_top, size: 16, color: Colors.blue),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '開始: ${_allTemplates.firstWhere((t) => t.id == _headerTemplateId).title}',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, size: 16, color: Colors.orange),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Text(
                        '中間: AIが生成する質問',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                if (_footerTemplateId != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.vertical_align_bottom, size: 16, color: Colors.blue),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '終了: ${_allTemplates.firstWhere((t) => t.id == _footerTemplateId).title}',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  // 生成中の表示
  Widget _buildGeneratingView() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(strokeWidth: 3),
            const SizedBox(height: 24),
            Text(
              _statusMessage,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 300,
              child: LinearProgressIndicator(
                value: _generationProgress,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(_generationProgress * 100).toInt()}%',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  // 生成完了時の表示
  Widget _buildGeneratedView() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AIによる雛形が完成しました',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Google Formsで編集して、質問の追加や詳細設定を行ってください',
                        style: TextStyle(
                          color: Colors.green.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 説明テキスト
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '✨ ${_generatedTemplate!.questions.length}個の質問を生成しました。Google Formsで開いて、追加の編集を行ってください。',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 生成されたアンケートのプレビュー
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _generatedTemplate!.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _generatedTemplate!.description,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const Divider(height: 24),
                    ...List.generate(
                      _generatedTemplate!.questions.length,
                      (index) => _buildQuestionPreview(
                        _generatedTemplate!.questions[index],
                        index + 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // アクションボタン
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 左側: 再生成ボタン
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _generatedTemplate = null;
                    _generationResult = null;
                    _formUrl = null;
                    _editUrl = null;
                    _formId = null;
                    _generationProgress = 0.0;
                    _statusMessage = '';
                  });
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('再生成', style: TextStyle(fontSize: 14)),
              ),

              // 右側: ボタングループ
              Row(
                children: [
                  // 完了ボタン（ダイアログを閉じる）
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('完了'),
                  ),
                  const SizedBox(width: 8),
                  // Google Formsで編集ボタン（メインボタン）
                  ElevatedButton.icon(
                    onPressed: () async {
                      // Google Formsの編集URLを開く
                      if (_editUrl != null && _editUrl!.isNotEmpty) {
                        await _launchUrl(_editUrl!);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                                  const SizedBox(width: 8),
                                  const Text('Google Formsを新しいタブで開きました'),
                                ],
                              ),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                        // ダイアログは閉じない（ユーザーが参照できるように）
                  } else {
                    // URLがない場合はエラーメッセージを表示
                    if (mounted) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Google Forms作成エラー'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Google Formsの自動作成に失敗しました。'),
                              const SizedBox(height: 16),
                              const Text('生成された質問は以下の通りです：'),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _generatedTemplate!.questions
                                      .map((q) => '• ${q.question}')
                                      .join('\n'),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('閉じる'),
                            ),
                          ],
                        ),
                      );
                    }
                  }
                    },
                    icon: const Icon(Icons.edit_document),
                    label: const Text(
                      'Google Formsで編集',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8E1728),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      elevation: 2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 質問のプレビュー
  Widget _buildQuestionPreview(SurveyQuestion question, int number) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Q$number',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  question.question + (question.required ? ' *' : ''),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '形式: ${question.type.label}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          if (question.options != null && question.options!.isNotEmpty) ...[
            const SizedBox(height: 4),
            ...question.options!.map((option) => Padding(
              padding: const EdgeInsets.only(left: 16, top: 2),
              child: Text('• $option', style: const TextStyle(fontSize: 14)),
            )),
          ],
        ],
      ),
    );
  }

  // アクションボタン
  Widget _buildActionButtons(bool isMobile) {
    return Container(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _isGenerating ? null : _generateSurvey,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('AIで生成'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8E1728),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
                vertical: isMobile ? 10 : 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}