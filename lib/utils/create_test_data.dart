import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TestDataCreator {
  /// 3件のサンプル実験データを作成
  static Future<void> createSampleExperiments() async {
    final firestore = FirebaseFirestore.instance;
    final currentUser = FirebaseAuth.instance.currentUser;
    
    // ログインユーザーがいない場合はエラー
    if (currentUser == null) {
      throw Exception('ログインが必要です');
    }
    
    final creatorId = currentUser.uid;
    final creatorEmail = currentUser.email ?? 'unknown@example.com';
    
    
    // 最初の3件のみを使用
    final sampleExperiments = [
      {
        'title': '記憶力と学習効果に関する認知心理学実験',
        'description': '単語リストを用いた記憶力測定実験です。異なる学習方法が記憶の保持にどのような影響を与えるかを調査します。実験は約60分程度で、休憩を挟みながら進行します。',
        'requirements': '・日本語を母語とする方\n・正常な視力（矯正視力可）\n・18歳以上30歳以下の学生',
        'duration': 60,
        'reward': 1500,
        'location': '早稲田大学 戸山キャンパス 33号館 認知心理学実験室',
        'category': '心理学',
        'participantCount': 30,
      },
      {
        'title': '音声認識システムの精度評価実験',
        'description': '新しく開発した音声認識AIの性能評価を行います。様々な文章を読み上げていただき、認識精度を測定します。騒音環境と静音環境での比較も行います。',
        'requirements': '・日本語ネイティブスピーカー\n・発声に問題がない方\n・約90分の実験時間を確保できる方',
        'duration': 90,
        'reward': 2000,
        'location': '早稲田大学 西早稲田キャンパス 63号館 音響実験室',
        'category': '工学',
        'participantCount': 25,
      },
      {
        'title': 'VR空間における空間認知能力の測定',
        'description': 'VRヘッドセットを使用した空間認知能力の測定実験です。仮想空間内でのナビゲーションタスクを行っていただきます。VR酔いしやすい方はご遠慮ください。',
        'requirements': '・VR体験に抵抗がない方\n・3D酔いしにくい方\n・視力0.7以上（矯正可）',
        'duration': 45,
        'reward': 1200,
        'location': '早稲田大学 西早稲田キャンパス 55号館 VR実験室',
        'category': '工学',
        'participantCount': 20,
      },
    ];
    
    // 基準日（今日）
    final now = DateTime.now();
    
    for (int i = 0; i < sampleExperiments.length; i++) {
      final exp = sampleExperiments[i];
      
      // 募集期間を長めに設定（1ヶ月半）
      final recruitmentStart = now.add(Duration(days: i * 2));
      final recruitmentEnd = recruitmentStart.add(const Duration(days: 45));
      
      // 実験期間（募集開始から2週間後から1ヶ月間）
      final experimentStart = recruitmentStart.add(const Duration(days: 14));
      final experimentEnd = experimentStart.add(const Duration(days: 30));
      
      // 予約候補日時の生成（dateTimeSlots）
      final List<Map<String, dynamic>> dateTimeSlots = [];
      for (int day = 0; day < 10; day++) { // 10日分のスロットを生成
        final slotDate = experimentStart.add(Duration(days: day));
        // 平日のみスロットを追加
        if (slotDate.weekday <= 5) {
          // 午前スロット (10:00-11:00)
          dateTimeSlots.add({
            'date': slotDate.toIso8601String(),
            'startHour': 10,
            'startMinute': 0,
            'endHour': 11,
            'endMinute': 0,
            'maxCapacity': 2,
            'isAvailable': true,
          });
          // 午後スロット (14:00-15:00)
          dateTimeSlots.add({
            'date': slotDate.toIso8601String(),
            'startHour': 14,
            'startMinute': 0,
            'endHour': 15,
            'endMinute': 0,
            'maxCapacity': 2,
            'isAvailable': true,
          });
          // 夕方スロット (16:00-17:00)
          dateTimeSlots.add({
            'date': slotDate.toIso8601String(),
            'startHour': 16,
            'startMinute': 0,
            'endHour': 17,
            'endMinute': 0,
            'maxCapacity': 1,
            'isAvailable': true,
          });
        }
      }
      
      // Firestoreにデータを追加（Timestampを使用）
      await firestore.collection('experiments').add({
        'title': exp['title'],
        'description': exp['description'],
        'requirements': exp['requirements'] is String 
          ? (exp['requirements'] as String).split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
          : List<String>.from(exp['requirements'] as List), // requirementsを配列として保存
        'duration': exp['duration'],
        'reward': exp['reward'],
        'location': exp['location'],
        'category': exp['category'],
        'participantCount': exp['participantCount'],
        'maxParticipants': exp['participantCount'], // 最大参加者数
        'participants': [], // 参加者リスト（空配列で初期化）
        'type': 'onsite', // 実験タイプ（すべて対面）
        'labName': '早稲田大学 ${exp['category']}研究室', // 研究室名
        'isPaid': (exp['reward'] as int) > 0, // 有償かどうか
        'allowFlexibleSchedule': true, // 柔軟なスケジュール対応
        'scheduleType': 'reservation', // デフォルトは予約制
        'status': 'recruiting',
        'recruitmentStart': Timestamp.fromDate(recruitmentStart),
        'recruitmentEnd': Timestamp.fromDate(recruitmentEnd),
        'recruitmentStartDate': Timestamp.fromDate(recruitmentStart), // 重複フィールド（互換性のため）
        'recruitmentEndDate': Timestamp.fromDate(recruitmentEnd),
        'experimentStart': Timestamp.fromDate(experimentStart),
        'experimentEnd': Timestamp.fromDate(experimentEnd),
        'experimentPeriodStart': Timestamp.fromDate(experimentStart), // 重複フィールド（互換性のため）
        'experimentPeriodEnd': Timestamp.fromDate(experimentEnd),
        'dateTimeSlots': dateTimeSlots, // 予約候補日時を追加
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'creatorId': creatorId, // 現在のユーザーIDを使用
        'researcherName': 'テスト研究者',
        'researcherEmail': creatorEmail,
      });
      
    }
    
  }
  
  /// 30件のテスト実験データを作成
  static Future<void> createTestExperiments() async {
    final firestore = FirebaseFirestore.instance;
    final currentUser = FirebaseAuth.instance.currentUser;
    
    // ログインユーザーがいない場合はエラー
    if (currentUser == null) {
      throw Exception('ログインが必要です');
    }
    
    final creatorId = currentUser.uid;
    final creatorEmail = currentUser.email ?? 'unknown@example.com';
    
    
    // テスト実験データのリスト
    final experiments = [
      {
        'title': '記憶力と学習効果に関する認知心理学実験',
        'description': '単語リストを用いた記憶力測定実験です。異なる学習方法が記憶の保持にどのような影響を与えるかを調査します。実験は約60分程度で、休憩を挟みながら進行します。',
        'requirements': '・日本語を母語とする方\n・正常な視力（矯正視力可）\n・18歳以上30歳以下の学生',
        'duration': 60,
        'reward': 1500,
        'location': '早稲田大学 戸山キャンパス 33号館 認知心理学実験室',
        'category': '心理学',
        'participantCount': 30,
      },
      {
        'title': '音声認識システムの精度評価実験',
        'description': '新しく開発した音声認識AIの性能評価を行います。様々な文章を読み上げていただき、認識精度を測定します。騒音環境と静音環境での比較も行います。',
        'requirements': '・日本語ネイティブスピーカー\n・発声に問題がない方\n・約90分の実験時間を確保できる方',
        'duration': 90,
        'reward': 2000,
        'location': '早稲田大学 西早稲田キャンパス 63号館 音響実験室',
        'category': '工学',
        'participantCount': 25,
      },
      {
        'title': 'VR空間における空間認知能力の測定',
        'description': 'VRヘッドセットを使用した空間認知能力の測定実験です。仮想空間内でのナビゲーションタスクを行っていただきます。VR酔いしやすい方はご遠慮ください。',
        'requirements': '・VR体験に抵抗がない方\n・3D酔いしにくい方\n・視力0.7以上（矯正可）',
        'duration': 45,
        'reward': 1200,
        'location': '早稲田大学 西早稲田キャンパス 55号館 VR実験室',
        'category': '工学',
        'participantCount': 20,
      },
      {
        'title': '消費者行動に関するマーケティング調査',
        'description': '商品選択における意思決定プロセスを調査します。複数の商品から選択する課題と、その選択理由についてのインタビューを行います。',
        'requirements': '・日常的に買い物をする方\n・20歳以上の成人\n・約40分のインタビューに協力できる方',
        'duration': 40,
        'reward': 1000,
        'location': '早稲田大学 早稲田キャンパス 11号館 行動経済学実験室',
        'category': '経済学',
        'participantCount': 40,
      },
      {
        'title': '運動パフォーマンスと疲労の関係性調査',
        'description': '軽い運動課題を行い、疲労度とパフォーマンスの関係を測定します。激しい運動ではありませんが、運動着をご持参ください。',
        'requirements': '・健康な方\n・運動制限がない方\n・運動着を持参できる方',
        'duration': 75,
        'reward': 1800,
        'location': '早稲田大学 所沢キャンパス スポーツ科学実験室',
        'category': 'スポーツ科学',
        'participantCount': 15,
      },
      {
        'title': '日本語学習者のための発音評価システム開発',
        'description': '日本語学習支援システムの開発のため、日本語の発音データを収集します。簡単な文章や単語を読み上げていただきます。',
        'requirements': '・日本語母語話者\n・標準的な日本語を話せる方\n・録音に同意いただける方',
        'duration': 50,
        'reward': 1300,
        'location': '早稲田大学 戸山キャンパス 36号館 言語学実験室',
        'category': '言語学',
        'participantCount': 35,
      },
      {
        'title': '脳波測定による集中力の評価実験',
        'description': '簡単な認知課題を行いながら脳波を測定し、集中力との関連を調査します。脳波測定は完全に非侵襲的で安全です。',
        'requirements': '・健康な方\n・頭皮に傷や炎症がない方\n・実験前日は十分な睡眠を取れる方',
        'duration': 120,
        'reward': 3000,
        'location': '早稲田大学 TWIns 脳科学研究室',
        'category': '神経科学',
        'participantCount': 10,
      },
      {
        'title': '食品の味覚評価と嗜好性調査',
        'description': '新商品開発のための味覚評価実験です。複数の食品サンプルを試食し、味や食感について評価していただきます。',
        'requirements': '・食物アレルギーがない方\n・味覚に異常がない方\n・実験2時間前から飲食を控えられる方',
        'duration': 30,
        'reward': 800,
        'location': '早稲田大学 西早稲田キャンパス 食品科学実験室',
        'category': '生物学',
        'participantCount': 50,
      },
      {
        'title': 'ARアプリケーションのユーザビリティ評価',
        'description': '開発中のARアプリケーションの使いやすさを評価していただきます。スマートフォンを使用した簡単な操作テストです。',
        'requirements': '・スマートフォン（iOS/Android）をお持ちの方\n・ARアプリの使用経験は不問\n・約45分の評価に協力できる方',
        'duration': 45,
        'reward': 1200,
        'location': '早稲田大学 西早稲田キャンパス 51号館 HCI実験室',
        'category': '工学',
        'participantCount': 30,
      },
      {
        'title': '社会的意思決定に関する行動経済学実験',
        'description': '他者との協力や競争場面での意思決定を調査します。ゲーム理論に基づいた実験で、実験結果に応じて追加報酬があります。',
        'requirements': '・18歳以上の学生\n・日本語での説明を理解できる方\n・約60分の実験に参加できる方',
        'duration': 60,
        'reward': 1500,
        'location': '早稲田大学 早稲田キャンパス 3号館 実験経済学ラボ',
        'category': '経済学',
        'participantCount': 24,
      },
      // 追加の20件
      {
        'title': 'オンライン学習効果の検証実験',
        'description': 'Zoomを使用したオンライン実験です。自宅から参加可能で、新しい学習アプリの効果を測定します。カメラONでの参加が必要です。',
        'requirements': '・安定したインターネット環境\n・Webカメラ付きPC\n・静かな環境で参加できる方',
        'duration': 30,
        'reward': 1000,
        'location': 'オンライン（Zoom）',
        'category': '教育学',
        'participantCount': 100,
        'isOnline': true,
      },
      {
        'title': '睡眠の質と認知機能の関係性調査（3日間）',
        'description': '3日間連続での参加が必要な実験です。睡眠記録デバイスを貸与し、日中の認知機能テストを行います。',
        'requirements': '・3日間連続で参加可能な方\n・規則正しい生活を送れる方\n・睡眠障害のない方',
        'duration': 180,
        'reward': 5000,
        'location': '早稲田大学 所沢キャンパス 睡眠研究室',
        'category': '神経科学',
        'participantCount': 8,
      },
      {
        'title': 'ストレス反応の生理学的測定',
        'description': '軽度のストレス課題中の心拍数、血圧、唾液中コルチゾールを測定します。医師立ち会いのもと安全に実施します。',
        'requirements': '・健康な成人\n・心臓疾患のない方\n・薬物治療を受けていない方',
        'duration': 90,
        'reward': 2500,
        'location': '早稲田大学 TWIns 医学研究棟',
        'category': '医学',
        'participantCount': 15,
      },
      {
        'title': 'AI音声アシスタントとの対話実験',
        'description': '開発中のAI音声アシスタントと自然な会話をしていただきます。様々なシナリオでの対話を評価します。',
        'requirements': '・日本語での自然な会話ができる方\n・AIとの対話に抵抗がない方',
        'duration': 40,
        'reward': 1200,
        'location': '早稲田大学 西早稲田キャンパス AI研究室',
        'category': '情報工学',
        'participantCount': 50,
      },
      {
        'title': '環境音が作業効率に与える影響',
        'description': '異なる環境音（自然音、都市音、無音など）の中で作業を行い、集中力と生産性を測定します。',
        'requirements': '・聴覚に問題がない方\n・PC基本操作ができる方',
        'duration': 60,
        'reward': 1400,
        'location': '早稲田大学 戸山キャンパス 音響心理実験室',
        'category': '心理学',
        'participantCount': 40,
      },
      {
        'title': '顔認識技術の精度評価（写真撮影あり）',
        'description': '様々な角度・照明条件での顔写真を撮影し、顔認識システムの精度を評価します。撮影データは研究目的のみに使用します。',
        'requirements': '・顔写真の撮影に同意できる方\n・メイクなしでも参加可能な方',
        'duration': 45,
        'reward': 1500,
        'location': '早稲田大学 西早稲田キャンパス 画像処理研究室',
        'category': '工学',
        'participantCount': 60,
      },
      {
        'title': '筋電図を用いた運動制御メカニズムの解析',
        'description': '表面筋電図を装着して簡単な運動タスクを行います。運動制御の神経メカニズムを調査します。',
        'requirements': '・運動制限のない健康な方\n・筋肉疾患のない方',
        'duration': 75,
        'reward': 2000,
        'location': '早稲田大学 所沢キャンパス バイオメカニクス実験室',
        'category': 'スポーツ科学',
        'participantCount': 20,
      },
      {
        'title': '瞑想アプリの効果検証（2週間プログラム）',
        'description': '2週間毎日10分の瞑想アプリを使用し、前後でストレスレベルと幸福度を測定します。アプリは無料提供します。',
        'requirements': '・2週間継続できる方\n・スマートフォンをお持ちの方\n・瞑想初心者歓迎',
        'duration': 30,
        'reward': 3000,
        'location': 'オンライン＋初回・最終回は大学',
        'category': '心理学',
        'participantCount': 30,
        'isOnline': true,
      },
      {
        'title': '新製品パッケージデザインの評価',
        'description': 'アイトラッキング装置を使用して、商品パッケージのどこに視線が集まるかを測定します。',
        'requirements': '・視力0.5以上（矯正可）\n・色覚に異常がない方',
        'duration': 35,
        'reward': 1000,
        'location': '早稲田大学 早稲田キャンパス マーケティング研究室',
        'category': '経営学',
        'participantCount': 80,
      },
      {
        'title': '多言語話者の脳活動測定（fMRI使用）',
        'description': 'fMRIを使用して、複数言語を話す際の脳活動を測定します。MRI検査の経験がなくても安全に参加できます。',
        'requirements': '・2言語以上話せる方\n・体内に金属がない方\n・閉所恐怖症でない方',
        'duration': 120,
        'reward': 5000,
        'location': '早稲田大学 TWIns 脳機能イメージングセンター',
        'category': '神経科学',
        'participantCount': 12,
      },
      {
        'title': 'ロボットとの協調作業実験',
        'description': '協働ロボットと一緒に組み立て作業を行い、人間とロボットの最適な協調方法を研究します。',
        'requirements': '・ロボットとの作業に抵抗がない方\n・簡単な組み立て作業ができる方',
        'duration': 50,
        'reward': 1600,
        'location': '早稲田大学 西早稲田キャンパス ロボティクス研究室',
        'category': '工学',
        'participantCount': 25,
      },
      {
        'title': '化粧品の使用感評価（パッチテスト含む）',
        'description': '新開発の化粧品の使用感を評価します。事前にパッチテストを行い、安全性を確認します。',
        'requirements': '・敏感肌でない方\n・化粧品アレルギーのない方\n・女性限定',
        'duration': 60,
        'reward': 2000,
        'location': '早稲田大学 西早稲田キャンパス 皮膚科学実験室',
        'category': '生物学',
        'participantCount': 30,
      },
      {
        'title': '歩行動作の3Dモーションキャプチャ',
        'description': 'モーションキャプチャスーツを着用して歩行動作を記録し、歩行パターンを分析します。',
        'requirements': '・歩行に問題がない方\n・タイトな服装で参加可能な方',
        'duration': 45,
        'reward': 1800,
        'location': '早稲田大学 所沢キャンパス 動作解析室',
        'category': 'スポーツ科学',
        'participantCount': 35,
      },
      {
        'title': '気候変動に関する意識調査（グループディスカッション）',
        'description': '6-8名のグループで気候変動について議論し、集団での意思決定プロセスを観察します。',
        'requirements': '・日本語での議論に参加できる方\n・他者の意見を尊重できる方',
        'duration': 90,
        'reward': 1700,
        'location': '早稲田大学 早稲田キャンパス 社会学実験室',
        'category': '社会学',
        'participantCount': 48,
      },
      {
        'title': 'バーチャル観光体験の評価',
        'description': 'VRゴーグルで世界各地の観光地を体験し、実際の旅行との比較評価を行います。',
        'requirements': '・VR酔いしにくい方\n・30分以上VRゴーグル着用可能な方',
        'duration': 40,
        'reward': 1300,
        'location': '早稲田大学 国際会議場 VR体験室',
        'category': '観光学',
        'participantCount': 45,
      },
      {
        'title': '香りが購買行動に与える影響',
        'description': '様々な香りの環境下で商品選択を行い、香りが消費者行動に与える影響を調査します。',
        'requirements': '・嗅覚に異常がない方\n・香料アレルギーがない方',
        'duration': 55,
        'reward': 1400,
        'location': '早稲田大学 早稲田キャンパス 感覚心理学実験室',
        'category': '心理学',
        'participantCount': 55,
      },
      {
        'title': '手書き文字認識システムの開発支援',
        'description': 'タブレットで様々な文字を書いていただき、手書き文字認識AIの学習データを収集します。',
        'requirements': '・日本語の読み書きができる方\n・タブレット操作が可能な方',
        'duration': 30,
        'reward': 900,
        'location': '早稲田大学 西早稲田キャンパス 情報工学実験室',
        'category': '情報工学',
        'participantCount': 100,
      },
      {
        'title': '音楽が感情に与える影響の脳波測定',
        'description': '様々なジャンルの音楽を聴きながら脳波を測定し、音楽と感情の関係を調査します。',
        'requirements': '・音楽鑑賞が好きな方\n・45分間座位保持可能な方',
        'duration': 45,
        'reward': 1500,
        'location': '早稲田大学 戸山キャンパス 音楽心理学研究室',
        'category': '芸術学',
        'participantCount': 40,
      },
      {
        'title': '災害避難シミュレーションゲーム',
        'description': 'VR環境での災害避難シミュレーションに参加し、避難行動パターンを分析します。',
        'requirements': '・VR体験可能な方\n・災害シミュレーションに心理的抵抗がない方',
        'duration': 60,
        'reward': 1800,
        'location': '早稲田大学 西早稲田キャンパス 防災研究センター',
        'category': '防災学',
        'participantCount': 30,
      },
      {
        'title': '新型コロナ後の生活様式に関するインタビュー',
        'description': 'コロナ禍を経験した後の生活変化について、1対1の詳細なインタビューを行います。',
        'requirements': '・20歳以上の方\n・60分程度のインタビューに応じられる方',
        'duration': 60,
        'reward': 2000,
        'location': 'オンライン（Zoom）または対面選択可',
        'category': '社会学',
        'participantCount': 20,
        'isOnline': true,
      },
    ];

    // 現在の日時を取得
    final now = DateTime.now();
    
    // 各実験をFirestoreに追加
    int successCount = 0;
    for (int i = 0; i < experiments.length; i++) {
      try {
        final exp = experiments[i];
        
        // 募集期間を設定（今日から45日後まで）
        final recruitmentStart = now.add(Duration(days: i * 2)); // 少しずつずらす
        final recruitmentEnd = recruitmentStart.add(const Duration(days: 45));
        
        // 実験期間を設定（募集終了の5日後から30日間）
        final experimentStart = recruitmentEnd.add(const Duration(days: 5));
        final experimentEnd = experimentStart.add(const Duration(days: 30));
        
        // 予約候補日時の生成（dateTimeSlots）
        final List<Map<String, dynamic>> dateTimeSlots = [];
        for (int day = 0; day < 14; day++) { // 14日分のスロットを生成
          final slotDate = experimentStart.add(Duration(days: day));
          // 平日のみスロットを追加
          if (slotDate.weekday <= 5) {
            // 朝スロット (9:00-10:30)
            dateTimeSlots.add({
              'date': slotDate.toIso8601String(),
              'startHour': 9,
              'startMinute': 0,
              'endHour': 10,
              'endMinute': 30,
              'maxCapacity': 3,
              'isAvailable': true,
            });
            // 午前スロット (11:00-12:30)
            dateTimeSlots.add({
              'date': slotDate.toIso8601String(),
              'startHour': 11,
              'startMinute': 0,
              'endHour': 12,
              'endMinute': 30,
              'maxCapacity': 2,
              'isAvailable': true,
            });
            // 午後スロット (13:30-15:00)
            dateTimeSlots.add({
              'date': slotDate.toIso8601String(),
              'startHour': 13,
              'startMinute': 30,
              'endHour': 15,
              'endMinute': 0,
              'maxCapacity': 2,
              'isAvailable': true,
            });
            // 夕方スロット (15:30-17:00)
            dateTimeSlots.add({
              'date': slotDate.toIso8601String(),
              'startHour': 15,
              'startMinute': 30,
              'endHour': 17,
              'endMinute': 0,
              'maxCapacity': 2,
              'isAvailable': true,
            });
          }
        }
        
        // タイムスロットを生成（平日の午後）
        final Map<String, dynamic> timeSlots = {};
        for (int day = 0; day < 30; day++) {
          final date = experimentStart.add(Duration(days: day));
          if (date.weekday <= 5) { // 平日のみ
            final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
            timeSlots[dateKey] = {
              '14:00': {'available': true, 'capacity': 2},
              '15:00': {'available': true, 'capacity': 2},
              '16:00': {'available': true, 'capacity': 2},
              '17:00': {'available': true, 'capacity': 2},
            };
          }
        }
        
        final experimentData = {
          'title': exp['title'],
          'description': exp['description'],
          'requirements': exp['requirements'] is String 
            ? (exp['requirements'] as String).split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
            : List<String>.from(exp['requirements'] as List), // requirementsを配列として保存
          'duration': exp['duration'],
          'reward': exp['reward'],
          'location': exp['location'],
          'category': exp['category'],
          'participantCount': exp['participantCount'],
          'currentParticipants': 0,
          'maxParticipants': exp['participantCount'], // 最大参加者数
          'participants': [], // 参加者リスト（空配列で初期化）
          'type': exp['isOnline'] == true ? 'online' : 'onsite', // 実験タイプ
          'recruitmentStart': Timestamp.fromDate(recruitmentStart),
          'recruitmentEnd': Timestamp.fromDate(recruitmentEnd),
          'recruitmentStartDate': Timestamp.fromDate(recruitmentStart), // 募集開始日も追加
          'recruitmentEndDate': Timestamp.fromDate(recruitmentEnd), // 募集終了日も追加
          'experimentStart': Timestamp.fromDate(experimentStart),
          'experimentEnd': Timestamp.fromDate(experimentEnd),
          'experimentPeriodStart': Timestamp.fromDate(experimentStart), // 実験開始日
          'experimentPeriodEnd': Timestamp.fromDate(experimentEnd), // 実験終了日
          'dateTimeSlots': dateTimeSlots, // 予約候補日時を追加
          'timeSlots': timeSlots,
          'creatorId': creatorId, // 現在のユーザーIDを使用
          'creatorName': 'テスト研究者',
          'labName': '早稲田大学 ${exp['category']}研究室', // 研究室名
          'createdAt': Timestamp.fromDate(now),
          'updatedAt': Timestamp.fromDate(now),
          'status': 'recruiting',
          'isOnline': exp['isOnline'] ?? false,
          'isPaid': (exp['reward'] as int) > 0, // 有償かどうか
          'allowFlexibleSchedule': true, // 柔軟なスケジュール対応
          'scheduleType': _getScheduleType(i), // スケジュールタイプを振り分け
          'fixedExperimentDate': _getScheduleType(i) == 'fixed' ? Timestamp.fromDate(experimentStart.add(Duration(days: 7))) : null,
          'fixedExperimentTime': _getScheduleType(i) == 'fixed' ? {'hour': 14, 'minute': 0} : null,
          'tags': ['早稲田大学', '実験', exp['category'].toString()],
          'imageUrl': '',
          'contactEmail': creatorEmail,
          'ethicsApproval': '早稲田大学倫理委員会承認済み（承認番号: 2024-TEST-${(i + 1).toString().padLeft(3, '0')}）',
          'notes': 'テスト用データです。実際の実験ではありません。',
        };
        
        // Firestoreに追加
        await firestore.collection('experiments').add(experimentData);
        successCount++;
      } catch (e) {
        // エラーをログに記録
        continue;
      }
    }
    
    return;
  }
  
  /// インデックスに基づいてスケジュールタイプを決定
  static String _getScheduleType(int index) {
    // 30件を3つのタイプに均等に振り分け
    if (index % 3 == 0) {
      return 'fixed'; // 固定日時
    } else if (index % 3 == 1) {
      return 'reservation'; // 予約制
    } else {
      return 'individual'; // 個別調整
    }
  }
}