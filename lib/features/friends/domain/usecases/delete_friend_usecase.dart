/*
====================================================
目的:
  - 友達削除ユースケース

処理構造:
  - 友達関係の削除
====================================================
*/

import '../repositories/friends_repository.dart';

/// 友達を削除する UseCase
class DeleteFriendUseCase {
  final FriendsRepository _repository;

  const DeleteFriendUseCase(this._repository);

  /// 友達を削除する（相互削除）
  ///
  /// [friendshipId] 削除する友達関係のドキュメントID
  Future<void> execute(String friendshipId) {
    return _repository.deleteFriend(friendshipId);
  }
}
