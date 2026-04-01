/*
====================================================
目的:
  - アプリケーションのルートウィジェット
  - テーマ設定とルーティング設定
  - 認証ゲートによるアクセス制御

処理構造:
  - テーマ設定（Material Design 3）
  - 認証状態の監視による画面切り替え
  - 認証済み: Beamerルーティングで機能画面へ
  - 未認証: ログイン/サインアップ/パスワードリセット画面へ
====================================================
*/

import 'package:flutter/material.dart';
import 'package:beamer/beamer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/router.dart';
import 'features/auth/presentation/auth_gate.dart';
import 'features/auth/presentation/signup_page.dart';
import 'features/auth/presentation/password_reset_page.dart';
import 'shared/services/deep_link_service.dart';
import 'shared/services/fcm_token_service.dart';

/// 封神アプリケーションのルートウィジェット
///
/// 認証状態に応じて2つのアプリ構成を切り替える:
/// - 未認証: AuthGate が LoginPage を表示（Navigator ベース）
/// - 認証済み: Beamer による機能画面ルーティング
class FujinApp extends ConsumerWidget {
  const FujinApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    // 認証状態が確定するまでローディング表示
    // data が確定したら AuthGate が適切な画面を選択する
    return authState.when(
      loading: () => MaterialApp(
        title: '封神',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, __) => MaterialApp(
        title: '封神',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const Scaffold(
          body: Center(child: Text('認証エラーが発生しました')),
        ),
      ),
      data: (user) {
        if (user == null) {
          // 未認証: AuthGate が LoginPage を home として表示
          // サインアップ・パスワードリセットは Navigator.pushNamed で遷移
          return MaterialApp(
            title: '封神',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            debugShowCheckedModeBanner: false,
            home: const AuthGate(child: SizedBox.shrink()),
            onGenerateRoute: (settings) {
              switch (settings.name) {
                case '/signup':
                  return MaterialPageRoute(
                    builder: (_) => const SignUpPage(),
                    settings: settings,
                  );
                case '/password-reset':
                  return MaterialPageRoute(
                    builder: (_) => const PasswordResetPage(),
                    settings: settings,
                  );
                default:
                  return null;
              }
            },
          );
        }
        // 認証済み: Beamer による機能画面ルーティング
        DeepLinkService().initialize();
        FcmTokenService().saveToken(user.uid);
        return MaterialApp.router(
          title: '封神',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          debugShowCheckedModeBanner: false,
          routerDelegate: appRouterDelegate,
          routeInformationParser: BeamerParser(),
          backButtonDispatcher: BeamerBackButtonDispatcher(
            delegate: appRouterDelegate,
          ),
        );
      },
    );
  }
}

