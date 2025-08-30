import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/time_slot.dart';

/// 時間枠編集ウィジェット
class TimeSlotEditor extends StatefulWidget {
  final List<TimeSlot> timeSlots;
  final Function(List<TimeSlot>) onTimeSlotsChanged;
  final int defaultSimultaneousCapacity;

  const TimeSlotEditor({
    super.key,
    required this.timeSlots,
    required this.onTimeSlotsChanged,
    this.defaultSimultaneousCapacity = 1,
  });

  @override
  State<TimeSlotEditor> createState() => _TimeSlotEditorState();
}

class _TimeSlotEditorState extends State<TimeSlotEditor> {
  late List<TimeSlot> _timeSlots;
  int _globalCapacity = 1;
  bool _useGlobalCapacity = false;

  @override
  void initState() {
    super.initState();
    _timeSlots = List.from(widget.timeSlots);
    _globalCapacity = widget.defaultSimultaneousCapacity;
  }

  /// 時間枠を追加
  Future<void> _addTimeSlot(int weekday) async {
    final result = await showDialog<TimeSlot>(
      context: context,
      builder: (context) => _TimeSlotDialog(
        weekday: weekday,
        defaultCapacity: _useGlobalCapacity ? _globalCapacity : 1,
      ),
    );

    if (result != null) {
      setState(() {
        _timeSlots.add(result);
        _timeSlots.sort((a, b) {
          if (a.weekday != b.weekday) return a.weekday.compareTo(b.weekday);
          return a.startTime.hour.compareTo(b.startTime.hour);
        });
      });
      widget.onTimeSlotsChanged(_timeSlots);
    }
  }

  /// 時間枠を削除
  void _removeTimeSlot(TimeSlot slot) {
    setState(() {
      _timeSlots.remove(slot);
    });
    widget.onTimeSlotsChanged(_timeSlots);
  }

  /// テンプレートを適用
  void _applyTemplate(TimeSlotTemplate template) {
    setState(() {
      _timeSlots = List.from(template.slots);
      if (_useGlobalCapacity) {
        _timeSlots = _timeSlots.map((slot) => slot.copyWith(
          maxCapacity: _globalCapacity,
        )).toList();
      }
    });
    widget.onTimeSlotsChanged(_timeSlots);
  }

  /// 曜日ごとの時間枠を取得
  List<TimeSlot> _getSlotsForWeekday(int weekday) {
    return _timeSlots.where((slot) => slot.weekday == weekday).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // グローバル設定
        Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '共通設定',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('同時実験可能人数を統一'),
                  subtitle: Text('すべての時間枠に同じ人数を設定'),
                  value: _useGlobalCapacity,
                  onChanged: (value) {
                    setState(() {
                      _useGlobalCapacity = value;
                      if (value) {
                        _timeSlots = _timeSlots.map((slot) => slot.copyWith(
                          maxCapacity: _globalCapacity,
                        )).toList();
                        widget.onTimeSlotsChanged(_timeSlots);
                      }
                    });
                  },
                  activeColor: const Color(0xFF8E1728),
                ),
                if (_useGlobalCapacity) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('同時実験可能人数: '),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 80,
                        child: TextFormField(
                          initialValue: _globalCapacity.toString(),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            suffixText: '名',
                          ),
                          onChanged: (value) {
                            final capacity = int.tryParse(value) ?? 1;
                            setState(() {
                              _globalCapacity = capacity;
                              _timeSlots = _timeSlots.map((slot) => slot.copyWith(
                                maxCapacity: capacity,
                              )).toList();
                            });
                            widget.onTimeSlotsChanged(_timeSlots);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),

