/*
====================================================
目的:
  - 友達申請拒否ユースケース

処理構造:
  - 申請ステータスの更新
====================================================
*/

import '../repositories/friends_repository.dart';

/// 友達申請を拒否する UseCase
class DeclineFriendRequestUseCase {
  final FriendsRepository _repository;

  const DeclineFriendRequestUseCase(this._repository);

  /// 友達申請を拒否する
  ///
  /// [requestId] 拒否する申請のドキュメントID
  Future<void> execute(String requestId) {
    return _repository.declineFriendRequest(requestId);
  }
}
