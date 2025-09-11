import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/experiment.dart';
import '../services/notification_service.dart';
import '../services/google_calendar_service.dart';

/// 柔軟な日程調整サービス
class FlexibleScheduleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();
  final GoogleCalendarService _calendarService = GoogleCalendarService();

  /// 参加者の個別日程を設定
  Future<void> setParticipantSchedule({
    required String experimentId,
    required String participantId,
    required DateTime scheduledDate,
    String? location,
    String? note,
  }) async {
    try {
      // 実験情報を取得
      final experimentDoc = await _firestore.collection('experiments').doc(experimentId).get();
      if (!experimentDoc.exists) {
        throw Exception('実験が見つかりません');
      }
      
      final experiment = Experiment.fromFirestore(experimentDoc);
      
      // 参加者のスケジュール情報を更新
      final participantSchedule = {
        'scheduledDate': Timestamp.fromDate(scheduledDate),
        'location': location,
        'note': note,
        'confirmedAt': FieldValue.serverTimestamp(),
        'googleCalendarEventIds': <String, String>{}, // 実験者と参加者のカレンダーイベントID
      };
      
      // Firestoreを更新
      await _firestore.collection('experiments').doc(experimentId).update({
        'participantEvaluations.$participantId': participantSchedule,
      });
      
      // 参加者に通知を送信
      final participantDoc = await _firestore.collection('users').doc(participantId).get();
      if (participantDoc.exists) {
        final participantName = participantDoc.data()?['name'] ?? 'ユーザー';
        
        await _notificationService.createScheduleConfirmedNotification(
          userId: participantId,
          experimentTitle: experiment.title,
          scheduledDate: scheduledDate,
          experimentId: experimentId,
        );
        
        // 実験者にも通知を送信
        await _notificationService.createCreatorScheduleNotification(
          creatorId: experiment.creatorId,
          experimentTitle: experiment.title,
          participantName: participantName,
          scheduledDate: scheduledDate,
          experimentId: experimentId,
          participantId: participantId,
        );
      }
      
      // 実験作成者のカレンダーに登録
      if (await _calendarService.isCalendarEnabled()) {
        try {
          final endTime = scheduledDate.add(Duration(minutes: experiment.duration ?? 60));
          final participantDoc = await _firestore.collection('users').doc(participantId).get();
          final participantName = participantDoc.data()?['name'] ?? 'ユーザー';
          
          final creatorEventId = await _calendarService.quickAddReservationToCalendar(
            experimentTitle: experiment.title,
            startTime: scheduledDate,
            endTime: endTime,
            participantName: participantName,
            location: location ?? experiment.location,
            surveyUrl: experiment.surveyUrl,
            type: experiment.type,
          );
          
          if (creatorEventId != null) {
            // カレンダーイベントIDを保存
            await _firestore.collection('experiments').doc(experimentId).update({
              'participantEvaluations.$participantId.googleCalendarEventIds.creator': creatorEventId,
            });
          }
        } catch (e) {
          debugPrint('実験作成者のカレンダー登録エラー: $e');
        }
      }
    } catch (e) {
      debugPrint('日程設定エラー: $e');
      rethrow;
    }
  }
  
  /// 参加者がカレンダーに登録
  Future<String?> addParticipantCalendarEvent({
    required String experimentId,
    required String participantId,
  }) async {
    try {
      // 実験情報を取得
      final experimentDoc = await _firestore.collection('experiments').doc(experimentId).get();
      if (!experimentDoc.exists) {
        throw Exception('実験が見つかりません');
      }
      
      final experiment = Experiment.fromFirestore(experimentDoc);
      final participantSchedule = experiment.participantEvaluations?[participantId];
      
      if (participantSchedule == null || participantSchedule['scheduledDate'] == null) {
        throw Exception('日程が設定されていません');
      }
      
      final scheduledDate = (participantSchedule['scheduledDate'] as Timestamp).toDate();
      final endTime = scheduledDate.add(Duration(minutes: experiment.duration ?? 60));
      final location = participantSchedule['location'] ?? experiment.location;
      
      // 実験作成者の名前を取得
      final creatorDoc = await _firestore.collection('users').doc(experiment.creatorId).get();
      final creatorName = creatorDoc.data()?['name'] ?? '実験者';
      
      // カレンダーに登録
      final eventId = await _calendarService.quickAddReservationToCalendar(
        experimentTitle: experiment.title,
        startTime: scheduledDate,
        endTime: endTime,
        participantName: creatorName, // 実験者の名前を表示
        location: location,
        surveyUrl: experiment.surveyUrl,
        type: experiment.type,
      );
      
      if (eventId != null) {
        // カレンダーイベントIDを保存
        await _firestore.collection('experiments').doc(experimentId).update({
          'participantEvaluations.$participantId.googleCalendarEventIds.participant': eventId,
        });
      }
      
      return eventId;
    } catch (e) {
      debugPrint('参加者のカレンダー登録エラー: $e');
      return null;
    }
  }
  
  /// 日程をキャンセル（カレンダーからも削除）
  Future<void> cancelParticipantSchedule({
    required String experimentId,
    required String participantId,
    String? reason,
  }) async {
    try {
      // 実験情報を取得
      final experimentDoc = await _firestore.collection('experiments').doc(experimentId).get();
      if (!experimentDoc.exists) {
        throw Exception('実験が見つかりません');
      }
      
      final experiment = Experiment.fromFirestore(experimentDoc);
      final participantSchedule = experiment.participantEvaluations?[participantId];
      
      if (participantSchedule != null) {
        // カレンダーイベントを削除
        if (await _calendarService.isCalendarEnabled()) {
          final eventIds = participantSchedule['googleCalendarEventIds'] as Map<String, dynamic>?;
          
          if (eventIds != null) {
            // 実験作成者のカレンダーから削除
            if (eventIds['creator'] != null) {
              try {
                await _calendarService.removeEventFromCalendar(eventIds['creator']);
              } catch (e) {
                debugPrint('実験作成者のカレンダー削除エラー: $e');
              }
            }
            
            // 参加者のカレンダーから削除（参加者自身がキャンセルする場合）
            if (eventIds['participant'] != null) {
              try {
                await _calendarService.removeEventFromCalendar(eventIds['participant']);
              } catch (e) {
                debugPrint('参加者のカレンダー削除エラー: $e');
              }
            }
          }
        }
        
        // Firestoreから日程情報を削除
        await _firestore.collection('experiments').doc(experimentId).update({
          'participantEvaluations.$participantId': FieldValue.delete(),
        });
        
        // 通知を送信
        await _notificationService.createScheduleCancelledNotification(
          userId: participantId,
          experimentTitle: experiment.title,
          experimentId: experimentId,
          reason: reason,
        );
      }
    } catch (e) {
      debugPrint('日程キャンセルエラー: $e');
      rethrow;
    }
  }
}