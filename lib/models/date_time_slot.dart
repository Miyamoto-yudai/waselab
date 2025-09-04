import 'package:flutter/material.dart';

/// 日付ベースの時間枠を表すモデルクラス
class DateTimeSlot {
  final DateTime date; // 特定の日付
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final int maxCapacity; // 同時実験可能人数
  final bool isAvailable;
  final String? id; // Firestore用のドキュメントID

  DateTimeSlot({
    required this.date,
    required this.startTime,
    required this.endTime,
    this.maxCapacity = 1,
    this.isAvailable = true,
    this.id,
  });

  /// 日付をyyyy-MM-dd形式で取得
  String get dateString {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 日付を日本語形式で取得
  String get dateStringJa {
    const weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    final weekday = weekdays[date.weekday - 1];
    return '${date.month}月${date.day}日($weekday)';
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

  /// この時間枠の開始日時を取得
  DateTime get startDateTime {
    return DateTime(
      date.year,
      date.month,
      date.day,
      startTime.hour,
      startTime.minute,
    );
  }

  /// この時間枠の終了日時を取得
  DateTime get endDateTime {
    return DateTime(
      date.year,
      date.month,
      date.day,
      endTime.hour,
      endTime.minute,
    );
  }

  /// JSONに変換
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'startHour': startTime.hour,
      'startMinute': startTime.minute,
      'endHour': endTime.hour,
      'endMinute': endTime.minute,
      'maxCapacity': maxCapacity,
      'isAvailable': isAvailable,
      if (id != null) 'id': id,
    };
  }

  /// JSONから作成
  factory DateTimeSlot.fromJson(Map<String, dynamic> json) {
    return DateTimeSlot(
      date: DateTime.parse(json['date']),
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
      id: json['id'],
    );
  }

  /// コピーを作成
  DateTimeSlot copyWith({
    DateTime? date,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    int? maxCapacity,
    bool? isAvailable,
    String? id,
  }) {
    return DateTimeSlot(
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      maxCapacity: maxCapacity ?? this.maxCapacity,
      isAvailable: isAvailable ?? this.isAvailable,
      id: id ?? this.id,
    );
  }

  @override
  String toString() {
    return '$dateStringJa $timeRangeString (最大$maxCapacity名)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DateTimeSlot &&
        other.date == date &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.maxCapacity == maxCapacity &&
        other.isAvailable == isAvailable;
  }

  @override
  int get hashCode {
    return Object.hash(date, startTime, endTime, maxCapacity, isAvailable);
  }
}