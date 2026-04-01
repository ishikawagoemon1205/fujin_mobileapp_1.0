/*
====================================================
目的:
  - 友達申請承認ユースケース

処理構造:
  - 申請ステータスの更新
  - 友達関係の作成
  - 通知の作成
====================================================
*/

import '../repositories/friends_repository.dart';

/// 友達申請を承認する UseCase
class AcceptFriendRequestUseCase {
  final FriendsRepository _repository;

  const AcceptFriendRequestUseCase(this._repository);

  /// 友達申請を承認する
  ///
  /// [requestId] 承認する申請のドキュメントID
  Future<void> execute(String requestId) {
    return _repository.acceptFriendRequest(requestId);
  }
}
