/*
====================================================
目的:
  - 箱詳細取得ユースケース

処理構造:
  - 箱データの取得
  - 確認日時の更新
  - 閲覧履歴の追加
====================================================
*/

import '../../../../shared/models/box_model.dart';
import '../repositories/box_detail_repository.dart';

/// 箱の詳細を取得する UseCase
class GetBoxDetailUseCase {
  final BoxDetailRepository _repository;

  const GetBoxDetailUseCase(this._repository);

  /// 箱詳細を取得し、閲覧記録を残す
  ///
  /// [boxId] 取得対象の箱ID
  ///
  /// Returns 箱データ、存在しない場合はnull
  Future<Box?> execute(String boxId) async {
    final box = await _repository.getBox(boxId);
    if (box == null) return null;

    await _repository.updateLastViewedAt(boxId);
    await _repository.addHistory(
      boxId,
      BoxHistory(
        timestamp: DateTime.now(),
        action: 'viewed',
        details: '箱の詳細を確認',
      ),
    );

    return box;
  }
}
