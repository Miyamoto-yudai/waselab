/// デモ用の認証サービス
/// Firebaseを使わずにローカルでテストできる
class DemoAuthService {
  // デモユーザーの情報を保持
  static String? _currentUserEmail;
  static String? _currentUserName;
  static bool _isWasedaUser = false;

  /// 現在のユーザー情報（デモ用）
  String? get currentUserEmail => _currentUserEmail;
  String? get currentUserName => _currentUserName;
  bool get isLoggedIn => _currentUserEmail != null;
  bool get isWasedaUser => _isWasedaUser;
  bool get canCreateExperiment => _isWasedaUser;
  
  /// デモ用のユーザーオブジェクト
  DemoUser? get currentUser => _currentUserEmail != null
      ? DemoUser(
          email: _currentUserEmail!,
          name: _currentUserName ?? 'デモユーザー',
          isWasedaUser: _isWasedaUser,
          canCreateExperiment: _isWasedaUser,
        )
      : null;

  /// 早稲田大学のメールアドレスかどうかを検証
  bool _isWasedaEmail(String email) {
    final lowercaseEmail = email.toLowerCase();
    return lowercaseEmail.endsWith('.waseda.jp') || 
           lowercaseEmail.endsWith('@waseda.jp');
  }

  /// デモ用サインアップ
  Future<String?> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    // 早稲田大学のメールアドレスかチェック
    if (!_isWasedaEmail(email)) {
      return '早稲田大学のメールアドレスのみ登録可能です';
    }

    // パスワードの簡単なチェック
    if (password.length < 6) {
      return 'パスワードは6文字以上で設定してください';
    }

    // デモ用に1秒待機（通信を模擬）
    await Future.delayed(const Duration(seconds: 1));

    // 成功したことにする
    _currentUserEmail = email;
    _currentUserName = name;
    _isWasedaUser = true; // 早稲田メールで登録
    
    return null; // 成功
  }

  /// デモ用サインイン
  Future<String?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    // 早稲田大学のメールアドレスかチェック
    if (!_isWasedaEmail(email)) {
      return '早稲田大学のメールアドレスのみログイン可能です';
    }

    // デモ用に1秒待機（通信を模擬）
    await Future.delayed(const Duration(seconds: 1));

    // デモ用：どんなメールアドレスでも成功したことにする
    _currentUserEmail = email;
    _currentUserName = 'デモユーザー';
    _isWasedaUser = true; // 早稲田メールでログイン
    
    return null; // 成功
  }

  /// デモ用パスワードリセット
  Future<String?> sendPasswordResetEmail(String email) async {
    // 早稲田大学のメールアドレスかチェック
    if (!_isWasedaEmail(email)) {
      return '早稲田大学のメールアドレスのみ利用可能です';
    }

    // デモ用に1秒待機
    await Future.delayed(const Duration(seconds: 1));
    
    return null; // 成功（実際にはメールは送信されない）
  }

  /// Googleアカウントでサインイン（デモ用）
  Future<String?> signInWithGoogle() async {
    // デモ用に1秒待機（通信を模擬）
    await Future.delayed(const Duration(seconds: 1));

    // デモ用：Googleアカウントでログイン成功
    _currentUserEmail = 'demo.user@gmail.com';
    _currentUserName = 'デモユーザー（Google）';
    _isWasedaUser = false; // Googleアカウントは非早稲田ユーザー
    
    return null; // 成功
  }

  /// デモ用サインアウト
  Future<void> signOut() async {
    _currentUserEmail = null;
    _currentUserName = null;
    _isWasedaUser = false;
  }
}

/// デモ用のユーザーモデル
class DemoUser {
  final String email;
  final String name;
  final bool isWasedaUser;
  final bool canCreateExperiment;

  DemoUser({
    required this.email,
    required this.name,
    required this.isWasedaUser,
    required this.canCreateExperiment,
  });
}