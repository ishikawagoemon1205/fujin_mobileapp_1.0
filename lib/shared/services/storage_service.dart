/*
====================================================
目的:
  - Firestore Storageへの画像アップロード機能

処理構造:
  - 画像の圧縮
  - Storageへのアップロード
  - URLの取得
  - 画像の削除
====================================================
*/

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import '../../core/constants/app_constants.dart';

/// Firebase Storageサービス
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// 画像を圧縮する
  /// 
  /// [file] 圧縮する画像ファイル
  /// 
  /// Returns 圧縮後の画像データ
  Future<List<int>> compressImage(File file) async {
    final imageBytes = await file.readAsBytes();
    final image = img.decodeImage(imageBytes);

    if (image == null) {
      throw Exception('画像の読み込みに失敗しました');
    }

    int quality = 85;
    List<int> compressed = img.encodeJpg(image, quality: quality);

    while (compressed.length > DataConstraints.maxPhotoSizeBytes && quality > 20) {
      quality -= 10;
      compressed = img.encodeJpg(image, quality: quality);
    }

    if (compressed.length > DataConstraints.maxPhotoSizeBytes) {
      final scale = 0.8;
      final resized = img.copyResize(
        image,
        width: (image.width * scale).round(),
        height: (image.height * scale).round(),
      );
      compressed = img.encodeJpg(resized, quality: 85);
    }

    return compressed;
  }

  /// 画像をアップロードする
  /// 
  /// [boxId] 箱のID
  /// [file] アップロードする画像ファイル
  /// [index] 画像のインデックス（0-9）
  /// 
  /// Returns アップロードされた画像のURLとストレージパス
  Future<Map<String, String>> uploadBoxPhoto({
    required String boxId,
    required File file,
    required int index,
  }) async {
    try {
      debugPrint('[StorageService] Starting upload for box: $boxId, index: $index');
      
      final compressedData = await compressImage(file);
      debugPrint('[StorageService] Image compressed: ${compressedData.length} bytes');
      
      final storagePath = 'boxes/$boxId/photos/photo_$index.jpg';
      debugPrint('[StorageService] Storage path: $storagePath');
      
      final ref = _storage.ref().child(storagePath);
      debugPrint('[StorageService] Reference created, starting upload...');

      await ref.putData(
        Uint8List.fromList(compressedData),
        SettableMetadata(contentType: 'image/jpeg'),
      );
      debugPrint('[StorageService] Upload completed, getting download URL...');

      final downloadUrl = await ref.getDownloadURL();
      debugPrint('[StorageService] Download URL obtained: $downloadUrl');

      return {
        'url': downloadUrl,
        'storagePath': storagePath,
      };
    } catch (e, stackTrace) {
      debugPrint('[StorageService] ERROR during upload: $e');
      debugPrint('[StorageService] StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// 画像を削除する
  /// 
  /// [storagePath] ストレージパス
  Future<void> deletePhoto(String storagePath) async {
    try {
      await _storage.ref().child(storagePath).delete();
    } catch (e) {
      // ファイルが存在しない場合は無視
    }
  }

  /// 箱のすべての画像を削除する
  /// 
  /// [boxId] 箱のID
  Future<void> deleteAllBoxPhotos(String boxId) async {
    try {
      final ref = _storage.ref().child('boxes/$boxId/photos');
      final result = await ref.listAll();
      
      for (final item in result.items) {
        await item.delete();
      }
    } catch (e) {
      // エラーは無視
    }
  }
}
