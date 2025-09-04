import 'package:cloud_firestore/cloud_firestore.dart';

/// アプリケーションユーザーモデル
/// ユーザー情報と権限を管理
class AppUser {
  final String uid;
  final String email;
  final String name;
  final bool isWasedaUser;        // 早稲田大学ユーザーかどうか
  final bool canCreateExperiment;  // 実験作成権限
  final DateTime createdAt;
  final String? photoUrl;          // プロフィール画像URL（Googleアカウント用）
  final String? bio;               // 自己紹介
  final int participatedExperiments; // 完了済み実験数
  final int scheduledExperiments;  // 参加予定実験数
  final List<String> completedExperimentIds; // 完了済み実験IDリスト
  final String? department;        // 学部・学科
  final String? grade;             // 学年
  final int goodCount;             // Good評価数
  final int badCount;              // Bad評価数
  final int totalEarnings;         // 今までに稼いだ総額（円）
  final int monthlyEarnings;       // 今月稼いだ額（円）
  final DateTime? lastEarningsUpdate; // 収益最終更新日
  final bool emailVerified;        // メール認証済みかどうか
  final DateTime? emailVerifiedAt; // メール認証完了日時
  final String? gender;             // 性別
  final int? age;                   // 年齢
  final int points;                 // 保有ポイント（Good評価1つ = 1ポイント）
  final List<String> unlockedFrames; // 解放済みフレームIDリスト
  final String? selectedFrame;      // 選択中のフレームID
  final List<String> unlockedDesigns; // 解放済みアイコンデザインIDリスト
  final String? selectedDesign;      // 選択中のアイコンデザインID

  AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.isWasedaUser,
    required this.canCreateExperiment,
    required this.createdAt,
    this.photoUrl,
    this.bio,
    this.participatedExperiments = 0,
    this.scheduledExperiments = 0,
    this.completedExperimentIds = const [],
    this.department,
    this.grade,
    this.goodCount = 0,
    this.badCount = 0,
    this.totalEarnings = 0,
    this.monthlyEarnings = 0,
    this.lastEarningsUpdate,
    this.emailVerified = false,
    this.emailVerifiedAt,
    this.gender,
    this.age,
    this.points = 0,
    this.unlockedFrames = const ['none', 'simple'], // デフォルトで2つ解放
    this.selectedFrame,
    this.unlockedDesigns = const ['default'], // デフォルトアイコンは最初から解放
    this.selectedDesign = 'default',
  });

  /// Firestoreのドキュメントからユーザーを作成
  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return AppUser(
      uid: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      isWasedaUser: data['isWasedaUser'] ?? false,
      canCreateExperiment: data['canCreateExperiment'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      photoUrl: data['photoUrl'],
      bio: data['bio'],
      participatedExperiments: data['participatedExperiments'] ?? 0,
      scheduledExperiments: data['scheduledExperiments'] ?? 0,
      completedExperimentIds: List<String>.from(data['completedExperimentIds'] ?? []),
      department: data['department'],
      grade: data['grade'],
      goodCount: data['goodCount'] ?? 0,
      badCount: data['badCount'] ?? 0,
      totalEarnings: data['totalEarnings'] ?? 0,
      monthlyEarnings: data['monthlyEarnings'] ?? 0,
      lastEarningsUpdate: (data['lastEarningsUpdate'] as Timestamp?)?.toDate(),
      emailVerified: data['emailVerified'] ?? false,
      emailVerifiedAt: (data['emailVerifiedAt'] as Timestamp?)?.toDate(),
      gender: data['gender'],
      age: data['age'],
      points: data['points'] ?? data['goodCount'] ?? 0, // goodCountをデフォルトポイントとして使用
      unlockedFrames: List<String>.from(data['unlockedFrames'] ?? ['none', 'simple']),
      selectedFrame: data['selectedFrame'],
      unlockedDesigns: List<String>.from(data['unlockedDesigns'] ?? ['default']),
      selectedDesign: data['selectedDesign'] ?? 'default',
    );
  }

  /// ユーザーをFirestoreに保存する形式に変換
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'isWasedaUser': isWasedaUser,
      'canCreateExperiment': canCreateExperiment,
      'createdAt': Timestamp.fromDate(createdAt),
      'photoUrl': photoUrl,
      'bio': bio,
      'participatedExperiments': participatedExperiments,
      'scheduledExperiments': scheduledExperiments,
      'completedExperimentIds': completedExperimentIds,
      'department': department,
      'grade': grade,
      'goodCount': goodCount,
      'badCount': badCount,
      'totalEarnings': totalEarnings,
      'monthlyEarnings': monthlyEarnings,
      'lastEarningsUpdate': lastEarningsUpdate != null 
        ? Timestamp.fromDate(lastEarningsUpdate!) 
        : null,
      'emailVerified': emailVerified,
      'emailVerifiedAt': emailVerifiedAt != null
        ? Timestamp.fromDate(emailVerifiedAt!)
        : null,
      'gender': gender,
      'age': age,
      'points': points,
      'unlockedFrames': unlockedFrames,
      'selectedFrame': selectedFrame,
      'unlockedDesigns': unlockedDesigns,
      'selectedDesign': selectedDesign,
    };
  }

  /// メールアドレスから早稲田ユーザーかどうかを判定
  static bool isWasedaEmail(String email) {
    final lowercaseEmail = email.toLowerCase();
    return lowercaseEmail.endsWith('.waseda.jp') || 
           lowercaseEmail.endsWith('@waseda.jp');
  }

  /// 新規ユーザー作成用のファクトリーメソッド
  factory AppUser.create({
    required String uid,
    required String email,
    required String name,
    String? photoUrl,
    bool emailVerified = false,
    String? gender,
    int? age,
  }) {
    final isWaseda = isWasedaEmail(email);
    
    return AppUser(
      uid: uid,
      email: email,
      name: name,
      isWasedaUser: isWaseda,
      canCreateExperiment: isWaseda, // 早稲田ユーザーのみ実験作成可能
      createdAt: DateTime.now(),
      photoUrl: photoUrl,
      emailVerified: emailVerified,
      gender: gender,
      age: age,
    );
  }
}