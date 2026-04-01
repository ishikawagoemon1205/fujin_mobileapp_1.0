/*
====================================================
目的:
  - 箱一覧機能の Firestore Repository 実装

処理構造:
  - Firestore からの全箱データ取得
  - Firestore ↔ ドメインモデル変換
====================================================
*/

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../shared/models/box_model.dart';
import '../../domain/repositories/box_list_repository.dart';

/// Firestore を使った箱一覧 Repository 実装
class FirestoreBoxListRepository implements BoxListRepository {
  final FirebaseFirestore _firestore;

  FirestoreBoxListRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<Box>> getAllBoxes(String userId) async {
    final myBoxesSnapshot = await _firestore
        .collection('boxes')
        .where('metadata.userId', isEqualTo: userId)
        .get(const GetOptions(source: Source.server));

    final myBoxes = myBoxesSnapshot.docs
        .map((doc) => _fromFirestore(doc.id, doc.data()))
        .where((box) => box.userId.isNotEmpty && box.userId == userId)
        .toList();

    final groupsSnapshot = await _firestore.collection('groups').get();
    final myGroupIds = <String>[];
    for (final groupDoc in groupsSnapshot.docs) {
      final members = groupDoc.data()['members'] as Map<String, Object?>?;
      if (members != null && members.containsKey(userId)) {
        final memberData = members[userId] as Map<String, Object?>?;
        if (memberData?['status'] == 'joined') {
          myGroupIds.add(groupDoc.id);
        }
      }
    }

    final groupBoxes = <Box>[];
    for (final groupId in myGroupIds) {
      final groupBoxSnapshot = await _firestore
          .collection('boxes')
          .where('metadata.groupId', isEqualTo: groupId)
          .get(const GetOptions(source: Source.server));

      for (final doc in groupBoxSnapshot.docs) {
        final box = _fromFirestore(doc.id, doc.data());
        if (!myBoxes.any((b) => b.boxId == box.boxId)) {
          groupBoxes.add(box);
        }
      }
    }

    return [...myBoxes, ...groupBoxes];
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
