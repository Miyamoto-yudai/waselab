import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/experiment.dart';
import '../models/time_slot.dart';
import 'experiment_card.dart';
import 'time_slot_editor.dart';
import 'time_slot_calendar_editor.dart';

/// 実験作成画面の共通ベースウィジェット
class CreateExperimentBase extends StatefulWidget {
  final bool isDemo;
  final Future<void> Function(Map<String, dynamic>) onSave;
  
  const CreateExperimentBase({
    super.key,
    this.isDemo = false,
    required this.onSave,
  });

  @override
  State<CreateExperimentBase> createState() => _CreateExperimentBaseState();
}

class _CreateExperimentBaseState extends State<CreateExperimentBase> {
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();
  int _currentStep = 0;
  
  // フォームコントローラー
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _detailedContentController = TextEditingController();
  final _rewardController = TextEditingController();
  final _locationController = TextEditingController();
  final _durationController = TextEditingController();
  final _maxParticipantsController = TextEditingController();
  final _labNameController = TextEditingController();
  
  // 選択項目
  ExperimentType _selectedType = ExperimentType.onsite;
  bool _isPaid = false;
  bool _allowFlexibleSchedule = false;
  DateTime? _recruitmentStartDate;
  DateTime? _recruitmentEndDate;
  DateTime? _experimentPeriodStart;
  DateTime? _experimentPeriodEnd;
  final List<String> _requirements = [];
  final _requirementController = TextEditingController();
  List<TimeSlot> _timeSlots = [];
  Map<DateTime, List<TimeSlot>> _dateTimeSlots = {};
  int _simultaneousCapacity = 1;
  
  bool _isLoading = false;
  bool _showPreview = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _detailedContentController.dispose();
    _rewardController.dispose();
    _locationController.dispose();
    _durationController.dispose();
    _maxParticipantsController.dispose();
    _labNameController.dispose();
    _requirementController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  /// サンプルデータを入力
  void _fillSampleData() {
    setState(() {
      _titleController.text = '心理学実験の参加者募集';
      _descriptionController.text = '簡単な認知課題を行っていただきます。所要時間は約30分です。';
      _detailedContentController.text = '''本実験では、視覚的注意のメカニズムを調査します。

【実験内容】
1. 画面に表示される図形を観察
2. 特定のパターンを見つける課題
3. 反応時間の測定

【測定項目】
- 視覚探索の反応時間
- 正答率
- 注意の持続性

実験データは匿名化され、研究目的のみに使用されます。''';
      _rewardController.text = '1500';
      _locationController.text = '早稲田大学 戸山キャンパス 33号館';
      _durationController.text = '30';
      _maxParticipantsController.text = '20';
      _labNameController.text = '認知科学研究室';
      _selectedType = ExperimentType.onsite;
      _isPaid = true;
      _allowFlexibleSchedule = true;
      _recruitmentStartDate = DateTime.now();
      _recruitmentEndDate = DateTime.now().add(const Duration(days: 14));
      _experimentPeriodStart = DateTime.now().add(const Duration(days: 7));
      _experimentPeriodEnd = DateTime.now().add(const Duration(days: 21));
      _requirements.clear();
      _requirements.addAll(['視力矯正後1.0以上', '色覚正常']);
    });
  }

