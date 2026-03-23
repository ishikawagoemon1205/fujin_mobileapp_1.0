/*
====================================================
目的:
  - 封印機能の Firestore Repository 実装
  - 箱の作成と写真アップロードの具体的なFirebase操作

処理構造:
  - Firestore ドキュメント作成
  - Firebase Storage への画像アップロード
  - データモデルとFirestoreドキュメントの変換
====================================================
*/

import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;

import '../../../../shared/models/box_model.dart';
import '../../domain/repositories/seal_repository.dart';

/// Firestore を使った封印 Repository 実装
class FirestoreSealRepository implements SealRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  FirestoreSealRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  @override
  Future<void> createBox(Box box) async {
    await _firestore.collection('boxes').doc(box.boxId).set(_toFirestore(box));
  }

  @override
  Future<bool> boxExists(String boxId) async {
    final doc = await _firestore.collection('boxes').doc(boxId).get();
    return doc.exists;
  }

  @override
  Future<BoxPhoto> uploadPhoto({
    required String boxId,
    required File file,
    required int index,
  }) async {
    final compressedBytes = await _compressImage(file);
    final storagePath = 'boxes/$boxId/photos/photo_$index.jpg';
    final ref = _storage.ref().child(storagePath);

    await ref.putData(
      compressedBytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    final url = await ref.getDownloadURL();

    return BoxPhoto(
      url: url,
      storagePath: storagePath,
      uploadedAt: DateTime.now(),
    );
  }

  Future<Uint8List> _compressImage(File file) async {
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);

    if (image == null) return bytes;

    const int kMaxPhotoSizeBytes = 2 * 1024 * 1024;

    for (final quality in [85, 70, 50, 30]) {
      final compressed = img.encodeJpg(image, quality: quality);
      if (compressed.length <= kMaxPhotoSizeBytes) {
        return Uint8List.fromList(compressed);
      }
    }

    final resized = img.copyResize(image, width: 1024);
    return Uint8List.fromList(img.encodeJpg(resized, quality: 50));
  }

  Map<String, Object?> _toFirestore(Box box) {
    return {
      'metadata': {
        'userId': box.userId,
        'createdAt': Timestamp.fromDate(box.createdAt),
        'updatedAt': Timestamp.fromDate(box.updatedAt),
        'status': box.status.value,
        'storageLocation': box.storageLocation,
        'qrFaceCount': box.qrFaceCount,
        'openedAt':
            box.openedAt != null ? Timestamp.fromDate(box.openedAt!) : null,
        'lastViewedAt': Timestamp.fromDate(box.lastViewedAt),
      },
      'faces': box.faces.map((key, face) => MapEntry(key, {
            'qrCode': face.qrCode,
            'scannedAt': Timestamp.fromDate(face.scannedAt),
            'checksum': face.checksum,
          })),
      'contents': {
        'photos': box.photos
            .map((photo) => {
                  'url': photo.url,
                  'storagePath': photo.storagePath,
                  'uploadedAt': Timestamp.fromDate(photo.uploadedAt),
                })
            .toList(),
        'memo': box.memo,
      },
      'history': box.history
          .map((h) => {
                'timestamp': Timestamp.fromDate(h.timestamp),
                'action': h.action,
                'details': h.details,
              })
          .toList(),
    };
  }
}
