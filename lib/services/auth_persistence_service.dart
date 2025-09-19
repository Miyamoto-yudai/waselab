import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'debug_service.dart';
import 'auth_service.dart';

/// Firebase Auth の認証状態を手動で永続化するサービス
/// SharedPreferencesとFlutterSecureStorageを併用して実装
class AuthPersistenceService {
  static const String _uidKey = 'user_uid';
  static const String _emailKey = 'user_email';
  static const String _authMethodKey = 'auth_method';
  static const String _lastSignInKey = 'last_sign_in';
  static const String _hasAuthKey = 'has_auth';
  static const String _secureTokenKey = 'email_auth_token';
  static const String _tokenExpiryKey = 'token_expiry';
  static const String _securePasswordKey = 'email_auth_password'; // パスワードを安全に保存

  // FlutterSecureStorageのインスタンス
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  /// ログイン時に認証情報を保存（メール/パスワード認証用）
  Future<void> saveEmailAuthState(User user, String password) async {
    try {
      if (kDebugMode) {
        print('[AuthPersistence] ========= SAVE EMAIL AUTH START =========');
        print('[AuthPersistence] Saving email auth state...');
        print('[AuthPersistence]   - UID: ${user.uid}');
        print('[AuthPersistence]   - Email: ${user.email}');
        print('[AuthPersistence]   - Email Verified: ${user.emailVerified}');
      }

      final prefs = await SharedPreferences.getInstance();

      // 基本情報を保存（パスワードは保存しない）
      await prefs.setString(_uidKey, user.uid);
      if (user.email != null) {
        await prefs.setString(_emailKey, user.email!);
      }
      await prefs.setString(_authMethodKey, 'email');
      await prefs.setString(_lastSignInKey, DateTime.now().toIso8601String());
      await prefs.setBool(_hasAuthKey, true);

      // IDトークンとパスワードをセキュアストレージに保存
      try {
        // パスワードを安全に保存（自動再ログイン用）
        await _secureStorage.write(key: _securePasswordKey, value: password);
        if (kDebugMode) {
          print('[AuthPersistence] Password saved to secure storage for auto re-login');
        }

        final idToken = await user.getIdToken();
        if (idToken != null) {
          await _secureStorage.write(key: _secureTokenKey, value: idToken);
          // トークンの有効期限を保存（1時間後）
          final expiry = DateTime.now().add(const Duration(hours: 1));
          await _secureStorage.write(
            key: _tokenExpiryKey,
            value: expiry.toIso8601String(),
          );

          if (kDebugMode) {
            print('[AuthPersistence] ID token saved to secure storage');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('[AuthPersistence] Failed to save secure data: $e');
        }
      }

      // 保存確認（即座に読み返して検証）
      await prefs.reload(); // SharedPreferencesをリロード
      final savedUid = prefs.getString(_uidKey);
      final savedEmail = prefs.getString(_emailKey);
      final savedMethod = prefs.getString(_authMethodKey);
      final savedHasAuth = prefs.getBool(_hasAuthKey);

      if (kDebugMode) {
        print('[AuthPersistence] Verification - Reading back saved data:');
        print('[AuthPersistence]   - Saved UID: ${savedUid ?? "NOT SAVED"} (expected: ${user.uid})');
        print('[AuthPersistence]   - Saved Email: ${savedEmail ?? "NOT SAVED"} (expected: ${user.email})');
        print('[AuthPersistence]   - Saved Method: ${savedMethod ?? "NOT SAVED"} (expected: email)');
        print('[AuthPersistence]   - Has Auth Flag: $savedHasAuth (expected: true)');

        if (savedUid == user.uid && savedEmail == user.email && savedMethod == 'email' && savedHasAuth == true) {
          print('[AuthPersistence] ✅ Email auth state saved and verified successfully');
        } else {
          print('[AuthPersistence] ⚠️ WARNING: Saved data does not match expected values!');
        }
      }

      AuthDebugService().log(
        '💾 Email auth state saved',
        type: LogType.info,
        data: {
          'uid': user.uid,
          'email': user.email,
          'method': 'email',
          'savedSuccessfully': savedUid == user.uid,
          'verificationPassed': savedUid == user.uid && savedEmail == user.email,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (kDebugMode) {
        print('[AuthPersistence] ========= SAVE EMAIL AUTH END =========');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[AuthPersistence] ❌ Failed to save email auth state: $e');
      }
      AuthDebugService().log(
        '❌ Failed to save email auth state: $e',
        type: LogType.error,
      );
    }
  }

  /// ログイン時に認証情報を保存（Google認証用）
  Future<void> saveAuthState(User user) async {
    try {
      if (kDebugMode) {
        print('[AuthPersistence] Saving Google auth state...');
        print('  - UID: ${user.uid}');
        print('  - Email: ${user.email}');
      }

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(_uidKey, user.uid);
      if (user.email != null) {
        await prefs.setString(_emailKey, user.email!);
      }
      await prefs.setString(_authMethodKey, 'google');
      await prefs.setString(_lastSignInKey, DateTime.now().toIso8601String());
      await prefs.setBool(_hasAuthKey, true);

      // 保存確認
      final savedUid = prefs.getString(_uidKey);

      if (kDebugMode) {
        print('[AuthPersistence] ✅ Google auth state saved successfully');
        print('  - Saved UID: ${savedUid != null ? 'Yes' : 'No'}');
      }

      AuthDebugService().log(
        '💾 Google auth state saved',
        type: LogType.info,
        data: {
          'uid': user.uid,
          'email': user.email,
          'method': 'google',
          'savedSuccessfully': savedUid != null,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('[AuthPersistence] ❌ Failed to save auth state: $e');
      }
      AuthDebugService().log(
        '❌ Failed to save auth state: $e',
        type: LogType.error,
      );
    }
  }

  /// アプリ起動時に認証状態を復元（自動再ログインをメインに使用）
  Future<bool> restoreAuthState() async {
    try {
      if (kDebugMode) {
        print('[AuthPersistence] ========= AUTO RE-LOGIN PRIMARY =========');
        print('[AuthPersistence] Time: ${DateTime.now().toIso8601String()}');
        print('[AuthPersistence] Using auto re-login as primary restoration method');
      }

      final prefs = await SharedPreferences.getInstance();

      // 保存されたデータを取得
      final uid = prefs.getString(_uidKey);
      final email = prefs.getString(_emailKey);
      final authMethod = prefs.getString(_authMethodKey);
      final lastSignIn = prefs.getString(_lastSignInKey);
      final hasAuth = prefs.getBool(_hasAuthKey) ?? false;

      if (kDebugMode) {
        print('[AuthPersistence] Checking saved credentials:');
        print('[AuthPersistence]   - Email: ${email ?? "NULL"}');
        print('[AuthPersistence]   - Method: ${authMethod ?? "NULL"}');
        print('[AuthPersistence]   - Has Auth: $hasAuth');
      }

      if (!hasAuth || uid == null || email == null) {
        if (kDebugMode) {
          print('[AuthPersistence] 📭 No saved credentials found');
          print('[AuthPersistence] ========= RESTORE END =========');
        }
        return false;
      }

      // 最終ログインから30日以上経過していたら無効化
      if (lastSignIn != null) {
        final lastSignInDate = DateTime.parse(lastSignIn);
        if (DateTime.now().difference(lastSignInDate).inDays > 30) {
          if (kDebugMode) {
            print('[AuthPersistence] ⏰ Auth state expired (>30 days)');
          }
          await clearAuthState();
          return false;
        }
      }

      // メール認証の場合: 即座に自動再ログインを実行（メインの復元方法）
      if (authMethod == 'email') {
        if (kDebugMode) {
          print('[AuthPersistence] 🔑 Email auth detected - attempting auto re-login');
          print('[AuthPersistence] Email: $email');
        }

        // パスワードを使用した自動再ログインを即座に実行
        final restoredWithPassword = await _tryAutoReLogin(email, uid);
        if (restoredWithPassword) {
          if (kDebugMode) {
            print('[AuthPersistence] ✅ AUTO RE-LOGIN SUCCESSFUL');
            print('[AuthPersistence] User restored: ${FirebaseAuth.instance.currentUser?.uid}');
            print('[AuthPersistence] Email verified: ${FirebaseAuth.instance.currentUser?.emailVerified}');
            print('[AuthPersistence] ========= RESTORE END =========');
          }
          return true;
        }

        if (kDebugMode) {
          print('[AuthPersistence] ❌ Auto re-login failed - password may be missing');
          print('[AuthPersistence] ========= RESTORE END =========');
        }
        return false;
      }

      // Google認証の場合はサイレントサインインを試みる
      if (authMethod == 'google') {
        if (kDebugMode) {
          print('[AuthPersistence] 🆖 Google auth detected - trying silent sign-in');
        }

        // AuthServiceを使用してサイレントサインイン
        final authService = AuthService();
        final success = await authService.silentSignInWithGoogle();

        if (success) {
          if (kDebugMode) {
            print('[AuthPersistence] ✅ GOOGLE SILENT SIGN-IN SUCCESSFUL');
            print('[AuthPersistence] User restored: ${FirebaseAuth.instance.currentUser?.uid}');
            print('[AuthPersistence] ========= RESTORE END =========');
          }
          return true;
        } else {
          if (kDebugMode) {
            print('[AuthPersistence] ❌ Google silent sign-in failed');
            print('[AuthPersistence] ========= RESTORE END =========');
          }
          return false;
        }
      }

      if (kDebugMode) {
        print('[AuthPersistence] ⚠️ Could not restore auth state');
        print('[AuthPersistence] ========= RESTORE END =========');
      }

      // 復元できなかった場合はクリア
      await clearAuthState();
      return false;

    } catch (e) {
      if (kDebugMode) {
        print('[AuthPersistence] ❌ Error restoring auth state: $e');
        print('[AuthPersistence] ========= RESTORE END =========');
      }
      AuthDebugService().log(
        '❌ [AuthPersistence] Error restoring auth state',
        type: LogType.error,
        data: {
          'error': e.toString(),
        },
      );
      return false;
    }
  }

  /// 保存されたパスワードを使用して自動再ログインを試みる
  Future<bool> _tryAutoReLogin(String email, String expectedUid) async {
    try {
      if (kDebugMode) {
        print('[AuthPersistence] Attempting auto re-login for $email');
      }

      // セキュアストレージからパスワードを取得
      final savedPassword = await _secureStorage.read(key: _securePasswordKey);

      if (savedPassword == null) {
        if (kDebugMode) {
          print('[AuthPersistence] No saved password found');
        }
        return false;
      }

      if (kDebugMode) {
        print('[AuthPersistence] Found saved password, attempting sign in...');
      }

      // Firebase Authで再ログイン
      try {
        final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: savedPassword,
        );

        if (userCredential.user != null && userCredential.user!.uid == expectedUid) {
          if (kDebugMode) {
            print('[AuthPersistence] ✅ Auto re-login successful');
            print('[AuthPersistence]   - UID: ${userCredential.user!.uid}');
            print('[AuthPersistence]   - Email: ${userCredential.user!.email}');
            print('[AuthPersistence]   - EmailVerified: ${userCredential.user!.emailVerified}');
          }

          // トークンを更新
          try {
            await userCredential.user!.reload();
            await userCredential.user!.getIdToken();
          } catch (e) {
            if (kDebugMode) {
              print('[AuthPersistence] Warning: Token update failed: $e');
            }
          }

          return true;
        } else {
          if (kDebugMode) {
            print('[AuthPersistence] Re-login UID mismatch: expected $expectedUid, got ${userCredential.user?.uid}');
          }
          return false;
        }
      } on FirebaseAuthException catch (e) {
        if (kDebugMode) {
          print('[AuthPersistence] Re-login failed: ${e.code} - ${e.message}');
        }

        // パスワードが間違っている場合は削除
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          await _secureStorage.delete(key: _securePasswordKey);
          if (kDebugMode) {
            print('[AuthPersistence] Invalid password removed from storage');
          }
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('[AuthPersistence] Auto re-login error: $e');
      }
      return false;
    }
  }

  /// セキュアストレージからトークンを使用して復元を試みる
  Future<bool> _tryRestoreWithSavedToken(String expectedUid) async {
    try {
      // セキュアストレージからトークンを取得
      final savedToken = await _secureStorage.read(key: _secureTokenKey);
      final tokenExpiryStr = await _secureStorage.read(key: _tokenExpiryKey);

      if (savedToken == null || tokenExpiryStr == null) {
        if (kDebugMode) {
          print('[AuthPersistence] No saved token found in secure storage');
        }
        return false;
      }

      // トークンの有効期限をチェック
      final tokenExpiry = DateTime.parse(tokenExpiryStr);
      if (DateTime.now().isAfter(tokenExpiry)) {
        if (kDebugMode) {
          print('[AuthPersistence] Saved token has expired');
        }
        // 期限切れトークンをクリーンアップ
        await _clearSecureTokens();
        return false;
      }

      // Firebaseにカスタムトークンとして認証を試みる
      // 注意: これは通常のIDトークンなので、カスタムトークン認証は使えない
      // 代わりに、Firebase Authの内部的な復元メカニズムを利用する

      // トークンが有効な場合、Firebase Authの状態を強制的に更新
      try {
        // 現在のユーザーを再確認
        await FirebaseAuth.instance.currentUser?.reload();
        final currentUser = FirebaseAuth.instance.currentUser;

        if (currentUser != null && currentUser.uid == expectedUid) {
          if (kDebugMode) {
            print('[AuthPersistence] User restored after reload with saved token');
          }
          return true;
        }

        // それでもユーザーがいない場合は、手動でサインイン状態を復元できない
        // （メール/パスワード認証はセキュリティ上、トークンだけでは復元不可）
        if (kDebugMode) {
          print('[AuthPersistence] Cannot restore email auth with token alone');
        }
        return false;
      } catch (e) {
        if (kDebugMode) {
          print('[AuthPersistence] Error during token restoration: $e');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('[AuthPersistence] Error reading saved token: $e');
      }
      return false;
    }
  }

  /// セキュアストレージのトークンをクリア
  Future<void> _clearSecureTokens() async {
    try {
      await _secureStorage.delete(key: _secureTokenKey);
      await _secureStorage.delete(key: _tokenExpiryKey);
      await _secureStorage.delete(key: _securePasswordKey);
      if (kDebugMode) {
        print('[AuthPersistence] Secure tokens and password cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[AuthPersistence] Error clearing secure data: $e');
      }
    }
  }

  /// ログアウト時に認証情報をクリア
  Future<void> clearAuthState() async {
    try {
      if (kDebugMode) {
        print('[AuthPersistence] Clearing auth state...');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_uidKey);
      await prefs.remove(_emailKey);
      await prefs.remove(_authMethodKey);
      await prefs.remove(_lastSignInKey);
      await prefs.remove(_hasAuthKey);

      // セキュアストレージのトークンもクリア
      await _clearSecureTokens();

      if (kDebugMode) {
        print('[AuthPersistence] 🗑️ Auth state cleared');
      }

      AuthDebugService().log(
        '🗑️ Auth state cleared',
        type: LogType.info,
      );
    } catch (e) {
      if (kDebugMode) {
        print('[AuthPersistence] ❌ Failed to clear auth state: $e');
      }
      AuthDebugService().log(
        '❌ Failed to clear auth state: $e',
        type: LogType.error,
      );
    }
  }

  /// 保存された認証情報が存在するかチェック
  Future<bool> hasSavedAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasAuth = prefs.getBool(_hasAuthKey) ?? false;
      final uid = prefs.getString(_uidKey);

      if (kDebugMode) {
        print('[AuthPersistence] Checking saved auth state:');
        print('  - Has Auth flag: $hasAuth');
        print('  - Has UID: ${uid != null}');
      }

      return hasAuth && uid != null;
    } catch (e) {
      if (kDebugMode) {
        print('[AuthPersistence] ❌ Error checking saved state: $e');
      }
      return false;
    }
  }

  /// 保存された認証情報を取得（デバッグ用）
  Future<Map<String, dynamic>> getSavedAuthInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'uid': prefs.getString(_uidKey),
        'email': prefs.getString(_emailKey),
        'authMethod': prefs.getString(_authMethodKey),
        'lastSignIn': prefs.getString(_lastSignInKey),
        'hasAuth': prefs.getBool(_hasAuthKey),
      };
    } catch (e) {
      return {};
    }
  }
}