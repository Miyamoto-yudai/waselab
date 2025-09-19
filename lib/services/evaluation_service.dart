import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/experiment.dart';
import '../models/experiment_evaluation.dart';
import 'user_service.dart';
import 'notification_service.dart';

class EvaluationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserService _userService = UserService();
  final NotificationService _notificationService = NotificationService();

  /// 評価を作成
  Future<void> createEvaluation({
    required String experimentId,
    required String evaluatorId,
    required String evaluatedUserId,
    required EvaluatorRole evaluatorRole,
    required EvaluationType type,
    String? comment,
  }) async {
    
    try {
      // まず実験を取得して検証
      final experimentDoc = await _firestore
          .collection('experiments')
          .doc(experimentId)
          .get();
      
      if (!experimentDoc.exists) {
        throw Exception('実験が見つかりません');
      }
      
      final experiment = Experiment.fromFirestore(experimentDoc);
      
      // 評価可能かチェック
      if (!experiment.canEvaluate(evaluatorId)) {
        throw Exception('この実験を評価する権限がありません');
      }
      
      // 既に評価済みかチェック
      if (experiment.hasEvaluated(evaluatorId)) {
        throw Exception('既に評価済みです');
      }
      
      // 評価を作成
      final evaluation = ExperimentEvaluation.create(
        experimentId: experimentId,
        evaluatorId: evaluatorId,
        evaluatedUserId: evaluatedUserId,
        evaluatorRole: evaluatorRole,
        type: type,
        comment: comment,
      );
      
      
      // evaluationsコレクションに評価を追加
      await _firestore.collection('evaluations').add(evaluation.toFirestore());
      
      
      // 実験のevaluationsフィールドを更新
      final evaluations = Map<String, Map<String, dynamic>>.from(
        experiment.evaluations ?? {},
      );
      evaluations[evaluatorId] = {
        'evaluated': true,
        'evaluationType': type.name,
        'evaluatedAt': Timestamp.fromDate(DateTime.now()),
      };
      
      // 実験ドキュメントを更新
      final updateData = <String, dynamic>{
        'evaluations': evaluations,
      };
      
      // まだ誰も評価していない場合（最初の評価）、ステータスを更新
      if (experiment.status != ExperimentStatus.waitingEvaluation && 
          experiment.status != ExperimentStatus.completed) {
        updateData['status'] = ExperimentStatus.waitingEvaluation.name;
        updateData['actualStartDate'] = Timestamp.fromDate(DateTime.now());
      }
      
      await _firestore.collection('experiments').doc(experimentId).update(updateData);
      
      
      // 無償実験の場合はポイントを3倍にする
      final pointsToAdd = type == EvaluationType.good ? 
          (experiment.isPaid ? 1 : 3) : 0;
      
      // 被評価者のユーザー統計を更新
      try {
        // まずユーザードキュメントが存在するか確認
        final userDoc = await _firestore.collection('users').doc(evaluatedUserId).get();
        
        if (userDoc.exists) {
          final userUpdateData = <String, dynamic>{};
          if (type == EvaluationType.good) {
            userUpdateData['goodCount'] = FieldValue.increment(1);
            userUpdateData['points'] = FieldValue.increment(pointsToAdd); // 有償:1ポイント、無償:3ポイント
          } else if (type == EvaluationType.bad) {
            userUpdateData['badCount'] = FieldValue.increment(1);
          }
          
          if (userUpdateData.isNotEmpty) {
            await _firestore.collection('users').doc(evaluatedUserId).update(userUpdateData);
          }
        } else {
          // ユーザードキュメントがない場合は作成
          await _firestore.collection('users').doc(evaluatedUserId).set({
            'goodCount': type == EvaluationType.good ? 1 : 0,
            'badCount': type == EvaluationType.bad ? 1 : 0,
            'points': pointsToAdd,
          }, SetOptions(merge: true));
        }
      } catch (userUpdateError) {
        // ユーザー統計の更新に失敗しても評価自体は成功とする
      }
      
      // 評価通知を送信
      try {
        // 評価者の名前を取得
        String evaluatorName = 'ユーザー';
        final evaluatorDoc = await _firestore.collection('users').doc(evaluatorId).get();
        if (evaluatorDoc.exists) {
          evaluatorName = evaluatorDoc.data()!['name'] as String? ?? 'ユーザー';
        }
        
        // 実験タイトルを取得
        final experimentTitle = experiment.title;
        
        // 評価された人に通知を送信
        await _notificationService.createEvaluationNotification(
          userId: evaluatedUserId,
          evaluatorName: evaluatorName,
          experimentTitle: experimentTitle,
          experimentId: experimentId,
          isGood: type == EvaluationType.good,
          pointsAwarded: pointsToAdd,
        );
      } catch (notificationError) {
      }
      
      // 個別の参加者評価状態を更新
      
      // participantEvaluationsフィールドを更新（実験者と参加者の個別評価管理）
      Map<String, dynamic> participantEvaluations = {};
      
      if (evaluatorRole == EvaluatorRole.experimenter) {
        // 実験者が参加者を評価した場合
        participantEvaluations = {
          'participantEvaluations.$evaluatedUserId.creatorEvaluated': true,
          'participantEvaluations.$evaluatedUserId.creatorEvaluatedAt': Timestamp.fromDate(DateTime.now()),
        };
      } else {
        // 参加者が実験者を評価した場合
        participantEvaluations = {
          'participantEvaluations.$evaluatorId.participantEvaluated': true,
          'participantEvaluations.$evaluatorId.participantEvaluatedAt': Timestamp.fromDate(DateTime.now()),
        };
      }
      
      // 相互評価が完了したかチェック
      final participantEvalDoc = await _firestore
          .collection('experiments')
          .doc(experimentId)
          .get();
      
      if (participantEvalDoc.exists) {
        final data = participantEvalDoc.data() as Map<String, dynamic>;
        final participantEvals = data['participantEvaluations'] as Map<String, dynamic>? ?? {};
        
        String targetUserId = evaluatorRole == EvaluatorRole.experimenter ? evaluatedUserId : evaluatorId;
        final userEval = participantEvals[targetUserId] as Map<String, dynamic>? ?? {};
        
        bool creatorEvaluated = userEval['creatorEvaluated'] ?? false;
        bool participantEvaluated = userEval['participantEvaluated'] ?? false;
        
        // 新規評価後の状態を予測
        if (evaluatorRole == EvaluatorRole.experimenter) {
          creatorEvaluated = true;
        } else {
          participantEvaluated = true;
        }
        
        // 相互評価が完了した場合
        if (creatorEvaluated && participantEvaluated) {
          participantEvaluations['participantEvaluations.$targetUserId.mutuallyCompleted'] = true;
          participantEvaluations['participantEvaluations.$targetUserId.completedAt'] = Timestamp.fromDate(DateTime.now());
        }
      }
      
      // participantEvaluationsを更新
      await _firestore.collection('experiments').doc(experimentId).update(participantEvaluations);
      
    } catch (e) {
      rethrow;
    }
  }

  // 未使用のメソッドを削除（個別評価管理に移行したため）
  
  /// 特定の参加者との相互評価が完了しているかチェック
  Future<bool> isMutualEvaluationComplete(String experimentId, String participantId) async {
    try {
      final doc = await _firestore
          .collection('experiments')
          .doc(experimentId)
          .get();
      
      if (!doc.exists) return false;
      
      final data = doc.data() as Map<String, dynamic>;
      final participantEvals = data['participantEvaluations'] as Map<String, dynamic>? ?? {};
      final userEval = participantEvals[participantId] as Map<String, dynamic>? ?? {};
      
      return userEval['mutuallyCompleted'] ?? false;
    } catch (e) {
      return false;
    }
  }

  /// 実験の評価状態を取得
  Future<Map<String, dynamic>> getExperimentEvaluationStatus(
    String experimentId,
    String userId,
  ) async {
    try {
      final experimentDoc = await _firestore
          .collection('experiments')
          .doc(experimentId)
          .get();
      
      if (!experimentDoc.exists) {
        return {'canEvaluate': false, 'hasEvaluated': false};
      }
      
      final experiment = Experiment.fromFirestore(experimentDoc);
      
      return {
        'canEvaluate': experiment.canEvaluate(userId),
        'hasEvaluated': experiment.hasEvaluated(userId),
        'status': experiment.status.name,
      };
    } catch (e) {
      return {'canEvaluate': false, 'hasEvaluated': false};
    }
  }

  /// ユーザーの評価履歴を取得
  Future<List<ExperimentEvaluation>> getUserEvaluations(String userId) async {
    try {
      
      // 評価者として（orderByを削除してクライアント側でソート）
      final asEvaluator = await _firestore
          .collection('evaluations')
          .where('evaluatorId', isEqualTo: userId)
          .get();
      
      
      // 被評価者として（orderByを削除してクライアント側でソート）
      final asEvaluated = await _firestore
          .collection('evaluations')
          .where('evaluatedUserId', isEqualTo: userId)
          .get();
      
      
      final evaluations = [
        ...asEvaluator.docs.map((doc) => ExperimentEvaluation.fromFirestore(doc)),
        ...asEvaluated.docs.map((doc) => ExperimentEvaluation.fromFirestore(doc)),
      ];
      
      // 日付でソート
      evaluations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      
      return evaluations;
    } catch (e) {
      return [];
    }
  }

  // 自動完了処理は削除（実験は個別の参加者評価で管理）

  /// 実験を評価待ち状態に変更
  Future<void> startEvaluation(String experimentId) async {
    try {
      await _firestore.collection('experiments').doc(experimentId).update({
        'status': ExperimentStatus.waitingEvaluation.name,
        'actualStartDate': Timestamp.fromDate(DateTime.now()),
      });
      
    } catch (e) {
      throw Exception('評価開始に失敗しました');
    }
  }
}