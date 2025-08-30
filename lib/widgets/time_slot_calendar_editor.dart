import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../models/time_slot.dart';

/// 編集モード
enum EditMode { selectRange, addTimeSlots }

/// カレンダーベースの時間枠設定ウィジェット
class TimeSlotCalendarEditor extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final Map<DateTime, List<TimeSlot>> dateTimeSlots;
  final Function(DateTime?, DateTime?, Map<DateTime, List<TimeSlot>>) onChanged;
  final int defaultSimultaneousCapacity;
  final int? experimentDuration; // 実験の所要時間（分）

  const TimeSlotCalendarEditor({
    super.key,
    this.initialStartDate,
    this.initialEndDate,
    required this.dateTimeSlots,
    required this.onChanged,
    this.defaultSimultaneousCapacity = 1,
    this.experimentDuration,
  });

  @override
  State<TimeSlotCalendarEditor> createState() => _TimeSlotCalendarEditorState();
}

class _TimeSlotCalendarEditorState extends State<TimeSlotCalendarEditor> {
  late DateTime _focusedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  DateTime? _selectedDay;
  late Map<DateTime, List<TimeSlot>> _dateTimeSlots;
  EditMode _editMode = EditMode.selectRange;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ja_JP', null);
    _focusedDay = widget.initialStartDate ?? DateTime.now();
    _rangeStart = widget.initialStartDate;
    _rangeEnd = widget.initialEndDate;
    _dateTimeSlots = Map.from(widget.dateTimeSlots);
  }

  /// 日付の時間枠を取得（日付のみで比較）
  List<TimeSlot> _getTimeSlotsForDay(DateTime day) {
    final dateKey = DateTime(day.year, day.month, day.day);
    return _dateTimeSlots[dateKey] ?? [];
  }

  /// 時間枠を追加
  Future<void> _addTimeSlotForDay(DateTime day) async {
    final result = await showDialog<TimeSlot>(
      context: context,
      builder: (context) => _TimeSlotAddDialog(
        date: day,
        defaultCapacity: widget.defaultSimultaneousCapacity,
      ),
    );

    if (result != null) {
      setState(() {
        final dateKey = DateTime(day.year, day.month, day.day);
        if (!_dateTimeSlots.containsKey(dateKey)) {
          _dateTimeSlots[dateKey] = [];
        }
        _dateTimeSlots[dateKey]!.add(result);
        // 時間順にソート
        _dateTimeSlots[dateKey]!.sort((a, b) {
          final aMinutes = a.startTime.hour * 60 + a.startTime.minute;
          final bMinutes = b.startTime.hour * 60 + b.startTime.minute;
          return aMinutes.compareTo(bMinutes);
        });
      });
      widget.onChanged(_rangeStart, _rangeEnd, _dateTimeSlots);
    }
  }

  /// 時間枠を削除
  void _removeTimeSlot(DateTime day, TimeSlot slot) {
    setState(() {
      final dateKey = DateTime(day.year, day.month, day.day);
      _dateTimeSlots[dateKey]?.remove(slot);
      if (_dateTimeSlots[dateKey]?.isEmpty ?? false) {
        _dateTimeSlots.remove(dateKey);
      }
    });
    widget.onChanged(_rangeStart, _rangeEnd, _dateTimeSlots);
  }

  /// 所要時間に基づいて自動的に時間枠を生成
  void _autoGenerateTimeSlots() {
    if (_rangeStart == null || _rangeEnd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('先に実施期間を選択してください')),
      );
      return;
    }
    
    if (widget.experimentDuration == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('実験の所要時間が設定されていません')),
      );
      return;
    }
    
    setState(() {
      _dateTimeSlots.clear();
      
      // 所要時間 + 準備時間（10分）
      final slotDuration = widget.experimentDuration! + 10;
      
      // 期間内のすべての日付を処理
      DateTime current = _rangeStart!;
      while (current.isBefore(_rangeEnd!) || current.isAtSameMomentAs(_rangeEnd!)) {
        final dateKey = DateTime(current.year, current.month, current.day);
        
        // 平日のみ設定（土日は除外）
        if (current.weekday <= 5) {
          final slots = <TimeSlot>[];
          
          // 午前の時間枠（9:00-12:00）
          int morningStartHour = 9;
          int morningStartMinute = 0;
          while (true) {
            final endMinutes = morningStartHour * 60 + morningStartMinute + slotDuration;
            if (endMinutes > 12 * 60) break; // 12:00を超えたら終了
            
            final endHour = endMinutes ~/ 60;
            final endMinute = endMinutes % 60;
            
            slots.add(TimeSlot(
              weekday: current.weekday,
              startTime: TimeOfDay(hour: morningStartHour, minute: morningStartMinute),
              endTime: TimeOfDay(hour: endHour, minute: endMinute),
              maxCapacity: widget.defaultSimultaneousCapacity,
            ));
            
            // 次の開始時刻を計算
            morningStartHour = endHour;
            morningStartMinute = endMinute;
          }
          
          // 午後の時間枠（13:00-17:00）
          int afternoonStartHour = 13;
          int afternoonStartMinute = 0;
          while (true) {
            final endMinutes = afternoonStartHour * 60 + afternoonStartMinute + slotDuration;
            if (endMinutes > 17 * 60) break; // 17:00を超えたら終了
            
            final endHour = endMinutes ~/ 60;
            final endMinute = endMinutes % 60;
            
            slots.add(TimeSlot(
              weekday: current.weekday,
              startTime: TimeOfDay(hour: afternoonStartHour, minute: afternoonStartMinute),
              endTime: TimeOfDay(hour: endHour, minute: endMinute),
              maxCapacity: widget.defaultSimultaneousCapacity,
            ));
            
            // 次の開始時刻を計算
            afternoonStartHour = endHour;
            afternoonStartMinute = endMinute;
          }
          
          if (slots.isNotEmpty) {
            _dateTimeSlots[dateKey] = slots;
          }
        }
        
        current = current.add(const Duration(days: 1));
      }
    });
    
    widget.onChanged(_rangeStart, _rangeEnd, _dateTimeSlots);
  }
  
  /// テンプレートを適用
  void _applyTemplate(String templateType) {
    if (_rangeStart == null || _rangeEnd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('先に実施期間を選択してください')),
      );
      return;
    }

    setState(() {
      _dateTimeSlots.clear();
      
      // 期間内のすべての日付を処理
      DateTime current = _rangeStart!;
      while (current.isBefore(_rangeEnd!) || current.isAtSameMomentAs(_rangeEnd!)) {
        final dateKey = DateTime(current.year, current.month, current.day);
        
        // テンプレートによって時間枠を設定
        if (templateType == 'weekday_morning' && current.weekday <= 5) {
          _dateTimeSlots[dateKey] = [
            TimeSlot(
              weekday: current.weekday,
              startTime: const TimeOfDay(hour: 9, minute: 0),
              endTime: const TimeOfDay(hour: 12, minute: 0),
              maxCapacity: widget.defaultSimultaneousCapacity,
            ),
          ];
        } else if (templateType == 'weekday_afternoon' && current.weekday <= 5) {
          _dateTimeSlots[dateKey] = [
            TimeSlot(
              weekday: current.weekday,
              startTime: const TimeOfDay(hour: 13, minute: 0),
              endTime: const TimeOfDay(hour: 17, minute: 0),
              maxCapacity: widget.defaultSimultaneousCapacity,
            ),
          ];
        } else if (templateType == 'weekday_all' && current.weekday <= 5) {
          _dateTimeSlots[dateKey] = [
            TimeSlot(
              weekday: current.weekday,
              startTime: const TimeOfDay(hour: 9, minute: 0),
              endTime: const TimeOfDay(hour: 12, minute: 0),
              maxCapacity: widget.defaultSimultaneousCapacity,
            ),
            TimeSlot(
              weekday: current.weekday,
              startTime: const TimeOfDay(hour: 13, minute: 0),
              endTime: const TimeOfDay(hour: 17, minute: 0),
              maxCapacity: widget.defaultSimultaneousCapacity,
            ),
          ];
        }
        
        current = current.add(const Duration(days: 1));
      }
    });
    
    widget.onChanged(_rangeStart, _rangeEnd, _dateTimeSlots);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // モード切替とテンプレート
        Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // モード表示
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _editMode == EditMode.selectRange
                          ? Colors.blue.withValues(alpha: 0.1)
                          : Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _editMode == EditMode.selectRange
                            ? Colors.blue
                            : Colors.green,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _editMode == EditMode.selectRange
                              ? Icons.date_range
                              : Icons.access_time,
                            size: 16,
                            color: _editMode == EditMode.selectRange
                              ? Colors.blue
                              : Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _editMode == EditMode.selectRange
                              ? 'ステップ1: 実施期間を選択'
                              : 'ステップ2: 時間枠を設定',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _editMode == EditMode.selectRange
                                ? Colors.blue
                                : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (_editMode == EditMode.selectRange && _rangeStart != null && _rangeEnd != null)
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _editMode = EditMode.addTimeSlots;
                          });
                        },
                        icon: const Icon(Icons.arrow_forward, size: 16),
                        label: const Text('次へ'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.green,
                        ),
                      ),
                    if (_editMode == EditMode.addTimeSlots)
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _editMode = EditMode.selectRange;
                          });
                        },
                        icon: const Icon(Icons.arrow_back, size: 16),
                        label: const Text('期間変更'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue,
                        ),
                      ),
                  ],
                ),
                
                // 選択された期間の表示
                if (_rangeStart != null && _rangeEnd != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.event, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          '実施期間: ${_rangeStart!.year}/${_rangeStart!.month}/${_rangeStart!.day} ~ ${_rangeEnd!.year}/${_rangeEnd!.month}/${_rangeEnd!.day}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
                
                // テンプレートボタン
                if (_editMode == EditMode.addTimeSlots) ...[
                  const SizedBox(height: 12),
                  const Text('テンプレート', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (widget.experimentDuration != null)
                        ActionChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.auto_awesome, size: 14),
                              const SizedBox(width: 4),
                              Text('${widget.experimentDuration}分で自動割当'),
                            ],
                          ),
                          onPressed: _autoGenerateTimeSlots,
                          backgroundColor: Colors.purple.withValues(alpha: 0.1),
                          labelStyle: const TextStyle(color: Colors.purple, fontSize: 12),
                        ),
                      _buildTemplateChip('平日午前', 'weekday_morning'),
                      _buildTemplateChip('平日午後', 'weekday_afternoon'),
                      _buildTemplateChip('平日終日', 'weekday_all'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '※ 個別の日付をタップして時間枠を細かく調整できます',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // カレンダー
        Card(
          child: TableCalendar<TimeSlot>(
            firstDay: DateTime.now().subtract(const Duration(days: 30)),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.sunday,
            locale: 'ja_JP',
            
            // 範囲選択モード
            rangeStartDay: _editMode == EditMode.selectRange ? _rangeStart : null,
            rangeEndDay: _editMode == EditMode.selectRange ? _rangeEnd : null,
            rangeSelectionMode: _editMode == EditMode.selectRange 
              ? RangeSelectionMode.toggledOn 
              : RangeSelectionMode.toggledOff,
            
            selectedDayPredicate: (day) {
              return _editMode == EditMode.addTimeSlots && isSameDay(_selectedDay, day);
            },
            
            eventLoader: (day) {
              return _getTimeSlotsForDay(day);
            },
            
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              weekendTextStyle: const TextStyle(color: Colors.red),
              rangeHighlightColor: Colors.blue.withValues(alpha: 0.2),
              rangeStartDecoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              rangeEndDecoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: Color(0xFF8E1728),
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              markersMaxCount: 3,
              markerSize: 6,
              markerMargin: const EdgeInsets.only(top: 8),
            ),
            
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            
            onDaySelected: (selectedDay, focusedDay) {
              if (_editMode == EditMode.addTimeSlots) {
                // 実施期間内かチェック
                if (_rangeStart != null && _rangeEnd != null) {
                  if (selectedDay.isBefore(_rangeStart!) || selectedDay.isAfter(_rangeEnd!)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('実施期間外の日付です')),
                    );
                    return;
                  }
                }
                
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                
                // 時間枠追加ダイアログを表示
                _addTimeSlotForDay(selectedDay);
              }
            },
            
            onRangeSelected: (start, end, focusedDay) {
              if (_editMode == EditMode.selectRange) {
                setState(() {
                  _rangeStart = start;
                  _rangeEnd = end;
                  _focusedDay = focusedDay;
                });
                widget.onChanged(start, end, _dateTimeSlots);
              }
            },
            
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                if (events.isEmpty) return null;
                
                return Positioned(
                  bottom: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${events.length}枠',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        
        // 選択した日の時間枠一覧
        if (_selectedDay != null && _editMode == EditMode.addTimeSlots) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${_selectedDay!.year}/${_selectedDay!.month}/${_selectedDay!.day}の時間枠',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Color(0xFF8E1728)),
                        onPressed: () => _addTimeSlotForDay(_selectedDay!),
                        tooltip: '時間枠を追加',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_getTimeSlotsForDay(_selectedDay!).isEmpty)
                    const Text(
                      'まだ時間枠が設定されていません',
                      style: TextStyle(color: Colors.grey),
                    )
                  else
                    ...(_getTimeSlotsForDay(_selectedDay!).map((slot) => ListTile(
                      leading: const Icon(Icons.access_time, size: 20),
                      title: Text(slot.timeRangeString),
                      subtitle: Text('定員: ${slot.maxCapacity}名'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                        onPressed: () => _removeTimeSlot(_selectedDay!, slot),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ))),
                ],
              ),
            ),
          ),
        ],
        
        // サマリー
        if (_dateTimeSlots.isNotEmpty) ...[
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
                    '${_dateTimeSlots.length}日間に合計${_dateTimeSlots.values.fold(0, (sum, list) => sum + list.length)}枠',
                    style: TextStyle(color: Colors.green.shade700),
                  ),
                  Text(
                    '総定員: ${_dateTimeSlots.values.fold(0, (sum, list) => sum + list.fold(0, (s, slot) => s + slot.maxCapacity))}名',
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

  Widget _buildTemplateChip(String label, String templateType) {
    return ActionChip(
      label: Text(label),
      onPressed: () => _applyTemplate(templateType),
      backgroundColor: const Color(0xFF8E1728).withValues(alpha: 0.1),
      labelStyle: const TextStyle(color: Color(0xFF8E1728), fontSize: 12),
    );
  }
}

/// 時間枠追加ダイアログ
class _TimeSlotAddDialog extends StatefulWidget {
  final DateTime date;
  final int defaultCapacity;

  const _TimeSlotAddDialog({
    required this.date,
    required this.defaultCapacity,
  });

  @override
  State<_TimeSlotAddDialog> createState() => _TimeSlotAddDialogState();
}

class _TimeSlotAddDialogState extends State<_TimeSlotAddDialog> {
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
    return AlertDialog(
      title: Text('${widget.date.year}/${widget.date.month}/${widget.date.day}の時間枠'),
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
          TextField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '同時実験可能人数',
              border: OutlineInputBorder(),
              suffixText: '名',
            ),
            controller: TextEditingController(text: _capacity.toString()),
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
              weekday: widget.date.weekday,
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