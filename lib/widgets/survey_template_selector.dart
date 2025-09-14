import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../models/survey_template.dart';
import '../services/google_forms_service.dart';
import 'ai_survey_generator.dart';

/// アンケートテンプレート選択ダイアログ
class SurveyTemplateSelector extends StatefulWidget {
  final bool isPreSurvey;
  final Function(SurveyTemplate template)? onTemplateSelected;
  final Function(String url)? onUrlEntered;

  // 実験コンテキスト情報
  final String? experimentTitle;
  final String? experimentDescription;
  final String? detailedContent;
  final String? experimentType;
  final String? location;
  final bool? isPaid;
  final String? reward;
  final String? duration;
  final String? labName;
  final List<String>? requirements;
  final List<String>? consentItems;
  final String? maxParticipants;

  const SurveyTemplateSelector({
    super.key,
    required this.isPreSurvey,
    this.onTemplateSelected,
    this.onUrlEntered,
    this.experimentTitle,
    this.experimentDescription,
    this.detailedContent,
    this.experimentType,
    this.location,
    this.isPaid,
    this.reward,
    this.duration,
    this.labName,
    this.requirements,
    this.consentItems,
    this.maxParticipants,
  });
  
  @override
  State<SurveyTemplateSelector> createState() => _SurveyTemplateSelectorState();
}

