/*
====================================================
目的:
  - 箱詳細機能の Firestore Repository 実装

処理構造:
  - Firestore からの箱データ取得
  - 確認日時更新
  - 履歴追加
  - Firestore ↔ ドメインモデル変換
====================================================
*/

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../shared/models/box_model.dart';
import '../../domain/repositories/box_detail_repository.dart';

/// Firestore を使った箱詳細 Repository 実装
class FirestoreBoxDetailRepository implements BoxDetailRepository {
  final FirebaseFirestore _firestore;

  FirestoreBoxDetailRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<Box?> getBox(String boxId, String userId) async {
    final doc = await _firestore.collection('boxes').doc(boxId).get();
    if (!doc.exists) return null;
    final box = _fromFirestore(boxId, doc.data()!);

    if (box.userId == userId) return box;

    if (box.groupId != null && box.groupId!.isNotEmpty) {
      final groupDoc = await _firestore.collection('groups').doc(box.groupId).get();
      if (groupDoc.exists) {
        final members = groupDoc.data()?['members'] as Map<String, Object?>?;
        if (members != null && members.containsKey(userId)) {
          final memberData = members[userId] as Map<String, Object?>?;
          if (memberData?['status'] == 'joined') {
            return box;
          }
        }
      }
    }

    return null;
  }

  @override
  Future<void> updateLastViewedAt(String boxId) async {
    await _firestore.collection('boxes').doc(boxId).update({
      'metadata.lastViewedAt': Timestamp.now(),
      'metadata.updatedAt': Timestamp.now(),
    });
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
      groupId: metadata['groupId'] as String?,
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
