/*
====================================================
目的:
  - 箱一覧機能の Repository インターフェース定義

処理構造:
  - 全箱取得の抽象メソッド定義
====================================================
*/

import '../../../../shared/models/box_model.dart';

/// 箱一覧機能の Repository インターフェース
abstract class BoxListRepository {
  /// 指定ユーザーの全箱を取得する
  ///
  /// [userId] 取得対象のユーザーID
  ///
  /// Returns 箱のリスト
  Future<List<Box>> getAllBoxes(String userId);
}
