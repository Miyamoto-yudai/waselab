import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../models/app_user.dart';
import 'debug_service.dart';
import 'auth_persistence_service.dart';

/// 認証サービスクラス
/// Firebase AuthenticationとGoogle Sign Inを使用したユーザー認証を管理する
class AuthService {
  // Firebase Auth、Firestore、GoogleSignInのインスタンス
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Google Sign-Inの初期化
  // プラットフォームごとに適切な設定を使用
  late final GoogleSignIn _googleSignIn = kIsWeb 
    ? GoogleSignIn(
        scopes: ['email', 'profile'],
        // Web向けのClient ID
        clientId: '788143974236-jqi4c0558nu50cda3jams444dov43lue.apps.googleusercontent.com',
      )
    : GoogleSignIn(
        scopes: ['email', 'profile'],
        // iOS/Androidはnative configを使用（GoogleService-Info.plist/google-services.jsonから自動読込）
      );

  /// 現在ログイン中のユーザーを取得
  User? get currentUser => _auth.currentUser;

  /// ユーザーの認証状態の変更をストリームで監視
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// ユーザーの変更をストリームで監視（より詳細な変更を検知）
  Stream<User?> get userChanges => _auth.userChanges();

  /// 早稲田大学のメールアドレスかどうかを検証
  /// @ruri.waseda.jp, @fuji.waseda.jp などのサブドメインも含む
  bool _isWasedaEmail(String email) {
    final lowercaseEmail = email.toLowerCase();
    // 早稲田大学の各種メールドメインに対応
    return lowercaseEmail.endsWith('.waseda.jp') || 
           lowercaseEmail.endsWith('@waseda.jp');
  }

