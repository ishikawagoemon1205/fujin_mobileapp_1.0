/*
====================================================
目的:
  - メール・パスワードおよびGoogleによるログイン画面

処理構造:
  - 入力フォーム
  - ログイン処理
  - Googleサインイン処理
  - エラーハンドリング
  - 画面遷移（サインアップ・パスワードリセット）
====================================================
*/

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/exceptions/auth_exceptions.dart';
import '../domain/usecases/sign_in_with_email_usecase.dart';
import '../domain/usecases/sign_in_with_google_usecase.dart';
import 'auth_gate.dart';

/// メール認証用サインイン UseCase の Provider
final signInWithEmailUseCaseProvider = Provider<SignInWithEmailUseCase>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return SignInWithEmailUseCase(authRepository);
});

/// Google認証用サインイン UseCase の Provider
final signInWithGoogleUseCaseProvider =
    Provider<SignInWithGoogleUseCase>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return SignInWithGoogleUseCase(authRepository);
});

/// ログイン画面
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final useCase = ref.read(signInWithEmailUseCaseProvider);
      await useCase.execute(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_mapAuthError(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isGoogleLoading = true);

    try {
      debugPrint('[LoginPage] Google Sign-In 開始');
      final useCase = ref.read(signInWithGoogleUseCaseProvider);
      await useCase.execute();
      debugPrint('[LoginPage] Google Sign-In 成功');
    } catch (e) {
      debugPrint('[LoginPage] Google Sign-In エラー: $e');
      if (mounted && e is! GoogleSignInCancelledException) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_mapAuthError(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  String _mapAuthError(Object error) {
    if (error is AuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'このメールアドレスは登録されていません';
        case 'wrong-password':
        case 'invalid-credential':
          return 'メールアドレスまたはパスワードが正しくありません';
        case 'invalid-email':
          return 'メールアドレスの形式が正しくありません';
        case 'too-many-requests':
          return 'ログイン試行回数が多すぎます。しばらくしてから再度お試しください';
        case 'network-request-failed':
          return 'ネットワークエラーが発生しました';
        case 'account-exists-with-different-credential':
          return 'このメールアドレスは別のログイン方法で登録されています';
        case 'google-sign-in-timeout':
          return 'Google サインインがタイムアウトしました。設定を確認してください';
        case 'google-sign-in-error':
          return 'Google サインインに失敗しました。再度お試しください';
        default:
          return 'ログインに失敗しました（${error.code}）';
      }
    }
    return 'ログインに失敗しました';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  '封神',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '未開封を証明するアプリ',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 48),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'メールアドレス',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'メールアドレスを入力してください';
                          }
                          if (!value.contains('@')) {
                            return 'メールアドレスの形式が正しくありません';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _signInWithEmail(),
                        decoration: InputDecoration(
                          labelText: 'パスワード',
                          prefixIcon: const Icon(Icons.lock_outlined),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(
                                  () => _obscurePassword = !_obscurePassword);
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'パスワードを入力してください';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/password-reset');
                    },
                    child: const Text('パスワードを忘れた方'),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _signInWithEmail,
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('ログイン'),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'または',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _isGoogleLoading ? null : _signInWithGoogle,
                    icon: _isGoogleLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.g_mobiledata, size: 28),
                    label: const Text('Google でログイン'),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('アカウントをお持ちでない方'),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/signup');
                      },
                      child: const Text('新規登録'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
