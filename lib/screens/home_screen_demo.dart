import 'package:flutter/material.dart';
import '../models/experiment.dart';
import '../services/demo_auth_service.dart';
import '../widgets/home_screen_base.dart';
import 'create_experiment_screen_demo.dart';
import 'my_page_screen_demo.dart';
import 'messages_screen_demo.dart';

/// デモ用ホーム画面（Firebase不要）
class HomeScreenDemo extends StatefulWidget {
  final DemoAuthService authService;
  final VoidCallback onLogout;
  
  const HomeScreenDemo({
    super.key,
    required this.authService,
    required this.onLogout,
  });

  @override
  State<HomeScreenDemo> createState() => _HomeScreenDemoState();
}

class _HomeScreenDemoState extends State<HomeScreenDemo> {
  // デモ用の未読メッセージ数
  final int _unreadMessages = 3;
  
  // 現在のユーザーのIDを取得（一貫性のあるIDを使用）
  String? get currentUserId => widget.authService.currentUser?.uid ?? 'demo_user_main';
  
  // デモ用の実験データ（一部を現在のユーザーの実験として設定）
  late final List<Experiment> _experiments = [
    Experiment(
      id: '1',
      title: '視覚認知実験への参加者募集',
      description: '画面に表示される図形を見て、特定のパターンを見つける実験です。所要時間は約30分です。',
      detailedContent: '本実験では、視覚的注意のメカニズムと図形認識における脳内処理過程を調査します。\n\n【実験の流れ】\n1. 実験説明と同意書への署名（5分）\n2. 練習試行（5分）\n3. 本試行（20分）\n   - 画面に様々な図形が表示されます\n   - 特定のパターンを見つけたらボタンを押してください\n   - 反応時間と正答率を測定します\n\n【測定項目】\n- 視覚探索課題における反応時間\n- パターン認識の正確性\n- 注意の持続性\n\n【注意事項】\n- 実験中は集中できる環境でご参加ください\n- 眼鏡・コンタクトレンズは着用可能です\n- 実験データは匿名化され、研究目的のみに使用されます',
      reward: 1500,
      location: '早稲田大学 戸山キャンパス 33号館',
      type: ExperimentType.onsite,
      isPaid: true,
      creatorId: 'demo_user_main', // 自分の実験として設定
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      recruitmentStartDate: DateTime.now(),
      recruitmentEndDate: DateTime.now().add(const Duration(days: 14)),
      experimentPeriodStart: DateTime.now().add(const Duration(days: 7)),
      experimentPeriodEnd: DateTime.now().add(const Duration(days: 21)),
      allowFlexibleSchedule: true,
      labName: '認知科学研究室',
      duration: 30,
      maxParticipants: 20,
      requirements: ['視力矯正後1.0以上', '色覚正常'],
    ),
    Experiment(
      id: '2',
      title: 'オンラインアンケート調査',
      description: '大学生の生活習慣に関するアンケート調査です。スマートフォンからも回答可能です。',
      detailedContent: 'コロナ禍を経た大学生の生活様式の変化について調査を行います。\n\n【調査内容】\n- 日常の生活リズム（起床・就寝時間、食事時間など）\n- 学習環境と学習方法の変化\n- オンライン授業と対面授業の比較\n- 課外活動への参加状況\n- ストレス管理と心理的健康\n\n【回答形式】\n- 選択式質問：約30問\n- 自由記述：3問\n\n【データの取り扱い】\n- 個人情報は統計的に処理され、個人が特定されることはありません\n- 研究成果は学会発表や論文として公表予定です\n- 回答データは研究終了後、適切に破棄されます\n\n【謝礼について】\n回答完了後、1週間以内にAmazonギフト券をメールで送付いたします',
      reward: 500,
      location: 'オンライン（Zoomリンクを送付）',
      type: ExperimentType.survey,
      isPaid: true,
      creatorId: 'demo_user_2',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      recruitmentStartDate: DateTime.now(),
      recruitmentEndDate: DateTime.now().add(const Duration(days: 10)),
      allowFlexibleSchedule: false,
      labName: '社会心理学研究室',
      duration: 15,
      maxParticipants: 100,
      requirements: ['早稲田大学の学部生'],
    ),
    Experiment(
      id: '3',
      title: '心理学実験の被験者募集（無償）',
      description: '簡単な認知課題を行っていただきます。研究室の卒業論文のデータ収集にご協力ください。',
      detailedContent: '卒業論文「ワーキングメモリと課題切り替えの関係」のためのデータ収集にご協力ください。\n\n【実験内容】\nコンピュータ画面上で以下の課題を行っていただきます：\n1. 数字記憶課題（数字の列を記憶し、再生する）\n2. 文字判断課題（表示される文字が母音か子音かを判断）\n3. 課題切り替え課題（上記2つの課題を交互に実施）\n\n【研究の意義】\nこの研究は、人間の認知的柔軟性のメカニズム解明に貢献し、将来的には学習支援や認知トレーニングの開発に役立つことが期待されます。\n\n【参加特典】\n- 実験終了後、ご自身の認知機能プロフィールをフィードバック\n- 希望者には研究成果の要約を送付\n- 心理学実験への参加証明書を発行可能\n\n無償での参加となりますが、心理学研究への貢献にご協力いただければ幸いです。',
      reward: 0,
      location: '早稲田大学 西早稲田キャンパス 51号館',
      type: ExperimentType.onsite,
      isPaid: false,
      creatorId: 'demo_user_3',
      participants: ['demo_user_main'], // 参加予定として設定
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      recruitmentStartDate: DateTime.now(),
      recruitmentEndDate: DateTime.now().add(const Duration(days: 12)),
      experimentPeriodStart: DateTime.now().add(const Duration(days: 5)),
      experimentPeriodEnd: DateTime.now().add(const Duration(days: 15)),
      allowFlexibleSchedule: true,
      labName: '実験心理学研究室',
      duration: 45,
      maxParticipants: 15,
      requirements: ['日本語ネイティブスピーカー'],
    ),
    Experiment(
      id: '4',
      title: '記憶力測定実験',
      description: '短期記憶と長期記憶の関係を調べる実験です。単語や数字の記憶テストを行います。',
      detailedContent: '記憶の符号化、保持、検索過程について詳細に調査する実験です。\n\n【実験課題】\n1. 単語リスト記憶課題\n   - 日本語単語20個を提示\n   - 即時再生テストと遅延再生テスト（30分後）\n\n2. 数字スパン課題\n   - 順唱および逆唱課題\n   - 徐々に桁数を増やしていきます\n\n3. 物語記憶課題\n   - 短い物語を聞いて、内容を再生\n\n【測定内容】\n- 記憶容量の個人差\n- 記憶方略の使用傾向\n- 干渉効果の影響\n\n【実験環境】\n- 静かな実験室で個別に実施\n- 休憩時間を含みます\n- 実験後にデブリーフィングを行います',
      reward: 2000,
      location: '早稲田大学 戸山キャンパス 34号館',
      type: ExperimentType.onsite,
      isPaid: true,
      creatorId: 'demo_user_4',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      recruitmentStartDate: DateTime.now(),
      recruitmentEndDate: DateTime.now().add(const Duration(days: 11)),
      experimentPeriodStart: DateTime.now().add(const Duration(days: 4)),
      experimentPeriodEnd: DateTime.now().add(const Duration(days: 14)),
      allowFlexibleSchedule: true,
      labName: '認知心理学研究室',
      duration: 45,
      maxParticipants: 15,
      requirements: ['日本語ネイティブスピーカー', '20-30歳'],
    ),
    Experiment(
      id: '5',
      title: 'VR空間での行動観察実験',
      description: 'VRヘッドセットを使用した仮想空間での行動パターンを観察します。',
      detailedContent: '最新のVR技術を用いて、仮想環境における人間の空間認知と行動決定プロセスを研究します。\n\n【使用機器】\n- Meta Quest 3\n- ハンドトラッキング機能使用\n- 6DoF（6自由度）トラッキング\n\n【実験内容】\n1. VR環境への順応（10分）\n2. 仮想迷路課題（20分）\n3. 物体操作課題（15分）\n4. 社会的インタラクション課題（15分）\n\n【安全対策】\n- 15分ごとに休憩\n- VR酔い対策を実施\n- スタッフが常時サポート\n\n【データ収集】\n- 移動軌跡\n- 視線データ\n- 操作ログ\n- 生理指標（心拍数）',
      reward: 3000,
      location: '早稲田大学 西早稲田キャンパス 63号館',
      type: ExperimentType.onsite,
      isPaid: true,
      creatorId: 'demo_user_main', // 自分の実験として設定
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      recruitmentStartDate: DateTime.now(),
      recruitmentEndDate: DateTime.now().add(const Duration(days: 20)),
      experimentPeriodStart: DateTime.now().add(const Duration(days: 6)),
      experimentPeriodEnd: DateTime.now().add(const Duration(days: 25)),
      allowFlexibleSchedule: true,
      labName: 'ヒューマンインターフェース研究室',
      duration: 60,
      maxParticipants: 10,
      requirements: ['VR酔いしにくい方', '視力矯正可'],
    ),
    Experiment(
      id: '6',
      title: '音声認識システムの評価実験',
      description: '新しい音声認識システムの精度を評価するため、様々な文章を読み上げていただきます。',
      detailedContent: '次世代音声認識AIの開発のため、日本語音声データの収集を行います。\n\n【録音内容】\n- ニュース記事の朗読（10文）\n- 日常会話文（20文）\n- 専門用語を含む文章（10文）\n\n【録音環境】\n- 防音室での高品質録音\n- プロ仕様の録音機材を使用\n\n【プライバシー保護】\n- 音声データは匿名化処理\n- 個人を特定できない形で利用\n- 研究終了後、データは安全に破棄\n\n【参加者への配慮】\n- 喉の負担を考慮し、適宜休憩\n- 飲み物を用意',
      reward: 1800,
      location: '早稲田大学 西早稲田キャンパス 55号館',
      type: ExperimentType.onsite,
      isPaid: true,
      creatorId: 'demo_user_6',
      createdAt: DateTime.now().subtract(const Duration(hours: 12)),
      recruitmentStartDate: DateTime.now(),
      recruitmentEndDate: DateTime.now().add(const Duration(days: 7)),
      experimentPeriodStart: DateTime.now().add(const Duration(days: 2)),
      experimentPeriodEnd: DateTime.now().add(const Duration(days: 10)),
      allowFlexibleSchedule: true,
      labName: '音響工学研究室',
      duration: 40,
      maxParticipants: 25,
      requirements: ['日本語ネイティブ', '標準語話者'],
    ),
    Experiment(
      id: '7',
      title: 'スマートフォンアプリUIテスト',
      description: '開発中のアプリケーションの使いやすさを評価していただきます。',
      detailedContent: '新しい学習管理アプリのユーザビリティテストにご協力ください。\n\n【テスト内容】\n- アプリのインストール\n- 初回セットアップの完了\n- 5つのタスクを実行\n- アンケートに回答\n\n【評価項目】\n- ナビゲーションのわかりやすさ\n- 操作の直感性\n- デザインの見やすさ\n- 機能の使いやすさ\n\n【必要環境】\n- iOS 14.0以上またはAndroid 8.0以上\n- インターネット接続\n\n【フィードバック方法】\n- 画面録画を行います\n- Think Aloud法で操作中の思考を言語化',
      reward: 1000,
      location: 'オンライン（アプリをインストール）',
      type: ExperimentType.online,
      isPaid: true,
      creatorId: 'demo_user_7',
      participants: ['demo_user_main'], // 参加予定として設定
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      recruitmentStartDate: DateTime.now(),
      recruitmentEndDate: DateTime.now().add(const Duration(days: 5)),
      allowFlexibleSchedule: false,
      labName: 'ソフトウェア工学研究室',
      duration: 20,
      maxParticipants: 50,
      requirements: ['iOSまたはAndroidスマートフォン所持'],
    ),
    Experiment(
      id: '8',
      title: '睡眠習慣に関するアンケート',
      description: '大学生の睡眠パターンと学習効率の関係を調査します。',
      detailedContent: '睡眠の質が学業成績に与える影響を調査する縦断研究です。\n\n【調査項目】\n- 平日・休日の睡眠時間\n- 入眠時刻と起床時刻\n- 睡眠の質（主観的評価）\n- 昼寝の習慣\n- 睡眠薬の使用\n- カフェイン摂取量\n\n【学習関連項目】\n- GPA\n- 勉強時間\n- 集中力の自己評価\n- 記憶力の自己評価\n\n【回答時間】\n約10分程度\n\n【個人情報保護】\n- 完全匿名での回答\n- 統計処理のみに使用',
      reward: 300,
      location: 'オンライン（Googleフォーム）',
      type: ExperimentType.survey,
      isPaid: true,
      creatorId: 'demo_user_8',
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      recruitmentStartDate: DateTime.now(),
      recruitmentEndDate: DateTime.now().add(const Duration(days: 14)),
      allowFlexibleSchedule: false,
      labName: '健康科学研究室',
      duration: 10,
      maxParticipants: 200,
      requirements: ['早稲田大学学部生'],
    ),
    Experiment(
      id: '9',
      title: '言語学習アプリの効果測定',
      description: '新しい言語学習方法の効果を測定します。2週間の継続参加が必要です。',
      detailedContent: 'AI技術を活用した新しい英語学習アプリの効果を検証する実験です。\n\n【実験スケジュール】\n- 事前テスト（対面・60分）\n- 2週間の学習期間（毎日30分のアプリ学習）\n- 事後テスト（対面・60分）\n\n【測定項目】\n- リスニング能力の向上度\n- スピーキング能力の向上度\n- 語彙力の増加量\n- 学習モチベーションの変化\n\n【アプリの特徴】\n- AIによる個別最適化学習\n- ゲーミフィケーション要素\n- ネイティブスピーカーの音声\n\n【参加特典】\n- 実験終了後もアプリを3ヶ月無料利用可能\n- TOEICスコア換算レポート提供',
      reward: 5000,
      location: 'オンライン＋戸山キャンパス（事前・事後テスト）',
      type: ExperimentType.online,
      isPaid: true,
      creatorId: 'demo_user_9',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
      recruitmentStartDate: DateTime.now().add(const Duration(days: 3)),
      recruitmentEndDate: DateTime.now().add(const Duration(days: 10)),
      labName: '応用言語学研究室',
      duration: 30,
      maxParticipants: 30,
      requirements: ['英語学習意欲がある方', '2週間継続可能な方'],
    ),
    Experiment(
      id: '10',
      title: '運動時の生体反応測定',
      description: 'ウェアラブルデバイスを装着して軽い運動をしていただきます。',
      detailedContent: '最新のウェアラブルデバイスを用いて、運動時の生体反応を多角的に測定します。\n\n【測定項目】\n- 心拍数・心拍変動\n- 血中酸素濃度\n- 発汗量\n- 体温変化\n- 筋電図\n\n【運動内容】\n1. 準備運動（10分）\n2. ウォーキング（15分）\n3. 軽いジョギング（10分）\n4. 階段昇降（10分）\n5. クールダウン（10分）\n\n【使用デバイス】\n- Apple Watch Series 9\n- Polar H10心拍センサー\n- 筋電図測定装置\n\n【データ活用】\n収集したデータは、個人に最適化された運動プログラムの開発に活用されます。\n\n【参加者への配慮】\n- 体調不良時は即座に中止\n- 医療スタッフ待機\n- 運動着・シューズは貸出可能',
      reward: 2500,
      location: '早稲田大学 戸山キャンパス 体育館',
      type: ExperimentType.onsite,
      isPaid: true,
      creatorId: 'demo_user_10',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      recruitmentStartDate: DateTime.now().add(const Duration(days: 8)),
      recruitmentEndDate: DateTime.now().add(const Duration(days: 15)),
      labName: 'スポーツ科学研究室',
      duration: 90,
      maxParticipants: 12,
      requirements: ['健康な方', '運動に支障がない方'],
    ),
    Experiment(
      id: '11',
      title: '消費者行動に関する調査',
      description: 'オンラインショッピングの購買行動について質問します。',
      detailedContent: 'ECサイトにおける消費者の意思決定プロセスを解明する調査です。\n\n【調査方法】\n- Zoomによる半構造化インタビュー（25分）\n\n【質問内容】\n1. オンラインショッピングの利用頻度と金額\n2. 商品選択の決め手となる要因\n3. レビューの影響度\n4. 価格比較の方法\n5. カート離脱の理由\n6. リピート購入の動機\n\n【追加調査】\n- 実際のECサイトを見ながらの行動観察\n- アイトラッキング（同意者のみ）\n\n【データ利用目的】\n- ECサイトのUI/UX改善\n- レコメンドアルゴリズムの最適化\n- 消費者心理の学術研究\n\n【プライバシー保護】\n- 録画は研究目的のみ使用\n- 個人情報は厳重に管理',
      reward: 700,
      location: 'オンライン（Zoom）',
      type: ExperimentType.survey,
      isPaid: true,
      creatorId: 'demo_user_11',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      recruitmentStartDate: DateTime.now().add(const Duration(days: 2)),
      recruitmentEndDate: DateTime.now().add(const Duration(days: 9)),
      labName: 'マーケティング研究室',
      duration: 25,
      maxParticipants: 40,
      requirements: ['オンラインショッピング経験あり'],
    ),
    Experiment(
      id: '12',
      title: '顔認識システムの精度検証',
      description: '様々な角度から顔写真を撮影させていただきます。',
      detailedContent: 'セキュリティシステム向けの高精度顔認識AIの開発にご協力ください。\n\n【撮影内容】\n- 正面、左右45度、左右90度の顔写真\n- 様々な表情（笑顔、真顔、目を閉じた状態など）\n- 異なる照明条件下での撮影\n- マスク着用時と非着用時\n\n【技術仕様】\n- 4K解像度での撮影\n- 3D深度センサー使用\n- 赤外線カメラでの撮影\n\n【データの扱い】\n- 顔の特徴点のみを数値化\n- 元画像は暗号化して保存\n- 研究終了後、希望者のデータは削除\n\n【倫理的配慮】\n- 生体認証データの取り扱いガイドラインに準拠\n- 第三者提供は一切なし\n- 商用利用はしません',
      reward: 1200,
      location: '早稲田大学 西早稲田キャンパス 61号館',
      type: ExperimentType.onsite,
      isPaid: true,
      creatorId: 'demo_user_12',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      recruitmentStartDate: DateTime.now().add(const Duration(days: 5)),
      recruitmentEndDate: DateTime.now().add(const Duration(days: 12)),
      labName: '画像処理研究室',
      duration: 35,
      maxParticipants: 18,
      requirements: ['顔写真撮影に同意できる方'],
    ),
    Experiment(
      id: '13',
      title: '集中力測定実験（無償）',
      description: '様々な環境下での集中力の変化を測定します。',
      detailedContent: '学習環境が集中力に与える影響を科学的に検証する実験です。\n\n【実験条件】\n1. 静寂環境（防音室）\n2. 自然音環境（鳥の声、水の音）\n3. ホワイトノイズ環境\n4. カフェ環境（適度な雑音）\n\n【測定方法】\n- 持続的注意課題（CPT）\n- ストループ課題\n- N-back課題\n- 主観的集中度評価\n\n【生理指標】\n- 脳波測定（集中度の客観的評価）\n- 瞳孔径測定\n\n【研究の意義】\n本研究の成果は、より効果的な学習環境の設計に活用され、多くの学生の学習効率向上に貢献します。\n\n【参加メリット】\n- 自分に最適な学習環境を発見\n- 集中力プロファイルのフィードバック\n- 研究貢献証明書の発行',
      reward: 0,
      location: '早稲田大学 戸山キャンパス 36号館',
      type: ExperimentType.onsite,
      isPaid: false,
      creatorId: 'demo_user_13',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      recruitmentStartDate: DateTime.now().add(const Duration(days: 4)),
      recruitmentEndDate: DateTime.now().add(const Duration(days: 11)),
      labName: '教育心理学研究室',
      duration: 50,
      maxParticipants: 20,
      requirements: ['学部生・大学院生'],
    ),
    Experiment(
      id: '14',
      title: 'ゲームプレイ中の脳活動測定',
      description: '脳波計を装着してゲームをプレイしていただきます。',
      detailedContent: 'ゲーミングと認知機能の関係を脳科学的に解明する研究です。\n\n【測定内容】\n- 脳波（EEG）による脳活動の記録\n- 反応時間の測定\n- 正確性の評価\n- 視線追跡\n\n【ゲーム内容】\n1. パズルゲーム（テトリス型）- 20分\n2. アクションゲーム（FPS）- 20分\n3. ストラテジーゲーム（RTS）- 20分\n4. リズムゲーム - 20分\n\n【使用機器】\n- 64チャンネル脳波計\n- アイトラッカー\n- ゲーミングPC（ハイスペック）\n\n【測定する認知機能】\n- 注意の分配と切り替え\n- ワーキングメモリ\n- 空間認知能力\n- 意思決定速度\n\n【研究の目的】\n- eスポーツ選手の脳活動特性の解明\n- ゲーム依存症の早期発見指標の開発\n- 認知トレーニングとしてのゲームの有効性検証\n\n【参加者への配慮】\n- 休憩時間を十分に確保\n- 疲労度をモニタリング\n- ゲーム酔い対策',
      reward: 3500,
      location: '早稲田大学 西早稲田キャンパス 52号館',
      type: ExperimentType.onsite,
      isPaid: true,
      creatorId: 'demo_user_14',
      createdAt: DateTime.now().subtract(const Duration(hours: 18)),
      recruitmentStartDate: DateTime.now().add(const Duration(days: 7)),
      recruitmentEndDate: DateTime.now().add(const Duration(days: 21)),
      labName: '神経科学研究室',
      duration: 120,
      maxParticipants: 8,
      requirements: ['ゲーム経験者', '脳波測定に同意'],
    ),
    Experiment(
      id: '15',
      title: '食習慣調査アンケート',
      description: '大学生の食生活について調査します。1週間の食事記録をお願いします。',
      detailedContent: '現代大学生の食生活パターンと健康状態の関連を明らかにする研究です。\n\n【記録内容】\n- 毎食の写真撮影\n- 食事内容の詳細記録\n- 食事時間と場所\n- 誰と食べたか\n- 満腹度と満足度\n\n【記録方法】\n- 専用アプリで簡単記録\n- 写真から自動で栄養計算\n- 音声入力も可能\n\n【追加調査項目】\n- 体重・体脂肪率（任意）\n- 運動習慣\n- 睡眠時間\n- ストレスレベル\n- アルバイトの有無\n\n【栄養分析】\n- カロリー計算\n- PFCバランス\n- ビタミン・ミネラル\n- 食物繊維量\n\n【フィードバック】\n- 個人の栄養状態レポート提供\n- 管理栄養士からのアドバイス\n- 改善提案の提供\n\n【データ活用】\n- 学食メニューの改善\n- 健康支援プログラムの開発',
      reward: 1500,
      location: 'オンライン（専用アプリ）',
      type: ExperimentType.survey,
      isPaid: true,
      creatorId: 'demo_user_15',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      recruitmentStartDate: DateTime.now().add(const Duration(days: 1)),
      recruitmentEndDate: DateTime.now().add(const Duration(days: 8)),
      labName: '栄養学研究室',
      duration: 15,
      maxParticipants: 60,
      requirements: ['1週間継続記録可能な方'],
    ),
    Experiment(
      id: '16',
      title: '歩行動作分析実験',
      description: 'モーションキャプチャを使用して歩行パターンを分析します。',
      detailedContent: '最先端のモーションキャプチャ技術で歩行メカニズムを解析します。\n\n【測定項目】\n- 3次元動作解析\n- 床反力測定\n- 筋電図測定\n- 関節角度変化\n- 重心移動軌跡\n\n【実験プロトコル】\n1. マーカー装着（全身39箇所）\n2. 通常歩行（10m×10回）\n3. 速歩（10m×5回）\n4. 階段昇降\n5. 障害物回避歩行\n6. 後ろ歩き\n\n【使用システム】\n- VICON モーションキャプチャ（12台カメラ）\n- AMTI床反力計\n- Delsys筋電図システム\n\n【研究応用分野】\n- リハビリテーション医学\n- スポーツ科学\n- ロボット工学\n- 高齢者支援技術\n\n【参加者の利点】\n- 歩行分析レポート提供\n- 歩行改善アドバイス\n- 姿勢チェック\n\n【服装】\n- 動きやすい服装（タイトなもの推奨）\n- 室内シューズ持参',
      reward: 2200,
      location: '早稲田大学 所沢キャンパス',
      type: ExperimentType.onsite,
      isPaid: true,
      creatorId: 'demo_user_16',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      recruitmentStartDate: DateTime.now().add(const Duration(days: 9)),
      recruitmentEndDate: DateTime.now().add(const Duration(days: 16)),
      labName: 'バイオメカニクス研究室',
      duration: 75,
      maxParticipants: 14,
      requirements: ['健康な方', '運動着持参'],
    ),
    Experiment(
      id: '17',
      title: 'プログラミング学習支援システムの評価',
      description: '新しいプログラミング学習ツールを使用していただき、フィードバックをお願いします。',
      detailedContent: 'AI支援型プログラミング学習システムの教育効果を検証する研究です。\n\n【評価内容】\n- チュートリアルの分かりやすさ\n- エラーメッセージの的確性\n- ヒント機能の有用性\n- 学習進度の可視化\n- モチベーション維持機能\n\n【実施タスク】\n1. Python基礎文法の学習（10分）\n2. 簡単なプログラム作成（10分）\n3. デバッグ課題（5分）\n4. アンケート回答（5分）\n\n【評価指標】\n- タスク完了率\n- エラー発生頻度\n- ヘルプ使用回数\n- 学習時間\n- 主観的満足度\n\n【システムの特徴】\n- リアルタイムエラー検出\n- AIによる個別化されたヒント\n- ゲーミフィケーション要素\n- ペアプログラミング機能\n\n【研究の意義】\n本研究により、プログラミング初学者の学習障壁を低減し、効率的な学習を支援するシステムの開発に貢献します。\n\n【参加後の特典】\n- システムの無料利用権（3ヶ月）\n- プログラミング学習資料の提供',
      reward: 800,
      location: 'オンライン',
      type: ExperimentType.online,
      isPaid: true,
      creatorId: 'demo_user_17',
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      recruitmentStartDate: DateTime.now().add(const Duration(days: 2)),
      recruitmentEndDate: DateTime.now().add(const Duration(days: 7)),
      labName: '情報教育研究室',
      duration: 30,
      maxParticipants: 35,
      requirements: ['プログラミング初心者'],
    ),
    Experiment(
      id: '18',
      title: '環境音が作業効率に与える影響',
      description: '様々な環境音の中で簡単な作業をしていただきます。',
      detailedContent: '音環境が認知パフォーマンスに与える影響を科学的に検証する実験です。\n\n【実験条件】\n1. 無音環境\n2. ホワイトノイズ（60dB）\n3. 自然音（川のせせらぎ、鳥の声）\n4. カフェの環境音（70dB）\n5. クラシック音楽（モーツァルト）\n6. Lo-fi音楽\n\n【作業内容】\n- 文章校正タスク\n- 計算問題\n- 創造性課題（アイデア出し）\n- 記憶課題\n\n【測定項目】\n- 作業速度\n- 正確性\n- 集中度（主観評価）\n- ストレスレベル\n- 心拍変動（HRV）\n\n【実験の流れ】\n1. 事前アンケート（5分）\n2. 練習セッション（5分）\n3. 本実験（6条件×7分＝42分）\n4. 休憩時間（条件間に2分）\n5. 事後インタビュー（5分）\n\n【使用機器】\n- 高品質ヘッドホン（SONY WH-1000XM5）\n- 心拍センサー\n- アイトラッカー（任意）\n\n【研究成果の応用】\n- オフィス環境の最適化\n- 学習空間の設計\n- 在宅ワーク環境の改善提案',
      reward: 1600,
      location: '早稲田大学 戸山キャンパス 32号館',
      type: ExperimentType.onsite,
      isPaid: true,
      creatorId: 'demo_user_18',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      recruitmentStartDate: DateTime.now().add(const Duration(days: 3)),
      recruitmentEndDate: DateTime.now().add(const Duration(days: 10)),
      labName: '環境心理学研究室',
      duration: 55,
      maxParticipants: 22,
      requirements: ['聴力正常な方'],
    ),
    Experiment(
      id: '19',
      title: '対話型AIの評価実験',
      description: 'チャットボットと会話していただき、自然さを評価します。',
      detailedContent: '最新の対話型AI技術の自然言語処理能力を評価する実験です。\n\n【評価タスク】\n1. 日常会話（5分）\n2. 情報検索対話（5分）\n3. 問題解決支援（5分）\n4. 感情的な対話（5分）\n5. 専門的な質問応答（5分）\n\n【評価項目】\n- 応答の自然さ\n- 文脈理解の正確性\n- 回答の有用性\n- 対話の流暢さ\n- 共感性の表現\n- 応答速度\n\n【実験システム】\n- 3種類の異なるAIモデル\n- ランダムに割り当て\n- ブラインドテスト形式\n\n【データ収集】\n- 対話ログ\n- 評価スコア（5段階）\n- 自由記述フィードバック\n- 改善提案\n\n【チューリングテスト】\n一部のセッションでは人間とAIを区別できるかのテストも実施\n\n【研究の目的】\n- 対話AIの実用性評価\n- ユーザーエクスペリエンスの向上\n- 倫理的な課題の発見\n\n【プライバシー】\n- 対話内容は匿名化処理\n- 個人情報は一切収集しません',
      reward: 900,
      location: 'オンライン',
      type: ExperimentType.online,
      isPaid: true,
      creatorId: 'demo_user_19',
      createdAt: DateTime.now().subtract(const Duration(hours: 15)),
      recruitmentStartDate: DateTime.now().add(const Duration(days: 1)),
      recruitmentEndDate: DateTime.now().add(const Duration(days: 4)),
      labName: '自然言語処理研究室',
      duration: 25,
      maxParticipants: 45,
      requirements: ['日本語ネイティブ'],
    ),
    Experiment(
      id: '20',
      title: '色彩感覚テスト（無償）',
      description: '色の識別能力と感性を測定する実験です。',
      detailedContent: '色覚の個人差と色彩感性の関係を探る基礎研究です。\n\n【テスト内容】\n1. 色相識別テスト\n   - 微妙な色の違いを見分ける\n   - 100色のグラデーション配列\n\n2. 色彩記憶テスト\n   - 色の短期記憶能力\n   - 色の名前との対応\n\n3. 色彩調和テスト\n   - 配色の美的判断\n   - 好みの色の組み合わせ\n\n4. 色彩感情テスト\n   - 色から受ける印象\n   - 色と感情の関連性\n\n【測定環境】\n- 標準光源D65使用\n- キャリブレーション済みモニター\n- 暗室環境\n\n【所要時間詳細】\n- 説明・準備：5分\n- 各テスト：8-10分\n- 休憩：5分\n- アンケート：5分\n\n【研究への貢献】\nこの研究は色覚多様性の理解を深め、ユニバーサルデザインの発展に貢献します。\n\n【参加特典】\n- 個人の色覚プロファイル提供\n- 色彩感覚の特徴分析レポート\n- デザイン分野での活用アドバイス\n\n※無償ですが、科学研究への貴重な貢献となります',
      reward: 0,
      location: '早稲田大学 戸山キャンパス 39号館',
      type: ExperimentType.onsite,
      isPaid: false,
      creatorId: 'demo_user_20',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      recruitmentStartDate: DateTime.now().add(const Duration(days: 6)),
      recruitmentEndDate: DateTime.now().add(const Duration(days: 13)),
      labName: '視覚デザイン研究室',
      duration: 40,
      maxParticipants: 25,
      requirements: ['色覚正常な方'],
    ),
    Experiment(
      id: '21',
      title: '瞑想アプリの効果検証',
      description: '瞑想アプリを1週間使用していただき、ストレス軽減効果を測定します。',
      detailedContent: 'マインドフルネス瞑想アプリの心理的・生理的効果を科学的に検証します。\n\n【実験スケジュール】\n- 事前測定（対面・30分）\n- 1週間のアプリ使用（毎日15分）\n- 事後測定（対面・30分）\n\n【測定項目】\n- ストレスレベル（唾液コルチゾール）\n- 心拍変動（HRV）\n- 不安尺度（STAI）\n- マインドフルネス尺度（MAAS）\n- 睡眠の質\n\n【アプリ内容】\n- ガイド付き瞑想（5-15分）\n- 呼吸法エクササイズ\n- ボディスキャン\n- 睡眠導入プログラム\n\n【参加特典】\n- アプリ永久利用権\n- 個人レポート提供',
      reward: 2000,
      location: 'オンライン＋事前事後測定（戸山）',
      type: ExperimentType.online,
      isPaid: true,
      creatorId: 'demo_user_21',
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      recruitmentStartDate: DateTime.now().add(const Duration(days: 3)),
      recruitmentEndDate: DateTime.now().add(const Duration(days: 17)),
      labName: '臨床心理学研究室',
      duration: 20,
      maxParticipants: 30,
      requirements: ['継続参加可能な方', 'スマートフォン所持'],
    ),
    Experiment(
      id: '22',
      title: 'SNS利用と幸福度の関係調査',
      description: 'SNSの利用状況と主観的幸福度についてインタビューします。',
      detailedContent: 'SNS利用パターンが若者の心理的well-beingに与える影響を調査します。\n\n【調査方法】\n- 半構造化インタビュー（Zoom・45分）\n- 事前アンケート（10分）\n\n【インタビュー内容】\n- SNS利用時間と頻度\n- 主要な利用目的\n- 投稿・閲覧の比率\n- SNS上の人間関係\n- FOMO（見逃し不安）経験\n- 自己呈示戦略\n\n【心理測定】\n- 主観的幸福感尺度\n- 自尊感情尺度\n- 社会的比較傾向\n- 孤独感尺度\n\n【プライバシー保護】\n- 録画は研究目的のみ\n- 完全匿名化処理',
      reward: 1100,
      location: 'オンライン（Zoom）',
      type: ExperimentType.survey,
      isPaid: true,
      creatorId: 'demo_user_22',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      recruitmentStartDate: DateTime.now().add(const Duration(days: 2)),
      recruitmentEndDate: DateTime.now().add(const Duration(days: 8)),
      labName: '社会情報学研究室',
      duration: 45,
      maxParticipants: 24,
      requirements: ['SNS利用者', '18-25歳'],
    ),
    Experiment(
      id: '23',
      title: '筋電図測定実験',
      description: '簡単な動作中の筋肉の活動を測定します。',
      detailedContent: '表面筋電図を用いて運動制御メカニズムを解明する実験です。\n\n【測定内容】\n- 上肢の筋活動パターン\n- 筋疲労の進行過程\n- 協調運動時の筋シナジー\n- 反射応答の測定\n\n【実験プロトコル】\n1. 電極装着（8チャンネル）\n2. 最大随意収縮測定\n3. 等尺性収縮課題\n4. 動的運動課題\n5. 疲労課題\n\n【使用機器】\n- Delsys Trigno無線筋電図\n- 動作解析カメラ\n- 力センサー\n\n【安全管理】\n- 医療スタッフ常駐\n- 適切な休憩時間確保',
      reward: 2800,
      location: '早稲田大学 所沢キャンパス',
      type: ExperimentType.onsite,
      isPaid: true,
      creatorId: 'demo_user_23',
      createdAt: DateTime.now().subtract(const Duration(hours: 20)),
      recruitmentStartDate: DateTime.now().add(const Duration(days: 10)),
      recruitmentEndDate: DateTime.now().add(const Duration(days: 24)),
      labName: '運動生理学研究室',
      duration: 100,
      maxParticipants: 10,
      requirements: ['健康な方', '運動制限なし'],
    ),
    Experiment(
      id: '24',
      title: 'AR技術を用いた学習効果の検証',
      description: 'AR教材を使った学習と従来の学習方法を比較します。',
      detailedContent: '''本実験では、拡張現実（AR）技術を活用した教材と従来の紙ベースやPC教材での学習効果を比較検証します。

【実験内容】
参加者は2つのグループに分かれて、同じ内容（生物学：細胞の構造）を異なる方法で学習していただきます。

グループA：AR教材による学習
- HoloLens 2を使用した3D細胞モデルの観察
- インタラクティブな構造解説
- 空間的な理解を促進する演習

グループB：従来教材による学習
- 教科書とPC画面での2D図解
- 動画教材の視聴
- ワークシートによる演習

【測定項目】
- 学習前後の理解度テスト
- 記憶定着度（1週間後の再テスト）
- 学習意欲と満足度のアンケート
- 視線計測による注目度分析

ARデバイスの操作は簡単で、事前に丁寧な説明を行います。''',
      reward: 1700,
      location: '早稲田大学 西早稲田キャンパス 60号館',
      type: ExperimentType.onsite,
      isPaid: true,
      creatorId: 'demo_user_24',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      recruitmentStartDate: DateTime.now().add(const Duration(days: 5)),
      recruitmentEndDate: DateTime.now().add(const Duration(days: 19)),
      labName: '教育工学研究室',
      duration: 65,
      maxParticipants: 16,
      requirements: ['ARデバイス使用経験不問'],
    ),
    Experiment(
      id: '25',
      title: 'オンライン授業の満足度調査',
      description: 'オンライン授業に関する経験と改善点についてお聞きします。',
      detailedContent: '''コロナ禍以降、急速に普及したオンライン授業の効果と課題について、学生の視点から調査を行います。

【調査項目】
1. オンライン授業の受講経験
- 受講した科目数と形態（リアルタイム/オンデマンド）
- 使用プラットフォーム（Zoom、Teams、Moodle等）
- 受講環境（機器、通信環境）

2. 学習効果について
- 対面授業との比較
- 集中力の維持
- 質問のしやすさ
- グループワークの実施状況

3. メリット・デメリット
- 時間の有効活用
- 復習のしやすさ
- コミュニケーションの課題
- 技術的トラブル

4. 改善提案
- 理想的なオンライン授業の形態
- 必要なサポート
- ハイブリッド授業への要望

回答は選択式が中心で、一部自由記述があります。所要時間は約15分です。''',
      reward: 400,
      location: 'オンライン（アンケート）',
      type: ExperimentType.survey,
      isPaid: true,
      creatorId: 'demo_user_25',
      createdAt: DateTime.now().subtract(const Duration(hours: 10)),
      recruitmentStartDate: DateTime.now(),
      recruitmentEndDate: DateTime.now().add(const Duration(days: 6)),
      labName: '高等教育研究室',
      duration: 15,
      maxParticipants: 150,
      requirements: ['オンライン授業経験者'],
    ),
    Experiment(
      id: '26',
      title: '表情認識システムの開発協力（無償）',
      description: '様々な表情を撮影させていただき、データベース作成に協力していただきます。',
      detailedContent: '''感情認識AIの開発のため、日本人の表情データベース構築にご協力いただける方を募集しています。

【実験内容】
高精度カメラで以下の表情を撮影させていただきます：
- 基本6感情（喜び、悲しみ、怒り、恐怖、驚き、嫌悪）
- 中立表情
- 微細表情（軽い笑顔、困惑、疑問など）

【撮影方法】
1. 正面、左右45度の3方向から撮影
2. 各表情を3秒間維持
3. 研究者の指示に従って表情を作っていただきます
4. 必要に応じて表情の見本をお見せします

【データの取り扱い】
- 撮影データは厳重に管理し、研究目的以外には使用しません
- 個人が特定されない形で処理されます
- 希望者には撮影した画像の一部をお渡しします

無償での協力となりますが、AI技術の発展に貢献できる貴重な機会です。化粧をしていない状態でお越しください。''',
      reward: 0,
      location: '早稲田大学 西早稲田キャンパス 57号館',
      type: ExperimentType.onsite,
      isPaid: false,
      creatorId: 'demo_user_26',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      recruitmentStartDate: DateTime.now().add(const Duration(days: 4)),
      recruitmentEndDate: DateTime.now().add(const Duration(days: 11)),
      labName: '感情認識研究室',
      duration: 30,
      maxParticipants: 40,
      requirements: ['顔撮影に同意'],
    ),
    Experiment(
      id: '27',
      title: '音楽が勉強効率に与える影響',
      description: '様々なジャンルの音楽を聴きながら課題に取り組んでいただきます。',
      detailedContent: '''音楽が認知課題のパフォーマンスに与える影響を科学的に検証する実験です。

【実験条件】
4つの音楽条件下で、異なる認知課題を実施していただきます：
1. 無音条件（コントロール）
2. クラシック音楽（モーツァルト、バッハ）
3. アンビエント/環境音楽
4. 参加者の好きな音楽

【実施する課題】
- 計算課題（四則演算）
- 記憶課題（単語記憶）
- 読解課題（文章理解）
- 創造性課題（アイデア生成）

【測定項目】
- 課題の正答率と反応時間
- 主観的な集中度と快適さ
- 心拍変動による自律神経活動
- 課題後の疲労度

音楽はヘッドフォンで提供し、音量は個人で調整可能です。休憩時間も十分に設けています。''',
      reward: 1400,
      location: '早稲田大学 戸山キャンパス 38号館',
      type: ExperimentType.onsite,
      isPaid: true,
      creatorId: 'demo_user_27',
      createdAt: DateTime.now().subtract(const Duration(hours: 7)),
      recruitmentStartDate: DateTime.now().add(const Duration(days: 3)),
      recruitmentEndDate: DateTime.now().add(const Duration(days: 9)),
      labName: '音楽心理学研究室',
      duration: 70,
      maxParticipants: 28,
      requirements: ['聴力正常', '音楽好き歓迎'],
    ),
    Experiment(
      id: '28',
      title: '新型コントローラーの操作性評価',
      description: '開発中のゲームコントローラーを使用していただき、操作感をフィードバックしていただきます。',
      detailedContent: '''次世代ゲームコントローラーのプロトタイプの操作性を評価していただく実験です。

【評価対象】
新開発のコントローラーの特徴：
- 適応型触覚フィードバック
- 圧力感知トリガー
- ジャイロセンサー強化
- 人間工学に基づいた新形状

【テスト内容】
1. 基本操作テスト（15分）
- ボタン配置の確認
- 握りやすさの評価
- 重量バランスのチェック

2. ゲームプレイテスト（45分）
- アクションゲーム
- レースゲーム
- パズルゲーム
- FPSゲーム

3. 長時間使用テスト（20分）
- 疲労度の測定
- 快適性の評価

【フィードバック方法】
- 操作ログの自動記録
- アンケート調査
- インタビュー
- 手の動きのモーションキャプチャ

ゲーム初心者の方でも参加可能ですが、ある程度のゲーム経験がある方を優先させていただきます。''',
      reward: 1900,
      location: '早稲田大学 西早稲田キャンパス 56号館',
      type: ExperimentType.onsite,
      isPaid: true,
      creatorId: 'demo_user_28',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      recruitmentStartDate: DateTime.now().add(const Duration(days: 6)),
      recruitmentEndDate: DateTime.now().add(const Duration(days: 15)),
      labName: 'インタラクションデザイン研究室',
      duration: 80,
      maxParticipants: 12,
      requirements: ['ゲーム経験あり'],
    ),
    Experiment(
      id: '29',
      title: '外国語学習モチベーション調査',
      description: '外国語学習に対する動機づけについてインタビューします。',
      detailedContent: '''外国語学習者の動機づけメカニズムと継続要因を探る研究です。

【調査方法】
オンラインでの半構造化インタビュー形式で実施します。

【インタビュー内容】
1. 学習履歴について
- 学習している言語と期間
- 学習のきっかけ
- 現在の学習レベル

2. 動機づけ要因
- 内発的動機（楽しさ、興味）
- 外発的動機（仕事、試験）
- 統合的動機（文化理解）
- 道具的動機（実用性）

3. 学習継続の課題
- モチベーション低下の経験
- 困難を乗り越えた方法
- 学習環境の影響

4. 学習方法と効果
- 使用している教材・アプリ
- 効果的だった学習法
- 今後の学習目標

インタビューは録音させていただきますが、個人情報は匿名化して分析します。''',
      reward: 600,
      location: 'オンライン（Google Meet）',
      type: ExperimentType.survey,
      isPaid: true,
      creatorId: 'demo_user_29',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      recruitmentStartDate: DateTime.now().add(const Duration(days: 1)),
      recruitmentEndDate: DateTime.now().add(const Duration(days: 7)),
      labName: '言語教育研究室',
      duration: 30,
      maxParticipants: 50,
      requirements: ['外国語学習経験者'],
    ),
    Experiment(
      id: '30',
      title: '視線追跡を用いた読書行動分析',
      description: 'アイトラッカーを使用して読書中の視線の動きを記録します。',
      detailedContent: '''最新の視線追跡技術を用いて、読書時の認知プロセスを解明する研究です。

【実験概要】
高精度アイトラッカー（Tobii Pro Spark）を使用して、様々なテキストを読む際の視線パターンを分析します。

【読書材料】
- 小説（物語文）
- 新聞記事（説明文）
- 専門書（論説文）
- 詩（韻文）
- 図表を含む資料

【測定項目】
1. 視線データ
- 注視点の位置と時間
- サッケード（視線移動）の速度と方向
- 読み返し（回帰）の頻度
- 行間の視線移動パターン

2. 読解特性
- 読書速度（WPM）
- 理解度テスト
- 記憶保持テスト
- 主観的な読みやすさ評価

3. 個人差要因
- 読書習慣アンケート
- 言語能力テスト
- ワーキングメモリ容量測定

【実験環境】
- 照明・姿勢を統制した快適な実験室
- キャリブレーション後、自然な読書が可能
- 眼鏡・コンタクトレンズ着用可

データは読書教育の改善に活用されます。''',
      reward: 2300,
      location: '早稲田大学 戸山キャンパス 31号館',
      type: ExperimentType.onsite,
      isPaid: true,
      creatorId: 'demo_user_30',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      recruitmentStartDate: DateTime.now().add(const Duration(days: 5)),
      recruitmentEndDate: DateTime.now().add(const Duration(days: 14)),
      labName: '読書科学研究室',
      duration: 60,
      maxParticipants: 16,
      requirements: ['日本語読解能力', '眼鏡・コンタクト可'],
    ),
  ];

  void _handleCreateExperiment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateExperimentScreenDemo(),
      ),
    );
  }

  /// マイページへ遷移
  void _navigateToMyPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MyPageScreenDemo(
          authService: widget.authService,
          onLogout: widget.onLogout,
        ),
      ),
    );
  }

  /// メッセージ画面へ遷移
  void _navigateToMessages() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessagesScreenDemo(
          authService: widget.authService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return HomeScreenBase(
      title: 'わせラボ',
      experiments: _experiments,
      canCreateExperiment: widget.authService.canCreateExperiment,
      userName: widget.authService.currentUserName,
      isWasedaUser: widget.authService.isWasedaUser,
      onLogout: widget.onLogout,
      isDemo: true,
      onCreateExperiment: widget.authService.canCreateExperiment 
          ? _handleCreateExperiment 
          : null,
      currentUserId: currentUserId,
      unreadMessages: _unreadMessages,
      onNavigateToMyPage: _navigateToMyPage,
      onNavigateToMessages: _navigateToMessages,
    );
  }
}