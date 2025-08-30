import 'package:flutter/material.dart';

/// 時間枠を表すモデルクラス
class TimeSlot {
  final int weekday; // 1=月曜日, 2=火曜日, ..., 7=日曜日
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final int maxCapacity; // 同時実験可能人数
  final bool isAvailable;

  TimeSlot({
    required this.weekday,
    required this.startTime,
    required this.endTime,
    this.maxCapacity = 1,
    this.isAvailable = true,
  });

  /// 曜日名を取得
  String get weekdayName {
    const weekdays = ['月曜日', '火曜日', '水曜日', '木曜日', '金曜日', '土曜日', '日曜日'];
    return weekdays[weekday - 1];
  }

  /// 時間範囲を文字列で取得
  String get timeRangeString {
    final start = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final end = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    return '$start-$end';
  }

  /// 所要時間（分）を計算
  int get durationInMinutes {
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    return endMinutes - startMinutes;
  }

  /// JSONに変換
  Map<String, dynamic> toJson() {
    return {
      'weekday': weekday,
      'startHour': startTime.hour,
      'startMinute': startTime.minute,
      'endHour': endTime.hour,
      'endMinute': endTime.minute,
      'maxCapacity': maxCapacity,
      'isAvailable': isAvailable,
    };
  }

  /// JSONから作成
  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      weekday: json['weekday'] ?? 1,
      startTime: TimeOfDay(
        hour: json['startHour'] ?? 9,
        minute: json['startMinute'] ?? 0,
      ),
      endTime: TimeOfDay(
        hour: json['endHour'] ?? 10,
        minute: json['endMinute'] ?? 0,
      ),
      maxCapacity: json['maxCapacity'] ?? 1,
      isAvailable: json['isAvailable'] ?? true,
    );
  }

  /// コピーを作成
  TimeSlot copyWith({
    int? weekday,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    int? maxCapacity,
    bool? isAvailable,
  }) {
    return TimeSlot(
      weekday: weekday ?? this.weekday,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      maxCapacity: maxCapacity ?? this.maxCapacity,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  @override
  String toString() {
    return '$weekdayName $timeRangeString (最大$maxCapacity名)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimeSlot &&
        other.weekday == weekday &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.maxCapacity == maxCapacity &&
        other.isAvailable == isAvailable;
  }

  @override
  int get hashCode {
    return Object.hash(weekday, startTime, endTime, maxCapacity, isAvailable);
  }
}

/// 時間枠のテンプレート
class TimeSlotTemplate {
  final String name;
  final List<TimeSlot> slots;

  const TimeSlotTemplate({
    required this.name,
    required this.slots,
  });

  /// プリセットテンプレート：平日午前
  static TimeSlotTemplate get weekdayMorning => TimeSlotTemplate(
    name: '平日午前',
    slots: List.generate(5, (index) => TimeSlot(
      weekday: index + 1, // 月〜金
      startTime: const TimeOfDay(hour: 9, minute: 0),
      endTime: const TimeOfDay(hour: 12, minute: 0),
      maxCapacity: 1,
    )),
  );

  /// プリセットテンプレート：平日午後
  static TimeSlotTemplate get weekdayAfternoon => TimeSlotTemplate(
    name: '平日午後',
    slots: List.generate(5, (index) => TimeSlot(
      weekday: index + 1, // 月〜金
      startTime: const TimeOfDay(hour: 13, minute: 0),
      endTime: const TimeOfDay(hour: 17, minute: 0),
      maxCapacity: 1,
    )),
  );

  /// プリセットテンプレート：平日終日
  static TimeSlotTemplate get weekdayAllDay => TimeSlotTemplate(
    name: '平日終日',
    slots: List.generate(5, (index) => [
      TimeSlot(
        weekday: index + 1,
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 12, minute: 0),
        maxCapacity: 1,
      ),
      TimeSlot(
        weekday: index + 1,
        startTime: const TimeOfDay(hour: 13, minute: 0),
        endTime: const TimeOfDay(hour: 17, minute: 0),
        maxCapacity: 1,
      ),
    ]).expand((e) => e).toList(),
  );

  /// プリセットテンプレート：1時間枠（平日）
  static TimeSlotTemplate get hourlySlots => TimeSlotTemplate(
    name: '1時間枠（平日）',
    slots: List.generate(5, (day) => List.generate(8, (hour) => TimeSlot(
      weekday: day + 1,
      startTime: TimeOfDay(hour: 9 + hour, minute: 0),
      endTime: TimeOfDay(hour: 10 + hour, minute: 0),
      maxCapacity: 1,
    ))).expand((e) => e).toList(),
  );
}