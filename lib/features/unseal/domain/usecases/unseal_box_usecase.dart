/*
====================================================
目的:
  - 箱の開封ユースケース

処理構造:
  - 箱データの取得
  - QR検証結果に基づくステータス更新
  - 履歴の追加
====================================================
*/

import '../../../../shared/models/box_model.dart';
import '../repositories/unseal_repository.dart';

/// 開封パラメータ
class UnsealBoxParams {
  final String boxId;
  final Set<String> scannedFaceIds;

  const UnsealBoxParams({
    required this.boxId,
    required this.scannedFaceIds,
  });
}

/// 箱を開封する UseCase
class UnsealBoxUseCase {
  final UnsealRepository _repository;

  const UnsealBoxUseCase(this._repository);

  /// 開封を実行する
  ///
  /// [params] 開封パラメータ
  ///
  /// Returns 更新後のステータス（opened または tampered）
  Future<BoxStatus> execute(UnsealBoxParams params) async {
    final box = await _repository.getBox(params.boxId);
    if (box == null) {
      throw BoxNotFoundException(params.boxId);
    }

    if (box.status != BoxStatus.sealed) {
      throw BoxNotSealedException(params.boxId, box.status);
    }

    final registeredFaceIds = box.faces.keys.toSet();
    final allScanned = registeredFaceIds.difference(params.scannedFaceIds).isEmpty;

    final newStatus = allScanned ? BoxStatus.opened : BoxStatus.tampered;

    await _repository.updateBoxStatus(params.boxId, newStatus);

    final details = allScanned
        ? '全${registeredFaceIds.length}面のQRコードを検証し正常開封'
        : '${params.scannedFaceIds.length}/${registeredFaceIds.length}面のみ検証。未検証: ${registeredFaceIds.difference(params.scannedFaceIds).join(", ")}';

    await _repository.addHistory(
      params.boxId,
      BoxHistory(
        timestamp: DateTime.now(),
        action: newStatus.value,
        details: details,
      ),
    );

    return newStatus;
  }
}

/// 箱が見つからない場合の例外
class BoxNotFoundException implements Exception {
  final String boxId;
  const BoxNotFoundException(this.boxId);

  @override
  String toString() => 'BoxNotFoundException: Box $boxId not found';
}

/// 箱が封印状態でない場合の例外
class BoxNotSealedException implements Exception {
  final String boxId;
  final BoxStatus currentStatus;
  const BoxNotSealedException(this.boxId, this.currentStatus);

  @override
  String toString() =>
      'BoxNotSealedException: Box $boxId is ${currentStatus.value}, not sealed';
}
