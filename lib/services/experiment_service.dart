import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/experiment.dart';

class ExperimentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ユーザーが参加した実験履歴を取得
  Future<List<Experiment>> getUserParticipatedExperiments(String userId) async {
    try {
      // participantsフィールドにユーザーIDが含まれる実験を取得
      final snapshot = await _firestore
          .collection('experiments')
          .where('participants', arrayContains: userId)
          .orderBy('experimentDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Experiment.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching participated experiments: $e');
      return [];
    }
  }

  /// ユーザーが募集した実験履歴を取得
  Future<List<Experiment>> getUserCreatedExperiments(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('experiments')
          .where('creatorId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Experiment.fromFirestore(doc))
          .toList();
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
      await _firestore.collection('experiments').doc(experimentId).update({
        'participants': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      debugPrint('Error joining experiment: $e');
      throw Exception('実験への参加に失敗しました');
    }
  }

  /// 実験から離脱
  Future<void> leaveExperiment(String experimentId, String userId) async {
    try {
      await _firestore.collection('experiments').doc(experimentId).update({
        'participants': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      debugPrint('Error leaving experiment: $e');
      throw Exception('実験からの離脱に失敗しました');
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
}