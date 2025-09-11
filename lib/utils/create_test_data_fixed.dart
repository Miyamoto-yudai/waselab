import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 修正版テストデータ作成クラス
class TestDataCreatorFixed {
  /// 正確に3件のサンプル実験データを作成
  static Future<void> createExactThreeExperiments() async {
    final firestore = FirebaseFirestore.instance;
    final currentUser = FirebaseAuth.instance.currentUser;
    
    // ログインユーザーがいない場合はエラー
    if (currentUser == null) {
      throw Exception('ログインが必要です');
    }
    
    final creatorId = currentUser.uid;
    final creatorEmail = currentUser.email ?? 'unknown@example.com';
    
    print('テストデータ作成: creatorId=$creatorId, email=$creatorEmail');
    
    // 3つの実験データ
    final experiments = [
      {
        'title': '認知心理学実験：記憶力と学習効果',
        'description': '異なる学習方法が記憶保持に与える影響を調査します。単語リストを使用した記憶実験です。',
        'requirements': ['18歳以上30歳以下', '日本語母語話者', '正常な視力（矯正可）'],
        'duration': 60,
        'reward': 1500,
        'location': '早稲田大学 戸山キャンパス 33号館',
        'type': 'onsite',
      },
      {
        'title': 'オンライン調査：SNS利用と幸福度',
        'description': 'SNSの利用パターンと主観的幸福度の関係を調査します。Zoomでのインタビュー形式です。',
        'requirements': ['20歳以上', 'SNSを日常的に利用', 'Zoom参加可能'],
        'duration': 45,
        'reward': 1200,
        'location': 'オンライン（Zoom）',
        'type': 'online',
      },
      {
        'title': 'VR空間での空間認知実験',
        'description': 'VRヘッドセットを使用して、仮想空間での空間認知能力を測定します。',
        'requirements': ['VR酔いしにくい方', '視力0.7以上（矯正可）', '18歳以上'],
        'duration': 30,
        'reward': 1000,
        'location': '早稲田大学 西早稲田キャンパス 51号館',
        'type': 'onsite',
      },
    ];
    
    // 基準日（今日）
    final now = DateTime.now();
    int createdCount = 0;
    
    for (int i = 0; i < experiments.length; i++) {
      try {
        final exp = experiments[i];
        
        // 募集期間（今日から30日間）
        final recruitmentStart = now.add(Duration(days: i));
        final recruitmentEnd = recruitmentStart.add(const Duration(days: 30));
        
        // 実験期間（募集開始の7日後から30日間）
        final experimentStart = recruitmentStart.add(const Duration(days: 7));
        final experimentEnd = experimentStart.add(const Duration(days: 30));
        
        // 実験データを作成
        final experimentData = {
          'title': exp['title'],
          'description': exp['description'],
          'requirements': exp['requirements'],
          'duration': exp['duration'],
          'reward': exp['reward'],
          'location': exp['location'],
          'type': exp['type'],
          'isPaid': true,
          'allowFlexibleSchedule': true,
          'scheduleType': i % 3 == 0 ? 'fixed' : (i % 3 == 1 ? 'reservation' : 'individual'), // 3種類をローテーション
          'maxParticipants': 30,
          'participants': [],
          'status': 'recruiting',
          'creatorId': creatorId,
          'labName': '早稲田大学 実験心理学研究室',
          'recruitmentStartDate': Timestamp.fromDate(recruitmentStart),
          'recruitmentEndDate': Timestamp.fromDate(recruitmentEnd),
          'experimentPeriodStart': Timestamp.fromDate(experimentStart),
          'experimentPeriodEnd': Timestamp.fromDate(experimentEnd),
          'createdAt': Timestamp.fromDate(now.add(Duration(seconds: i))),
          'updatedAt': Timestamp.fromDate(now),
        };
        
        // Firestoreに保存
        final docRef = await firestore.collection('experiments').add(experimentData);
        
        // scheduleTypeに応じて処理を分岐
        final scheduleType = experimentData['scheduleType'];
        if (scheduleType == 'reservation') {
          // 予約制の場合のみスロットを作成
          await _createExperimentSlots(docRef.id, experimentStart, experimentEnd);
        } else if (scheduleType == 'fixed') {
          // 固定日時の場合は、固定日時情報を追加
          await firestore.collection('experiments').doc(docRef.id).update({
            'fixedExperimentDate': Timestamp.fromDate(experimentStart.add(Duration(days: 7))),
            'fixedExperimentTime': {'hour': 14, 'minute': 0},
          });
        }
        // individualの場合は特別な処理なし（参加者と個別調整）
        
        createdCount++;
        print('実験データ作成 ${i + 1}/3: ${exp['title']}');
        
      } catch (e) {
        print('エラー: $e');
      }
    }
    
    print('完了: $createdCount件の実験データを作成しました');
  }
  
  /// 実験の予約スロットを作成
  static Future<void> _createExperimentSlots(
    String experimentId,
    DateTime experimentStart,
    DateTime experimentEnd,
  ) async {
    final firestore = FirebaseFirestore.instance;
    
    // 実験開始から14日分のスロットを作成
    for (int day = 0; day < 14; day++) {
      final slotDate = experimentStart.add(Duration(days: day));
      
      // 平日のみ（月曜=1、日曜=7）
      if (slotDate.weekday <= 5) {
        // 1日3スロット作成
        final slotTimes = [
          {'hour': 10, 'minute': 0, 'duration': 60},  // 10:00-11:00
          {'hour': 14, 'minute': 0, 'duration': 60},  // 14:00-15:00
          {'hour': 16, 'minute': 0, 'duration': 60},  // 16:00-17:00
        ];
        
        for (final time in slotTimes) {
          final startTime = DateTime(
            slotDate.year,
            slotDate.month,
            slotDate.day,
            time['hour']!,
            time['minute']!,
          );
          
          final endTime = startTime.add(Duration(minutes: time['duration']!));
          
          // experiment_slotsコレクションに保存
          await firestore.collection('experiment_slots').add({
            'experimentId': experimentId,
            'startTime': Timestamp.fromDate(startTime),
            'endTime': Timestamp.fromDate(endTime),
            'maxCapacity': 2,
            'currentCapacity': 0,
            'isAvailable': true,
            'createdAt': Timestamp.fromDate(DateTime.now()),
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });
        }
      }
    }
    
    print('  → 予約スロットを作成しました');
  }
}