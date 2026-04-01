/*
====================================================
目的:
  - グループ退出ユースケース

処理構造:
  - グループからの退出
====================================================
*/

import '../repositories/groups_repository.dart';

/// グループから退出する UseCase
class LeaveGroupUseCase {
  final GroupsRepository _repository;

  const LeaveGroupUseCase(this._repository);

  /// グループから退出する（メンバー操作、オーナーは不可）
  Future<void> execute(String groupId, String uid) {
    return _repository.leaveGroup(groupId, uid);
  }
}
