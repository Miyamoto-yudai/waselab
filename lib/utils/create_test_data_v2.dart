import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

/// 改良版テストデータ作成クラス（多様性を重視）
class TestDataCreatorV2 {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Random _random = Random();
  
  /// 実験タイプのリスト
  static final List<String> experimentTypes = ['online', 'onsite', 'survey'];
  
  /// 実験タイプの分配比率
  static final Map<String, double> typeDistribution = {
    'survey': 0.30,  // 30%
    'online': 0.35,  // 35%
    'onsite': 0.35,  // 35%
  };
  
  /// 場所のリスト
  static final List<Map<String, String>> locations = [
    {'name': '早稲田大学 早稲田キャンパス', 'building': '3号館', 'room': '301実験室'},
    {'name': '早稲田大学 西早稲田キャンパス', 'building': '51号館', 'room': 'B1F実験室'},
    {'name': '早稲田大学 戸山キャンパス', 'building': '33号館', 'room': '認知心理学実験室'},
    {'name': '早稲田大学 所沢キャンパス', 'building': '100号館', 'room': 'スポーツ科学実験室'},
    {'name': 'オンライン（Zoom）', 'building': '', 'room': ''},
  ];
  
  /// 研究分野
  static final List<String> categories = [
    '心理学', '認知科学', '脳科学', '工学', '情報工学', 
    'HCI', 'VR/AR', '経済学', '社会学', '言語学', 
    'スポーツ科学', '医学', '生物学', '教育学', 'デザイン'
  ];
  
  /// 実験タイトルのテンプレート
  static final List<Map<String, dynamic>> experimentTemplates = [
    {
      'title': 'VRを用いた{subject}の研究',
      'subject': ['空間認知', '学習効果', '疲労度測定', '共感性', 'プレゼンス'],
      'duration': [30, 45, 60],
      'reward': [1000, 1500, 2000],
    },
    {
      'title': '{method}による{target}の分析',
      'method': ['脳波測定', 'アイトラッキング', '心拍変動', 'fMRI', '行動観察'],
      'target': ['注意力', '集中力', 'ストレス反応', '意思決定', '感情変化'],
      'duration': [60, 90, 120],
      'reward': [2000, 3000, 5000],
    },
    {
      'title': '{product}のユーザビリティ評価',
      'product': ['新型ARアプリ', '学習支援システム', '健康管理アプリ', 'AIアシスタント', 'ゲームUI'],
      'duration': [20, 30, 40],
      'reward': [800, 1000, 1200],
    },
    {
      'title': '{topic}に関するインタビュー調査',
      'topic': ['コロナ後の生活変化', 'SNS利用習慣', '消費者行動', 'ワークライフバランス', '学習スタイル'],
      'duration': [45, 60, 90],
      'reward': [1500, 2000, 2500],
    },
    {
      'title': '{skill}能力の測定実験',
      'skill': ['記憶力', '空間認識', '言語処理', '計算能力', '創造性'],
      'duration': [30, 45, 60],
      'reward': [1000, 1200, 1500],
    },
    {
      'title': '{topic}に関するアンケート調査',
      'topic': ['購買行動', '食生活', '運動習慣', 'メディア利用', '睡眠パターン'],
      'duration': [10, 15, 20],
      'reward': [500, 500, 1000],
    },
    {
      'title': '{method}を用いた{effect}の検証',
      'method': ['ゲーミフィケーション', 'マインドフルネス', 'フィードバック', 'ピアラーニング', 'AI支援'],
      'effect': ['学習効果', 'モチベーション向上', 'ストレス軽減', 'パフォーマンス改善', '創造性向上'],
      'duration': [40, 50, 60],
      'reward': [1200, 1500, 2000],
    },
    {
      'title': '{device}デバイスの{aspect}評価実験',
      'device': ['ウェアラブル', 'スマート家電', 'IoT', 'ヘルスケア', 'フィットネス'],
      'aspect': ['使いやすさ', '精度', '快適性', 'デザイン', '機能性'],
      'duration': [30, 40, 50],
      'reward': [1000, 1200, 1500],
    },
    {
      'title': 'オンライン{activity}の効果測定',
      'activity': ['会議', '授業', 'ワークショップ', 'カウンセリング', 'トレーニング'],
      'duration': [60, 90, 120],
      'reward': [1500, 2000, 3000],
    },
    {
      'title': '{field}分野における意識調査',
      'field': ['環境問題', 'ジェンダー', 'キャリア', 'テクノロジー', '健康意識'],
      'duration': [15, 20, 25],
      'reward': [500, 500, 1000],
    },
  ];
  
