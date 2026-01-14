/*
====================================================
目的:
  - アプリケーションのルートウィジェット
  - テーマ設定とルーティング設定

処理構造:
  - テーマ設定（Material Design 3）
  - Beamerルーティングの初期化
  - アプリケーション全体の構造定義
====================================================
*/

import 'package:flutter/material.dart';
import 'package:beamer/beamer.dart';
import 'core/theme/app_theme.dart';
import 'core/router.dart';

/// 封神アプリケーションのルートウィジェット
class FujinApp extends StatelessWidget {
  const FujinApp({super.key});

  @override
  Widget build(BuildContext context) {
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
  }
}
