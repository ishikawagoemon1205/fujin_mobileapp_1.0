/*
====================================================
目的:
  - 全通知を既読にするユースケース

処理構造:
  - 全既読処理の委譲
====================================================
*/

import '../repositories/notifications_repository.dart';

/// 全通知を既読にする
class MarkAllAsReadUseCase {
  final NotificationsRepository _repository;

  MarkAllAsReadUseCase(this._repository);

  /// [uid] 対象ユーザーのUID
  Future<void> execute(String uid) async {
    await _repository.markAllAsRead(uid);
  }
}
