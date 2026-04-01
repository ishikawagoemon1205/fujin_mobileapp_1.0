/*
====================================================
目的:
  - グループ一覧取得ユースケース

処理構造:
  - グループ一覧の取得
====================================================
*/

import '../../../../shared/models/group_model.dart';
import '../repositories/groups_repository.dart';

/// グループ一覧を取得する UseCase
class GetGroupsUseCase {
  final GroupsRepository _repository;

  const GetGroupsUseCase(this._repository);

  /// 自分が参加中のグループ一覧を取得する
  ///
  /// [uid] 自分の UID
  Future<List<Group>> execute(String uid) {
    return _repository.getGroups(uid);
  }
}
