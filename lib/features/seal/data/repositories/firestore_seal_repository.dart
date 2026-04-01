/*
====================================================
目的:
  - 封印機能の Firestore Repository 実装
  - 箱の作成と写真アップロードの具体的なFirebase操作
  - グループ封印時のメンバーへの通知送信

処理構造:
  - Firestore ドキュメント作成
  - Firebase Storage への画像アップロード
  - グループメンバー取得 → 通知ドキュメント作成
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
  Future<void> notifyGroupMembers({
    required String groupId,
    required String senderUid,
    required String boxId,
    required String storageLocation,
  }) async {
    // グループドキュメントから memberUids を取得する
    final groupDoc =
        await _firestore.collection('groups').doc(groupId).get();
    if (!groupDoc.exists) return;

    final data = groupDoc.data()!;
    final memberUids = List<String>.from(data['memberUids'] as List? ?? []);

    // 送信者自身には通知しない
    final targets =
        memberUids.where((uid) => uid != senderUid).toList();
    if (targets.isEmpty) return;

    // 送信者の表示名を取得する（通知本文に使用）
    final senderDoc =
        await _firestore.collection('users').doc(senderUid).get();
    final senderName = (senderDoc.data()?['displayName'] as String?)
        ?? (senderDoc.data()?['email'] as String?)
        ?? '不明なユーザー';

    final groupName = data['name'] as String? ?? 'グループ';

    // 自分以外の全メンバーに通知を送る
    final batch = _firestore.batch();
    for (final uid in targets) {
      final notifRef = _firestore.collection('notifications').doc();
      batch.set(notifRef, {
        'toUid': uid,
        'type': 'box_sealed',
        'title': '📦 グループで封印されました',
        'body': '$senderName が「$groupName」で封印しました（保管場所: $storageLocation）',
        'payload': {
          'boxId': boxId,
          'groupId': groupId,
          'groupName': groupName,
        },
        'isRead': false,
        'createdAt': Timestamp.now(),
      });
    }
    await batch.commit();
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
        'groupId': box.groupId,
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
