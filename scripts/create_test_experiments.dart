import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  // Firebase初期化
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyAzaF0kA2p_beAqJRcIUh3JSJUhpLJvCmU",
      authDomain: "waseda-project-ea1e5.firebaseapp.com",
      projectId: "waseda-project-ea1e5",
      storageBucket: "waseda-project-ea1e5.appspot.com",
      messagingSenderId: "1022296387241",
      appId: "1:1022296387241:web:2c3a4e0ca98e36e24ae8c0",
      measurementId: "G-78V1YC3N3H"
    ),
  );

  final firestore = FirebaseFirestore.instance;
  
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
  ];

  // 現在の日時を取得
  final now = DateTime.now();
  
  // 各実験をFirestoreに追加
  for (int i = 0; i < experiments.length; i++) {
    final exp = experiments[i];
    
    // 募集期間を設定（今日から45日後まで）
    final recruitmentStart = now.add(Duration(days: i * 2)); // 少しずつずらす
    final recruitmentEnd = recruitmentStart.add(const Duration(days: 45));
    
    // 実験期間を設定（募集終了の5日後から30日間）
    final experimentStart = recruitmentEnd.add(const Duration(days: 5));
    final experimentEnd = experimentStart.add(const Duration(days: 30));
    
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
      'requirements': exp['requirements'],
      'duration': exp['duration'],
      'reward': exp['reward'],
      'location': exp['location'],
      'category': exp['category'],
      'participantCount': exp['participantCount'],
      'currentParticipants': 0,
      'recruitmentStart': recruitmentStart,
      'recruitmentEnd': recruitmentEnd,
      'experimentStart': experimentStart,
      'experimentEnd': experimentEnd,
      'timeSlots': timeSlots,
      'createdBy': 'yudai5287@ruri.waseda.jp',
      'creatorName': '宮本雄大',
      'createdAt': now,
      'updatedAt': now,
      'status': 'recruiting',
      'isOnline': false,
      'tags': ['早稲田大学', '実験', exp['category']],
      'imageUrl': '',
      'contactEmail': 'yudai5287@ruri.waseda.jp',
      'ethicsApproval': '早稲田大学倫理委員会承認済み（承認番号: 2024-TEST-${(i + 1).toString().padLeft(3, '0')}）',
      'notes': 'テスト用データです。実際の実験ではありません。',
    };
    
    // Firestoreに追加
    await firestore.collection('experiments').add(experimentData);
    print('実験 ${i + 1}/10 を追加しました: ${exp['title']}');
  }
  
  print('\nすべてのテスト実験データの作成が完了しました！');
}