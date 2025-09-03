import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/create_experiment_base.dart';

/// 実験作成画面（早稲田ユーザー専用）
class CreateExperimentScreen extends StatelessWidget {
  const CreateExperimentScreen({super.key});

  Future<void> _handleSave(Map<String, dynamic> data) async {
    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;
    
    final user = auth.currentUser;
    if (user == null) {
      throw Exception('ユーザーが見つかりません');
    }

    // Firestoreに実験を追加
    await firestore.collection('experiments').add({
      'title': data['title'],
      'description': data['description'],
      'detailedContent': data['detailedContent'],
      'reward': data['reward'],
      'location': data['location'],
      'type': data['type'],
      'isPaid': data['isPaid'],
      'creatorId': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'recruitmentStartDate': data['recruitmentStartDate'] != null 
        ? Timestamp.fromDate(data['recruitmentStartDate']) 
        : null,
      'recruitmentEndDate': data['recruitmentEndDate'] != null
        ? Timestamp.fromDate(data['recruitmentEndDate'])
        : null,
      'experimentPeriodStart': data['experimentPeriodStart'] != null
        ? Timestamp.fromDate(data['experimentPeriodStart'])
        : null,
      'experimentPeriodEnd': data['experimentPeriodEnd'] != null
        ? Timestamp.fromDate(data['experimentPeriodEnd'])
        : null,
      'allowFlexibleSchedule': data['allowFlexibleSchedule'],
      'labName': data['labName'],
      'duration': data['duration'],
      'maxParticipants': data['maxParticipants'],
      'requirements': data['requirements'],
      'timeSlots': data['timeSlots'],
      'simultaneousCapacity': data['simultaneousCapacity'],
      'fixedExperimentDate': data['fixedExperimentDate'] != null
        ? Timestamp.fromDate(data['fixedExperimentDate'])
        : null,
      'fixedExperimentTime': data['fixedExperimentTime'],
      'surveyUrl': data['surveyUrl'],
    });
  }

  @override
  Widget build(BuildContext context) {
    return CreateExperimentBase(
      isDemo: false,
      onSave: _handleSave,
    );
  }
}