import 'package:flutter/material.dart';
import '../services/auth_service.dart';  // Firebase使用時はこちらを有効化
// import '../services/demo_auth_service.dart';  // デモモード用
import 'navigation_screen.dart';
import 'email_verification_screen.dart';

/// ログイン画面
/// 早稲田大学メールアドレス（@waseda.jp）でのみログイン・新規登録が可能
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // デモモード用: AuthServiceの代わりにDemoAuthServiceを使用
  final AuthService _authService = AuthService();
  // final DemoAuthService _authService = DemoAuthService();
  final _formKey = GlobalKey<FormState>();
  
  // テキストフィールドのコントローラー
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  
  // 性別選択
  String? _selectedGender;
  
  // 状態管理用の変数
  bool _isLogin = true; // true: ログイン画面, false: 新規登録画面
  bool _isLoading = false; // ローディング状態
  bool _obscurePassword = true; // パスワード表示/非表示

  @override
  void dispose() {
    // コントローラーの破棄
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  /// ログイン処理
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await _authService.signInWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (result == null && mounted) {
      // ログイン成功：メール認証状態をチェック
      if (!_authService.isEmailVerified) {
        // メール未認証の場合は認証画面へ
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const EmailVerificationScreen(),
            transitionDuration: const Duration(milliseconds: 300),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          ),
        );
      } else {
        // メール認証済みの場合はナビゲーション画面へ
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const NavigationScreen(),
            transitionDuration: const Duration(milliseconds: 300),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          ),
        );
      }
    } else if (result != null && mounted) {
      // エラー表示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 新規登録処理
  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await _authService.signUpWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      gender: _selectedGender,
      age: int.tryParse(_ageController.text),
    );

    setState(() => _isLoading = false);

    if (result == null && mounted) {
      // 登録成功：メール認証画面へ遷移
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const EmailVerificationScreen(),
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      );
      
      // 成功メッセージを表示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('アカウントを作成しました。メールを確認してください。'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (result != null && mounted) {
      // エラー表示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Googleサインイン処理
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    final result = await _authService.signInWithGoogle();

    setState(() => _isLoading = false);

    if (result == null && mounted) {
      // ログイン成功
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const NavigationScreen()),
      );
    } else if (result != null && mounted) {
      // エラー表示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// パスワードリセット処理
  Future<void> _handlePasswordReset() async {
    final email = _emailController.text.trim();
    
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('メールアドレスを入力してください'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final result = await _authService.sendPasswordResetEmail(email);

    if (mounted) {
      if (result == null) {
        // 成功
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('パスワードリセットメールを送信しました'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // エラー
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ロゴ・タイトル
                      Icon(
                        Icons.science,
                        size: 48,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'わせラボ',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: const Color(0xFF8E1728),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ログイン/新規登録切り替えタブ
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: _isLoading ? null : () {
                                setState(() => _isLogin = true);
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: _isLogin 
                                  ? Theme.of(context).primaryColor 
                                  : Colors.transparent,
                                foregroundColor: _isLogin 
                                  ? Colors.white 
                                  : Theme.of(context).primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('ログイン'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextButton(
                              onPressed: _isLoading ? null : () {
                                setState(() => _isLogin = false);
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: !_isLogin 
                                  ? Theme.of(context).primaryColor 
                                  : Colors.transparent,
                                foregroundColor: !_isLogin 
                                  ? Colors.white 
                                  : Theme.of(context).primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('新規登録'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 名前フィールド（新規登録のみ）
                      if (!_isLogin) ...[
                        TextFormField(
                          controller: _nameController,
                          enabled: !_isLoading,
                          decoration: const InputDecoration(
                            labelText: '名前',
                            hintText: '山田太郎',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return '名前を入力してください';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // 性別選択
                        DropdownButtonFormField<String>(
                          value: _selectedGender,
                          decoration: const InputDecoration(
                            labelText: '性別',
                            prefixIcon: Icon(Icons.wc),
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: '男性', child: Text('男性')),
                            DropdownMenuItem(value: '女性', child: Text('女性')),
                            DropdownMenuItem(value: 'その他', child: Text('その他')),
                            DropdownMenuItem(value: '回答しない', child: Text('回答しない')),
                          ],
                          onChanged: _isLoading ? null : (value) {
                            setState(() {
                              _selectedGender = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '性別を選択してください';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // 年齢フィールド
                        TextFormField(
                          controller: _ageController,
                          enabled: !_isLoading,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: '年齢',
                            hintText: '20',
                            prefixIcon: Icon(Icons.cake),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return '年齢を入力してください';
                            }
                            final age = int.tryParse(value);
                            if (age == null || age < 18 || age > 100) {
                              return '18歳以上100歳以下で入力してください';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      // メールアドレスフィールド
                      TextFormField(
                        controller: _emailController,
                        enabled: !_isLoading,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'メールアドレス',
                          hintText: 'example@waseda.jp',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'メールアドレスを入力してください';
                          }
                          final lowercaseEmail = value.toLowerCase();
                          // 早稲田大学の各種メールドメインに対応
                          if (!lowercaseEmail.endsWith('.waseda.jp') && 
                              !lowercaseEmail.endsWith('@waseda.jp')) {
                            return '早稲田大学のメールアドレスを使用してください';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // パスワードフィールド
                      TextFormField(
                        controller: _passwordController,
                        enabled: !_isLoading,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'パスワード',
                          hintText: '6文字以上',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword 
                                ? Icons.visibility 
                                : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'パスワードを入力してください';
                          }
                          if (value.length < 6) {
                            return 'パスワードは6文字以上で設定してください';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // 実行ボタン
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading 
                            ? null 
                            : (_isLogin ? _handleLogin : _handleSignUp),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(_isLogin ? 'ログイン' : '新規登録'),
                        ),
                      ),

                      // Googleサインインボタン
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'または',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Google Sign-Inボタン（ガイドライン準拠）
                      Container(
                        width: double.infinity,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFDADADA)),
                          color: Colors.white,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _isLoading ? null : _handleGoogleSignIn,
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Google Gロゴ（公式アセット）
                                  Image.asset(
                                    'assets/images/google_logo.png',
                                    height: 18,
                                    width: 18,
                                  ),
                                  const SizedBox(width: 24),
                                  // テキスト（Roboto Medium フォント）
                                  Text(
                                    _isLogin ? 'Googleでログイン' : 'Googleで登録',
                                    style: const TextStyle(
                                      color: Color(0xFF3C4043),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Roboto',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      // パスワードリセットリンク（ログインのみ）
                      if (_isLogin) ...[
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _isLoading ? null : _handlePasswordReset,
                          child: const Text('パスワードを忘れた方はこちら'),
                        ),
                      ],
                      
                      // 注意書き
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.blue.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Colors.blue,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '早稲田メール: 実験募集可\nGoogle: 閲覧・応募のみ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}