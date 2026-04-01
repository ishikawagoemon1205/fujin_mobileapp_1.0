/*
====================================================
目的:
  - 友達一覧取得ユースケース

処理構造:
  - 友達一覧の取得
====================================================
*/

import '../../../../shared/models/friend_model.dart';
import '../repositories/friends_repository.dart';

/// 友達一覧を取得する UseCase
class GetFriendsUseCase {
  final FriendsRepository _repository;

  const GetFriendsUseCase(this._repository);

  /// 友達一覧を取得する
  ///
  /// [uid] 自分の UID
  Future<List<Friend>> execute(String uid) {
    return _repository.getFriends(uid);
  }
}
