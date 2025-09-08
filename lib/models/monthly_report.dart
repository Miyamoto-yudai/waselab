import 'package:cloud_firestore/cloud_firestore.dart';

class MonthlyReport {
  final String userId;
  final String userName;
  final int year;
  final int month;
  final int totalExperiments;
  final int totalEarnings;
  final int totalMinutes;
  final int onlineExperiments;
  final int offlineExperiments;
  final int labExperiments;
  final int fieldExperiments;
  final int goodEvaluations;
  final int badEvaluations;
  final List<ExperimentSummary> experiments;
  final DateTime createdAt;

  MonthlyReport({
    required this.userId,
    required this.userName,
    required this.year,
    required this.month,
    required this.totalExperiments,
    required this.totalEarnings,
    required this.totalMinutes,
    required this.onlineExperiments,
    required this.offlineExperiments,
    required this.labExperiments,
    required this.fieldExperiments,
    required this.goodEvaluations,
    required this.badEvaluations,
    required this.experiments,
    required this.createdAt,
  });

  factory MonthlyReport.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MonthlyReport(
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      year: data['year'] ?? 0,
      month: data['month'] ?? 0,
      totalExperiments: data['totalExperiments'] ?? 0,
      totalEarnings: data['totalEarnings'] ?? 0,
      totalMinutes: data['totalMinutes'] ?? 0,
      onlineExperiments: data['onlineExperiments'] ?? 0,
      offlineExperiments: data['offlineExperiments'] ?? 0,
      labExperiments: data['labExperiments'] ?? 0,
      fieldExperiments: data['fieldExperiments'] ?? 0,
      goodEvaluations: data['goodEvaluations'] ?? 0,
      badEvaluations: data['badEvaluations'] ?? 0,
      experiments: (data['experiments'] as List<dynamic>?)
          ?.map((e) => ExperimentSummary.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'year': year,
      'month': month,
      'totalExperiments': totalExperiments,
      'totalEarnings': totalEarnings,
      'totalMinutes': totalMinutes,
      'onlineExperiments': onlineExperiments,
      'offlineExperiments': offlineExperiments,
      'labExperiments': labExperiments,
      'fieldExperiments': fieldExperiments,
      'goodEvaluations': goodEvaluations,
      'badEvaluations': badEvaluations,
      'experiments': experiments.map((e) => e.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  double get averageEarningsPerExperiment {
    if (totalExperiments == 0) return 0;
    return totalEarnings / totalExperiments;
  }

  double get averageMinutesPerExperiment {
    if (totalExperiments == 0) return 0;
    return totalMinutes / totalExperiments;
  }

  double get goodEvaluationRate {
    final total = goodEvaluations + badEvaluations;
    if (total == 0) return 0;
    return (goodEvaluations / total) * 100;
  }

  String get monthLabel {
    return '$year年$month月';
  }
}

class ExperimentSummary {
  final String experimentId;
  final String title;
  final String experimentType;
  final String locationType;
  final DateTime participationDate;
  final int reward;
  final int duration;
  final String? evaluation;
  final String? comment;

  ExperimentSummary({
    required this.experimentId,
    required this.title,
    required this.experimentType,
    required this.locationType,
    required this.participationDate,
    required this.reward,
    required this.duration,
    this.evaluation,
    this.comment,
  });

  factory ExperimentSummary.fromMap(Map<String, dynamic> map) {
    return ExperimentSummary(
      experimentId: map['experimentId'] ?? '',
      title: map['title'] ?? '',
      experimentType: map['experimentType'] ?? '',
      locationType: map['locationType'] ?? '',
      participationDate: (map['participationDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reward: map['reward'] ?? 0,
      duration: map['duration'] ?? 0,
      evaluation: map['evaluation'],
      comment: map['comment'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'experimentId': experimentId,
      'title': title,
      'experimentType': experimentType,
      'locationType': locationType,
      'participationDate': Timestamp.fromDate(participationDate),
      'reward': reward,
      'duration': duration,
      'evaluation': evaluation,
      'comment': comment,
    };
  }
}