  /// 日付選択
  Future<void> _selectDate(BuildContext context, String type) async {
    DateTime initialDate = DateTime.now();
    DateTime firstDate = DateTime.now();
    DateTime lastDate = DateTime.now().add(const Duration(days: 365));
    
    switch (type) {
      case 'recruitmentStart':
        initialDate = _recruitmentStartDate ?? DateTime.now();
        break;
      case 'recruitmentEnd':
        initialDate = _recruitmentEndDate ?? DateTime.now().add(const Duration(days: 7));
        firstDate = _recruitmentStartDate ?? DateTime.now();
        break;
      case 'experimentStart':
        initialDate = _experimentPeriodStart ?? DateTime.now().add(const Duration(days: 7));
        firstDate = _recruitmentStartDate ?? DateTime.now();
        break;
      case 'experimentEnd':
        initialDate = _experimentPeriodEnd ?? DateTime.now().add(const Duration(days: 14));
        firstDate = _experimentPeriodStart ?? DateTime.now();
        break;
    }
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF8E1728),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        switch (type) {
          case 'recruitmentStart':
            _recruitmentStartDate = picked;
            break;
          case 'recruitmentEnd':
            _recruitmentEndDate = picked;
            break;
          case 'experimentStart':
            _experimentPeriodStart = picked;
            break;
          case 'experimentEnd':
            _experimentPeriodEnd = picked;
            break;
        }
      });
    }
  }

  /// 参加条件を追加
  void _addRequirement() {
    final text = _requirementController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _requirements.add(text);
        _requirementController.clear();
      });
    }
  }

  /// プレビュー用の実験オブジェクトを作成
  Experiment _createPreviewExperiment() {
    return Experiment(
      id: 'preview',
      title: _titleController.text.isEmpty ? 'タイトル未入力' : _titleController.text,
      description: _descriptionController.text.isEmpty ? '説明未入力' : _descriptionController.text,
      detailedContent: _detailedContentController.text.isEmpty ? null : _detailedContentController.text,
      reward: _isPaid ? (int.tryParse(_rewardController.text) ?? 0) : 0,
      location: _locationController.text.isEmpty ? '場所未定' : _locationController.text,
      type: _selectedType,
      isPaid: _isPaid,
      creatorId: 'demo_user',
      createdAt: DateTime.now(),
      recruitmentStartDate: _recruitmentStartDate,
      recruitmentEndDate: _recruitmentEndDate,
      experimentPeriodStart: _allowFlexibleSchedule ? _experimentPeriodStart : null,
      experimentPeriodEnd: _allowFlexibleSchedule ? _experimentPeriodEnd : null,
      allowFlexibleSchedule: _allowFlexibleSchedule,
      labName: _labNameController.text.isEmpty ? null : _labNameController.text,
      duration: int.tryParse(_durationController.text),
      maxParticipants: int.tryParse(_maxParticipantsController.text),
      requirements: _requirements,
      timeSlots: _timeSlots,
      simultaneousCapacity: _simultaneousCapacity,
    );
  }

  /// 実験を保存
  Future<void> _saveExperiment() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    final data = {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'detailedContent': _detailedContentController.text.trim(),
      'reward': _isPaid ? int.tryParse(_rewardController.text) ?? 0 : 0,
      'location': _locationController.text.trim(),
      'type': _selectedType.name,
      'isPaid': _isPaid,
      'recruitmentStartDate': _recruitmentStartDate,
      'recruitmentEndDate': _recruitmentEndDate,
      'experimentPeriodStart': _allowFlexibleSchedule ? _experimentPeriodStart : null,
      'experimentPeriodEnd': _allowFlexibleSchedule ? _experimentPeriodEnd : null,
      'allowFlexibleSchedule': _allowFlexibleSchedule,
      'labName': _labNameController.text.trim().isNotEmpty ? _labNameController.text.trim() : null,
      'duration': int.tryParse(_durationController.text),
      'maxParticipants': int.tryParse(_maxParticipantsController.text),
      'requirements': _requirements,
      'timeSlots': _timeSlots.map((slot) => slot.toJson()).toList(),
      'simultaneousCapacity': _simultaneousCapacity,
    };
    
    try {
      await widget.onSave(data);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isDemo ? '実験を作成しました（デモ）' : '実験を作成しました'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// ステップのタイトル
  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return '基本情報';
      case 1:
        return '実験詳細';
      case 2:
        return '日程設定';
      case 3:
        return '募集要項';
      case 4:
        return '確認・プレビュー';
      default:
        return '';
    }
  }

  /// 次のステップへ
  void _nextStep() {
    if (_currentStep < 4) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// 前のステップへ
  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getStepTitle()),
        actions: [
          if (widget.isDemo)
            TextButton.icon(
              onPressed: _fillSampleData,
              icon: const Icon(Icons.auto_fix_high, color: Colors.white),
              label: const Text('サンプル入力', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Column(
        children: [
          // デモモード表示
          if (widget.isDemo)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.orange.shade100,
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.orange.shade800),
                  const SizedBox(width: 8),
                  Text(
                    'デモモードのため実際には保存されません',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          
          // ステップインジケーター
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: index == _currentStep ? 32 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: index <= _currentStep 
                      ? const Color(0xFF8E1728)
                      : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
          
          // フォーム
          Expanded(
            child: Form(
              key: _formKey,
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentStep = index;
                  });
                },
                children: [
                  // ステップ1: 基本情報
                  _buildBasicInfoStep(),
                  
                  // ステップ2: 実験詳細
                  _buildExperimentDetailsStep(),
                  
                  // ステップ3: 日程設定
                  _buildScheduleStep(),
                  
                  // ステップ4: 募集要項
                  _buildRequirementsStep(),
                  
                  // ステップ5: 確認・プレビュー
                  _buildConfirmationStep(),
                ],
              ),
            ),
          ),
          
          // ナビゲーションボタン
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousStep,
                      child: const Text('戻る'),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _currentStep < 4 
                      ? _nextStep
                      : _isLoading ? null : _saveExperiment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8E1728),
                    ),
                    child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(_currentStep < 4 ? '次へ' : '作成する'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ステップ1: 基本情報
  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '実験の基本情報を入力してください',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'タイトル *',
              hintText: '例: 視覚認知実験への参加者募集',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.title),
            ),
            maxLength: 50,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'タイトルを入力してください';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: '簡単な説明 *',
              hintText: '実験の概要を簡潔に説明してください',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.description),
            ),
            maxLines: 3,
            maxLength: 200,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '説明を入力してください';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _detailedContentController,
            decoration: const InputDecoration(
              labelText: '詳細内容',
              hintText: '実験の詳細な内容、手順、注意事項など',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.article),
            ),
            maxLines: 8,
            maxLength: 1000,
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _labNameController,
            decoration: const InputDecoration(
              labelText: '研究室名',
              hintText: '例: 認知科学研究室',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.school),
            ),
          ),
        ],
      ),
    );
  }

  /// ステップ2: 実験詳細
  Widget _buildExperimentDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '実験の詳細情報を設定してください',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          
          // 実験タイプ
          const Text('実験タイプ *', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ExperimentType.values.map((type) {
              return ChoiceChip(
                label: Text(type.label),
                selected: _selectedType == type,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedType = type;
                      // オンライン/アンケートの場合、場所を自動設定
                      if (type == ExperimentType.online || type == ExperimentType.survey) {
                        _locationController.text = 'オンライン';
                      }
                    });
                  }
                },
                selectedColor: const Color(0xFF8E1728).withValues(alpha: 0.2),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          
          // 場所
          TextFormField(
            controller: _locationController,
            decoration: const InputDecoration(
              labelText: '場所 *',
              hintText: '例: 早稲田大学 戸山キャンパス',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_on),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '場所を入力してください';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          
          // 報酬設定
          SwitchListTile(
            title: const Text('有償実験'),
            subtitle: const Text('参加者に報酬を支払う場合はオンにしてください'),
            value: _isPaid,
            onChanged: (value) {
              setState(() {
                _isPaid = value;
                if (!value) {
                  _rewardController.clear();
                }
              });
            },
            activeColor: const Color(0xFF8E1728),
          ),
          
          if (_isPaid) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _rewardController,
              decoration: const InputDecoration(
                labelText: '報酬額（円）',
                hintText: '例: 1500',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.monetization_on),
                suffixText: '円',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (_isPaid && (value == null || value.isEmpty)) {
                  return '報酬額を入力してください';
                }
                if (_isPaid && int.tryParse(value!) == null) {
                  return '数値を入力してください';
                }
                return null;
              },
            ),
          ],
          const SizedBox(height: 16),
          
          // 所要時間
          TextFormField(
            controller: _durationController,
            decoration: const InputDecoration(
              labelText: '所要時間（分）',
              hintText: '例: 30',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.timer),
              suffixText: '分',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ],
      ),
    );
  }

  /// ステップ3: 日程設定
  Widget _buildScheduleStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '募集期間と実施日程を設定してください',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          
          // 募集期間
          const Text('募集期間', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context, 'recruitmentStart'),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: '開始日',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _recruitmentStartDate != null
                        ? '${_recruitmentStartDate!.year}/${_recruitmentStartDate!.month.toString().padLeft(2, '0')}/${_recruitmentStartDate!.day.toString().padLeft(2, '0')}'
                        : '選択してください',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context, 'recruitmentEnd'),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: '終了日',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _recruitmentEndDate != null
                        ? '${_recruitmentEndDate!.year}/${_recruitmentEndDate!.month.toString().padLeft(2, '0')}/${_recruitmentEndDate!.day.toString().padLeft(2, '0')}'
                        : '選択してください',
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // 日程調整オプション
          SwitchListTile(
            title: const Text('柔軟な日程調整'),
            subtitle: const Text('参加者が実施日時を選択できるようにする'),
            value: _allowFlexibleSchedule,
            onChanged: (value) {
              setState(() {
                _allowFlexibleSchedule = value;
              });
            },
            activeColor: const Color(0xFF8E1728),
          ),
          const SizedBox(height: 16),
          
          // カレンダーベースの実施期間と時間枠設定
          if (_allowFlexibleSchedule) ...[
            const Text('実施期間と時間枠の設定', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  Icon(Icons.info_outline, size: 20, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'カレンダー上で実施期間を選択し、各日付に時間枠を設定してください',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TimeSlotCalendarEditor(
              initialStartDate: _experimentPeriodStart,
              initialEndDate: _experimentPeriodEnd,
              dateTimeSlots: _dateTimeSlots,
              experimentDuration: int.tryParse(_durationController.text),
              onChanged: (startDate, endDate, dateSlots) {
                setState(() {
                  _experimentPeriodStart = startDate;
                  _experimentPeriodEnd = endDate;
                  _dateTimeSlots = dateSlots;
                  // 日付ベースの時間枠を曜日ベースに変換（互換性のため）
                  _timeSlots = [];
                  for (var slots in dateSlots.values) {
                    _timeSlots.addAll(slots);
                  }
                });
              },
              defaultSimultaneousCapacity: _simultaneousCapacity,
            ),
          ] else ...[
            const Text('固定日程で実施', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.event_available, size: 20, color: Colors.purple.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '実施日時は募集後に個別に連絡します',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.purple.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// ステップ4: 募集要項
  Widget _buildRequirementsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '募集人数と参加条件を設定してください',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          
          // 募集人数
          TextFormField(
            controller: _maxParticipantsController,
            decoration: const InputDecoration(
              labelText: '募集人数',
              hintText: '例: 20',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.group),
              suffixText: '名',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 24),
          
          // 参加条件
          const Text('参加条件', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _requirementController,
                  decoration: const InputDecoration(
                    hintText: '例: 視力矯正後1.0以上',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _addRequirement(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _addRequirement,
                icon: const Icon(Icons.add_circle),
                color: const Color(0xFF8E1728),
                iconSize: 32,
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_requirements.isNotEmpty) ...[
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: _requirements.asMap().entries.map((entry) {
                  final index = entry.key;
                  final requirement = entry.value;
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFF8E1728).withValues(alpha: 0.1),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8E1728),
                        ),
                      ),
                    ),
                    title: Text(requirement),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      onPressed: () {
                        setState(() {
                          _requirements.removeAt(index);
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Center(
                child: Text(
                  '参加条件はまだ設定されていません',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// ステップ5: 確認・プレビュー
  Widget _buildConfirmationStep() {
    final previewExperiment = _createPreviewExperiment();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '内容を確認してください',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '以下の内容で実験を募集します',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          
          // プレビュー切り替え
          SwitchListTile(
            title: const Text('カードプレビュー'),
            subtitle: const Text('実際の表示を確認'),
            value: _showPreview,
            onChanged: (value) {
              setState(() {
                _showPreview = value;
              });
            },
            activeColor: const Color(0xFF8E1728),
          ),
          const SizedBox(height: 16),
          
          if (_showPreview) ...[
            // カードプレビュー
            Container(
              height: 230,
              child: ExperimentCard(
                experiment: previewExperiment,
                isDemo: true,
              ),
            ),
            const SizedBox(height: 24),
          ],
          
          // 詳細情報
          _buildConfirmationSection('基本情報', [
            _buildConfirmationItem('タイトル', previewExperiment.title),
            _buildConfirmationItem('説明', previewExperiment.description),
            if (previewExperiment.labName != null)
              _buildConfirmationItem('研究室', previewExperiment.labName!),
          ]),
          const SizedBox(height: 16),
          
          _buildConfirmationSection('実験詳細', [
            _buildConfirmationItem('タイプ', previewExperiment.type.label),
            _buildConfirmationItem('場所', previewExperiment.location),
            _buildConfirmationItem(
              '報酬',
              previewExperiment.isPaid ? '¥${previewExperiment.reward}' : '無償',
            ),
            if (previewExperiment.duration != null)
              _buildConfirmationItem('所要時間', '${previewExperiment.duration}分'),
          ]),
          const SizedBox(height: 16),
          
          _buildConfirmationSection('日程', [
            _buildConfirmationItem(
              '募集期間',
              '${_formatDate(_recruitmentStartDate)} 〜 ${_formatDate(_recruitmentEndDate)}',
            ),
            if (_allowFlexibleSchedule)
              _buildConfirmationItem(
                '実施期間',
                '${_formatDate(_experimentPeriodStart)} 〜 ${_formatDate(_experimentPeriodEnd)}',
              ),
            _buildConfirmationItem(
              '日程調整',
              _allowFlexibleSchedule ? '柔軟（予約制）' : '固定',
            ),
          ]),
          const SizedBox(height: 16),
          
          if (previewExperiment.maxParticipants != null || _requirements.isNotEmpty)
            _buildConfirmationSection('募集要項', [
              if (previewExperiment.maxParticipants != null)
                _buildConfirmationItem('募集人数', '${previewExperiment.maxParticipants}名'),
              if (_requirements.isNotEmpty)
                _buildConfirmationItem('参加条件', _requirements.join('、')),
            ]),
        ],
      ),
    );
  }

  /// 確認セクション
  Widget _buildConfirmationSection(String title, List<Widget> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...items,
          ],
        ),
      ),
    );
  }

  /// 確認項目
  Widget _buildConfirmationItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 日付フォーマット
  String _formatDate(DateTime? date) {
    if (date == null) return '未設定';
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}