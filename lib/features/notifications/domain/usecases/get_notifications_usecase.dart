/*
====================================================
目的:
  - 通知一覧を取得するユースケース

処理構造:
  - 通知取得処理の委譲
====================================================
*/

import '../../../../shared/models/notification_model.dart';
import '../repositories/notifications_repository.dart';

/// ユーザーの通知一覧を取得する
class GetNotificationsUseCase {
  final NotificationsRepository _repository;

  GetNotificationsUseCase(this._repository);

  /// [uid] 対象ユーザーのUID
  ///
  /// Returns 通知リスト（新しい順）
  Future<List<AppNotification>> execute(String uid) async {
    return _repository.getNotifications(uid);
  }
}
