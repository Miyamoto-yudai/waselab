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
  DateTime? _experimentDate;
  DateTime? _endDate;
  TimeOfDay? _experimentTime;
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

  /// 実施日選択
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _experimentDate) {
      setState(() {
        _experimentDate = picked;
      });
    }
  }

  /// 終了日選択
  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _experimentDate?.add(const Duration(days: 7)) ?? DateTime.now().add(const Duration(days: 14)),
      firstDate: _experimentDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  /// 時間選択
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && picked != _experimentTime) {
      setState(() {
        _experimentTime = picked;
      });
    }
  }

  /// 実験日時を結合
  DateTime? get _combinedDateTime {
    if (_experimentDate == null) return null;
    if (_experimentTime == null) return _experimentDate;
    
    return DateTime(
      _experimentDate!.year,
      _experimentDate!.month,
      _experimentDate!.day,
      _experimentTime!.hour,
      _experimentTime!.minute,
    );
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
        'experimentDate': _combinedDateTime != null 
          ? Timestamp.fromDate(_combinedDateTime!) 
          : null,
        'endDate': _endDate != null
          ? Timestamp.fromDate(_endDate!)
          : null,
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

              // 募集開始日時
              const Text('募集開始日時', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectDate(context),
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _experimentDate != null
                          ? '${_experimentDate!.year}/${_experimentDate!.month}/${_experimentDate!.day}'
                          : '開始日を選択',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectTime(context),
                      icon: const Icon(Icons.access_time),
                      label: Text(
                        _experimentTime != null
                          ? '${_experimentTime!.hour}:${_experimentTime!.minute.toString().padLeft(2, '0')}'
                          : '時間を選択',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 募集終了日
              const Text('募集終了日', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _selectEndDate(context),
                icon: const Icon(Icons.event),
                label: Text(
                  _endDate != null
                    ? '${_endDate!.year}/${_endDate!.month}/${_endDate!.day}'
                    : '終了日を選択',
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