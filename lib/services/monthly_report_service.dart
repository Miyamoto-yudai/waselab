import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/monthly_report.dart';
import '../models/experiment.dart';
import '../models/experiment_reservation.dart';

class MonthlyReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<MonthlyReport?> getMonthlyReport(String userId, int year, int month) async {
    try {
      final reportDoc = await _firestore
          .collection('monthlyReports')
          .doc('${userId}_${year}_$month')
          .get();

      if (reportDoc.exists) {
        return MonthlyReport.fromFirestore(reportDoc);
      }

      // レポートが存在しない場合は生成
      return await generateMonthlyReport(userId, year, month);
    } catch (e) {
      print('月次レポート取得エラー: $e');
      return null;
    }
  }

  Future<MonthlyReport?> generateMonthlyReport(String userId, int year, int month) async {
    try {
      // ユーザー情報を取得
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return null;
      
      final userData = userDoc.data()!;
      final userName = userData['name'] ?? 'Unknown';

      // 指定月の開始日と終了日を計算
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

      // 該当月の予約データを取得
      final reservationsSnapshot = await _firestore
          .collection('reservations')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .get();

      List<ExperimentSummary> experiments = [];
      int totalExperiments = 0;
      int totalEarnings = 0;
      int totalMinutes = 0;
      int onlineExperiments = 0;
      int offlineExperiments = 0;
      int labExperiments = 0;
      int fieldExperiments = 0;
      int goodEvaluations = 0;
      int badEvaluations = 0;

      for (var reservationDoc in reservationsSnapshot.docs) {
        final reservation = ExperimentReservation.fromFirestore(reservationDoc);
        
        // 予約日時が指定月に含まれるかチェック
        if (reservation.reservedAt.isBefore(startDate) || 
            reservation.reservedAt.isAfter(endDate)) {
          continue;
        }

        // 実験情報を取得
        final experimentDoc = await _firestore
            .collection('experiments')
            .doc(reservation.experimentId)
            .get();
        
        if (!experimentDoc.exists) continue;
        
        final experiment = Experiment.fromFirestore(experimentDoc);
        
        totalExperiments++;
        totalEarnings += experiment.reward;
        totalMinutes += experiment.duration ?? 0;

        // 実験タイプ別カウント
        if (experiment.type == ExperimentType.online) {
          onlineExperiments++;
        } else {
          offlineExperiments++;
        }

        // 研究室実験とフィールド実験の分類
        // location情報やラボ名から判定
        if (experiment.labName != null && experiment.labName!.isNotEmpty) {
          labExperiments++;
        } else {
          fieldExperiments++;
        }

        // 評価情報を取得
        final evaluationSnapshot = await _firestore
            .collection('evaluations')
            .where('evaluatedUserId', isEqualTo: userId)
            .where('experimentId', isEqualTo: reservation.experimentId)
            .get();

        String? evaluation;
        String? comment;
        
        if (evaluationSnapshot.docs.isNotEmpty) {
          final evalData = evaluationSnapshot.docs.first.data();
          evaluation = evalData['evaluation'];
          comment = evalData['comment'];
          
          if (evaluation == 'good') {
            goodEvaluations++;
          } else if (evaluation == 'bad') {
            badEvaluations++;
          }
        }

        experiments.add(ExperimentSummary(
          experimentId: reservation.experimentId,
          title: experiment.title,
          experimentType: experiment.labName != null ? 'lab' : 'field',
          locationType: experiment.type == ExperimentType.online ? 'online' : 'offline',
          participationDate: reservation.reservedAt,
          reward: experiment.reward,
          duration: experiment.duration ?? 0,
          evaluation: evaluation,
          comment: comment,
        ));
      }

      // レポートを作成
      final report = MonthlyReport(
        userId: userId,
        userName: userName,
        year: year,
        month: month,
        totalExperiments: totalExperiments,
        totalEarnings: totalEarnings,
        totalMinutes: totalMinutes,
        onlineExperiments: onlineExperiments,
        offlineExperiments: offlineExperiments,
        labExperiments: labExperiments,
        fieldExperiments: fieldExperiments,
        goodEvaluations: goodEvaluations,
        badEvaluations: badEvaluations,
        experiments: experiments,
        createdAt: DateTime.now(),
      );

      // Firestoreに保存
      await _firestore
          .collection('monthlyReports')
          .doc('${userId}_${year}_$month')
          .set(report.toFirestore());

      return report;
    } catch (e) {
      print('月次レポート生成エラー: $e');
      return null;
    }
  }

  Future<List<MonthlyReport>> getUserReports(String userId, {int limit = 12}) async {
    try {
      final snapshot = await _firestore
          .collection('monthlyReports')
          .where('userId', isEqualTo: userId)
          .orderBy('year', descending: true)
          .orderBy('month', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => MonthlyReport.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('ユーザーレポート取得エラー: $e');
      return [];
    }
  }

  Future<List<int>> getAvailableReportMonths(String userId) async {
    try {
      // 完了済み予約を取得して利用可能な月を判定
      final reservationsSnapshot = await _firestore
          .collection('reservations')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .get();

      Set<int> availableMonths = {};
      
      for (var doc in reservationsSnapshot.docs) {
        final reservation = ExperimentReservation.fromFirestore(doc);
        final yearMonth = reservation.reservedAt.year * 100 + reservation.reservedAt.month;
        availableMonths.add(yearMonth);
      }

      return availableMonths.toList()..sort((a, b) => b.compareTo(a));
    } catch (e) {
      print('利用可能な月取得エラー: $e');
      return [];
    }
  }
}