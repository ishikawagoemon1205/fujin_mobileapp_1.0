/*
====================================================
目的:
  - 未読通知数を取得するユースケース

処理構造:
  - 未読カウント取得処理の委譲
====================================================
*/

import '../repositories/notifications_repository.dart';

/// 未読通知数を取得する
class GetUnreadCountUseCase {
  final NotificationsRepository _repository;

  GetUnreadCountUseCase(this._repository);

  /// [uid] 対象ユーザーのUID
  ///
  /// Returns 未読件数
  Future<int> execute(String uid) async {
    return _repository.getUnreadCount(uid);
  }
}
