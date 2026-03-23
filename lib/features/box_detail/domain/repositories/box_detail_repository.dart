/*
====================================================
目的:
  - 箱詳細機能の Repository インターフェース定義

処理構造:
  - 箱の取得操作
  - 確認日時の更新操作
====================================================
*/

import '../../../../shared/models/box_model.dart';

/// 箱詳細機能の Repository インターフェース
abstract class BoxDetailRepository {
  /// boxId で箱を取得する
  ///
  /// [boxId] 取得対象の箱ID
  ///
  /// Returns 箱データ、存在しない場合はnull
  Future<Box?> getBox(String boxId);

  /// 最終確認日時を更新する
  ///
  /// [boxId] 更新対象の箱ID
  Future<void> updateLastViewedAt(String boxId);

  /// 操作履歴を追加する
  ///
  /// [boxId] 対象の箱ID
  /// [history] 追加する履歴
  Future<void> addHistory(String boxId, BoxHistory history);
}
