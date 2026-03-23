/*
====================================================
目的:
  - アプリケーションのルートウィジェット
  - テーマ設定とルーティング設定
  - 認証ゲートによるアクセス制御

処理構造:
  - テーマ設定（Material Design 3）
  - Beamerルーティングの初期化
  - AuthGate による認証状態の振り分け
====================================================
*/

import 'package:flutter/material.dart';
import 'package:beamer/beamer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/router.dart';
import 'features/auth/presentation/auth_gate.dart';

/// 封神アプリケーションのルートウィジェット
class FujinApp extends ConsumerWidget {
  const FujinApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      builder: (context, child) {
        return AuthGate(child: child ?? const SizedBox.shrink());
      },
    );
  }
}
