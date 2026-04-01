/*
====================================================
目的:
  - グループメンバーを削除するユースケース

処理構造:
  - メンバー削除処理の委譲
====================================================
*/

import '../repositories/groups_repository.dart';

/// グループからメンバーを削除する（オーナー権限）
class RemoveMemberUseCase {
  final GroupsRepository _repository;

  RemoveMemberUseCase(this._repository);

  /// [groupId] 対象グループID
  /// [memberUid] 削除対象メンバーのUID
  Future<void> execute(String groupId, String memberUid) async {
    await _repository.removeMember(groupId, memberUid);
  }
}
