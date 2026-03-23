/*
====================================================
目的:
  - 全箱取得ユースケース

処理構造:
  - 全箱データの取得
====================================================
*/

import '../../../../shared/models/box_model.dart';
import '../repositories/box_list_repository.dart';

/// 全箱を取得する UseCase
class GetAllBoxesUseCase {
  final BoxListRepository _repository;

  const GetAllBoxesUseCase(this._repository);

  /// 指定ユーザーの全箱を取得する
  ///
  /// [userId] 取得対象のユーザーID
  ///
  /// Returns 箱のリスト
  Future<List<Box>> execute(String userId) {
    return _repository.getAllBoxes(userId);
  }
}