  /// 多様な実験データを作成
  static Future<void> createDiverseExperiments({int count = 30}) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('ログインが必要です');
    }
    
    final creatorId = currentUser.uid;
    final creatorEmail = currentUser.email ?? 'unknown@example.com';
    final now = DateTime.now();
    
    
    // タイプ別の作成数を計算
    final surveyCount = (count * typeDistribution['survey']!).round();
    final onlineCount = (count * typeDistribution['online']!).round();
    final onsiteCount = count - surveyCount - onlineCount;
    
    
    // タイプ別のリストを作成
    final List<String> typeSequence = [];
    typeSequence.addAll(List.filled(surveyCount, 'survey'));
    typeSequence.addAll(List.filled(onlineCount, 'online'));
    typeSequence.addAll(List.filled(onsiteCount, 'onsite'));
    typeSequence.shuffle(_random);
    
    for (int i = 0; i < count; i++) {
      try {
        // 実験タイプを順番に取得
        final experimentType = typeSequence[i];
        final isOnline = experimentType == 'online';
        final isSurvey = experimentType == 'survey';
        
        // アンケート調査の場合は特定のテンプレートを優先
        List<Map<String, dynamic>> availableTemplates = experimentTemplates;
        if (isSurvey) {
          // アンケート調査向けのテンプレート（タイトルに「調査」が含まれるもの）
          availableTemplates = experimentTemplates.where((t) => 
            t['title'].toString().contains('調査') || 
            t['title'].toString().contains('アンケート')
          ).toList();
          if (availableTemplates.isEmpty) {
            availableTemplates = experimentTemplates;
          }
        }
        
        // テンプレートを選択
        final template = availableTemplates[_random.nextInt(availableTemplates.length)];
        
        // タイトルを生成
        String title = template['title'] as String;
        for (String key in template.keys) {
          if (key != 'title' && key != 'duration' && key != 'reward') {
            final options = template[key] as List;
            final selected = options[_random.nextInt(options.length)];
            title = title.replaceAll('{$key}', selected);
          }
        }
        
        // 場所を選択（オンラインの場合は固定）
        final locationData = isOnline 
            ? locations.last 
            : locations[_random.nextInt(locations.length - 1)];
        final location = locationData['name']! + 
            (locationData['building']!.isNotEmpty ? ' ${locationData['building']} ${locationData['room']}' : '');
        
        // 期間を設定（バリエーションを持たせる）
        final recruitmentStart = now.add(Duration(days: _random.nextInt(7)));
        final recruitmentDays = 14 + _random.nextInt(30); // 14-44日間
        final recruitmentEnd = recruitmentStart.add(Duration(days: recruitmentDays));
        
        final experimentStart = recruitmentEnd.add(Duration(days: 1 + _random.nextInt(7)));
        final experimentDays = 14 + _random.nextInt(30); // 14-44日間
        final experimentEnd = experimentStart.add(Duration(days: experimentDays));
        
        // 報酬と時間を設定
        final durations = template['duration'] as List<int>;
        final rewards = template['reward'] as List<int>;
        final durationIndex = _random.nextInt(durations.length);
        final duration = durations[durationIndex];
        final baseReward = rewards[durationIndex];
        final reward = baseReward + (_random.nextInt(5) * 100); // ±500円のバリエーション
        
        // 参加者数を設定
        final maxParticipants = 10 + _random.nextInt(40); // 10-50人
        
        // カテゴリをランダムに選択
        final category = categories[_random.nextInt(categories.length)];
        
        // 参加条件を生成
        final requirements = _generateRequirements(experimentType, category);
        
        // 予約スロットを生成（experiment_slotsコレクションに別途保存）
        final slots = await _createExperimentSlots(
          experimentId: '', // 後で更新
          experimentStart: experimentStart,
          experimentEnd: experimentEnd,
          experimentType: experimentType,
          duration: duration,
        );
        
        // 実験データを作成
        final experimentData = {
          'title': title,
          'description': _generateDescription(title, experimentType, duration, category),
          'detailedContent': _generateDetailedContent(title, experimentType, category),
          'requirements': requirements,
          'duration': duration,
          'reward': reward,
          'location': location,
          'category': category,
          'type': experimentType,
          'isPaid': reward > 0,
          'allowFlexibleSchedule': !isSurvey && _random.nextBool(),
          'maxParticipants': maxParticipants,
          'participants': [],
          'labName': '早稲田大学 $category研究室',
          'status': 'recruiting',
          'recruitmentStartDate': Timestamp.fromDate(recruitmentStart),
          'recruitmentEndDate': Timestamp.fromDate(recruitmentEnd),
          'experimentPeriodStart': Timestamp.fromDate(experimentStart),
          'experimentPeriodEnd': Timestamp.fromDate(experimentEnd),
          'dateTimeSlots': [], // 後で更新
          'createdAt': Timestamp.fromDate(now.add(Duration(seconds: i))), // 作成時刻をずらす
          'updatedAt': Timestamp.fromDate(now),
          'creatorId': creatorId,
          'researcherName': 'テスト研究者${i + 1}',
          'researcherEmail': creatorEmail,
          'simultaneousCapacity': 1 + _random.nextInt(3), // 1-3人同時
          'reservationDeadlineDays': 1 + _random.nextInt(3), // 1-3日前締切
        };
        
        // 固定日時の実験の場合
        if (experimentData['allowFlexibleSchedule'] == false && !isSurvey) {
          final fixedDate = experimentStart.add(Duration(days: _random.nextInt(7)));
          experimentData['fixedExperimentDate'] = Timestamp.fromDate(fixedDate);
          experimentData['fixedExperimentTime'] = {
            'hour': 10 + _random.nextInt(8), // 10-17時
            'minute': _random.nextBool() ? 0 : 30,
          };
        }
        
        // Firestoreに保存
        final docRef = await _firestore.collection('experiments').add(experimentData);
        
        // experiment_slotsコレクションにスロットを保存
        if (!isSurvey) {
          await _saveExperimentSlots(docRef.id, experimentStart, experimentEnd, duration);
        }
        
        
      } catch (e) {
      }
    }
    
  }
  
  /// 参加条件を生成
  static List<String> _generateRequirements(String type, String category) {
    final requirements = <String>[];
    
    // 基本条件
    requirements.add('18歳以上の健康な成人');
    
    // タイプ別条件
    if (type == 'online') {
      requirements.add('安定したインターネット環境');
      requirements.add('Webカメラ・マイク使用可能');
    } else if (type == 'onsite') {
      requirements.add('実験室への来訪が可能な方');
    }
    
    // カテゴリ別条件
    if (category.contains('心理') || category.contains('脳')) {
      requirements.add('精神疾患の既往歴がない方');
    }
    if (category.contains('VR') || category.contains('AR')) {
      requirements.add('VR酔いしにくい方');
      requirements.add('視力0.7以上（矯正可）');
    }
    if (category.contains('スポーツ')) {
      requirements.add('運動制限のない方');
    }
    if (category.contains('言語')) {
      requirements.add('日本語母語話者');
    }
    
    return requirements;
  }
  
  /// 説明文を生成
  static String _generateDescription(String title, String type, int duration, String category) {
    String desc = '$categoryの研究として、$titleを実施します。';
    
    if (type == 'online') {
      desc += 'オンライン（Zoom）での実施となり、ご自宅から参加可能です。';
    } else if (type == 'survey') {
      desc += 'アンケート形式の調査で、ご都合の良い時間に回答いただけます。';
    } else {
      desc += '大学の実験室にお越しいただいての実施となります。';
    }
    
    desc += '所要時間は約$duration分です。';
    
    return desc;
  }
  
  /// 詳細内容を生成
  static String _generateDetailedContent(String title, String type, String category) {
    return '''
【研究概要】
本研究は$categoryの観点から、$titleを目的としています。

【実験内容】
1. 事前説明（5分）
2. 実験課題の実施（メイン部分）
3. 事後アンケート（5分）

【注意事項】
- 実験データは匿名化され、研究目的以外には使用されません
- 途中で気分が悪くなった場合は、いつでも中断可能です
- ご不明な点は事前にお問い合わせください

【倫理審査】
本研究は早稲田大学倫理委員会の承認を得ています。
    ''';
  }
  
  /// 予約スロットを生成（ダミー）
  static Future<List<Map<String, dynamic>>> _createExperimentSlots({
    required String experimentId,
    required DateTime experimentStart,
    required DateTime experimentEnd,
    required String experimentType,
    required int duration,
  }) async {
    final slots = <Map<String, dynamic>>[];
    
    // アンケートタイプは予約不要
    if (experimentType == 'survey') {
      return slots;
    }
    
    return slots;
  }
  
  /// experiment_slotsコレクションに予約スロットを保存
  static Future<void> _saveExperimentSlots(
    String experimentId,
    DateTime experimentStart,
    DateTime experimentEnd,
    int duration,
  ) async {
    try {
      // 実験期間中の平日にスロットを作成
      DateTime currentDate = experimentStart;
      int slotCount = 0;
      final maxSlots = 20 + _random.nextInt(30); // 20-50スロット
      
      while (currentDate.isBefore(experimentEnd) && slotCount < maxSlots) {
        // 平日のみ（月曜=1、日曜=7）
        if (currentDate.weekday <= 5) {
          // 1日に2-4スロット作成
          final slotsPerDay = 2 + _random.nextInt(3);
          
          for (int i = 0; i < slotsPerDay; i++) {
            // 時間を設定（9時-17時の間）
            final startHour = 9 + (i * 2) + _random.nextInt(2);
            if (startHour > 17) continue;
            
            final startTime = DateTime(
              currentDate.year,
              currentDate.month,
              currentDate.day,
              startHour,
              _random.nextBool() ? 0 : 30,
            );
            
            final endTime = startTime.add(Duration(minutes: duration));
            
            // experiment_slotsコレクションに保存
            await _firestore.collection('experiment_slots').add({
              'experimentId': experimentId,
              'startTime': Timestamp.fromDate(startTime),
              'endTime': Timestamp.fromDate(endTime),
              'maxCapacity': 1 + _random.nextInt(3), // 1-3人
              'currentCapacity': 0,
              'isAvailable': true,
              'createdAt': Timestamp.fromDate(DateTime.now()),
              'updatedAt': Timestamp.fromDate(DateTime.now()),
            });
            
            slotCount++;
          }
        }
        
        currentDate = currentDate.add(const Duration(days: 1));
      }
      
      
    } catch (e) {
    }
  }
}