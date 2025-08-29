import 'package:cloud_firestore/cloud_firestore.dart';

/// 予約状態
enum ReservationStatus {
  pending('確認中'),
  confirmed('確定'),
  cancelled('キャンセル'),
  completed('完了');

  final String label;
  const ReservationStatus(this.label);
}

/// 実験予約のモデル
class ExperimentReservation {
  final String id;
  final String userId;           // 予約者のユーザーID
  final String experimentId;     // 実験ID
  final String slotId;          // 予約枠ID
  final DateTime reservedAt;     // 予約日時
  final ReservationStatus status; // 予約状態
  final String? cancelReason;    // キャンセル理由（オプション）
  final String? note;           // 備考（オプション）

  ExperimentReservation({
    required this.id,
    required this.userId,
    required this.experimentId,
    required this.slotId,
    required this.reservedAt,
    required this.status,
    this.cancelReason,
    this.note,
  });

  /// FirestoreのドキュメントからExperimentReservationを作成
  factory ExperimentReservation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ExperimentReservation(
      id: doc.id,
      userId: data['userId'] ?? '',
      experimentId: data['experimentId'] ?? '',
      slotId: data['slotId'] ?? '',
      reservedAt: (data['reservedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: ReservationStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'pending'),
        orElse: () => ReservationStatus.pending,
      ),
      cancelReason: data['cancelReason'],
      note: data['note'],
    );
  }

  /// ExperimentReservationをFirestoreに保存する形式に変換
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'experimentId': experimentId,
      'slotId': slotId,
      'reservedAt': Timestamp.fromDate(reservedAt),
      'status': status.name,
      'cancelReason': cancelReason,
      'note': note,
    };
  }

  /// コピーを作成（一部のフィールドを更新）
  ExperimentReservation copyWith({
    String? id,
    String? userId,
    String? experimentId,
    String? slotId,
    DateTime? reservedAt,
    ReservationStatus? status,
    String? cancelReason,
    String? note,
  }) {
    return ExperimentReservation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      experimentId: experimentId ?? this.experimentId,
      slotId: slotId ?? this.slotId,
      reservedAt: reservedAt ?? this.reservedAt,
      status: status ?? this.status,
      cancelReason: cancelReason ?? this.cancelReason,
      note: note ?? this.note,
    );
  }
}