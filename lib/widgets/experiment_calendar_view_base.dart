import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../models/experiment.dart';

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

  // デモ用の予約状況（ランダムに空き状況を生成）
  Map<String, int> _demoAvailability = {};

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
    final slots = <String, int>{};
    for (var daySlots in _demoTimeSlots.values) {
      for (var slot in daySlots) {
        // ランダムに0〜3の空き枠を設定
        slots[slot] = (DateTime.now().microsecond % 4);
      }
    }
    setState(() {
      _demoAvailability = slots;
    });
  }

  /// 選択した日の曜日を取得
  String _getWeekday(DateTime date) {
    final weekdays = ['月曜日', '火曜日', '水曜日', '木曜日', '金曜日', '土曜日', '日曜日'];
    return weekdays[date.weekday - 1];
  }

  /// 選択した日の時間枠を取得
  List<String> _getTimeSlotsForDay(DateTime? day) {
    if (day == null) return [];
    
    final weekday = _getWeekday(day);
    // 土日は予約不可
    if (weekday == '土曜日' || weekday == '日曜日') {
      return [];
    }
    
    if (widget.isDemo) {
      return _demoTimeSlots[weekday] ?? [];
    } else {
      // 本番環境ではFirebaseから取得する処理を追加
      return _demoTimeSlots[weekday] ?? [];
    }
  }

  /// イベントがある日かどうか（予約可能な日）
  List<String> _getEventsForDay(DateTime day) {
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedDaySlots = _getTimeSlotsForDay(_selectedDay);
    
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
                final weekday = weekdays[day.weekday % 7];
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
                if (selectedDaySlots.isNotEmpty)
                  Text(
                    '${selectedDaySlots.length}枠あり',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          
          if (selectedDaySlots.isEmpty)
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
                itemCount: selectedDaySlots.length,
                itemBuilder: (context, index) {
                  final slot = selectedDaySlots[index];
                  final availability = widget.isDemo ? (_demoAvailability[slot] ?? 0) : 3;
                  final isAvailable = availability > 0;
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isAvailable 
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.grey.withValues(alpha: 0.2),
                        child: Icon(
                          isAvailable ? Icons.check_circle : Icons.block,
                          color: isAvailable ? Colors.green : Colors.grey,
                        ),
                      ),
                      title: Text(
                        slot,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isAvailable ? null : Colors.grey,
                        ),
                      ),
                      subtitle: Text(
                        isAvailable 
                          ? '残り$availability枠'
                          : '満員',
                        style: TextStyle(
                          color: isAvailable ? Colors.green : Colors.grey,
                        ),
                      ),
                      trailing: isAvailable
                        ? ElevatedButton(
                            onPressed: () => widget.onSlotSelected(_selectedDay!, slot),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8E1728),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('予約'),
                          )
                        : null,
                      onTap: isAvailable 
                        ? () => widget.onSlotSelected(_selectedDay!, slot)
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