/*
====================================================
目的:
  - 認証状態に応じた画面の振り分け
  - 未ログイン時はログイン画面、ログイン済みなら子Widgetを表示

処理構造:
  - 認証状態の監視
  - 画面の切り替え
====================================================
*/

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'login_page.dart';
import '../domain/repositories/auth_repository.dart';

/// 認証状態を監視する StreamProvider
///
/// アプリ全体で認証状態を共有するため autoDispose を使わない。
/// autoDispose にすると、リスナーが一時的にゼロになった際に
/// Provider が破棄されてしまい、ユーザー切り替え時に状態が失われる。
final authStateProvider = StreamProvider((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges;
});

/// AuthRepository の Provider（main.dart で override する）
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  throw UnimplementedError('authRepositoryProvider must be overridden');
});

/// 認証状態に応じて画面を切り替えるゲートWidget
///
/// user == null の場合は LoginPage を起点とした Navigator ツリーを表示する。
/// サインアップ・パスワードリセットは Navigator.push で遷移する。
class AuthGate extends ConsumerWidget {
  final Widget child;

  const AuthGate({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const LoginPage();
        }
        return child;
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                '認証エラーが発生しました',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
