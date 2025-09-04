import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../models/experiment.dart';
import '../models/time_slot.dart';
import '../models/date_time_slot.dart';

/// 実験予約カレンダービューの共通ベースウィジェット
class ExperimentCalendarViewBase extends StatefulWidget {
  final Experiment experiment;
  final Function(DateTime, String) onSlotSelected;
  final bool isDemo;

  const ExperimentCalendarViewBase({
    super.key,
    required this.experiment,
    required this.onSlotSelected,
    this.isDemo = false,
  });

  @override
  State<ExperimentCalendarViewBase> createState() => _ExperimentCalendarViewBaseState();
}

class _ExperimentCalendarViewBaseState extends State<ExperimentCalendarViewBase> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  
  // デモ用の予約可能な時間枠
  final Map<String, List<String>> _demoTimeSlots = {
    '月曜日': ['10:00-11:00', '14:00-15:00', '16:00-17:00'],
    '火曜日': ['9:00-10:00', '13:00-14:00', '15:00-16:00'],
    '水曜日': ['11:00-12:00', '14:00-15:00', '17:00-18:00'],
    '木曜日': ['10:00-11:00', '15:00-16:00'],
    '金曜日': ['9:00-10:00', '11:00-12:00', '14:00-15:00', '16:00-17:00'],
  };

  // デモ用の予約状況（時間枠ごとの予約済み人数）
  Map<String, int> _demoBookedCounts = {};
  
  // 選択した日の時間枠のTimeSlotオブジェクトを保持
  List<TimeSlot> _selectedDayTimeSlots = [];
  List<DateTimeSlot> _selectedDateTimeSlots = [];

  @override
  void initState() {
    super.initState();
    // Initialize locale data
    initializeDateFormatting('ja_JP', null);
    
    // Initialize focusedDay to be within the valid range
    final now = DateTime.now();
    final startDate = widget.experiment.experimentPeriodStart ?? now;
    final endDate = widget.experiment.experimentPeriodEnd ?? now.add(const Duration(days: 365));
    
    // Ensure focusedDay is within the valid range
    if (now.isBefore(startDate)) {
      _focusedDay = startDate;
    } else if (now.isAfter(endDate)) {
      _focusedDay = endDate;
    } else {
      _focusedDay = now;
    }
    
    if (widget.isDemo) {
      _generateDemoAvailability();
    }
  }

  void _generateDemoAvailability() {
    final bookings = <String, int>{};
    
    // 実験に設定された時間枠がある場合
    if (widget.experiment.timeSlots.isNotEmpty) {
      for (var slot in widget.experiment.timeSlots) {
        final key = '${slot.weekday}_${slot.timeRangeString}';
        // ランダムに0〜maxCapacityの間で予約済み人数を設定
        final booked = DateTime.now().microsecond % (slot.maxCapacity + 1);
        bookings[key] = booked;
      }
    } else {
      // 従来のデモデータ
      for (var daySlots in _demoTimeSlots.values) {
        for (var slot in daySlots) {
          // ランダムに0〜3の予約済み人数を設定
          bookings[slot] = DateTime.now().microsecond % 4;
        }
      }
    }
    
    setState(() {
      _demoBookedCounts = bookings;
    });
  }

  /// 選択した日の曜日を取得
  String _getWeekday(DateTime date) {
    final weekdays = ['月曜日', '火曜日', '水曜日', '木曜日', '金曜日', '土曜日', '日曜日'];
    return weekdays[date.weekday - 1];
  }

  /// 選択した日の時間枠を取得
  List<TimeSlot> _getTimeSlotsForDay(DateTime? day) {
    if (day == null) return [];
    
    // 日付ベースの時間枠が設定されている場合
    if (widget.experiment.dateTimeSlots.isNotEmpty) {
      final dateKey = DateTime(day.year, day.month, day.day);
      _selectedDateTimeSlots = widget.experiment.dateTimeSlots
          .where((slot) {
            final slotDate = DateTime(slot.date.year, slot.date.month, slot.date.day);
            return slotDate.isAtSameMomentAs(dateKey);
          })
          .toList();
      
      // DateTimeSlotをTimeSlotに変換（互換性のため）
      if (_selectedDateTimeSlots.isNotEmpty) {
        return _selectedDateTimeSlots.map((dateSlot) => TimeSlot(
          weekday: day.weekday,
          startTime: dateSlot.startTime,
          endTime: dateSlot.endTime,
          maxCapacity: dateSlot.maxCapacity,
          isAvailable: dateSlot.isAvailable,
        )).toList();
      }
    }
    
    // 従来の曜日ベースの時間枠が設定されている場合（互換性のため）
    if (widget.experiment.timeSlots.isNotEmpty) {
      // 該当する曜日の時間枠を取得（月曜日=1, 日曜日=7）
      final weekdaySlots = widget.experiment.timeSlots
          .where((slot) => slot.weekday == day.weekday)
          .toList();
      
      if (weekdaySlots.isNotEmpty) {
        return weekdaySlots;
      }
    }
    
    // デモモードまたは時間枠が設定されていない場合は従来の処理
    final weekday = _getWeekday(day);
    // 土日は予約不可
    if (weekday == '土曜日' || weekday == '日曜日') {
      return [];
    }
    
    // デフォルトの時間枠を作成
    final defaultSlots = _demoTimeSlots[weekday] ?? [];
    return defaultSlots.map((timeString) {
      final parts = timeString.split('-');
      final startParts = parts[0].split(':');
      final endParts = parts[1].split(':');
      return TimeSlot(
        weekday: day.weekday,
        startTime: TimeOfDay(hour: int.parse(startParts[0]), minute: int.parse(startParts[1])),
        endTime: TimeOfDay(hour: int.parse(endParts[0]), minute: int.parse(endParts[1])),
        maxCapacity: widget.experiment.simultaneousCapacity,
      );
    }).toList();
  }

  /// イベントがある日かどうか（予約可能な日）
  List<String> _getEventsForDay(DateTime day) {
    // 日付ベースの時間枠がある場合
    if (widget.experiment.dateTimeSlots.isNotEmpty) {
      final dateKey = DateTime(day.year, day.month, day.day);
      final hasSlots = widget.experiment.dateTimeSlots.any((slot) {
        final slotDate = DateTime(slot.date.year, slot.date.month, slot.date.day);
        return slotDate.isAtSameMomentAs(dateKey);
      });
      return hasSlots ? ['available'] : [];
    }
    
    // 従来の曜日ベースの処理（互換性のため）
    final weekday = _getWeekday(day);
    if (weekday == '土曜日' || weekday == '日曜日') {
      return [];
    }
    
    // 実施期間内かチェック
    if (widget.experiment.experimentPeriodStart != null &&
        widget.experiment.experimentPeriodEnd != null) {
      if (day.isBefore(widget.experiment.experimentPeriodStart!) ||
          day.isAfter(widget.experiment.experimentPeriodEnd!)) {
        return [];
      }
    }
    
    return ['available'];
  }

  /// 日付選択時の処理
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _selectedDayTimeSlots = _getTimeSlotsForDay(selectedDay);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedDay != null && _selectedDayTimeSlots.isEmpty) {
      _selectedDayTimeSlots = _getTimeSlotsForDay(_selectedDay);
    }
    
    // Ensure we have valid dates for the calendar
    final firstDay = widget.experiment.experimentPeriodStart ?? DateTime.now();
    final lastDay = widget.experiment.experimentPeriodEnd ?? 
        DateTime.now().add(const Duration(days: 365));
    
    // Ensure firstDay is before lastDay
    final validLastDay = lastDay.isAfter(firstDay) ? lastDay : firstDay.add(const Duration(days: 30));
    
    return Column(
      children: [
        // カレンダー
        Card(
          margin: const EdgeInsets.all(8),
          child: TableCalendar<String>(
            firstDay: firstDay,
            lastDay: validLastDay,
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            eventLoader: _getEventsForDay,
            startingDayOfWeek: StartingDayOfWeek.sunday,
            locale: 'ja_JP',
            availableCalendarFormats: const {
              CalendarFormat.month: '月',
              CalendarFormat.twoWeeks: '2週間',
              CalendarFormat.week: '週',
            },
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              weekendTextStyle: const TextStyle(color: Colors.red),
              selectedDecoration: const BoxDecoration(
                color: Color(0xFF8E1728),
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              markersMaxCount: 1,
              markerSize: 6,
              markerMargin: const EdgeInsets.only(top: 8),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
              formatButtonDecoration: BoxDecoration(
                color: Color(0xFF8E1728),
                borderRadius: BorderRadius.all(Radius.circular(12.0)),
              ),
              formatButtonTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
              titleTextStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            onDaySelected: _onDaySelected,
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarBuilders: CalendarBuilders(
              dowBuilder: (context, day) {
                final weekdays = ['日', '月', '火', '水', '木', '金', '土'];
                // day.weekday: 1=月曜日, 7=日曜日
                // 日曜日を0番目にするための変換
                final index = day.weekday == 7 ? 0 : day.weekday;
                final weekday = weekdays[index];
                final isWeekend = day.weekday == DateTime.saturday || 
                                 day.weekday == DateTime.sunday;
                
                return Center(
                  child: Text(
                    weekday,
                    style: TextStyle(
                      color: isWeekend ? Colors.red : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                );
              },
              disabledBuilder: (context, day, focusedDay) {
                return Container(
                  margin: const EdgeInsets.all(4),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${day.day}',
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                );
              },
            ),
          ),
        ),
        
        // 選択した日のスロット一覧
        if (_selectedDay != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.schedule, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${_selectedDay!.year}年${_selectedDay!.month.toString().padLeft(2, '0')}月${_selectedDay!.day.toString().padLeft(2, '0')}日',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_selectedDayTimeSlots.isNotEmpty)
                  Text(
                    '${_selectedDayTimeSlots.length}枠あり',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          
          if (_selectedDayTimeSlots.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'この日に予約可能な枠はありません',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            SizedBox(
              height: 200,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _selectedDayTimeSlots.length,
                itemBuilder: (context, index) {
                  final timeSlot = _selectedDayTimeSlots[index];
                  final slotKey = '${timeSlot.weekday}_${timeSlot.timeRangeString}';
                  
                  // 予約済み人数を取得
                  final bookedCount = widget.isDemo 
                    ? (_demoBookedCounts[slotKey] ?? _demoBookedCounts[timeSlot.timeRangeString] ?? 0)
                    : 0;
                  
                  // 空き枠数を計算
                  final availableSlots = timeSlot.maxCapacity - bookedCount;
                  final isAvailable = availableSlots > 0;
                  
                  // 満席率に応じて色を変える
                  Color getAvailabilityColor() {
                    final ratio = bookedCount / timeSlot.maxCapacity;
                    if (ratio >= 1.0) return Colors.grey;
                    if (ratio >= 0.75) return Colors.orange;
                    if (ratio >= 0.5) return Colors.amber;
                    return Colors.green;
                  }
                  
                  final availabilityColor = getAvailabilityColor();
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            backgroundColor: availabilityColor.withValues(alpha: 0.2),
                            child: Icon(
                              isAvailable ? Icons.group : Icons.block,
                              color: availabilityColor,
                              size: 20,
                            ),
                          ),
                          if (timeSlot.maxCapacity > 1)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: availabilityColor,
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  timeSlot.maxCapacity.toString(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: availabilityColor,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      title: Row(
                        children: [
                          Text(
                            timeSlot.timeRangeString,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isAvailable ? null : Colors.grey,
                            ),
                          ),
                          if (timeSlot.maxCapacity > 1) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8E1728).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '同時${timeSlot.maxCapacity}名',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF8E1728),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 14,
                            color: availabilityColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isAvailable 
                              ? '${bookedCount}/${timeSlot.maxCapacity}名予約済み (残り$availableSlots枠)'
                              : '満員 (${timeSlot.maxCapacity}/${timeSlot.maxCapacity}名)',
                            style: TextStyle(
                              color: availabilityColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      trailing: isAvailable
                        ? ElevatedButton(
                            onPressed: () => widget.onSlotSelected(_selectedDay!, timeSlot.timeRangeString),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8E1728),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('予約'),
                          )
                        : null,
                      onTap: isAvailable 
                        ? () => widget.onSlotSelected(_selectedDay!, timeSlot.timeRangeString)
                        : null,
                    ),
                  );
                },
              ),
            ),
        ],
      ],
    );
  }
}