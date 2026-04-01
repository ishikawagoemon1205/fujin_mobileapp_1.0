/*
====================================================
目的:
  - グループ解散ユースケース

処理構造:
  - グループの解散
====================================================
*/

import '../repositories/groups_repository.dart';

/// グループを解散する UseCase
class DisbandGroupUseCase {
  final GroupsRepository _repository;

  const DisbandGroupUseCase(this._repository);

  /// グループを解散する（オーナーのみ）
  Future<void> execute(String groupId) {
    return _repository.disbandGroup(groupId);
  }
}