class _SurveyTemplateSelectorState extends State<SurveyTemplateSelector> {
  SurveyCategory? _selectedCategory;
  SurveyTemplate? _selectedTemplate;
  final _urlController = TextEditingController();
  bool _showUrlInput = false;
  bool _showAIGenerator = false;
  
  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  /// 実験コンテキストを構築
  String _buildExperimentContext() {
    final List<String> contextParts = [];

    if (widget.experimentDescription != null && widget.experimentDescription!.isNotEmpty) {
      contextParts.add('実験概要: ${widget.experimentDescription}');
    }
    if (widget.detailedContent != null && widget.detailedContent!.isNotEmpty) {
      contextParts.add('詳細: ${widget.detailedContent}');
    }
    if (widget.experimentType != null && widget.experimentType!.isNotEmpty) {
      contextParts.add('実験タイプ: ${widget.experimentType}');
    }
    if (widget.location != null && widget.location!.isNotEmpty) {
      contextParts.add('場所: ${widget.location}');
    }
    if (widget.isPaid == true && widget.reward != null && widget.reward!.isNotEmpty) {
      contextParts.add('報酬: ${widget.reward}');
    }
    if (widget.duration != null && widget.duration!.isNotEmpty) {
      contextParts.add('所要時間: ${widget.duration}分');
    }
    if (widget.labName != null && widget.labName!.isNotEmpty) {
      contextParts.add('研究室: ${widget.labName}');
    }
    if (widget.requirements != null && widget.requirements!.isNotEmpty) {
      contextParts.add('参加条件: ${widget.requirements!.join(', ')}');
    }
    if (widget.consentItems != null && widget.consentItems!.isNotEmpty) {
      contextParts.add('同意項目: ${widget.consentItems!.join(', ')}');
    }
    if (widget.maxParticipants != null && widget.maxParticipants!.isNotEmpty) {
      contextParts.add('募集人数: ${widget.maxParticipants}名');
    }

    return contextParts.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 600;

    // モバイルの場合はモーダルボトムシートとして表示
    if (isMobile) {
      return _buildMobileLayout(context);
    }

    // デスクトップ/タブレットの場合は従来のダイアログ
    return Dialog(
      child: Container(
        width: screenWidth * 0.9,
        height: screenHeight * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.isPreSurvey ? '事前アンケート作成' : '実験アンケート作成',
                    style: Theme.of(context).textTheme.headlineSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            
            // タブ切り替え
            _buildTabSelector(),
            const SizedBox(height: 16),

            // コンテンツ
            Expanded(
              child: _showAIGenerator
                ? AISurveyGenerator(
                    isPreSurvey: widget.isPreSurvey,
                    experimentTitle: widget.experimentTitle,
                    experimentDescription: _buildExperimentContext(),
                    onFormCreated: (url) {
                      // URLを親ウィジェットに渡すが、ダイアログは閉じない
                      widget.onUrlEntered?.call(url);
                      // Navigator.of(context).pop(); // 削除: ユーザーが手動で閉じるまで開いたままにする
                    },
                  )
                : _showUrlInput
                  ? _buildUrlInput()
                  : _buildTemplateSelector(),
            ),
            
            // アクションボタン
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('キャンセル'),
                ),
                const SizedBox(width: 8),
                if (_showAIGenerator)
                  const SizedBox() // AI生成は独自のボタンを持つ
                else if (_showUrlInput)
                  ElevatedButton(
                    onPressed: _urlController.text.trim().isNotEmpty
                      ? () {
                          widget.onUrlEntered?.call(_urlController.text.trim());
                          Navigator.of(context).pop();
                        }
                      : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8E1728),
                    ),
                    child: const Text('URLを設定'),
                  )
                else if (_selectedTemplate != null)
                  ElevatedButton.icon(
                    onPressed: () => _createFormAutomatically(),
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Googleフォームを作成'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8E1728),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // モバイル用レイアウト
  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ドラッグハンドル
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // ヘッダー
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.isPreSurvey ? '事前アンケート作成' : '実験アンケート作成',
                        style: Theme.of(context).textTheme.titleLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 0),
              // タブ切り替え
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _buildTabSelector(),
              ),
              // コンテンツ
              Expanded(
                child: _showAIGenerator
                  ? AISurveyGenerator(
                      isPreSurvey: widget.isPreSurvey,
                      experimentTitle: widget.experimentTitle,
                      experimentDescription: _buildExperimentContext(),
                      onFormCreated: (url) {
                        // URLを親ウィジェットに渡すが、ダイアログは閉じない
                        widget.onUrlEntered?.call(url);
                        // Navigator.of(context).pop(); // 削除: ユーザーが手動で閉じるまで開いたままにする
                      },
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _showUrlInput
                        ? _buildUrlInput()
                        : _buildMobileTemplateSelector(),
                    ),
              ),
              // 固定アクションボタン
              _buildMobileActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  // タブセレクター（共通）
  Widget _buildTabSelector() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (isMobile) {
      // モバイル用：セグメントコントロール風
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() {
                  _showUrlInput = false;
                  _showAIGenerator = false;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: (!_showUrlInput && !_showAIGenerator) ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.list_alt,
                        size: 16,
                        color: (!_showUrlInput && !_showAIGenerator) ? const Color(0xFF8E1728) : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          'テンプレ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: (!_showUrlInput && !_showAIGenerator) ? FontWeight.bold : FontWeight.normal,
                            color: (!_showUrlInput && !_showAIGenerator) ? const Color(0xFF8E1728) : Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() {
                  _showUrlInput = true;
                  _showAIGenerator = false;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _showUrlInput ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.link,
                        size: 16,
                        color: _showUrlInput ? const Color(0xFF8E1728) : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          'URL',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: _showUrlInput ? FontWeight.bold : FontWeight.normal,
                            color: _showUrlInput ? const Color(0xFF8E1728) : Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() {
                  _showUrlInput = false;
                  _showAIGenerator = true;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _showAIGenerator ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 16,
                        color: _showAIGenerator ? const Color(0xFF8E1728) : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          'AI生成',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: _showAIGenerator ? FontWeight.bold : FontWeight.normal,
                            color: _showAIGenerator ? const Color(0xFF8E1728) : Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // デスクトップ用：従来のボタン
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => setState(() {
                _showUrlInput = false;
                _showAIGenerator = false;
              }),
              icon: const Icon(Icons.list_alt),
              label: const Text('テンプレート'),
              style: ElevatedButton.styleFrom(
                backgroundColor: (!_showUrlInput && !_showAIGenerator)
                  ? const Color(0xFF8E1728)
                  : Colors.grey.shade300,
                foregroundColor: (!_showUrlInput && !_showAIGenerator)
                  ? Colors.white
                  : Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => setState(() {
                _showUrlInput = true;
                _showAIGenerator = false;
              }),
              icon: const Icon(Icons.link),
              label: const Text('URL入力'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _showUrlInput
                  ? const Color(0xFF8E1728)
                  : Colors.grey.shade300,
                foregroundColor: _showUrlInput
                  ? Colors.white
                  : Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => setState(() {
                _showUrlInput = false;
                _showAIGenerator = true;
              }),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('AI生成'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _showAIGenerator
                  ? const Color(0xFF8E1728)
                  : Colors.grey.shade300,
                foregroundColor: _showAIGenerator
                  ? Colors.white
                  : Colors.black,
              ),
            ),
          ),
        ],
      );
    }
  }

  // モバイル用固定アクションボタン
  Widget _buildMobileActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('キャンセル'),
              ),
            ),
            const SizedBox(width: 8),
            if (_showAIGenerator)
              const SizedBox() // AI生成は独自のボタンを持つ
            else if (_showUrlInput)
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _urlController.text.trim().isNotEmpty
                    ? () {
                        widget.onUrlEntered?.call(_urlController.text.trim());
                        Navigator.of(context).pop();
                      }
                    : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8E1728),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('URLを設定'),
                ),
              )
            else if (_selectedTemplate != null)
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () => _createFormAutomatically(),
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('フォーム作成'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8E1728),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUrlInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '既に作成済みのGoogleフォームのURLを入力してください',
                  style: TextStyle(fontSize: 14, color: Colors.blue.shade700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _urlController,
          decoration: const InputDecoration(
            labelText: 'GoogleフォームURL',
            hintText: 'https://forms.google.com/...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.link),
          ),
          keyboardType: TextInputType.url,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        Text(
          '例: https://forms.google.com/d/e/xxxxx/viewform',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
  
  Widget _buildTemplateSelector() {
    final templates = GoogleFormsService.getRecommendedTemplates(
      isPreSurvey: widget.isPreSurvey,
      preferredCategory: _selectedCategory,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // カテゴリフィルター
        const Text(
          'カテゴリを選択',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('すべて'),
              selected: _selectedCategory == null,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = null;
                });
              },
              selectedColor: const Color(0xFF8E1728).withValues(alpha: 0.2),
            ),
            ...SurveyCategory.values.map((category) {
              return ChoiceChip(
                label: Text(category.label),
                selected: _selectedCategory == category,
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = selected ? category : null;
                  });
                },
                selectedColor: const Color(0xFF8E1728).withValues(alpha: 0.2),
              );
            }),
          ],
        ),
        const SizedBox(height: 16),
        
        // テンプレートリスト
        const Text(
          'テンプレートを選択',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];
              final isSelected = _selectedTemplate?.id == template.id;
              
              return Card(
                elevation: isSelected ? 4 : 1,
                color: isSelected ? const Color(0xFF8E1728).withValues(alpha: 0.05) : null,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getCategoryColor(template.category),
                    child: Icon(
                      _getCategoryIcon(template.category),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    template.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.description,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 12,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.quiz, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                '${template.questions.length}問',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                          if (template.estimatedMinutes != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.timer, size: 14, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  '約${template.estimatedMinutes}分',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.preview),
                        onPressed: () => _showTemplatePreview(template),
                        tooltip: 'プレビュー',
                      ),
                      Radio<SurveyTemplate>(
                        value: template,
                        groupValue: _selectedTemplate,
                        onChanged: (value) {
                          setState(() {
                            _selectedTemplate = value;
                          });
                        },
                        activeColor: const Color(0xFF8E1728),
                      ),
                    ],
                  ),
                  onTap: () {
                    setState(() {
                      _selectedTemplate = template;
                    });
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // モバイル用テンプレートセレクター
  Widget _buildMobileTemplateSelector() {
    final templates = GoogleFormsService.getRecommendedTemplates(
      isPreSurvey: widget.isPreSurvey,
      preferredCategory: _selectedCategory,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // カテゴリフィルター（横スクロール）
        const Text(
          'カテゴリを選択',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: const Text('すべて'),
                  selected: _selectedCategory == null,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = null;
                    });
                  },
                  selectedColor: const Color(0xFF8E1728).withValues(alpha: 0.2),
                ),
              ),
              ...SurveyCategory.values.map((category) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category.label),
                    selected: _selectedCategory == category,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected ? category : null;
                      });
                    },
                    selectedColor: const Color(0xFF8E1728).withValues(alpha: 0.2),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // テンプレートリスト
        const Text(
          'テンプレートを選択',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...templates.map((template) {
          final isSelected = _selectedTemplate?.id == template.id;

          return Card(
            elevation: isSelected ? 4 : 1,
            color: isSelected ? const Color(0xFF8E1728).withValues(alpha: 0.05) : null,
            margin: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedTemplate = template;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // タイトルとカテゴリ
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(template.category).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getCategoryIcon(template.category),
                                size: 14,
                                color: _getCategoryColor(template.category),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                template.category.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _getCategoryColor(template.category),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: const Color(0xFF8E1728),
                            size: 20,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // タイトル
                    Text(
                      template.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // 説明
                    Text(
                      template.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // メタ情報とアクション
                    Row(
                      children: [
                        // 質問数
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.quiz, size: 12, color: Colors.grey.shade600),
                              const SizedBox(width: 2),
                              Text(
                                '${template.questions.length}問',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 所要時間
                        if (template.estimatedMinutes != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.timer, size: 12, color: Colors.grey.shade600),
                                const SizedBox(width: 2),
                                Text(
                                  '${template.estimatedMinutes}分',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        const Spacer(),
                        // プレビューボタン
                        TextButton(
                          onPressed: () => _showTemplatePreview(template),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'プレビュー',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Color _getCategoryColor(SurveyCategory category) {
    switch (category) {
      case SurveyCategory.psychology:
        return Colors.purple;
      case SurveyCategory.cognitive:
        return Colors.blue;
      case SurveyCategory.behavioral:
        return Colors.green;
      case SurveyCategory.ux:
        return Colors.orange;
      case SurveyCategory.demographic:
        return Colors.teal;
      case SurveyCategory.health:
        return Colors.red;
      case SurveyCategory.custom:
        return Colors.grey;
    }
  }
  
  IconData _getCategoryIcon(SurveyCategory category) {
    switch (category) {
      case SurveyCategory.psychology:
        return Icons.psychology;
      case SurveyCategory.cognitive:
        return Icons.lightbulb;
      case SurveyCategory.behavioral:
        return Icons.directions_walk;
      case SurveyCategory.ux:
        return Icons.phone_android;
      case SurveyCategory.demographic:
        return Icons.person;
      case SurveyCategory.health:
        return Icons.favorite;
      case SurveyCategory.custom:
        return Icons.edit;
    }
  }
  
  Widget _buildInstructionStep(String number, String instruction) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFF8E1728),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              instruction,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showTemplatePreview(SurveyTemplate template) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (isMobile) {
      // モバイル用フルスクリーンプレビュー
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.95,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: _buildPreviewContent(template, isMobile: true),
        ),
      );
    } else {
      // デスクトップ用ダイアログ
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Container(
            width: screenWidth * 0.8,
            height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.all(16),
            child: _buildPreviewContent(template, isMobile: false),
          ),
        ),
      );
    }
  }

  Widget _buildPreviewContent(SurveyTemplate template, {required bool isMobile}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isMobile) ...[
          // モバイル用ドラッグハンドル
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 8, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
        // ヘッダー
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 0,
            vertical: isMobile ? 8 : 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  template.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize: isMobile ? 20 : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        const Divider(),
        // 内容部分
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template.description,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: isMobile ? 14 : null,
                  ),
                ),
                const SizedBox(height: 8),
                if (template.instructions != null) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      template.instructions!,
                      style: TextStyle(
                        fontSize: isMobile ? 13 : 14,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      label: Text(
                        template.type.label,
                        style: TextStyle(fontSize: isMobile ? 12 : null),
                      ),
                      backgroundColor: Colors.blue.shade100,
                    ),
                    Chip(
                      label: Text(
                        template.category.label,
                        style: TextStyle(fontSize: isMobile ? 12 : null),
                      ),
                      backgroundColor: _getCategoryColor(template.category).withValues(alpha: 0.2),
                    ),
                    if (template.estimatedMinutes != null)
                      Chip(
                        label: Text(
                          '約${template.estimatedMinutes}分',
                          style: TextStyle(fontSize: isMobile ? 12 : null),
                        ),
                        backgroundColor: Colors.grey.shade200,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '質問項目',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 15 : 16,
                  ),
                ),
                const Divider(),
                // 質問リスト
                ...List.generate(template.questions.length, (index) {
                  final question = template.questions[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 10 : 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 6 : 8,
                                  vertical: isMobile ? 3 : 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8E1728),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Q${index + 1}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isMobile ? 11 : 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  question.question +
                                      (question.required ? ' *' : ''),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: isMobile ? 14 : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: _buildQuestionPreview(question),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        const Divider(),
        // フッター
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 0,
            vertical: isMobile ? 8 : 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!isMobile)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.download),
                  tooltip: 'エクスポート',
                  onSelected: (format) {
                    String exportData;
                    String message;

                    switch (format) {
                      case 'text':
                        exportData = template.exportQuestionsAsText();
                        message = 'テキスト形式でコピーしました';
                        break;
                      case 'json':
                        final jsonData = template.exportAsGoogleFormsJson();
                        exportData = const JsonEncoder.withIndent('  ').convert(jsonData);
                        message = 'JSON形式でコピーしました';
                        break;
                      case 'markdown':
                        exportData = template.exportAsMarkdown();
                        message = 'Markdown形式でコピーしました';
                        break;
                      default:
                        return;
                    }

                    Clipboard.setData(ClipboardData(text: exportData));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(message),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem<String>(
                      value: 'text',
                      child: Row(
                        children: [
                          Icon(Icons.text_fields, size: 20),
                          SizedBox(width: 8),
                          Text('テキスト形式'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'json',
                      child: Row(
                        children: [
                          Icon(Icons.code, size: 20),
                          SizedBox(width: 8),
                          Text('JSON形式'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'markdown',
                      child: Row(
                        children: [
                          Icon(Icons.description, size: 20),
                          SizedBox(width: 8),
                          Text('Markdown形式'),
                        ],
                      ),
                    ),
                  ],
                )
              else
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () {
                    final exportData = template.exportQuestionsAsText();
                    Clipboard.setData(ClipboardData(text: exportData));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('テキスト形式でコピーしました'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(isMobile ? 80 : 100, 36),
                ),
                child: Text(
                  '閉じる',
                  style: TextStyle(fontSize: isMobile ? 14 : null),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  /// 手動でフォームを作成（使わなくなったがコードは残しておく）
  Future<void> _createFormManually() async {
    // まず質問項目をコピー
    final questionsText = _selectedTemplate!.exportQuestionsAsText();
    await Clipboard.setData(ClipboardData(text: questionsText));
    
    if (!mounted) return;
    
    // ダイアログを表示して手順を説明
    final shouldContinue = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600),
            const SizedBox(width: 8),
            const Text('テンプレートを準備しました'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(Icons.content_copy, size: 16, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'テンプレート内容をクリップボードにコピーしました',
                        style: TextStyle(fontSize: 13, color: Colors.green.shade700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Googleフォーム作成手順',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              _buildInstructionStep('1', 'この画面で「Googleフォームを開く」をクリック'),
              _buildInstructionStep('2', '空白のフォームが開きます'),
              _buildInstructionStep('3', 'フォームの説明欄をクリック'),
              _buildInstructionStep('4', 'Ctrl+V (Mac: Cmd+V) で貼り付け'),
              _buildInstructionStep('5', '貼り付けた内容を参考に質問を作成'),
              _buildInstructionStep('6', '各質問の形式を設定（ラジオボタン、記述式など）'),
              _buildInstructionStep('7', '必須項目は「必須」をONに設定'),
              _buildInstructionStep('8', '作成完了後、フォームのURLをコピー'),
              _buildInstructionStep('9', '実験作成画面に戻ってURLを貼り付け'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.amber.shade800),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ヒント: 質問タイプ（[ラジオボタン]など）が記載されているので、適切な形式を選択してください',
                        style: TextStyle(fontSize: 12, color: Colors.amber.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Googleフォームを開く'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8E1728),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    ) ?? false;
    
    if (shouldContinue && mounted) {
      // Googleフォームを開く
      final success = await GoogleFormsService.openNewGoogleForm();
      
      if (success && mounted) {
        widget.onTemplateSelected?.call(_selectedTemplate!);
        Navigator.of(context).pop();
      }
    }
  }
  
  /// 自動でフォームを作成（Firebase Functions経由）
  Future<void> _createFormAutomatically() async {
    // ローディングダイアログを表示
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Googleフォームを作成中...'),
          ],
        ),
      ),
    );
    
    try {
      // Firebase Functions経由でフォームを作成して開く
      final result = await GoogleFormsService.createAndOpenGoogleForm(
        template: _selectedTemplate!,
        customTitle: '${_selectedTemplate!.title}_${DateTime.now().millisecondsSinceEpoch}',
      );
      
      if (!mounted) return;
      Navigator.of(context).pop(); // ローディングダイアログを閉じる
      
      if (result != null && result['success'] == true) {
        // 成功したらダイアログを閉じる
        if (mounted) {
          widget.onUrlEntered?.call(result['formUrl'] ?? '');
          Navigator.of(context).pop();
          
          // 成功メッセージを表示
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text('Googleフォームを作成して開きました'),
                ],
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // エラーダイアログを表示（詳細なエラー情報を含む）
        final errorMessage = result?['error'] ?? 'フォームの作成に失敗しました';
        final errorCode = result?['code'] ?? 'unknown';
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('エラー'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('エラー: $errorMessage'),
                if (errorCode != 'unknown')
                  Text('コード: $errorCode', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 16),
                const Text(
                  '解決方法:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                if (errorCode == 'permission-denied' || errorMessage.contains('403'))
                  const Text('• Google Forms APIを有効化してください')
                else if (errorCode == 'unauthenticated' || errorMessage.contains('401'))
                  const Text('• サービスアカウントの認証情報を設定してください')
                else
                  const Text('• Firebase Functionsの設定を確認してください'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // ローディングダイアログを閉じる
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('エラー'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('エラーが発生しました: $e'),
              const SizedBox(height: 16),
              const Text(
                'セットアップ手順:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('1. Google Forms APIを有効化'),
              const Text('2. サービスアカウントを作成'),
              const Text('3. Firebase Functionsをデプロイ'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
  
  
  Widget _buildQuestionPreview(SurveyQuestion question) {
    switch (question.type) {
      case QuestionType.shortText:
        return Row(
          children: [
            Icon(Icons.short_text, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(
              question.placeholder ?? '短い回答',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        );
        
      case QuestionType.longText:
        return Row(
          children: [
            Icon(Icons.notes, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(
              question.placeholder ?? '長い回答',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        );
        
      case QuestionType.multipleChoice:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.radio_button_checked, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  'ラジオボタン',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            if (question.options != null) ...[
              const SizedBox(height: 4),
              ...question.options!.map((option) => Padding(
                    padding: const EdgeInsets.only(left: 24, top: 2),
                    child: Text('○ $option', style: const TextStyle(fontSize: 14)),
                  )),
            ],
          ],
        );
        
      case QuestionType.checkbox:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_box, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  'チェックボックス',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            if (question.options != null) ...[
              const SizedBox(height: 4),
              ...question.options!.map((option) => Padding(
                    padding: const EdgeInsets.only(left: 24, top: 2),
                    child: Text('□ $option', style: const TextStyle(fontSize: 14)),
                  )),
            ],
          ],
        );
        
      case QuestionType.scale:
        return Row(
          children: [
            Icon(Icons.linear_scale, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(
              '${question.scaleMin ?? 1}',
              style: const TextStyle(fontSize: 14),
            ),
            if (question.scaleMinLabel != null)
              Text(
                ' (${question.scaleMinLabel})',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            const Text(' ～ '),
            Text(
              '${question.scaleMax ?? 5}',
              style: const TextStyle(fontSize: 14),
            ),
            if (question.scaleMaxLabel != null)
              Text(
                ' (${question.scaleMaxLabel})',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
          ],
        );
        
      case QuestionType.date:
        return Row(
          children: [
            Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(
              '日付選択',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        );
        
      case QuestionType.time:
        return Row(
          children: [
            Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(
              '時刻選択',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        );
    }
  }
}