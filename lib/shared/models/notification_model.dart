/*
====================================================
目的:
  - アプリ内通知のデータモデル定義

処理構造:
  - データ構造の定義
  - 通知種別の管理
====================================================
*/

/// 通知の種別
enum NotificationType {
  boxSealed('box_sealed', '封印完了'),
  boxOpened('box_opened', '開封完了'),
  boxTampered('box_tampered', '破損検知'),
  boxUnsealed('box_unsealed', '開封通知'),
  friendRequested('friend_requested', '友達申請'),
  friendAccepted('friend_accepted', '友達承認'),
  groupInvited('group_invited', 'グループ招待'),
  groupMemberJoined('group_member_joined', 'メンバー参加'),
  groupMemberLeft('group_member_left', 'メンバー脱退');

  const NotificationType(this.value, this.label);
  final String value;
  final String label;

  /// 文字列から通知種別を取得する
  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => NotificationType.boxSealed,
    );
  }
}

/// アプリ内通知のデータモデル
class AppNotification {
  final String notificationId;
  final String toUid;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, String> payload;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.notificationId,
    required this.toUid,
    required this.type,
    required this.title,
    required this.body,
    required this.payload,
    required this.isRead,
    required this.createdAt,
  });

  /// 既読にしたコピーを返す
  AppNotification markAsRead() {
    return AppNotification(
      notificationId: notificationId,
      toUid: toUid,
      type: type,
      title: title,
      body: body,
      payload: payload,
      isRead: true,
      createdAt: createdAt,
    );
  }
}
