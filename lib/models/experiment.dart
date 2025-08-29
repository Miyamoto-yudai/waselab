import 'package:cloud_firestore/cloud_firestore.dart';

/// 実験種別
enum ExperimentType {
  online('オンライン'),
  onsite('対面'),
  survey('アンケート');

  final String label;
  const ExperimentType(this.label);
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
  final DateTime? experimentDate; // 実験実施日時（募集開始日）
  final DateTime? endDate;       // 募集終了日
  final String? labName;         // 研究室名
  final int? duration;          // 所要時間（分）
  final int? maxParticipants;   // 最大参加者数
  final List<String> requirements; // 参加条件

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
    this.experimentDate,
    this.endDate,
    this.labName,
    this.duration,
    this.maxParticipants,
    this.requirements = const [],
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
      experimentDate: (data['experimentDate'] as Timestamp?)?.toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      labName: data['labName'],
      duration: data['duration'],
      maxParticipants: data['maxParticipants'],
      requirements: List<String>.from(data['requirements'] ?? []),
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
      'experimentDate': experimentDate != null 
        ? Timestamp.fromDate(experimentDate!) 
        : null,
      'endDate': endDate != null
        ? Timestamp.fromDate(endDate!)
        : null,
      'labName': labName,
      'duration': duration,
      'maxParticipants': maxParticipants,
      'requirements': requirements,
    };
  }
}