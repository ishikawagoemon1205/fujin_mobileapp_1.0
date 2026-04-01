/*
====================================================
目的:
  - 友達関係のデータモデル定義

処理構造:
  - データ構造の定義
====================================================
*/

/// 友達関係のデータモデル
///
/// 相互に同意して繋がった2人のユーザーを表す
class Friend {
  final String friendshipId;
  final List<String> userIds;
  final DateTime createdAt;

  const Friend({
    required this.friendshipId,
    required this.userIds,
    required this.createdAt,
  });

  /// 相手の UID を取得する
  ///
  /// [myUid] 自分の UID
  ///
  /// Returns 相手の UID
  String getOtherUid(String myUid) {
    return userIds.firstWhere((uid) => uid != myUid);
  }
}
