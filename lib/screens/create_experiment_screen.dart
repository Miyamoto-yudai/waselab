import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/experiment.dart';

/// 実験作成画面（早稲田ユーザー専用）
class CreateExperimentScreen extends StatefulWidget {
  const CreateExperimentScreen({super.key});

  @override
  State<CreateExperimentScreen> createState() => _CreateExperimentScreenState();
}

class _CreateExperimentScreenState extends State<CreateExperimentScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // フォームコントローラー
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
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
  
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _rewardController.dispose();
    _locationController.dispose();
    _durationController.dispose();
    _maxParticipantsController.dispose();
    _labNameController.dispose();
    _requirementController.dispose();
    super.dispose();
  }

  /// 募集開始日選択
  Future<void> _selectRecruitmentStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _recruitmentStartDate = picked;
      });
    }
  }

  /// 募集終了日選択
  Future<void> _selectRecruitmentEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _recruitmentStartDate?.add(const Duration(days: 7)) ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: _recruitmentStartDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _recruitmentEndDate = picked;
      });
    }
  }

  /// 実験実施期間開始日選択
  Future<void> _selectExperimentPeriodStart(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _recruitmentStartDate?.add(const Duration(days: 1)) ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: _recruitmentStartDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _experimentPeriodStart = picked;
      });
    }
  }

  /// 実験実施期間終了日選択
  Future<void> _selectExperimentPeriodEnd(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _experimentPeriodStart?.add(const Duration(days: 7)) ?? DateTime.now().add(const Duration(days: 14)),
      firstDate: _experimentPeriodStart ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _experimentPeriodEnd = picked;
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

  /// 実験を作成
  Future<void> _createExperiment() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('ユーザーが見つかりません');
      }

      // Firestoreに実験を追加
      await _firestore.collection('experiments').add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'reward': _isPaid ? int.tryParse(_rewardController.text) ?? 0 : 0,
        'location': _locationController.text.trim(),
        'type': _selectedType.name,
        'isPaid': _isPaid,
        'creatorId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'recruitmentStartDate': _recruitmentStartDate != null 
          ? Timestamp.fromDate(_recruitmentStartDate!) 
          : null,
        'recruitmentEndDate': _recruitmentEndDate != null
          ? Timestamp.fromDate(_recruitmentEndDate!)
          : null,
        'experimentPeriodStart': _experimentPeriodStart != null
          ? Timestamp.fromDate(_experimentPeriodStart!)
          : null,
        'experimentPeriodEnd': _experimentPeriodEnd != null
          ? Timestamp.fromDate(_experimentPeriodEnd!)
          : null,
        'allowFlexibleSchedule': _allowFlexibleSchedule,
        'labName': _labNameController.text.trim().isNotEmpty
          ? _labNameController.text.trim()
          : null,
        'duration': int.tryParse(_durationController.text),
        'maxParticipants': int.tryParse(_maxParticipantsController.text),
        'requirements': _requirements,
      });

      if (mounted) {
        // 成功メッセージ
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('実験を作成しました'),
            backgroundColor: Colors.green,
          ),
        );
        
        // ホーム画面に戻る
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('実験を募集'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // タイトル
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '実験タイトル *',
                  hintText: '例：視覚認知実験への参加者募集',
                  border: OutlineInputBorder(),
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

              // 研究室名
              TextFormField(
                controller: _labNameController,
                decoration: const InputDecoration(
                  labelText: '研究室名',
                  hintText: '例：認知科学研究室',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.school),
                ),
                maxLength: 30,
              ),
              const SizedBox(height: 16),

              // 説明
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '実験内容 *',
                  hintText: '実験の詳細な説明を入力してください',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                maxLength: 500,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '実験内容を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 種別
              const Text('実験種別 *', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              SegmentedButton<ExperimentType>(
                segments: ExperimentType.values.map((type) {
                  return ButtonSegment(
                    value: type,
                    label: Text(type.label),
                    icon: Icon(_getTypeIcon(type)),
                  );
                }).toList(),
                selected: {_selectedType},
                onSelectionChanged: (Set<ExperimentType> selection) {
                  setState(() {
                    _selectedType = selection.first;
                  });
                },
              ),
              const SizedBox(height: 16),

              // 有償/無償
              SwitchListTile(
                title: const Text('有償実験'),
                subtitle: const Text('謝礼金がある場合はオンにしてください'),
                value: _isPaid,
                onChanged: (value) {
                  setState(() {
                    _isPaid = value;
                    if (!value) {
                      _rewardController.clear();
                    }
                  });
                },
              ),

              // 報酬
              if (_isPaid) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _rewardController,
                  decoration: const InputDecoration(
                    labelText: '報酬（円） *',
                    hintText: '例：1500',
                    border: OutlineInputBorder(),
                    prefixText: '¥ ',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (_isPaid) {
                      if (value == null || value.trim().isEmpty) {
                        return '報酬額を入力してください';
                      }
                      if (int.tryParse(value) == null) {
                        return '数値を入力してください';
                      }
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 16),

              // 場所
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: '場所 *',
                  hintText: '例：早稲田大学 戸山キャンパス 33号館',
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
              const SizedBox(height: 16),

              // 柔軟なスケジュール調整
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'スケジュール設定',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('柔軟なスケジュール調整'),
                        subtitle: Text(
                          _allowFlexibleSchedule
                            ? '参加者が予約可能な日時から選択できます'
                            : '固定の日時で実施します',
                        ),
                        value: _allowFlexibleSchedule,
                        onChanged: (value) {
                          setState(() {
                            _allowFlexibleSchedule = value;
                          });
                        },
                      ),
                      const Divider(),
                      const SizedBox(height: 8),
                      
                      // 募集期間
                      const Text('募集期間', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _selectRecruitmentStartDate(context),
                              icon: const Icon(Icons.calendar_today, size: 20),
                              label: Text(
                                _recruitmentStartDate != null
                                  ? '${_recruitmentStartDate!.year}/${_recruitmentStartDate!.month.toString().padLeft(2, '0')}/${_recruitmentStartDate!.day.toString().padLeft(2, '0')}'
                                  : '開始日',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text('〜'),
                          ),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _selectRecruitmentEndDate(context),
                              icon: const Icon(Icons.calendar_today, size: 20),
                              label: Text(
                                _recruitmentEndDate != null
                                  ? '${_recruitmentEndDate!.year}/${_recruitmentEndDate!.month.toString().padLeft(2, '0')}/${_recruitmentEndDate!.day.toString().padLeft(2, '0')}'
                                  : '終了日',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      if (_allowFlexibleSchedule) ...[
                        const SizedBox(height: 16),
                        const Text('実験実施期間', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        const Text(
                          'この期間内で参加者が予約可能な日時を選択できます',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _selectExperimentPeriodStart(context),
                                icon: const Icon(Icons.event, size: 20),
                                label: Text(
                                  _experimentPeriodStart != null
                                    ? '${_experimentPeriodStart!.year}/${_experimentPeriodStart!.month.toString().padLeft(2, '0')}/${_experimentPeriodStart!.day.toString().padLeft(2, '0')}'
                                    : '開始日',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text('〜'),
                            ),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _selectExperimentPeriodEnd(context),
                                icon: const Icon(Icons.event, size: 20),
                                label: Text(
                                  _experimentPeriodEnd != null
                                    ? '${_experimentPeriodEnd!.year}/${_experimentPeriodEnd!.month.toString().padLeft(2, '0')}/${_experimentPeriodEnd!.day.toString().padLeft(2, '0')}'
                                    : '終了日',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 所要時間
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(
                  labelText: '所要時間（分）',
                  hintText: '例：30',
                  border: OutlineInputBorder(),
                  suffixText: '分',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // 最大参加者数
              TextFormField(
                controller: _maxParticipantsController,
                decoration: const InputDecoration(
                  labelText: '募集人数',
                  hintText: '例：20',
                  border: OutlineInputBorder(),
                  suffixText: '名',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // 参加条件
              const Text('参加条件', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _requirementController,
                      decoration: const InputDecoration(
                        hintText: '例：視力矯正後1.0以上',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _addRequirement(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _addRequirement,
                    icon: const Icon(Icons.add),
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              if (_requirements.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _requirements.map((req) {
                    return Chip(
                      label: Text(req),
                      onDeleted: () {
                        setState(() {
                          _requirements.remove(req);
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 32),

              // 作成ボタン
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _createExperiment,
                  icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                  label: Text(_isLoading ? '作成中...' : '実験を作成'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(ExperimentType type) {
    switch (type) {
      case ExperimentType.online:
        return Icons.computer;
      case ExperimentType.onsite:
        return Icons.location_on;
      case ExperimentType.survey:
        return Icons.assignment;
    }
  }
}