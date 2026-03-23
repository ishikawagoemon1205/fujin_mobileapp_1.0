/*
====================================================
目的:
  - 箱の封印作成ユースケース

処理構造:
  - 重複チェック
  - 写真アップロード
  - 箱データ作成
====================================================
*/

import 'dart:io';

import '../../../../shared/models/box_model.dart';
import '../repositories/seal_repository.dart';

/// 封印パラメータ
class CreateBoxParams {
  final String boxId;
  final String userId;
  final String storageLocation;
  final String memo;
  final Map<String, QRFace> faces;
  final List<File> photos;

  const CreateBoxParams({
    required this.boxId,
    required this.userId,
    required this.storageLocation,
    required this.memo,
    required this.faces,
    required this.photos,
  });
}

/// 箱を封印する UseCase
class CreateBoxUseCase {
  final SealRepository _repository;

  const CreateBoxUseCase(this._repository);

  /// 封印を実行する
  ///
  /// [params] 封印パラメータ
  ///
  /// Returns 作成された箱データ
  Future<Box> execute(CreateBoxParams params) async {
    final exists = await _repository.boxExists(params.boxId);
    if (exists) {
      throw BoxAlreadyExistsException(params.boxId);
    }

    final List<BoxPhoto> uploadedPhotos = [];
    for (int i = 0; i < params.photos.length; i++) {
      final photo = await _repository.uploadPhoto(
        boxId: params.boxId,
        file: params.photos[i],
        index: i,
      );
      uploadedPhotos.add(photo);
    }

    final now = DateTime.now();
    final box = Box(
      boxId: params.boxId,
      userId: params.userId,
      createdAt: now,
      updatedAt: now,
      status: BoxStatus.sealed,
      storageLocation: params.storageLocation,
      qrFaceCount: params.faces.length,
      lastViewedAt: now,
      faces: params.faces,
      photos: uploadedPhotos,
      memo: params.memo,
      history: [
        BoxHistory(
          timestamp: now,
          action: 'sealed',
          details: '${params.faces.length}面のQRコードで封印',
        ),
      ],
    );

    await _repository.createBox(box);
    return box;
  }
}

/// 同一BoxIDが既に存在する場合の例外
class BoxAlreadyExistsException implements Exception {
  final String boxId;
  const BoxAlreadyExistsException(this.boxId);

  @override
  String toString() => 'BoxAlreadyExistsException: Box $boxId already exists';
}
