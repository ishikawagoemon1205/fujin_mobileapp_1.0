/*
====================================================
目的:
  - グループにメンバーを招待するユースケース

処理構造:
  - メンバー招待処理の委譲
====================================================
*/

import '../repositories/groups_repository.dart';

/// グループに友達を招待する
class InviteMemberUseCase {
  final GroupsRepository _repository;

  InviteMemberUseCase(this._repository);

  /// [groupId] 対象グループID
  /// [inviteeUid] 招待する友達のUID
  Future<void> execute(String groupId, String inviteeUid) async {
    await _repository.inviteMember(groupId, inviteeUid);
  }
}
