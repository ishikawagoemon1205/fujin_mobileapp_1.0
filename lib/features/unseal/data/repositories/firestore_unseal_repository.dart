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

  @override
  Future<void> notifyGroupMembersOnUnseal({
    required String groupId,
    required String senderUid,
    required String boxId,
    required String storageLocation,
    required BoxStatus status,
  }) async {
    final groupDoc =
        await _firestore.collection('groups').doc(groupId).get();
    if (!groupDoc.exists) return;

    final data = groupDoc.data()!;
    final memberUids = List<String>.from(data['memberUids'] as List? ?? []);

    final targets =
        memberUids.where((uid) => uid != senderUid).toList();
    if (targets.isEmpty) return;

    final senderDoc =
        await _firestore.collection('users').doc(senderUid).get();
    final senderName = (senderDoc.data()?['displayName'] as String?)
        ?? (senderDoc.data()?['email'] as String?)
        ?? '不明なユーザー';

    final groupName = data['name'] as String? ?? 'グループ';

    final bool isTampered = status == BoxStatus.tampered;
    final notificationType = isTampered ? 'box_tampered' : 'box_opened';
    final title = isTampered
        ? '⚠️ 破損が検知されました'
        : '📦 グループの封印が開封されました';
    final body = isTampered
        ? '「$groupName」の封印物で破損が検知されました（保管場所: $storageLocation）'
        : '$senderName が「$groupName」の封印物を開封しました（保管場所: $storageLocation）';

    final batch = _firestore.batch();
    for (final uid in targets) {
      final notifRef = _firestore.collection('notifications').doc();
      batch.set(notifRef, {
        'toUid': uid,
        'type': notificationType,
        'title': title,
        'body': body,
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
