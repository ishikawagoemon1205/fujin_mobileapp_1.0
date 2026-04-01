/*
====================================================
目的:
  - ディープリンク（招待リンク）の受信と処理

処理構造:
  - アプリ起動時の初期リンク取得
  - フォアグラウンド時のリンクストリーム監視
  - Beamer ルーターへの遷移委譲
====================================================
*/

import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

import '../../core/router.dart';

/// ディープリンクの受信を管理するサービス
class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  bool _initialized = false;

  /// ディープリンク監視を開始する
  ///
  /// 認証済み状態でのみ呼び出すこと
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint('[DeepLinkService] Failed to get initial link: $e');
    }

    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handleDeepLink,
      onError: (Object error) {
        debugPrint('[DeepLinkService] Link stream error: $error');
      },
    );
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('[DeepLinkService] Received deep link: $uri');

    final bool isHttpsInvite =
        uri.host == 'fujin.app' && uri.path == '/invite';
    final bool isCustomSchemeInvite =
        uri.scheme == 'fujin-app' && uri.host == 'invite';

    if (isHttpsInvite || isCustomSchemeInvite) {
      final from = uri.queryParameters['from'];
      final token = uri.queryParameters['token'];

      if (from != null && token != null && from.isNotEmpty && token.isNotEmpty) {
        final beamerUri = '/invite?from=$from&token=$token';
        debugPrint('[DeepLinkService] Navigating to: $beamerUri');
        appRouterDelegate.beamToNamed(beamerUri);
      }
    }
  }

  /// ディープリンク監視を停止する
  void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
    _initialized = false;
  }
}
