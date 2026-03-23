/*
====================================================
目的:
  - 開封機能の Firestore Repository 実装

処理構造:
  - Firestore からの箱データ取得
  - ステータス更新
  - 履歴追加
  - Firestore ↔ ドメインモデル変換
====================================================
*/

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../shared/models/box_model.dart';
import '../../domain/repositories/unseal_repository.dart';

/// Firestore を使った開封 Repository 実装
class FirestoreUnsealRepository implements UnsealRepository {
  final FirebaseFirestore _firestore;

  FirestoreUnsealRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<Box?> getBox(String boxId, String userId) async {
    final doc = await _firestore.collection('boxes').doc(boxId).get();
    if (!doc.exists) return null;
    final box = _fromFirestore(boxId, doc.data()!);
    if (box.userId != userId) return null;
    return box;
  }

  @override
  Future<void> updateBoxStatus(String boxId, BoxStatus status) async {
    final updates = <String, Object?>{
      'metadata.status': status.value,
      'metadata.updatedAt': Timestamp.now(),
    };

    if (status == BoxStatus.opened || status == BoxStatus.tampered) {
      updates['metadata.openedAt'] = Timestamp.now();
    }

    await _firestore.collection('boxes').doc(boxId).update(updates);
  }

  @override
  Future<void> addHistory(String boxId, BoxHistory history) async {
    await _firestore.collection('boxes').doc(boxId).update({
      'history': FieldValue.arrayUnion([
        {
          'timestamp': Timestamp.fromDate(history.timestamp),
          'action': history.action,
          'details': history.details,
        }
      ]),
    });
  }

  Box _fromFirestore(String boxId, Map<String, Object?> doc) {
    final metadata = doc['metadata'] as Map<String, Object?>;
    final facesData = doc['faces'] as Map<String, Object?>? ?? {};
    final contents = doc['contents'] as Map<String, Object?>;
    final historyData = doc['history'] as List<Object?>? ?? [];

    return Box(
      boxId: boxId,
      userId: metadata['userId'] as String? ?? '',
      createdAt: (metadata['createdAt'] as Timestamp).toDate(),
      updatedAt: (metadata['updatedAt'] as Timestamp).toDate(),
      status: BoxStatus.fromString(metadata['status'] as String),
      storageLocation: metadata['storageLocation'] as String,
      qrFaceCount: metadata['qrFaceCount'] as int,
      openedAt: metadata['openedAt'] != null
          ? (metadata['openedAt'] as Timestamp).toDate()
          : null,
      lastViewedAt: (metadata['lastViewedAt'] as Timestamp).toDate(),
      faces: facesData.map(
        (key, value) {
          final faceMap = value as Map<String, Object?>;
          return MapEntry(
            key,
            QRFace(
              faceId: key,
              qrCode: faceMap['qrCode'] as String,
              scannedAt: (faceMap['scannedAt'] as Timestamp).toDate(),
              checksum: faceMap['checksum'] as String,
            ),
          );
        },
      ),
      photos: (contents['photos'] as List<Object?>)
          .map((p) {
            final photoMap = p as Map<String, Object?>;
            return BoxPhoto(
              url: photoMap['url'] as String,
              storagePath: photoMap['storagePath'] as String,
              uploadedAt: (photoMap['uploadedAt'] as Timestamp).toDate(),
            );
          })
          .toList(),
      memo: contents['memo'] as String,
      history: historyData
          .map((h) {
            final historyMap = h as Map<String, Object?>;
            return BoxHistory(
              timestamp: (historyMap['timestamp'] as Timestamp).toDate(),
              action: historyMap['action'] as String,
              details: historyMap['details'] as String,
            );
          })
          .toList(),
    );
  }
}
