import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// IDからユーザーを取得
  Future<AppUser?> getUserById(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      
      if (doc.exists) {
        return AppUser.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<AppUser?> getUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return AppUser.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Stream<AppUser?> getUserStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? AppUser.fromFirestore(doc) : null);
  }

  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? bio,
    String? department,
    String? grade,
  }) async {
    final updateData = <String, dynamic>{};
    
    if (name != null) updateData['name'] = name;
    if (bio != null) updateData['bio'] = bio;
    if (department != null) updateData['department'] = department;
    if (grade != null) updateData['grade'] = grade;
    
    if (updateData.isNotEmpty) {
      await _firestore.collection('users').doc(userId).update(updateData);
    }
  }

  Future<void> incrementParticipatedExperiments(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'participatedExperiments': FieldValue.increment(1),
    });
  }

  /// 既存ユーザーのscheduledExperimentsフィールドを初期化
  Future<void> initializeScheduledExperimentsField(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        
        // scheduledExperimentsフィールドが存在しない場合のみ初期化
        if (!data.containsKey('scheduledExperiments')) {
          await _firestore.collection('users').doc(userId).update({
            'scheduledExperiments': 0,
          });
        }
      }
    } catch (e) {
    }
  }

  Future<void> incrementScheduledExperiments(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'scheduledExperiments': FieldValue.increment(1),
    });
  }

  Future<void> completeExperiment({
    required String userId,
    required String experimentId,
  }) async {
    await _firestore.collection('users').doc(userId).update({
      'scheduledExperiments': FieldValue.increment(-1),
      'participatedExperiments': FieldValue.increment(1),
      'completedExperimentIds': FieldValue.arrayUnion([experimentId]),
    });
  }

  Future<List<AppUser>> searchUsers(String query) async {
    if (query.isEmpty) return [];
    
    final lowercaseQuery = query.toLowerCase();
    
    final snapshot = await _firestore
        .collection('users')
        .orderBy('name')
        .limit(20)
        .get();
    
    return snapshot.docs
        .map((doc) => AppUser.fromFirestore(doc))
        .where((user) => 
            user.name.toLowerCase().contains(lowercaseQuery) ||
            user.email.toLowerCase().contains(lowercaseQuery))
        .toList();
  }

  Future<List<AppUser>> getAllUsers({int limit = 50}) async {
    final snapshot = await _firestore
        .collection('users')
        .orderBy('name')
        .limit(limit)
        .get();
    
    return snapshot.docs
        .map((doc) => AppUser.fromFirestore(doc))
        .toList();
  }

  Future<void> updateUserRatings({
    required String userId,
    bool isGood = true,
  }) async {
    final field = isGood ? 'goodCount' : 'badCount';
    await _firestore.collection('users').doc(userId).update({
      field: FieldValue.increment(1),
    });
  }

  Future<void> updateUserEarnings({
    required String userId,
    required int amount,
  }) async {
    final now = DateTime.now();
    final userDoc = await _firestore.collection('users').doc(userId).get();
    
    if (userDoc.exists) {
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
        // 新しい月の場合、月次収益をリセット
        updates['monthlyEarnings'] = amount;
      } else {
        // 同じ月の場合、月次収益に加算
        updates['monthlyEarnings'] = FieldValue.increment(amount);
      }
      
      await _firestore.collection('users').doc(userId).update(updates);
    }
  }

  Future<void> resetMonthlyEarnings(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'monthlyEarnings': 0,
      'lastEarningsUpdate': Timestamp.fromDate(DateTime.now()),
    });
  }
  
  /// scheduledExperimentsを減らす
  Future<void> decrementScheduledExperiments(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'scheduledExperiments': FieldValue.increment(-1),
    });
  }

  /// ポイントを追加（Good評価時に呼び出す）
  Future<void> addPoints({
    required String userId,
    required int points,
  }) async {
    await _firestore.collection('users').doc(userId).update({
      'points': FieldValue.increment(points),
    });
  }

  /// フレームを解放（購入）
  Future<void> unlockFrame({
    required String userId,
    required String frameId,
    required int cost,
  }) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    
    if (!userDoc.exists) {
      throw Exception('ユーザーが見つかりません');
    }
    
    final userData = userDoc.data() as Map<String, dynamic>;
    final currentPoints = userData['points'] ?? 0;
    
    if (currentPoints < cost) {
      throw Exception('ポイントが不足しています');
    }
    
    await _firestore.collection('users').doc(userId).update({
      'points': FieldValue.increment(-cost),
      'unlockedFrames': FieldValue.arrayUnion([frameId]),
    });
  }

  /// フレームを選択（装備）
  Future<void> selectFrame({
    required String userId,
    required String frameId,
  }) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    
    if (!userDoc.exists) {
      throw Exception('ユーザーが見つかりません');
    }
    
    final userData = userDoc.data() as Map<String, dynamic>;
    // デフォルトで解放されているフレームも含める
    final unlockedFrames = List<String>.from(userData['unlockedFrames'] ?? ['none', 'simple']);
    
    // 無料フレームは常に装備可能
    final freeFrames = ['none', 'simple'];
    
    if (!unlockedFrames.contains(frameId) && !freeFrames.contains(frameId)) {
      throw Exception('このフレームは解放されていません');
    }
    
    await _firestore.collection('users').doc(userId).update({
      'selectedFrame': frameId,
    });
  }

  /// フレームの選択を解除
  Future<void> unselectFrame(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'selectedFrame': null,
    });
  }

  /// デザインを解放（購入）
  Future<void> unlockDesign({
    required String userId,
    required String designId,
    required int cost,
  }) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    
    if (!userDoc.exists) {
      throw Exception('ユーザーが見つかりません');
    }
    
    final userData = userDoc.data() as Map<String, dynamic>;
    final currentPoints = userData['points'] ?? 0;
    
    if (currentPoints < cost) {
      throw Exception('ポイントが不足しています');
    }
    
    await _firestore.collection('users').doc(userId).update({
      'points': FieldValue.increment(-cost),
      'unlockedDesigns': FieldValue.arrayUnion([designId]),
    });
  }

  /// デザインを選択（装備）
  Future<void> selectDesign({
    required String userId,
    required String designId,
  }) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    
    if (!userDoc.exists) {
      throw Exception('ユーザーが見つかりません');
    }
    
    final userData = userDoc.data() as Map<String, dynamic>;
    final unlockedDesigns = List<String>.from(userData['unlockedDesigns'] ?? ['default']);
    
    // デフォルトデザインは常に装備可能
    if (!unlockedDesigns.contains(designId) && designId != 'default') {
      throw Exception('このデザインは解放されていません');
    }
    
    await _firestore.collection('users').doc(userId).update({
      'selectedDesign': designId,
    });
  }

  /// カラーを解放（購入）
  Future<void> unlockColor({
    required String userId,
    required String colorId,
    required int cost,
  }) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    
    if (!userDoc.exists) {
      throw Exception('ユーザーが見つかりません');
    }
    
    final userData = userDoc.data() as Map<String, dynamic>;
    final currentPoints = userData['points'] ?? 0;
    
    if (currentPoints < cost) {
      throw Exception('ポイントが不足しています');
    }
    
    await _firestore.collection('users').doc(userId).update({
      'points': FieldValue.increment(-cost),
      'unlockedColors': FieldValue.arrayUnion([colorId]),
    });
  }

  /// カラーを選択（装備）
  Future<void> selectColor({
    required String userId,
    required String colorId,
  }) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    
    if (!userDoc.exists) {
      throw Exception('ユーザーが見つかりません');
    }
    
    final userData = userDoc.data() as Map<String, dynamic>;
    final unlockedColors = List<String>.from(userData['unlockedColors'] ?? ['default']);
    
    // デフォルトカラーは常に装備可能
    if (!unlockedColors.contains(colorId) && colorId != 'default') {
      throw Exception('このカラーは解放されていません');
    }
    
    await _firestore.collection('users').doc(userId).update({
      'selectedColor': colorId,
    });
  }
}