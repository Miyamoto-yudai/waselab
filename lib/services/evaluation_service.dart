import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/experiment.dart';
import '../models/experiment_evaluation.dart';
import 'user_service.dart';

class EvaluationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserService _userService = UserService();

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
      // トランザクションで評価を作成し、実験の状態を更新
      await _firestore.runTransaction((transaction) async {
        // 実験ドキュメントを取得
        final experimentDoc = await transaction.get(
          _firestore.collection('experiments').doc(experimentId),
        );
        
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
        final evaluationRef = _firestore.collection('evaluations').doc();
        transaction.set(evaluationRef, evaluation.toFirestore());
        
        // 実験のevaluationsフィールドを更新
        final evaluations = Map<String, Map<String, dynamic>>.from(
          experiment.evaluations ?? {},
        );
        evaluations[evaluatorId] = {
          'evaluated': true,
          'evaluationType': type.name,
          'evaluatedAt': Timestamp.fromDate(DateTime.now()),
        };
        
        // 最初の評価の場合、ステータスをwaitingEvaluationに変更
        final updateData = <String, dynamic>{
          'evaluations': evaluations,
        };
        
        // まだ誰も評価していない場合（最初の評価）、ステータスを更新
        if (experiment.status != ExperimentStatus.waitingEvaluation && 
            experiment.status != ExperimentStatus.completed) {
          updateData['status'] = ExperimentStatus.waitingEvaluation.name;
          updateData['actualStartDate'] = Timestamp.fromDate(DateTime.now());
        }
        
        transaction.update(experimentDoc.reference, updateData);
        
        // 被評価者のユーザー統計を更新
        await _updateUserRatings(transaction, evaluatedUserId, type);
        
        // 双方の評価が完了したかチェック
        await _checkAndCompleteExperiment(
          transaction,
          experimentDoc,
          experiment,
          evaluations,
        );
      });
      
      debugPrint('Successfully created evaluation for experiment: $experimentId');
    } catch (e) {
      debugPrint('Error creating evaluation: $e');
      rethrow;
    }
  }

  /// ユーザーの評価統計を更新
  Future<void> _updateUserRatings(
    Transaction transaction,
    String userId,
    EvaluationType type,
  ) async {
    final userDoc = await transaction.get(
      _firestore.collection('users').doc(userId),
    );
    
    if (!userDoc.exists) return;
    
    if (type == EvaluationType.good) {
      transaction.update(userDoc.reference, {
        'goodCount': FieldValue.increment(1),
      });
    } else if (type == EvaluationType.bad) {
      transaction.update(userDoc.reference, {
        'badCount': FieldValue.increment(1),
      });
    }
  }

  /// 双方の評価が完了したかチェックし、完了していれば実験を完了状態にする
  Future<void> _checkAndCompleteExperiment(
    Transaction transaction,
    DocumentSnapshot experimentDoc,
    Experiment experiment,
    Map<String, Map<String, dynamic>> evaluations,
  ) async {
    // 実験者と全参加者が評価済みかチェック
    final allUsers = [experiment.creatorId, ...experiment.participants];
    bool allEvaluated = true;
    
    for (final userId in allUsers) {
      if (evaluations[userId] == null || 
          evaluations[userId]!['evaluated'] != true) {
        allEvaluated = false;
        break;
      }
    }
    
    if (allEvaluated) {
      // 全員が評価済みの場合、実験を完了状態にする
      transaction.update(experimentDoc.reference, {
        'status': ExperimentStatus.completed.name,
        'completedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      // 参加者の統計を更新
      for (final participantId in experiment.participants) {
        final participantDoc = await transaction.get(
          _firestore.collection('users').doc(participantId),
        );
        
        if (participantDoc.exists) {
          // 参加予定から参加済みに移行
          transaction.update(participantDoc.reference, {
            'scheduledExperiments': FieldValue.increment(-1),
            'participatedExperiments': FieldValue.increment(1),
            'completedExperimentIds': FieldValue.arrayUnion([experiment.id]),
          });
          
          // 報酬を付与（有償の場合）
          if (experiment.isPaid) {
            await _awardReward(transaction, participantId, experiment.reward);
          }
        }
      }
      
      debugPrint('Experiment completed: ${experiment.id}');
    }
  }

  /// 報酬を付与
  Future<void> _awardReward(
    Transaction transaction,
    String userId,
    int amount,
  ) async {
    final userDoc = await transaction.get(
      _firestore.collection('users').doc(userId),
    );
    
    if (!userDoc.exists) return;
    
    final now = DateTime.now();
    final userData = userDoc.data() as Map<String, dynamic>;
    final lastUpdate = (userData['lastEarningsUpdate'] as Timestamp?)?.toDate();
    
    // 月が変わっているかチェック
    bool isNewMonth = lastUpdate == null || 
      lastUpdate.year != now.year || 
      lastUpdate.month != now.month;
    
    final updates = <String, dynamic>{
      'totalEarnings': FieldValue.increment(amount),
      'lastEarningsUpdate': Timestamp.fromDate(now),
    };
    
    if (isNewMonth) {
      updates['monthlyEarnings'] = amount;
    } else {
      updates['monthlyEarnings'] = FieldValue.increment(amount);
    }
    
    transaction.update(userDoc.reference, updates);
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
      debugPrint('Error getting evaluation status: $e');
      return {'canEvaluate': false, 'hasEvaluated': false};
    }
  }

  /// ユーザーの評価履歴を取得
  Future<List<ExperimentEvaluation>> getUserEvaluations(String userId) async {
    try {
      // 評価者として
      final asEvaluator = await _firestore
          .collection('evaluations')
          .where('evaluatorId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      // 被評価者として
      final asEvaluated = await _firestore
          .collection('evaluations')
          .where('evaluatedUserId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      final evaluations = [
        ...asEvaluator.docs.map((doc) => ExperimentEvaluation.fromFirestore(doc)),
        ...asEvaluated.docs.map((doc) => ExperimentEvaluation.fromFirestore(doc)),
      ];
      
      // 日付でソート
      evaluations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return evaluations;
    } catch (e) {
      debugPrint('Error getting user evaluations: $e');
      return [];
    }
  }

  /// 期限切れの実験を自動完了する（バッチ処理用）
  Future<void> autoCompleteExpiredExperiments() async {
    try {
      // 完了していないすべての実験を取得
      final snapshot = await _firestore
          .collection('experiments')
          .where('status', whereIn: [
            ExperimentStatus.recruiting.name,
            ExperimentStatus.ongoing.name,
            ExperimentStatus.waitingEvaluation.name,
          ])
          .get();
      
      for (final doc in snapshot.docs) {
        final experiment = Experiment.fromFirestore(doc);
        
        if (experiment.shouldAutoComplete()) {
          // 自動完了処理
          await _firestore.runTransaction((transaction) async {
            // 未評価のユーザーに対してニュートラル評価を作成
            final allUsers = [experiment.creatorId, ...experiment.participants];
            final evaluations = Map<String, Map<String, dynamic>>.from(
              experiment.evaluations ?? {},
            );
            
            for (final userId in allUsers) {
              if (evaluations[userId] == null || 
                  evaluations[userId]!['evaluated'] != true) {
                // ニュートラル評価を追加
                evaluations[userId] = {
                  'evaluated': true,
                  'evaluationType': EvaluationType.neutral.name,
                  'evaluatedAt': Timestamp.fromDate(DateTime.now()),
                  'isAutoGenerated': true,
                };
                
                // 自動生成された評価レコードを作成
                final evaluation = ExperimentEvaluation.create(
                  experimentId: experiment.id,
                  evaluatorId: 'system',
                  evaluatedUserId: userId,
                  evaluatorRole: userId == experiment.creatorId 
                    ? EvaluatorRole.experimenter 
                    : EvaluatorRole.participant,
                  type: EvaluationType.neutral,
                  comment: '期限切れのため自動完了',
                  isAutoGenerated: true,
                );
                
                final evaluationRef = _firestore.collection('evaluations').doc();
                transaction.set(evaluationRef, evaluation.toFirestore());
              }
            }
            
            // 実験を完了状態にする
            transaction.update(doc.reference, {
              'status': ExperimentStatus.completed.name,
              'completedAt': Timestamp.fromDate(DateTime.now()),
              'evaluations': evaluations,
            });
            
            // 参加者の統計を更新
            for (final participantId in experiment.participants) {
              final participantDoc = await transaction.get(
                _firestore.collection('users').doc(participantId),
              );
              
              if (participantDoc.exists) {
                // 参加予定から参加済みに移行
                transaction.update(participantDoc.reference, {
                  'scheduledExperiments': FieldValue.increment(-1),
                  'participatedExperiments': FieldValue.increment(1),
                  'completedExperimentIds': FieldValue.arrayUnion([experiment.id]),
                });
                
                // 報酬を付与（有償の場合）
                if (experiment.isPaid) {
                  await _awardReward(transaction, participantId, experiment.reward);
                }
              }
            }
          });
          
          debugPrint('Auto-completed experiment: ${experiment.id}');
        }
      }
    } catch (e) {
      debugPrint('Error auto-completing experiments: $e');
    }
  }

  /// 実験を評価待ち状態に変更
  Future<void> startEvaluation(String experimentId) async {
    try {
      await _firestore.collection('experiments').doc(experimentId).update({
        'status': ExperimentStatus.waitingEvaluation.name,
        'actualStartDate': Timestamp.fromDate(DateTime.now()),
      });
      
      debugPrint('Started evaluation for experiment: $experimentId');
    } catch (e) {
      debugPrint('Error starting evaluation: $e');
      throw Exception('評価開始に失敗しました');
    }
  }
}