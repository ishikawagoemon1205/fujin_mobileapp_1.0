/*
====================================================
目的:
  - グループ招待を辞退するユースケース

処理構造:
  - 招待辞退処理の委譲
====================================================
*/

import '../repositories/groups_repository.dart';

/// グループ招待を辞退する
class DeclineGroupInviteUseCase {
  final GroupsRepository _repository;

  DeclineGroupInviteUseCase(this._repository);

  /// [groupId] 対象グループID
  /// [uid] 辞退するユーザーのUID
  Future<void> execute(String groupId, String uid) async {
    await _repository.declineGroupInvite(groupId, uid);
  }
}
