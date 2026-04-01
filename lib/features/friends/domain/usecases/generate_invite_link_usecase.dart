/*
====================================================
目的:
  - 招待リンク生成ユースケース

処理構造:
  - トークン生成・保存
  - リンク文字列構築
====================================================
*/

import '../repositories/friends_repository.dart';

/// 招待リンクを生成する UseCase
class GenerateInviteLinkUseCase {
  final FriendsRepository _repository;

  const GenerateInviteLinkUseCase(this._repository);

  /// 招待リンクを生成する
  ///
  /// [fromUid] 招待を送るユーザーの UID
  ///
  /// Returns 招待リンクURL文字列
  Future<String> execute(String fromUid) async {
    final token = await _repository.generateInviteToken(fromUid);
    final expires = DateTime.now()
        .add(const Duration(hours: 72))
        .millisecondsSinceEpoch;
    return 'https://fujin.app/invite?from=$fromUid&token=$token&expires=$expires';
  }
}
