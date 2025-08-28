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

  AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.isWasedaUser,
    required this.canCreateExperiment,
    required this.createdAt,
    this.photoUrl,
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
    );
  }
}