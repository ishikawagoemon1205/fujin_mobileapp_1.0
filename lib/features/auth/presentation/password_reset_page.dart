/*
====================================================
目的:
  - パスワードリセットメール送信画面

処理構造:
  - メールアドレス入力フォーム
  - リセットメール送信処理
  - エラーハンドリング
====================================================
*/

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/exceptions/auth_exceptions.dart';
import '../domain/usecases/send_password_reset_usecase.dart';
import 'auth_gate.dart';

/// パスワードリセット UseCase の Provider
final sendPasswordResetUseCaseProvider =
    Provider<SendPasswordResetUseCase>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return SendPasswordResetUseCase(authRepository);
});

/// パスワードリセット画面
class PasswordResetPage extends ConsumerStatefulWidget {
  const PasswordResetPage({super.key});

  @override
  ConsumerState<PasswordResetPage> createState() => _PasswordResetPageState();
}

class _PasswordResetPageState extends ConsumerState<PasswordResetPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendPasswordReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final useCase = ref.read(sendPasswordResetUseCaseProvider);
      await useCase.execute(email: _emailController.text.trim());
      if (mounted) {
        setState(() => _isSent = true);
      }
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

  String _mapAuthError(Object error) {
    if (error is AuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'このメールアドレスは登録されていません';
        case 'invalid-email':
          return 'メールアドレスの形式が正しくありません';
        case 'network-request-failed':
          return 'ネットワークエラーが発生しました';
        default:
          return 'メール送信に失敗しました（${error.code}）';
      }
    }
    return 'メール送信に失敗しました';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('パスワードリセット'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _isSent ? _buildSentMessage(theme) : _buildForm(theme),
          ),
        ),
      ),
    );
  }

  Widget _buildSentMessage(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.mark_email_read_outlined,
          size: 64,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          'メールを送信しました',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${_emailController.text.trim()} にパスワードリセット用のメールを送信しました。\nメール内のリンクからパスワードを再設定してください。',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ログイン画面に戻る'),
          ),
        ),
      ],
    );
  }

  Widget _buildForm(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.lock_reset_outlined,
          size: 64,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          'パスワードリセット',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '登録済みのメールアドレスを入力してください。\nパスワードリセット用のメールを送信します。',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Form(
          key: _formKey,
          child: TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _sendPasswordReset(),
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
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            onPressed: _isLoading ? null : _sendPasswordReset,
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('リセットメールを送信'),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ログイン画面に戻る'),
        ),
      ],
    );
  }
}
