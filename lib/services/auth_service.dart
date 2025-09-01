import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/app_user.dart';

/// 認証サービスクラス
/// Firebase AuthenticationとGoogle Sign Inを使用したユーザー認証を管理する
class AuthService {
  // Firebase Auth、Firestore、GoogleSignInのインスタンス
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Google Sign-Inの初期化
  // Web向けにはclientIdが必要です（Firebase ConsoleのWeb SDK configurationから取得）
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // Web Client IDを設定（Web、Android、iOS全プラットフォーム共通）
    clientId: '788143974236-jqi4c0558nu50cda3jams444dov43lue.apps.googleusercontent.com',
  );

  /// 現在ログイン中のユーザーを取得
  User? get currentUser => _auth.currentUser;

  /// ユーザーの認証状態の変更をストリームで監視
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// 早稲田大学のメールアドレスかどうかを検証
  /// @ruri.waseda.jp, @fuji.waseda.jp などのサブドメインも含む
  bool _isWasedaEmail(String email) {
    final lowercaseEmail = email.toLowerCase();
    // 早稲田大学の各種メールドメインに対応
    return lowercaseEmail.endsWith('.waseda.jp') || 
           lowercaseEmail.endsWith('@waseda.jp');
  }

  /// メールアドレスとパスワードでサインアップ（早稲田メール限定）
  Future<String?> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // 早稲田大学のメールアドレスかチェック
      if (!_isWasedaEmail(email)) {
        return '早稲田大学のメールアドレスのみ登録可能です';
      }

      // ユーザー作成
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Firestoreにユーザー情報を保存
      if (userCredential.user != null) {
        final appUser = AppUser.create(
          uid: userCredential.user!.uid,
          email: email,
          name: name,
        );

        await _firestore.collection('users')
            .doc(userCredential.user!.uid)
            .set(appUser.toFirestore());

        // 表示名を設定
        await userCredential.user!.updateDisplayName(name);
      }

      return null; // 成功
    } on FirebaseAuthException catch (e) {
      // エラーメッセージを日本語化
      switch (e.code) {
        case 'weak-password':
          return 'パスワードは6文字以上で設定してください';
        case 'email-already-in-use':
          return 'このメールアドレスは既に使用されています';
        case 'invalid-email':
          return 'メールアドレスの形式が正しくありません';
        default:
          return 'エラーが発生しました: ${e.message}';
      }
    } catch (e) {
      return 'エラーが発生しました: $e';
    }
  }

  /// メールアドレスとパスワードでサインイン（早稲田メール限定）
  Future<String?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      // 早稲田大学のメールアドレスかチェック
      if (!_isWasedaEmail(email)) {
        return '早稲田大学のメールアドレスのみログイン可能です';
      }

      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return null; // 成功
    } on FirebaseAuthException catch (e) {
      // エラーメッセージを日本語化
      switch (e.code) {
        case 'user-not-found':
          return 'このメールアドレスのユーザーは見つかりません';
        case 'wrong-password':
          return 'パスワードが間違っています';
        case 'invalid-email':
          return 'メールアドレスの形式が正しくありません';
        case 'user-disabled':
          return 'このユーザーは無効化されています';
        default:
          return 'エラーが発生しました: ${e.message}';
      }
    } catch (e) {
      return 'エラーが発生しました: $e';
    }
  }

  /// Googleアカウントでサインイン（全ユーザー利用可能）
  Future<String?> signInWithGoogle() async {
    try {
      // Googleサインインフローを開始
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return 'サインインがキャンセルされました';
      }

      // 認証情報を取得
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Firebase用の認証情報を作成
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebaseにサインイン
      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      // ユーザー情報をFirestoreに保存/更新
      if (userCredential.user != null) {
        final user = userCredential.user!;
        final docRef = _firestore.collection('users').doc(user.uid);
        final doc = await docRef.get();
        
        if (!doc.exists) {
          // 新規ユーザーの場合
          final appUser = AppUser.create(
            uid: user.uid,
            email: user.email ?? '',
            name: user.displayName ?? '名無し',
            photoUrl: user.photoURL,
          );
          
          await docRef.set(appUser.toFirestore());
        } else {
          // 既存ユーザーの場合、最終ログイン日時を更新
          await docRef.update({
            'lastLoginAt': FieldValue.serverTimestamp(),
          });
        }
      }

      return null; // 成功
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'account-exists-with-different-credential':
          return 'このメールアドレスは既に別の方法で登録されています';
        case 'invalid-credential':
          return '認証情報が無効です';
        case 'operation-not-allowed':
          return 'Googleサインインが無効です';
        case 'user-disabled':
          return 'このユーザーは無効化されています';
        default:
          return 'エラーが発生しました: ${e.message}';
      }
    } catch (e) {
      return 'エラーが発生しました: $e';
    }
  }

  /// パスワードリセットメールの送信（早稲田メール限定）
  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      // 早稲田大学のメールアドレスかチェック
      if (!_isWasedaEmail(email)) {
        return '早稲田大学のメールアドレスのみ利用可能です';
      }

      await _auth.sendPasswordResetEmail(email: email);
      return null; // 成功
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'このメールアドレスのユーザーは見つかりません';
        case 'invalid-email':
          return 'メールアドレスの形式が正しくありません';
        default:
          return 'エラーが発生しました: ${e.message}';
      }
    } catch (e) {
      return 'エラーが発生しました: $e';
    }
  }

  /// サインアウト
  Future<void> signOut() async {
    // Googleサインアウトも実行
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// 現在のユーザー情報を取得
  Future<AppUser?> getCurrentAppUser() async {
    final user = currentUser;
    if (user == null) return null;
    
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;
    
    return AppUser.fromFirestore(doc);
  }
}