import 'package:cloud_firestore/cloud_firestore.dart';

/// 実験予約枠のモデル
class ExperimentSlot {
  final String id;
  final String experimentId;     // 実験ID
  final DateTime startTime;      // 開始時刻
  final DateTime endTime;        // 終了時刻
  final int maxParticipants;    // 最大参加者数
  final int currentParticipants; // 現在の参加者数
  final bool isAvailable;       // 予約可能かどうか
  final String? note;           // 備考（オプション）

  ExperimentSlot({
    required this.id,
    required this.experimentId,
    required this.startTime,
    required this.endTime,
    required this.maxParticipants,
    this.currentParticipants = 0,
    this.isAvailable = true,
    this.note,
  });

  /// 残り枠数を計算
  int get availableSlots => maxParticipants - currentParticipants;

  /// 予約可能かどうかを判定
  bool get canReserve => isAvailable && availableSlots > 0 && startTime.isAfter(DateTime.now());

  /// FirestoreのドキュメントからExperimentSlotを作成
  factory ExperimentSlot.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ExperimentSlot(
      id: doc.id,
      experimentId: data['experimentId'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      maxParticipants: data['maxParticipants'] ?? 1,
      currentParticipants: data['currentParticipants'] ?? 0,
      isAvailable: data['isAvailable'] ?? true,
      note: data['note'],
    );
  }

  /// ExperimentSlotをFirestoreに保存する形式に変換
  Map<String, dynamic> toFirestore() {
    return {
      'experimentId': experimentId,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'maxParticipants': maxParticipants,
      'currentParticipants': currentParticipants,
      'isAvailable': isAvailable,
      'note': note,
    };
  }

  /// コピーを作成（一部のフィールドを更新）
  ExperimentSlot copyWith({
    String? id,
    String? experimentId,
    DateTime? startTime,
    DateTime? endTime,
    int? maxParticipants,
    int? currentParticipants,
    bool? isAvailable,
    String? note,
  }) {
    return ExperimentSlot(
      id: id ?? this.id,
      experimentId: experimentId ?? this.experimentId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      currentParticipants: currentParticipants ?? this.currentParticipants,
      isAvailable: isAvailable ?? this.isAvailable,
      note: note ?? this.note,
    );
  }
}