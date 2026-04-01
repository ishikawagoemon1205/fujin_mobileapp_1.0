/*
====================================================
目的:
  - グループ招待承認ユースケース

処理構造:
  - 招待の承認
====================================================
*/

import '../repositories/groups_repository.dart';

/// グループ招待を承認する UseCase
class AcceptGroupInviteUseCase {
  final GroupsRepository _repository;

  const AcceptGroupInviteUseCase(this._repository);

  /// グループ招待を承認する
  Future<void> execute(String groupId, String uid) {
    return _repository.acceptGroupInvite(groupId, uid);
  }
}
