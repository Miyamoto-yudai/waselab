import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/create_experiment_base.dart';
import '../models/experiment_slot.dart';
import '../services/reservation_service.dart';

/// 実験作成画面（早稲田ユーザー専用）
class CreateExperimentScreen extends StatelessWidget {
  const CreateExperimentScreen({super.key});

  Future<void> _handleSave(Map<String, dynamic> data) async {
    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;
    final reservationService = ReservationService();
    
    final user = auth.currentUser;
    if (user == null) {
      throw Exception('ユーザーが見つかりません');
    }

    // データ整合性チェック（デバッグ用）
    debugPrint('=== 実験作成データ確認 ===');
    debugPrint('タイトル: ${data['title']}');
    debugPrint('説明: ${data['description']}');
    debugPrint('詳細: ${data['detailedContent']}');
    debugPrint('報酬: ${data['reward']}');
    debugPrint('場所: ${data['location']}');
    debugPrint('タイプ: ${data['type']}');
    debugPrint('有償: ${data['isPaid']}');
    debugPrint('募集開始日: ${data['recruitmentStartDate']}');
    debugPrint('募集終了日: ${data['recruitmentEndDate']}');
    debugPrint('実験期間開始: ${data['experimentPeriodStart']}');
    debugPrint('実験期間終了: ${data['experimentPeriodEnd']}');
    debugPrint('柔軟なスケジュール: ${data['allowFlexibleSchedule']}');
    debugPrint('研究室名: ${data['labName']}');
    debugPrint('所要時間: ${data['duration']}');
    debugPrint('最大参加者数: ${data['maxParticipants']}');
    debugPrint('参加条件: ${data['requirements']}');
    debugPrint('同意項目: ${data['consentItems']}');
    debugPrint('日時スロット数: ${(data['dateTimeSlots'] as List?)?.length ?? 0}');
    debugPrint('同時実験可能人数: ${data['simultaneousCapacity']}');
    debugPrint('固定実験日: ${data['fixedExperimentDate']}');
    debugPrint('固定実験時刻: ${data['fixedExperimentTime']}');
    debugPrint('予約締切日数: ${data['reservationDeadlineDays']}');
    debugPrint('アンケートURL: ${data['surveyUrl']}');
    debugPrint('研究室/個人: ${data['isLabExperiment']}');
    debugPrint('=========================');

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
        debugPrint('Creating slots from dateTimeSlots: ${dateTimeSlots.length}');
        
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
        
        debugPrint('Creating slots - allowFlexible: ${data['allowFlexibleSchedule']}, timeSlots: ${timeSlots.length}');
        debugPrint('Period: $startDate to $endDate');
        debugPrint('TimeSlots data: $timeSlots');
        
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
            
            debugPrint('Date: $currentDate, weekday: $weekday, found slots: ${daySlots.length}');
            
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
      debugPrint('Total slots to create: ${slots.length}');
      if (slots.isNotEmpty) {
        await reservationService.createMultipleSlots(slots);
        debugPrint('Slots created successfully');
      } else {
        debugPrint('No slots to create');
      }
    } else if (data['fixedExperimentDate'] != null && data['fixedExperimentTime'] != null) {
      // 固定日時の場合のスロット作成
      debugPrint('Creating fixed date slot');
      final fixedDate = data['fixedExperimentDate'] as DateTime;
      final fixedTime = data['fixedExperimentTime'] as Map<String, int>;
      final simultaneousCapacity = data['simultaneousCapacity'] as int? ?? 1;
      final duration = data['duration'] as int? ?? 60;
      
      debugPrint('Fixed date: $fixedDate, time: $fixedTime, duration: $duration');
      
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
      debugPrint('Fixed slot created successfully');
    } else {
      debugPrint('No slot creation needed - allowFlexible: ${data['allowFlexibleSchedule']}, fixedDate: ${data['fixedExperimentDate']}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CreateExperimentBase(
      isDemo: false,
      onSave: _handleSave,
    );
  }
}