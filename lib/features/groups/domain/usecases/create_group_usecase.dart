/*
====================================================
目的:
  - グループ作成ユースケース

処理構造:
  - バリデーション
  - グループの作成
  - 招待通知の送信
====================================================
*/

import '../repositories/groups_repository.dart';

/// グループ作成パラメータ
class CreateGroupParams {
  final String name;
  final String ownerUid;
  final List<String> inviteeUids;

  const CreateGroupParams({
    required this.name,
    required this.ownerUid,
    required this.inviteeUids,
  });
}

/// グループを作成する UseCase
class CreateGroupUseCase {
  final GroupsRepository _repository;

  const CreateGroupUseCase(this._repository);

  /// グループを作成する
  ///
  /// [params] グループ作成パラメータ
  ///
  /// Returns 作成されたグループID
  Future<String> execute(CreateGroupParams params) {
    if (params.name.trim().isEmpty) {
      throw GroupException('グループ名を入力してください');
    }
    if (params.inviteeUids.isEmpty) {
      throw GroupException('メンバーを1人以上選択してください');
    }
    final totalMembers = params.inviteeUids.length + 1;
    if (totalMembers > 5) {
      throw GroupException('グループは最大5人までです');
    }
    return _repository.createGroup(
      params.name.trim(),
      params.ownerUid,
      params.inviteeUids,
    );
  }
}

/// グループ関連の例外
class GroupException implements Exception {
  final String message;
  const GroupException(this.message);

  @override
  String toString() => 'GroupException: $message';
}
