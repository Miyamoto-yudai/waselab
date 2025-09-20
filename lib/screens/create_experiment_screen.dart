import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/create_experiment_base.dart';
import '../models/experiment_slot.dart';
import '../services/reservation_service.dart';
import '../services/preference_service.dart';
import '../services/google_calendar_service.dart';

/// 実験作成画面（早稲田ユーザー専用）
class CreateExperimentScreen extends StatelessWidget {
  const CreateExperimentScreen({super.key});

  Future<void> _handleSave(Map<String, dynamic> data) async {
    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;
    final reservationService = ReservationService();
    final calendarService = GoogleCalendarService();
    
    final user = auth.currentUser;
    if (user == null) {
      throw Exception('ユーザーが見つかりません');
    }


    // 初回実験作成かつカレンダー連携が無効の場合、プロンプトを表示
    final isFirstExperiment = await PreferenceService.isFirstExperimentCreated();
    final calendarEnabled = await calendarService.isCalendarEnabled();
    final hasShownPrompt = await PreferenceService.hasShownCalendarPrompt();
    
    if (isFirstExperiment && !calendarEnabled && !hasShownPrompt) {
      await PreferenceService.recordCalendarPromptShown();
      // ここではダイアログを表示できないため、フラグのみ設定
      // 実際のダイアログ表示はWidget側で制御
    }
    
    // Firestoreに実験を追加
    final docRef = await firestore.collection('experiments').add({
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
      'scheduleType': data['scheduleType'],
      'labName': data['labName'],
      'duration': data['duration'],
      'maxParticipants': data['maxParticipants'],
      'requirements': data['requirements'],
      'consentItems': data['consentItems'] ?? [],
      'timeSlots': data['timeSlots'] ?? [],
      'dateTimeSlots': data['dateTimeSlots'] ?? [],
      'simultaneousCapacity': data['simultaneousCapacity'],
      'fixedExperimentDate': data['fixedExperimentDate'] != null
        ? Timestamp.fromDate(data['fixedExperimentDate'])
        : null,
      'fixedExperimentTime': data['fixedExperimentTime'],
      'reservationDeadlineDays': data['reservationDeadlineDays'] ?? 1,
      'surveyUrl': data['surveyUrl'],
      'preSurveyUrl': data['preSurveyUrl'],
      'preSurveyTemplateId': data['preSurveyTemplateId'],
      'experimentSurveyTemplateId': data['experimentSurveyTemplateId'],
      'postSurveyUrl': data['postSurveyUrl'],
      'postSurveyTemplateId': data['postSurveyTemplateId'],
      'isLabExperiment': data['isLabExperiment'] ?? true,
      'participants': [], // 初期値として空配列を設定
      'status': 'recruiting', // 初期ステータスを設定
    });

    // タイムスロットから実験スロットを生成
    if (data['allowFlexibleSchedule'] == true) {
      final List<ExperimentSlot> slots = [];
      // dateTimeSlotsを使用（新しい日付ベースのスロット）
      final dateTimeSlots = data['dateTimeSlots'] as List<dynamic>?;
      
      if (dateTimeSlots != null && dateTimeSlots.isNotEmpty) {
        
        for (final slotData in dateTimeSlots) {
          final slot = slotData as Map<String, dynamic>;
          final date = DateTime.parse(slot['date'] as String);
          final startHour = slot['startHour'] as int;
          final startMinute = slot['startMinute'] as int;
          final endHour = slot['endHour'] as int;
          final endMinute = slot['endMinute'] as int;
          final maxCapacity = slot['maxCapacity'] as int? ?? 1;
          
          final slotStartTime = DateTime(
            date.year,
            date.month,
            date.day,
            startHour,
            startMinute,
          );
          
          final slotEndTime = DateTime(
            date.year,
            date.month,
            date.day,
            endHour,
            endMinute,
          );
          
          slots.add(ExperimentSlot(
            id: '',
            experimentId: docRef.id,
            startTime: slotStartTime,
            endTime: slotEndTime,
            maxParticipants: maxCapacity,
            currentParticipants: 0,
            isAvailable: true,
          ));
        }
      } else if (data['timeSlots'] != null) {
        // 旧形式のタイムスロット（曜日ベース）のフォールバック
        final timeSlots = data['timeSlots'] as List<dynamic>;
        final startDate = data['experimentPeriodStart'] as DateTime?;
        final endDate = data['experimentPeriodEnd'] as DateTime?;
        final simultaneousCapacity = data['simultaneousCapacity'] as int? ?? 1;
        
        
        if (startDate != null && endDate != null && timeSlots.isNotEmpty) {
          // 実験期間内の各日付に対してスロットを生成
          DateTime currentDate = startDate;
          while (!currentDate.isAfter(endDate)) {
            // Flutterのweekday: 月=1, 火=2, ..., 土=6, 日=7
            // TimeSlotのweekday: 月=1, 火=2, ..., 土=6, 日=7
            final weekday = currentDate.weekday;
            
            // その曜日のタイムスロットを取得
            final daySlots = timeSlots.where((s) {
              final slot = s as Map<String, dynamic>;
              return slot['weekday'] == weekday;
            }).toList();
            
            
            for (final slotData in daySlots) {
              final slot = slotData as Map<String, dynamic>;
              final startHour = slot['startHour'] as int;
              final startMinute = slot['startMinute'] as int;
              final endHour = slot['endHour'] as int;
              final endMinute = slot['endMinute'] as int;
              
              final slotStartTime = DateTime(
                currentDate.year,
                currentDate.month,
                currentDate.day,
                startHour,
                startMinute,
              );
              
              final slotEndTime = DateTime(
                currentDate.year,
                currentDate.month,
                currentDate.day,
                endHour,
                endMinute,
              );
              
              // スロットを作成
              slots.add(ExperimentSlot(
                id: '', // IDは後で自動生成される
                experimentId: docRef.id,
                startTime: slotStartTime,
                endTime: slotEndTime,
                maxParticipants: simultaneousCapacity,
                currentParticipants: 0,
                isAvailable: true,
              ));
            }
            
            currentDate = currentDate.add(const Duration(days: 1));
          }
        }
      }
      
      // スロットを一括作成
      if (slots.isNotEmpty) {
        await reservationService.createMultipleSlots(slots);
      } else {
      }
    } else if (data['fixedExperimentDate'] != null && data['fixedExperimentTime'] != null) {
      // 固定日時の場合のスロット作成
      final fixedDate = data['fixedExperimentDate'] as DateTime;
      final fixedTime = data['fixedExperimentTime'] as Map<String, int>;
      final simultaneousCapacity = data['simultaneousCapacity'] as int? ?? 1;
      final duration = data['duration'] as int? ?? 60;
      
      
      final slotStartTime = DateTime(
        fixedDate.year,
        fixedDate.month,
        fixedDate.day,
        fixedTime['hour'] ?? 0,
        fixedTime['minute'] ?? 0,
      );
      
      final slotEndTime = slotStartTime.add(Duration(minutes: duration));
      
      final slot = ExperimentSlot(
        id: '',
        experimentId: docRef.id,
        startTime: slotStartTime,
        endTime: slotEndTime,
        maxParticipants: simultaneousCapacity,
        currentParticipants: 0,
        isAvailable: true,
      );
      
      await reservationService.createSlot(slot);
    } else {
    }
    
    // 初回実験作成を記録
    if (isFirstExperiment) {
      await PreferenceService.recordFirstExperimentCreated();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = FirebaseAuth.instance;
    return CreateExperimentBase(
      isDemo: false,
      onSave: _handleSave,
      currentUserId: auth.currentUser?.uid,
    );
  }
}