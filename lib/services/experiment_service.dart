import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/experiment.dart';
import 'user_service.dart';

class ExperimentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// IDから実験を取得
  Future<Experiment?> getExperimentById(String experimentId) async {
    try {
      final doc = await _firestore
          .collection('experiments')
          .doc(experimentId)
          .get();
      
      if (doc.exists) {
        return Experiment.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching experiment by ID: $e');
      return null;
    }
  }

  /// ユーザーが参加した実験履歴を取得
  Future<List<Experiment>> getUserParticipatedExperiments(String userId) async {
    try {
      debugPrint('Fetching participated experiments for user: $userId');
      
      // participantsフィールドにユーザーIDが含まれる実験を取得
      final snapshot = await _firestore
          .collection('experiments')
          .where('participants', arrayContains: userId)
          .get();

      debugPrint('Found ${snapshot.docs.length} participated experiments');
      
      final experiments = snapshot.docs
          .map((doc) => Experiment.fromFirestore(doc))
          .toList();
      
      // メモリ上でソート（experimentDateがnullの可能性があるため）
      experiments.sort((a, b) {
        if (a.experimentDate == null && b.experimentDate == null) return 0;
        if (a.experimentDate == null) return 1;
        if (b.experimentDate == null) return -1;
        return b.experimentDate!.compareTo(a.experimentDate!);
      });
      
      return experiments;
    } catch (e) {
      debugPrint('Error fetching participated experiments: $e');
      return [];
    }
  }

  /// ユーザーが募集した実験履歴を取得
  Future<List<Experiment>> getUserCreatedExperiments(String userId) async {
    try {
      debugPrint('Fetching created experiments for user: $userId');
      
      final snapshot = await _firestore
          .collection('experiments')
          .where('creatorId', isEqualTo: userId)
          .get();

      debugPrint('Found ${snapshot.docs.length} created experiments');
      
      final experiments = snapshot.docs
          .map((doc) => Experiment.fromFirestore(doc))
          .toList();
      
      // メモリ上でソート（createdAtがnullの可能性があるため）
      experiments.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
      
      return experiments;
    } catch (e) {
      debugPrint('Error fetching created experiments: $e');
      return [];
    }
  }

  /// 実験を作成
  Future<String> createExperiment(Experiment experiment) async {
    try {
      final docRef = await _firestore.collection('experiments').add(
        experiment.toFirestore(),
      );
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating experiment: $e');
      throw Exception('実験の作成に失敗しました');
    }
  }

  /// 実験に参加
  Future<void> joinExperiment(String experimentId, String userId) async {
    try {
      debugPrint('Joining experiment: experimentId=$experimentId, userId=$userId');
      
      // トランザクションで実験への参加を処理
      await _firestore.runTransaction((transaction) async {
        // 実験ドキュメントを取得
        final experimentDoc = await transaction.get(
          _firestore.collection('experiments').doc(experimentId),
        );
        
        if (!experimentDoc.exists) {
          debugPrint('Experiment document does not exist: $experimentId');
          throw Exception('実験が見つかりません');
        }
        
        final data = experimentDoc.data()!;
        final participants = List<String>.from(data['participants'] ?? []);
        final creatorId = data['creatorId'] as String?;
        
        debugPrint('Current participants: $participants');
        debugPrint('Creator ID: $creatorId, User ID: $userId');
        
        // 自分が作成した実験には参加できない
        if (creatorId == userId) {
          throw Exception('自分が募集した実験には参加できません');
        }
        
        // すでに参加している場合はエラー
        if (participants.contains(userId)) {
          throw Exception('すでにこの実験に参加しています');
        }
        
        // ユーザードキュメントの存在確認
        final userDocRef = _firestore.collection('users').doc(userId);
        final userDoc = await transaction.get(userDocRef);
        
        if (!userDoc.exists) {
          debugPrint('User document does not exist: $userId');
          // ユーザードキュメントが存在しない場合は参加者のみ追加
          transaction.update(experimentDoc.reference, {
            'participants': FieldValue.arrayUnion([userId]),
          });
        } else {
          debugPrint('User document exists, updating both experiment and user');
          // 参加者を追加
          transaction.update(experimentDoc.reference, {
            'participants': FieldValue.arrayUnion([userId]),
          });
          
          // ユーザーの参加予定実験数を更新（参加済みではなく予定として）
          final userData = userDoc.data() as Map<String, dynamic>;
          final currentScheduled = userData['scheduledExperiments'] ?? 0;
          debugPrint('Current scheduledExperiments count: $currentScheduled');
          
          // フィールドが存在しない場合は初期値を設定してから更新
          if (!userData.containsKey('scheduledExperiments')) {
            transaction.update(userDocRef, {
              'scheduledExperiments': 1,
            });
          } else {
            transaction.update(userDocRef, {
              'scheduledExperiments': FieldValue.increment(1),
            });
          }
        }
      });
      
      debugPrint('Successfully joined experiment: $experimentId');
    } catch (e, stackTrace) {
      debugPrint('Error joining experiment: $e');
      debugPrint('Stack trace: $stackTrace');
      
      if (e.toString().contains('すでに')) {
        throw Exception('すでにこの実験に参加しています');
      } else if (e.toString().contains('NOT_FOUND')) {
        throw Exception('ユーザー情報が見つかりません。再度ログインしてください。');
      } else if (e.toString().contains('permission')) {
        throw Exception('権限がありません。ログインし直してください。');
      }
      
      // エラーメッセージをそのまま伝える
      throw e;
    }
  }

  /// 実験から離脱
  Future<void> leaveExperiment(String experimentId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final experimentDoc = await transaction.get(
          _firestore.collection('experiments').doc(experimentId),
        );
        
        if (!experimentDoc.exists) {
          throw Exception('実験が見つかりません');
        }
        
        // 参加者から削除
        transaction.update(experimentDoc.reference, {
          'participants': FieldValue.arrayRemove([userId]),
        });
        
        // ユーザーの参加予定実験数を減らす（まだ完了していない場合）
        final userDocRef = _firestore.collection('users').doc(userId);
        final userDoc = await transaction.get(userDocRef);
        final experiment = Experiment.fromFirestore(experimentDoc);
        
        // 実験がまだ完了していない場合は参加予定から削除
        if (experiment.status != ExperimentStatus.completed && userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final currentScheduled = userData['scheduledExperiments'] ?? 0;
          
          // 0より大きい場合のみデクリメント
          if (currentScheduled > 0) {
            transaction.update(userDocRef, {
              'scheduledExperiments': FieldValue.increment(-1),
            });
          }
        }
      });
    } catch (e) {
      debugPrint('Error leaving experiment: $e');
      throw Exception('実験からの離脱に失敗しました');
    }
  }
  
  /// ユーザーが特定の実験に参加しているかチェック
  Future<bool> isUserParticipating(String experimentId, String userId) async {
    try {
      final doc = await _firestore.collection('experiments').doc(experimentId).get();
      if (!doc.exists) return false;
      
      final participants = List<String>.from(doc.data()?['participants'] ?? []);
      return participants.contains(userId);
    } catch (e) {
      debugPrint('Error checking participation: $e');
      return false;
    }
  }

  /// すべての実験を取得（フィルタリング可能）
  Stream<List<Experiment>> getExperiments({
    ExperimentType? type,
    bool? isPaid,
  }) {
    Query<Map<String, dynamic>> query = _firestore.collection('experiments');

    if (type != null) {
      query = query.where('type', isEqualTo: type.name);
    }
    if (isPaid != null) {
      query = query.where('isPaid', isEqualTo: isPaid);
    }

    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Experiment.fromFirestore(doc))
            .toList());
  }

  /// 実験を開始（進行中状態に変更）
  Future<void> startExperiment(String experimentId) async {
    try {
      await _firestore.collection('experiments').doc(experimentId).update({
        'status': ExperimentStatus.ongoing.name,
        'actualStartDate': Timestamp.fromDate(DateTime.now()),
      });
      
      debugPrint('Started experiment: $experimentId');
    } catch (e) {
      debugPrint('Error starting experiment: $e');
      throw Exception('実験の開始に失敗しました');
    }
  }

  /// 実験を評価待ち状態に変更
  Future<void> finishExperiment(String experimentId) async {
    try {
      await _firestore.collection('experiments').doc(experimentId).update({
        'status': ExperimentStatus.waitingEvaluation.name,
        'actualStartDate': Timestamp.fromDate(DateTime.now()),
      });
      debugPrint('Finished experiment and started evaluation: $experimentId');
    } catch (e) {
      debugPrint('Error finishing experiment: $e');
      throw Exception('実験の終了処理に失敗しました');
    }
  }

  /// 実験の現在のステータスを取得
  Future<ExperimentStatus?> getExperimentStatus(String experimentId) async {
    try {
      final doc = await _firestore.collection('experiments').doc(experimentId).get();
      if (!doc.exists) return null;
      
      final data = doc.data() as Map<String, dynamic>;
      return data['status'] != null 
        ? ExperimentStatus.fromString(data['status'])
        : ExperimentStatus.recruiting;
    } catch (e) {
      debugPrint('Error getting experiment status: $e');
      return null;
    }
  }

  /// ユーザーが評価待ちの実験を取得
  Future<List<Experiment>> getPendingEvaluations(String userId) async {
    try {
      // ユーザーが実験者として関わった実験（全てのステータス）
      final createdQuery = await _firestore
          .collection('experiments')
          .where('creatorId', isEqualTo: userId)
          .get();
      
      // ユーザーが参加者として関わった実験（全てのステータス）
      final participatedQuery = await _firestore
          .collection('experiments')
          .where('participants', arrayContains: userId)
          .get();
      
      final experiments = <Experiment>[];
      
      // 重複を除いて実験リストを作成
      final experimentIds = <String>{};
      
      for (final doc in [...createdQuery.docs, ...participatedQuery.docs]) {
        if (!experimentIds.contains(doc.id)) {
          experimentIds.add(doc.id);
          final experiment = Experiment.fromFirestore(doc);
          // 評価可能な実験のみを追加（日時チェックを含む）
          if (experiment.canEvaluate(userId)) {
            experiments.add(experiment);
          }
        }
      }
      
      return experiments;
    } catch (e) {
      debugPrint('Error getting pending evaluations: $e');
      return [];
    }
  }

  /// 実験参加をキャンセル
  Future<void> cancelParticipation(String experimentId, String userId) async {
    try {
      final experimentDoc = await _firestore.collection('experiments').doc(experimentId).get();
      
      if (!experimentDoc.exists) {
        throw Exception('実験が見つかりません');
      }
      
      final experiment = Experiment.fromFirestore(experimentDoc);
      
      // participantsリストから削除
      final updatedParticipants = List<String>.from(experiment.participants);
      if (!updatedParticipants.contains(userId)) {
        throw Exception('この実験に参加していません');
      }
      
      updatedParticipants.remove(userId);
      
      // Firestoreを更新
      await _firestore.collection('experiments').doc(experimentId).update({
        'participants': updatedParticipants,
      });
      
      // ユーザーのscheduledExperimentsを減らす
      final userService = UserService();
      await userService.decrementScheduledExperiments(userId);
      
    } catch (e) {
      debugPrint('Error canceling participation: $e');
      throw e;
    }
  }
}