        // テンプレート選択
        Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'テンプレート',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildTemplateChip('平日午前', TimeSlotTemplate.weekdayMorning),
                    _buildTemplateChip('平日午後', TimeSlotTemplate.weekdayAfternoon),
                    _buildTemplateChip('平日終日', TimeSlotTemplate.weekdayAllDay),
                    _buildTemplateChip('1時間枠', TimeSlotTemplate.hourlySlots),
                  ],
                ),
              ],
            ),
          ),
        ),

        // 曜日別時間枠設定
        const Text(
          '曜日別時間枠',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        ...List.generate(7, (index) {
          final weekday = index + 1;
          final slots = _getSlotsForWeekday(weekday);
          final weekdayNames = ['月', '火', '水', '木', '金', '土', '日'];
          
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ExpansionTile(
              title: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: slots.isNotEmpty 
                        ? const Color(0xFF8E1728).withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        weekdayNames[index],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: slots.isNotEmpty 
                            ? const Color(0xFF8E1728)
                            : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${weekdayNames[index]}曜日',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  if (slots.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8E1728).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${slots.length}枠',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8E1728),
                        ),
                      ),
                    ),
                ],
              ),
              children: [
                ...slots.map((slot) => ListTile(
                  leading: const Icon(Icons.access_time, size: 20),
                  title: Text(slot.timeRangeString),
                  subtitle: Text('最大${slot.maxCapacity}名'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    onPressed: () => _removeTimeSlot(slot),
                  ),
                )),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextButton.icon(
                    onPressed: () => _addTimeSlot(weekday),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('時間枠を追加'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF8E1728),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),

        // サマリー
        if (_timeSlots.isNotEmpty) ...[
          const SizedBox(height: 16),
          Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '設定された時間枠',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '合計 ${_timeSlots.length} 枠',
                    style: TextStyle(color: Colors.green.shade700),
                  ),
                  if (_timeSlots.isNotEmpty)
                    Text(
                      '総定員 ${_timeSlots.fold(0, (sum, slot) => sum + slot.maxCapacity)} 名',
                      style: TextStyle(color: Colors.green.shade700),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTemplateChip(String label, TimeSlotTemplate template) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('テンプレートを適用'),
            content: Text('「$label」テンプレートを適用しますか？\n現在の設定は上書きされます。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('キャンセル'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _applyTemplate(template);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8E1728),
                ),
                child: const Text('適用'),
              ),
            ],
          ),
        );
      },
      backgroundColor: const Color(0xFF8E1728).withValues(alpha: 0.1),
      labelStyle: const TextStyle(color: Color(0xFF8E1728)),
    );
  }
}

/// 時間枠追加ダイアログ
class _TimeSlotDialog extends StatefulWidget {
  final int weekday;
  final int defaultCapacity;

  const _TimeSlotDialog({
    required this.weekday,
    required this.defaultCapacity,
  });

  @override
  State<_TimeSlotDialog> createState() => _TimeSlotDialogState();
}

class _TimeSlotDialogState extends State<_TimeSlotDialog> {
  TimeOfDay _startTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 11, minute: 0);
  int _capacity = 1;

  @override
  void initState() {
    super.initState();
    _capacity = widget.defaultCapacity;
  }

  Future<void> _selectTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
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
        if (isStart) {
          _startTime = picked;
          // 開始時刻が終了時刻より後の場合、終了時刻を1時間後に設定
          final startMinutes = _startTime.hour * 60 + _startTime.minute;
          final endMinutes = _endTime.hour * 60 + _endTime.minute;
          if (startMinutes >= endMinutes) {
            _endTime = TimeOfDay(
              hour: (_startTime.hour + 1) % 24,
              minute: _startTime.minute,
            );
          }
        } else {
          _endTime = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final weekdayNames = ['月曜日', '火曜日', '水曜日', '木曜日', '金曜日', '土曜日', '日曜日'];
    
    return AlertDialog(
      title: Text('${weekdayNames[widget.weekday - 1]}の時間枠を追加'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _selectTime(true),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: '開始時刻',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () => _selectTime(false),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: '終了時刻',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: _capacity.toString(),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: '同時実験可能人数',
              border: OutlineInputBorder(),
              suffixText: '名',
            ),
            onChanged: (value) {
              _capacity = int.tryParse(value) ?? 1;
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: () {
            // 時間の妥当性チェック
            final startMinutes = _startTime.hour * 60 + _startTime.minute;
            final endMinutes = _endTime.hour * 60 + _endTime.minute;
            
            if (startMinutes >= endMinutes) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('終了時刻は開始時刻より後に設定してください'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            
            Navigator.pop(context, TimeSlot(
              weekday: widget.weekday,
              startTime: _startTime,
              endTime: _endTime,
              maxCapacity: _capacity,
            ));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8E1728),
          ),
          child: const Text('追加'),
        ),
      ],
    );
  }
}