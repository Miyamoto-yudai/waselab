import 'package:cloud_firestore/cloud_firestore.dart';
import 'time_slot.dart';

/// 実験種別
enum ExperimentType {
  online('オンライン'),
  onsite('対面'),
  survey('アンケートのみ');

  final String label;
  const ExperimentType(this.label);
}

/// 実験ステータス
enum ExperimentStatus {
  recruiting('募集中'),
  ongoing('進行中'),
  completed('完了');

  final String label;
  const ExperimentStatus(this.label);
}

/// 実験データモデル
class Experiment {
  final String id;
  final String title;           // 実験タイトル
  final String description;      // 実験概要（カードに表示）
  final String? detailedContent; // 詳細内容（詳細画面のみ表示）
  final int reward;             // 報酬（円）
  final String location;         // 場所
  final ExperimentType type;     // 種別
  final bool isPaid;            // 有償/無償
  final String creatorId;       // 作成者ID
  final DateTime createdAt;      // 作成日時
  final DateTime? recruitmentStartDate; // 募集開始日
  final DateTime? recruitmentEndDate;   // 募集終了日
  final DateTime? experimentPeriodStart; // 実験実施期間開始
  final DateTime? experimentPeriodEnd;   // 実験実施期間終了
  final bool allowFlexibleSchedule;      // 柔軟なスケジュール調整可能
  final String? labName;         // 研究室名
  final int? duration;          // 所要時間（分）
  final int? maxParticipants;   // 最大参加者数
  final List<String> requirements; // 参加条件
  final List<String> participants; // 参加者IDリスト
  final List<TimeSlot> timeSlots; // 利用可能な時間枠リスト
  final int simultaneousCapacity; // 同時実験可能人数（デフォルト1）
  final DateTime? fixedExperimentDate; // 固定日時の場合の実施日
  final Map<String, int>? fixedExperimentTime; // 固定日時の場合の実施時刻
  final int reservationDeadlineDays; // 予約締切日数（デフォルト1日前）
  
  // 旧フィールドとの互換性のため
  DateTime? get experimentDate => recruitmentStartDate;
  DateTime? get endDate => recruitmentEndDate;

  Experiment({
    required this.id,
    required this.title,
    required this.description,
    this.detailedContent,
    required this.reward,
    required this.location,
    required this.type,
    required this.isPaid,
    required this.creatorId,
    required this.createdAt,
    this.recruitmentStartDate,
    this.recruitmentEndDate,
    this.experimentPeriodStart,
    this.experimentPeriodEnd,
    this.allowFlexibleSchedule = false,
    this.labName,
    this.duration,
    this.maxParticipants,
    this.requirements = const [],
    this.participants = const [],
    this.timeSlots = const [],
    this.simultaneousCapacity = 1,
    this.fixedExperimentDate,
    this.fixedExperimentTime,
    this.reservationDeadlineDays = 1,
  });

  /// FirestoreのドキュメントからExperimentを作成
  factory Experiment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Experiment(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      detailedContent: data['detailedContent'],
      reward: data['reward'] ?? 0,
      location: data['location'] ?? '',
      type: ExperimentType.values.firstWhere(
        (e) => e.name == (data['type'] ?? 'online'),
        orElse: () => ExperimentType.online,
      ),
      isPaid: data['isPaid'] ?? false,
      creatorId: data['creatorId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      recruitmentStartDate: (data['recruitmentStartDate'] as Timestamp?)?.toDate() ??
          (data['experimentDate'] as Timestamp?)?.toDate(), // 旧フィールドとの互換性
      recruitmentEndDate: (data['recruitmentEndDate'] as Timestamp?)?.toDate() ??
          (data['endDate'] as Timestamp?)?.toDate(), // 旧フィールドとの互換性
      experimentPeriodStart: (data['experimentPeriodStart'] as Timestamp?)?.toDate(),
      experimentPeriodEnd: (data['experimentPeriodEnd'] as Timestamp?)?.toDate(),
      allowFlexibleSchedule: data['allowFlexibleSchedule'] ?? false,
      labName: data['labName'],
      duration: data['duration'],
      maxParticipants: data['maxParticipants'],
      requirements: List<String>.from(data['requirements'] ?? []),
      participants: List<String>.from(data['participants'] ?? []),
      timeSlots: (data['timeSlots'] as List<dynamic>?)
          ?.map((slot) => TimeSlot.fromJson(slot as Map<String, dynamic>))
          .toList() ?? [],
      simultaneousCapacity: data['simultaneousCapacity'] ?? 1,
      fixedExperimentDate: (data['fixedExperimentDate'] as Timestamp?)?.toDate(),
      fixedExperimentTime: data['fixedExperimentTime'] != null
          ? Map<String, int>.from(data['fixedExperimentTime'] as Map)
          : null,
      reservationDeadlineDays: data['reservationDeadlineDays'] ?? 1,
    );
  }

  /// ExperimentをFirestoreに保存する形式に変換
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'detailedContent': detailedContent,
      'reward': reward,
      'location': location,
      'type': type.name,
      'isPaid': isPaid,
      'creatorId': creatorId,
      'createdAt': Timestamp.fromDate(createdAt),
      'recruitmentStartDate': recruitmentStartDate != null 
        ? Timestamp.fromDate(recruitmentStartDate!) 
        : null,
      'recruitmentEndDate': recruitmentEndDate != null
        ? Timestamp.fromDate(recruitmentEndDate!)
        : null,
      'experimentPeriodStart': experimentPeriodStart != null
        ? Timestamp.fromDate(experimentPeriodStart!)
        : null,
      'experimentPeriodEnd': experimentPeriodEnd != null
        ? Timestamp.fromDate(experimentPeriodEnd!)
        : null,
      'allowFlexibleSchedule': allowFlexibleSchedule,
      'labName': labName,
      'duration': duration,
      'maxParticipants': maxParticipants,
      'requirements': requirements,
      'participants': participants,
      'timeSlots': timeSlots.map((slot) => slot.toJson()).toList(),
      'simultaneousCapacity': simultaneousCapacity,
      'fixedExperimentDate': fixedExperimentDate != null
        ? Timestamp.fromDate(fixedExperimentDate!)
        : null,
      'fixedExperimentTime': fixedExperimentTime,
      'reservationDeadlineDays': reservationDeadlineDays,
    };
  }
}