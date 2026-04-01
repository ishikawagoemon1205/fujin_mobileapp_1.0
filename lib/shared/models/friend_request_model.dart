/*
====================================================
目的:
  - 友達申請のデータモデル定義

処理構造:
  - データ構造の定義
  - ステータス管理
====================================================
*/

/// 友達申請のステータス
enum FriendRequestStatus {
  pending('pending', '承認待ち'),
  accepted('accepted', '承認済み'),
  declined('declined', '拒否済み');

  const FriendRequestStatus(this.value, this.label);
  final String value;
  final String label;

  /// 文字列からステータスを取得する
  static FriendRequestStatus fromString(String value) {
    return FriendRequestStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => FriendRequestStatus.pending,
    );
  }
}

/// 友達申請のデータモデル
class FriendRequest {
  final String requestId;
  final String fromUid;
  final String toUid;
  final FriendRequestStatus status;
  final DateTime createdAt;

  const FriendRequest({
    required this.requestId,
    required this.fromUid,
    required this.toUid,
    required this.status,
    required this.createdAt,
  });
}
