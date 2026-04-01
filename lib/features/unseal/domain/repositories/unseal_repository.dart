/*
====================================================
目的:
  - 開封機能の Repository インターフェース定義

処理構造:
  - 箱の取得操作
  - ステータス更新操作
  - 履歴追加操作
====================================================
*/

import '../../../../shared/models/box_model.dart';

/// 開封機能の Repository インターフェース
abstract class UnsealRepository {
  /// boxId で箱を取得する（userId が所有者またはグループメンバーでない場合は null を返す）
  ///
  /// [boxId] 取得対象の箱ID
  /// [userId] ログイン中のユーザーID
  ///
  /// Returns 箱データ、存在しない・権限がない場合はnull
  Future<Box?> getBox(String boxId, String userId);

  /// 箱のステータスを更新する
  ///
  /// [boxId] 更新対象の箱ID
  /// [status] 新しいステータス
  Future<void> updateBoxStatus(String boxId, BoxStatus status);

  /// 操作履歴を追加する
  ///
  /// [boxId] 対象の箱ID
  /// [history] 追加する履歴
  Future<void> addHistory(String boxId, BoxHistory history);

  /// グループの自分以外の全メンバーに開封・破損通知を送る
  ///
  /// [groupId] グループID
  /// [senderUid] 開封を実行したユーザーのUID（この人には通知しない）
  /// [boxId] 対象の箱ID
  /// [storageLocation] 保管場所（通知本文に使用）
  /// [status] 開封結果のステータス（opened または tampered）
  Future<void> notifyGroupMembersOnUnseal({
    required String groupId,
    required String senderUid,
    required String boxId,
    required String storageLocation,
    required BoxStatus status,
  });
}
