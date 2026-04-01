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
import '../features/friends/presentation/friends_page.dart';
import '../features/friends/presentation/friend_requests_page.dart';
import '../features/friends/presentation/my_qr_page.dart';
import '../features/groups/presentation/group_list_page.dart';
import '../features/groups/presentation/group_create_page.dart';
import '../features/groups/presentation/group_detail_page.dart';
import '../features/notifications/presentation/notifications_page.dart';
import '../features/profile/presentation/profile_edit_page.dart';
import '../features/friends/presentation/invite_accept_page.dart';

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
        final boxId = state.pathParameters['boxId'] ?? '';
        if (boxId.isEmpty) return const BeamPage(key: ValueKey('box-list'), title: '封印一覧', child: BoxListPage());
        return BeamPage(
          key: ValueKey('box-$boxId'),
          title: '箱の詳細',
          child: BoxDetailPage(boxId: boxId),
        );
      },
      '/unseal/:boxId': (context, state, data) {
        final boxId = state.pathParameters['boxId'] ?? '';
        if (boxId.isEmpty) return const BeamPage(key: ValueKey('box-list'), title: '封印一覧', child: BoxListPage());
        return BeamPage(
          key: ValueKey('unseal-$boxId'),
          title: '開封する',
          child: UnsealPage(boxId: boxId),
        );
      },
      '/friends': (context, state, data) => const BeamPage(
            key: ValueKey('friends'),
            title: 'つながり',
            child: FriendsPage(),
          ),
      '/friends/requests': (context, state, data) => const BeamPage(
            key: ValueKey('friend-requests'),
            title: 'フレンド申請',
            child: FriendRequestsPage(),
          ),
      '/friends/my-qr': (context, state, data) => const BeamPage(
            key: ValueKey('my-qr'),
            title: 'マイQR',
            child: MyQrPage(),
          ),
      '/groups': (context, state, data) => const BeamPage(
            key: ValueKey('groups'),
            title: 'グループ',
            child: GroupListPage(),
          ),
      '/groups/create': (context, state, data) => const BeamPage(
            key: ValueKey('group-create'),
            title: 'グループ作成',
            child: GroupCreatePage(),
          ),
      // 正規表現で 'create' を除外: /groups/{英数字} にのみマッチ
      RegExp(r'^/groups/(?!create$)[^/]+$'): (context, state, data) {
        final groupId = state.pathParameters['groupId']
            ?? RegExp(r'^/groups/([^/]+)$')
                .firstMatch(state.routeInformation.uri.path)
                ?.group(1)
            ?? '';
        if (groupId.isEmpty) {
          return const BeamPage(
            key: ValueKey('groups-fallback'),
            title: 'グループ',
            child: GroupListPage(),
          );
        }
        return BeamPage(
          key: ValueKey('group-$groupId'),
          title: 'グループ詳細',
          child: GroupDetailPage(groupId: groupId),
        );
      },
      '/notifications': (context, state, data) => const BeamPage(
            key: ValueKey('notifications'),
            title: 'お知らせ',
            child: NotificationsPage(),
          ),
      '/profile/edit': (context, state, data) => const BeamPage(
            key: ValueKey('profile-edit'),
            title: 'プロフィール編集',
            child: ProfileEditPage(),
          ),
      '/invite': (context, state, data) {
        final uri = state.routeInformation.uri;
        final fromUid = uri.queryParameters['from'] ?? '';
        final token = uri.queryParameters['token'] ?? '';
        if (fromUid.isEmpty || token.isEmpty) {
          return const BeamPage(
            key: ValueKey('home'),
            title: '封神',
            child: HomePage(),
          );
        }
        return BeamPage(
          key: const ValueKey('invite-accept'),
          title: '友達招待',
          child: InviteAcceptPage(fromUid: fromUid, token: token),
        );
      },
    },
  ),
);
