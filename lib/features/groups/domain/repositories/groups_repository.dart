/*
====================================================
目的:
  - グループ機能の Repository インターフェース定義

処理構造:
  - グループのCRUD
  - メンバー管理
  - 招待・承認
====================================================
*/

import '../../../../shared/models/group_model.dart';

/// グループ機能の Repository インターフェース
abstract class GroupsRepository {
  /// グループを作成する
  ///
  /// [name] グループ名
  /// [ownerUid] オーナーの UID
  /// [inviteeUids] 招待するメンバーの UID リスト
  ///
  /// Returns 作成されたグループID
  Future<String> createGroup(String name, String ownerUid, List<String> inviteeUids);

  /// 自分が参加中のグループ一覧を取得する
  ///
  /// [uid] 自分の UID
  Future<List<Group>> getGroups(String uid);

  /// グループIDからグループを取得する
  ///
  /// [groupId] グループID
  Future<Group?> getGroup(String groupId);

  /// グループにメンバーを招待する
  ///
  /// [groupId] グループID
  /// [inviteeUid] 招待するメンバーの UID
  Future<void> inviteMember(String groupId, String inviteeUid);

  /// グループ招待を承認する
  ///
  /// [groupId] グループID
  /// [uid] 承認するメンバーの UID
  Future<void> acceptGroupInvite(String groupId, String uid);

  /// グループ招待を拒否する
  ///
  /// [groupId] グループID
  /// [uid] 拒否するメンバーの UID
  Future<void> declineGroupInvite(String groupId, String uid);

  /// グループからメンバーを削除する（オーナー操作）
  ///
  /// [groupId] グループID
  /// [memberUid] 削除するメンバーの UID
  Future<void> removeMember(String groupId, String memberUid);

  /// グループから退出する（メンバー操作）
  ///
  /// [groupId] グループID
  /// [uid] 退出するメンバーの UID
  Future<void> leaveGroup(String groupId, String uid);

  /// グループを解散する（オーナー操作）
  ///
  /// [groupId] グループID
  Future<void> disbandGroup(String groupId);

  /// グループ名を変更する（オーナー操作）
  ///
  /// [groupId] グループID
  /// [newName] 新しいグループ名
  Future<void> updateGroupName(String groupId, String newName);
}
