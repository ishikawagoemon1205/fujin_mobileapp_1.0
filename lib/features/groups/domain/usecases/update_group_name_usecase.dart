/*
====================================================
目的:
  - グループ名を変更するユースケース

処理構造:
  - グループ名変更処理の委譲
====================================================
*/

import '../repositories/groups_repository.dart';

/// グループ名を変更する（オーナー権限）
class UpdateGroupNameUseCase {
  final GroupsRepository _repository;

  UpdateGroupNameUseCase(this._repository);

  /// [groupId] 対象グループID
  /// [newName] 新しいグループ名
  Future<void> execute(String groupId, String newName) async {
    if (newName.trim().isEmpty) {
      throw ArgumentError('グループ名は空にできません');
    }
    await _repository.updateGroupName(groupId, newName.trim());
  }
}
