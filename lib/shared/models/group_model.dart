/*
====================================================
目的:
  - グループのデータモデル定義

処理構造:
  - データ構造の定義
  - ロール管理
  - メンバーステータス管理
====================================================
*/

/// グループ内のロール
enum GroupRole {
  owner('owner'),
  member('member');

  const GroupRole(this.value);
  final String value;

  /// 文字列からロールを取得する
  static GroupRole fromString(String value) {
    return GroupRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => GroupRole.member,
    );
  }
}

/// グループメンバーのステータス
enum GroupMemberStatus {
  invited('invited', '招待中'),
  joined('joined', '参加済み');

  const GroupMemberStatus(this.value, this.label);
  final String value;
  final String label;

  /// 文字列からステータスを取得する
  static GroupMemberStatus fromString(String value) {
    return GroupMemberStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => GroupMemberStatus.invited,
    );
  }
}

/// グループメンバーのデータモデル
class GroupMember {
  final String uid;
  final GroupRole role;
  final GroupMemberStatus status;
  final DateTime joinedAt;

  const GroupMember({
    required this.uid,
    required this.role,
    required this.status,
    required this.joinedAt,
  });
}

/// グループのデータモデル
class Group {
  final String groupId;
  final String name;
  final String ownerUid;
  final List<GroupMember> members;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Group({
    required this.groupId,
    required this.name,
    required this.ownerUid,
    required this.members,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 参加済みメンバーのみを取得する
  List<GroupMember> get joinedMembers =>
      members.where((m) => m.status == GroupMemberStatus.joined).toList();

  /// 指定ユーザーが参加済みメンバーか判定する
  bool isJoinedMember(String uid) =>
      joinedMembers.any((m) => m.uid == uid);

  /// 指定ユーザーがオーナーか判定する
  bool isOwner(String uid) => ownerUid == uid;
}
