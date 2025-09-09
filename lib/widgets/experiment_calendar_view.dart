import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/experiment.dart';
import '../models/experiment_slot.dart';
import '../services/reservation_service.dart';

/// 実験予約カレンダービュー
class ExperimentCalendarView extends StatefulWidget {
  final Experiment experiment;
  final Function(ExperimentSlot) onSlotSelected;

  const ExperimentCalendarView({
    super.key,
    required this.experiment,
    required this.onSlotSelected,
  });

  @override
  State<ExperimentCalendarView> createState() => _ExperimentCalendarViewState();
}

class _ExperimentCalendarViewState extends State<ExperimentCalendarView> {
  final ReservationService _reservationService = ReservationService();
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  Map<DateTime, List<ExperimentSlot>> _slotsByDate = {};
  List<ExperimentSlot> _selectedDaySlots = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // firstDayとfocusedDayを適切に初期化
    final firstDay = widget.experiment.experimentPeriodStart ?? DateTime.now();
    final now = DateTime.now();
    _focusedDay = now.isBefore(firstDay) ? firstDay : now;
    _loadSlots();
  }

  /// スロットデータを読み込む
  Future<void> _loadSlots() async {
    setState(() => _isLoading = true);
    
    try {
      // 実験期間を取得
      final startDate = widget.experiment.experimentPeriodStart ?? DateTime.now();
      final endDate = widget.experiment.experimentPeriodEnd ?? 
          DateTime.now().add(const Duration(days: 30));
      
      debugPrint('Loading slots for experiment: ${widget.experiment.id}');
      debugPrint('Period: $startDate to $endDate');
      
      // 期間内の全スロットを取得
      DateTime currentDate = startDate;
      final Map<DateTime, List<ExperimentSlot>> tempSlots = {};
      
      while (!currentDate.isAfter(endDate)) {
        try {
          final slots = await _reservationService.getSlotsByDate(
            widget.experiment.id, 
            currentDate,
          );
          
          if (slots.isNotEmpty) {
            final dateKey = DateTime(currentDate.year, currentDate.month, currentDate.day);
            tempSlots[dateKey] = slots;
            debugPrint('Found ${slots.length} slots for $dateKey');
          }
        } catch (e) {
          debugPrint('Error loading slots for $currentDate: $e');
          // 個別の日付でエラーが発生しても続行
        }
        
        currentDate = currentDate.add(const Duration(days: 1));
      }
      
      debugPrint('Total dates with slots: ${tempSlots.length}');
      
      setState(() {
        _slotsByDate = tempSlots;
        _isLoading = false;
      });
      
      // スロットが見つからない場合の警告
      if (tempSlots.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('この実験には予約可能な日時がまだ設定されていません'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error in _loadSlots: $e');
      debugPrint('StackTrace: $stackTrace');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('データの読み込みに失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 特定の日付のスロットを取得
  List<ExperimentSlot> _getSlotsForDay(DateTime day) {
    final dateKey = DateTime(day.year, day.month, day.day);
    return _slotsByDate[dateKey] ?? [];
  }

  /// 日付選択時の処理
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _selectedDaySlots = _getSlotsForDay(selectedDay);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // カレンダー
        Card(
          margin: const EdgeInsets.all(8),
          child: TableCalendar<ExperimentSlot>(
            firstDay: widget.experiment.experimentPeriodStart ?? DateTime.now(),
            lastDay: widget.experiment.experimentPeriodEnd ?? 
                DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay.isAfter(widget.experiment.experimentPeriodEnd ?? DateTime.now().add(const Duration(days: 365))) 
                ? widget.experiment.experimentPeriodEnd ?? DateTime.now().add(const Duration(days: 365))
                : _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            eventLoader: _getSlotsForDay,
            startingDayOfWeek: StartingDayOfWeek.sunday,
            locale: 'ja_JP',
            calendarStyle: const CalendarStyle(
              outsideDaysVisible: false,
              weekendTextStyle: TextStyle(color: Colors.red),
              selectedDecoration: BoxDecoration(
                color: Color(0xFF8E1728),
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Colors.grey,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            onDaySelected: _onDaySelected,
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                if (events.isNotEmpty) {
                  final availableSlots = events.where((e) => e.canReserve).length;
                  return Positioned(
                    bottom: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: availableSlots > 0 ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                      width: 7,
                      height: 7,
                    ),
                  );
                }
                return null;
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
                  DateFormat('yyyy年MM月dd日(E)', 'ja').format(_selectedDay!),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_selectedDaySlots.isNotEmpty)
                  Text(
                    '${_selectedDaySlots.where((s) => s.canReserve).length}枠空き',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_selectedDaySlots.isEmpty)
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
                itemCount: _selectedDaySlots.length,
                itemBuilder: (context, index) {
                  final slot = _selectedDaySlots[index];
                  final timeFormat = DateFormat('HH:mm');
                  final isAvailable = slot.canReserve;
                  
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
                        '${timeFormat.format(slot.startTime)} - ${timeFormat.format(slot.endTime)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isAvailable ? null : Colors.grey,
                        ),
                      ),
                      subtitle: Text(
                        isAvailable 
                          ? '残り${slot.availableSlots}/${slot.maxParticipants}枠'
                          : slot.startTime.isBefore(DateTime.now())
                            ? '終了'
                            : '満員',
                        style: TextStyle(
                          color: isAvailable ? Colors.green : Colors.grey,
                        ),
                      ),
                      trailing: isAvailable
                        ? ElevatedButton(
                            onPressed: () => widget.onSlotSelected(slot),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8E1728),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('選択'),
                          )
                        : null,
                      onTap: isAvailable 
                        ? () => widget.onSlotSelected(slot)
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