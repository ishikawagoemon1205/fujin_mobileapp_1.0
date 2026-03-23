/*
====================================================
目的:
  - 箱の情報取得ユースケース（確認機能用）

処理構造:
  - 箱の取得
  - 確認日時の更新
  - 履歴の追加
====================================================
*/

import '../../../../shared/models/box_model.dart';
import '../repositories/verify_repository.dart';

/// 箱を取得して確認記録を残す UseCase
class GetBoxUseCase {
  final VerifyRepository _repository;

  const GetBoxUseCase(this._repository);

  /// 箱情報を取得し、確認記録を残す
  ///
  /// [boxId] 取得対象の箱ID
  /// [userId] ログイン中のユーザーID
  ///
  /// Returns 箱データ、存在しない・他ユーザーの箱の場合はnull
  Future<Box?> execute(String boxId, String userId) async {
    final box = await _repository.getBox(boxId, userId);
    if (box == null) return null;

    await _repository.updateLastViewedAt(boxId);
    await _repository.addHistory(
      boxId,
      BoxHistory(
        timestamp: DateTime.now(),
        action: 'viewed',
        details: '箱の状態を確認',
      ),
    );

    return box;
  }
}
