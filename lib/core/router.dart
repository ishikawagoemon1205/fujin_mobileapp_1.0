/*
====================================================
目的:
  - アプリケーションのルーティング設定
  - Beamerを使った画面遷移の定義
  - 認証ガードによるアクセス制御

処理構造:
  - 認証ルート定義
  - 機能ルート定義
  - ルーターデリゲートの初期化
====================================================
*/

import 'package:beamer/beamer.dart';
import 'package:flutter/material.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/signup_page.dart';
import '../features/auth/presentation/password_reset_page.dart';
import '../features/home/presentation/home_page.dart';
import '../features/seal/presentation/seal_page.dart';
import '../features/verify/presentation/verify_page.dart';
import '../features/unseal/presentation/unseal_page.dart';
import '../features/box_list/presentation/box_list_page.dart';
import '../features/box_detail/presentation/box_detail_page.dart';

final appRouterDelegate = BeamerDelegate(
  locationBuilder: RoutesLocationBuilder(
    routes: {
      '/': (context, state, data) => const BeamPage(
            key: ValueKey('home'),
            title: '封神',
            child: HomePage(),
          ),
      '/login': (context, state, data) => const BeamPage(
            key: ValueKey('login'),
            title: 'ログイン',
            child: LoginPage(),
          ),
      '/signup': (context, state, data) => const BeamPage(
            key: ValueKey('signup'),
            title: '新規登録',
            child: SignUpPage(),
          ),
      '/password-reset': (context, state, data) => const BeamPage(
            key: ValueKey('password-reset'),
            title: 'パスワードリセット',
            child: PasswordResetPage(),
          ),
      '/seal': (context, state, data) => const BeamPage(
            key: ValueKey('seal'),
            title: '新しく封印する',
            child: SealPage(),
          ),
      '/verify': (context, state, data) => const BeamPage(
            key: ValueKey('verify'),
            title: '中身を確認する',
            child: VerifyPage(),
          ),
      '/box-list': (context, state, data) => const BeamPage(
            key: ValueKey('box-list'),
            title: '封印一覧',
            child: BoxListPage(),
          ),
      '/box/:boxId': (context, state, data) {
        final boxId = state.pathParameters['boxId']!;
        return BeamPage(
          key: ValueKey('box-$boxId'),
          title: '箱の詳細',
          child: BoxDetailPage(boxId: boxId),
        );
      },
      '/unseal/:boxId': (context, state, data) {
        final boxId = state.pathParameters['boxId']!;
        return BeamPage(
          key: ValueKey('unseal-$boxId'),
          title: '開封する',
          child: UnsealPage(boxId: boxId),
        );
      },
    },
  ),
);
