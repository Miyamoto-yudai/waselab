import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<AppUser?> getUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return AppUser.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user: $e');
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
    String? bio,
    String? department,
    String? grade,
  }) async {
    final updateData = <String, dynamic>{};
    
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
}