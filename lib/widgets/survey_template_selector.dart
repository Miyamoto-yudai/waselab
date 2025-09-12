import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/survey_template.dart';
import '../services/google_forms_service.dart';

/// アンケートテンプレート選択ダイアログ
class SurveyTemplateSelector extends StatefulWidget {
  final bool isPreSurvey;
  final Function(SurveyTemplate template)? onTemplateSelected;
  final Function(String url)? onUrlEntered;
  
  const SurveyTemplateSelector({
    super.key,
    required this.isPreSurvey,
    this.onTemplateSelected,
    this.onUrlEntered,
  });
  
  @override
  State<SurveyTemplateSelector> createState() => _SurveyTemplateSelectorState();
}

class _SurveyTemplateSelectorState extends State<SurveyTemplateSelector> {
  SurveyCategory? _selectedCategory;
  SurveyTemplate? _selectedTemplate;
  final _urlController = TextEditingController();
  bool _showUrlInput = false;
  
  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.isPreSurvey ? '事前アンケート作成' : '実験アンケート作成',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            
            // タブ切り替え
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _showUrlInput = false;
                      });
                    },
                    icon: const Icon(Icons.list_alt),
                    label: const Text('テンプレートから選択'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !_showUrlInput 
                        ? const Color(0xFF8E1728)
                        : Colors.grey.shade300,
                      foregroundColor: !_showUrlInput 
                        ? Colors.white
                        : Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _showUrlInput = true;
                      });
                    },
                    icon: const Icon(Icons.link),
                    label: const Text('URLを入力'),
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
              ],
            ),
            const SizedBox(height: 16),
            
            // コンテンツ
            Expanded(
              child: _showUrlInput 
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
                if (_showUrlInput)
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
                    onPressed: () async {
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
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Googleフォームで作成'),
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
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(template.description),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.quiz, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            '${template.questions.length}問',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                          if (template.estimatedMinutes != null) ...[
                            const SizedBox(width: 12),
                            Icon(Icons.timer, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              '約${template.estimatedMinutes}分',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
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
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    template.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              Text(
                template.description,
                style: TextStyle(color: Colors.grey.shade700),
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
                    style: TextStyle(fontSize: 14, color: Colors.amber.shade900),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Chip(
                    label: Text(template.type.label),
                    backgroundColor: Colors.blue.shade100,
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(template.category.label),
                    backgroundColor: _getCategoryColor(template.category).withValues(alpha: 0.2),
                  ),
                  if (template.estimatedMinutes != null) ...[
                    const SizedBox(width: 8),
                    Chip(
                      label: Text('約${template.estimatedMinutes}分'),
                      backgroundColor: Colors.grey.shade200,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                '質問項目',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: template.questions.length,
                  itemBuilder: (context, index) {
                    final question = template.questions[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF8E1728),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Q${index + 1}',
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
                                    question.question +
                                        (question.required ? ' *' : ''),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
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
                  },
                ),
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      final text = template.exportQuestionsAsText();
                      Clipboard.setData(ClipboardData(text: text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('質問項目をコピーしました'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('質問をコピー'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('閉じる'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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