  /// メールアドレスとパスワードでサインアップ
  Future<String?> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    String? gender,
    int? age,
    String? studentId,
  }) async {
    try {

      if (kDebugMode) {
        print('[AuthService] Creating user with email: $email');
      }

      // ユーザー作成
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      if (kDebugMode) {
        print('[AuthService] User created successfully: ${userCredential.user?.uid}');
      }

      // Firestoreにユーザー情報を保存
      if (userCredential.user != null) {
        final appUser = AppUser.create(
          uid: userCredential.user!.uid,
          email: email,
          name: name,
          emailVerified: false, // 初期状態は未認証
          gender: gender,
          age: age,
          studentId: studentId,
        );

        await _firestore.collection('users')
            .doc(userCredential.user!.uid)
            .set(appUser.toFirestore());

        // 表示名を設定
        await userCredential.user!.updateDisplayName(name);

        // 認証情報を保存（Android対策）
        await AuthPersistenceService().saveEmailAuthState(userCredential.user!, password);

        // Firebase Authの永続化を確実にするため、ユーザー情報を再読み込み
        // 注意: getIdToken(true)の強制リフレッシュは認証状態を不安定にする可能性があるため削除
        try {
          await userCredential.user!.reload();
          // トークンの自然な更新を待つ（強制リフレッシュしない）
          await userCredential.user!.getIdToken();
          if (kDebugMode) {
            print('[AuthService] New user authenticated successfully');
          }
        } catch (e) {
          if (kDebugMode) {
            print('[AuthService] Warning: User info reload failed: $e');
          }
        }

        // メール認証を送信
        await sendEmailVerification();
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

  /// メールアドレスとパスワードでサインイン
  Future<String?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      if (kDebugMode) {
        print('[AuthService] Signing in with email: $email');
      }

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (kDebugMode) {
        print('[AuthService] Sign in successful: ${userCredential.user?.uid}');
        print('[AuthService] Email verified: ${userCredential.user?.emailVerified}');
      }

      // 認証情報を保存（Android対策）
      if (userCredential.user != null) {
        if (kDebugMode) {
          print('[AuthService] Calling saveEmailAuthState for user: ${userCredential.user!.uid}');
        }
        await AuthPersistenceService().saveEmailAuthState(userCredential.user!, password);
        if (kDebugMode) {
          print('[AuthService] saveEmailAuthState completed');
        }

        // Firebase Authの永続化を確実にするため、ユーザー情報を確認
        try {
          await userCredential.user!.reload();
          // トークンの自然な更新を待つ（強制リフレッシュしない）
          final token = await userCredential.user!.getIdToken();
          if (kDebugMode) {
            print('[AuthService] Token exists: ${token != null && token.isNotEmpty}');
          }

          // 再度currentUserを確認
          final currentUser = _auth.currentUser;
          if (kDebugMode) {
            print('[AuthService] Current user after sign in and persistence save: ${currentUser?.uid}');
            print('[AuthService] Auth state should be persisted now');
          }

          // 保存されたデータを即座に確認
          if (kDebugMode) {
            final hasSaved = await AuthPersistenceService().hasSavedAuthState();
            print('[AuthService] Persistence check - Has saved auth: $hasSaved');
            final savedInfo = await AuthPersistenceService().getSavedAuthInfo();
            print('[AuthService] Persistence check - Saved info: $savedInfo');
          }
        } catch (e) {
          if (kDebugMode) {
            print('[AuthService] Warning: User verification failed: $e');
          }
        }
      }

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
        // ユーザーがキャンセルした場合は特別な値を返す
        return 'CANCELLED';
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
        
        // Firestoreトランザクションを使用して安全にドキュメントを作成/更新
        await _firestore.runTransaction((transaction) async {
          final docRef = _firestore.collection('users').doc(user.uid);
          final doc = await transaction.get(docRef);
          
          if (!doc.exists) {
            // 新規ユーザーの場合
            final appUser = AppUser.create(
              uid: user.uid,
              email: user.email ?? '',
              name: user.displayName ?? '名無し',
              photoUrl: user.photoURL,
            );
            
            transaction.set(docRef, appUser.toFirestore());
          } else {
            // 既存ユーザーの場合、最終ログイン日時を更新
            transaction.update(docRef, {
              'lastLoginAt': FieldValue.serverTimestamp(),
            });
          }
        });

        // 認証情報を保存（Android対策）
        await AuthPersistenceService().saveAuthState(user);
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
        case 'popup-closed-by-user':
        case 'cancelled':
        case 'popup_closed_by_user':
          // ポップアップがユーザーによって閉じられた場合
          return 'CANCELLED';
        default:
          return 'エラーが発生しました: ${e.message}';
      }
    } catch (e) {
      // エラーメッセージを詳しく確認
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('popup') || 
          errorString.contains('cancel') || 
          errorString.contains('closed')) {
        // ポップアップが閉じられた場合はキャンセル扱い
        return 'CANCELLED';
      }
      return 'エラーが発生しました: $e';
    }
  }

  /// パスワードリセットメールの送信
  Future<String?> sendPasswordResetEmail(String email) async {
    try {

      // アプリケーションの言語設定を日本語に設定
      await _auth.setLanguageCode('ja');
      
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

  /// Googleアカウントでサイレント再認証（復元用）
  Future<bool> silentSignInWithGoogle() async {
    try {
      if (kDebugMode) {
        print('[AuthService] Attempting silent Google sign-in...');
      }

      // サイレントサインインを試みる
      final GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently();

      if (googleUser == null) {
        if (kDebugMode) {
          print('[AuthService] Silent sign-in failed: No cached Google account');
        }
        return false;
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

      if (userCredential.user != null) {
        if (kDebugMode) {
          print('[AuthService] ✅ Silent Google sign-in successful: ${userCredential.user!.uid}');
        }

        // Firestoreのユーザー情報を更新
        await _firestore.collection('users').doc(userCredential.user!.uid).update({
          'lastLoginAt': FieldValue.serverTimestamp(),
        });

        // 認証情報を保存
        await AuthPersistenceService().saveAuthState(userCredential.user!);

        return true;
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('[AuthService] Silent Google sign-in error: $e');
      }
      return false;
    }
  }

  /// カスタムトークンで再認証（メール認証用の復元）
  Future<bool> signInWithCustomToken(String token) async {
    try {
      if (kDebugMode) {
        print('[AuthService] Attempting custom token sign-in...');
      }

      final UserCredential userCredential = await _auth.signInWithCustomToken(token);

      if (userCredential.user != null) {
        if (kDebugMode) {
          print('[AuthService] ✅ Custom token sign-in successful: ${userCredential.user!.uid}');
        }
        return true;
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('[AuthService] Custom token sign-in error: $e');
      }
      return false;
    }
  }

  /// サインアウト
  Future<void> signOut() async {
    // デバッグログ記録
    AuthDebugService().log(
      '🚪 signOut() called',
      type: LogType.critical,
      stackTrace: StackTrace.current,
      data: {
        'currentUser': currentUser?.uid,
        'email': currentUser?.email,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    // 保存された認証情報をクリア（Android対策）
    await AuthPersistenceService().clearAuthState();

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

  /// メール認証を送信
  Future<String?> sendEmailVerification() async {
    try {
      final user = currentUser;
      if (user == null) {
        return 'ユーザーが見つかりません';
      }
      
      if (user.emailVerified) {
        return 'メールアドレスは既に認証済みです';
      }
      
      // アプリケーションの言語設定を日本語に設定
      await _auth.setLanguageCode('ja');
      
      // デフォルトの設定でメール認証を送信
      // Firebase Consoleで設定したテンプレートが使用される
      await user.sendEmailVerification();
      
      return null; // 成功
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'too-many-requests':
          return 'リクエストが多すぎます。しばらく待ってから再試行してください';
        default:
          return 'エラーが発生しました: ${e.message}';
      }
    } catch (e) {
      return 'エラーが発生しました: $e';
    }
  }

  /// メール認証状態をチェック
  Future<bool> checkEmailVerification() async {
    try {
      final user = currentUser;
      if (user == null) return false;
      
      // 最新の認証状態を取得
      await user.reload();
      final refreshedUser = _auth.currentUser;
      
      if (refreshedUser != null && refreshedUser.emailVerified) {
        // Firestoreのユーザー情報を更新
        await _firestore.collection('users').doc(refreshedUser.uid).update({
          'emailVerified': true,
          'emailVerifiedAt': FieldValue.serverTimestamp(),
        });
        return true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  /// メール認証状態を取得
  bool get isEmailVerified => currentUser?.emailVerified ?? false;

  /// ユーザードキュメントを取得
  Future<DocumentSnapshot<Map<String, dynamic>>?> getUserDocument(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc;
    } catch (e) {
      return null;
    }
  }
}