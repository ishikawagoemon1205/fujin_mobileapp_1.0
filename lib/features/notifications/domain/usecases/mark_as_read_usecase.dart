/*
====================================================
目的:
  - 通知を既読にするユースケース

処理構造:
  - 既読処理の委譲
====================================================
*/

import '../repositories/notifications_repository.dart';

/// 通知を既読にする
class MarkAsReadUseCase {
  final NotificationsRepository _repository;

  MarkAsReadUseCase(this._repository);

  /// [notificationId] 対象通知のID
  Future<void> execute(String notificationId) async {
    await _repository.markAsRead(notificationId);
  }
}
