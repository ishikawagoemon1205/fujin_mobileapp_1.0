/*
====================================================
目的:
  - グループ機能の Firestore Repository 実装

処理構造:
  - グループのCRUD
  - メンバー管理
  - 通知ドキュメントの作成
====================================================
*/

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../shared/models/group_model.dart';
import '../../domain/repositories/groups_repository.dart';

/// Firestore を使ったグループ Repository 実装
class FirestoreGroupsRepository implements GroupsRepository {
  final FirebaseFirestore _firestore;

  FirestoreGroupsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<String> createGroup(String name, String ownerUid, List<String> inviteeUids) async {
    final docRef = _firestore.collection('groups').doc();
    final now = Timestamp.now();

    final members = <String, Map<String, Object?>>{
      ownerUid: {
        'role': GroupRole.owner.value,
        'status': GroupMemberStatus.joined.value,
        'joinedAt': now,
      },
    };

    for (final uid in inviteeUids) {
      members[uid] = {
        'role': GroupRole.member.value,
        'status': GroupMemberStatus.invited.value,
        'joinedAt': now,
      };
    }

    // memberUids は Array 形式で保持し、Firestore の arrayContains クエリに対応させる
    // （members は Map 形式のため where クエリ不可のため冗長フィールドとして管理）
    final memberUids = [ownerUid, ...inviteeUids];

    await docRef.set({
      'name': name,
      'ownerUid': ownerUid,
      'members': members,
      'memberUids': memberUids,
      'createdAt': now,
      'updatedAt': now,
    });

    for (final uid in inviteeUids) {
      await _createNotification(
        toUid: uid,
        type: 'group_invited',
        title: 'グループに招待されました',
        body: '「$name」に招待されています。',
        payload: {'groupId': docRef.id, 'groupName': name},
      );
    }

    return docRef.id;
  }

  @override
  Future<List<Group>> getGroups(String uid) async {
    final snapshot = await _firestore
        .collection('groups')
        .where('memberUids', arrayContains: uid)
        .get();

    return snapshot.docs
        .map((doc) => _fromFirestore(doc.id, doc.data()))
        .toList();
  }

  @override
  Future<Group?> getGroup(String groupId) async {
    final doc = await _firestore.collection('groups').doc(groupId).get();
    if (!doc.exists) return null;
    return _fromFirestore(doc.id, doc.data()!);
  }

  @override
  Future<void> inviteMember(String groupId, String inviteeUid) async {
    final doc = await _firestore.collection('groups').doc(groupId).get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final members = data['members'] as Map<String, Object?>;
    if (members.length >= 5) {
      throw Exception('グループは最大5人までです');
    }

    await _firestore.collection('groups').doc(groupId).update({
      'members.$inviteeUid': {
        'role': GroupRole.member.value,
        'status': GroupMemberStatus.invited.value,
        'joinedAt': Timestamp.now(),
      },
      'memberUids': FieldValue.arrayUnion([inviteeUid]),
      'updatedAt': Timestamp.now(),
    });

    final groupName = data['name'] as String;
    await _createNotification(
      toUid: inviteeUid,
      type: 'group_invited',
      title: 'グループに招待されました',
      body: '「$groupName」に招待されています。',
      payload: {'groupId': groupId, 'groupName': groupName},
    );
  }

  @override
  Future<void> acceptGroupInvite(String groupId, String uid) async {
    await _firestore.collection('groups').doc(groupId).update({
      'members.$uid.status': GroupMemberStatus.joined.value,
      'members.$uid.joinedAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    });
  }

  @override
  Future<void> declineGroupInvite(String groupId, String uid) async {
    await _firestore.collection('groups').doc(groupId).update({
      'members.$uid': FieldValue.delete(),
      'memberUids': FieldValue.arrayRemove([uid]),
      'updatedAt': Timestamp.now(),
    });
  }

  @override
  Future<void> removeMember(String groupId, String memberUid) async {
    await _firestore.collection('groups').doc(groupId).update({
      'members.$memberUid': FieldValue.delete(),
      'memberUids': FieldValue.arrayRemove([memberUid]),
      'updatedAt': Timestamp.now(),
    });
  }

  @override
  Future<void> leaveGroup(String groupId, String uid) async {
    await _firestore.collection('groups').doc(groupId).update({
      'members.$uid': FieldValue.delete(),
      'memberUids': FieldValue.arrayRemove([uid]),
      'updatedAt': Timestamp.now(),
    });
  }

  @override
  Future<void> disbandGroup(String groupId) async {
    await _firestore.collection('groups').doc(groupId).delete();
  }

  @override
  Future<void> updateGroupName(String groupId, String newName) async {
    await _firestore.collection('groups').doc(groupId).update({
      'name': newName,
      'updatedAt': Timestamp.now(),
    });
  }

  Group _fromFirestore(String groupId, Map<String, Object?> data) {
    final membersData = data['members'] as Map<String, Object?>? ?? {};
    final members = membersData.entries.map((entry) {
      final memberData = entry.value as Map<String, Object?>;
      return GroupMember(
        uid: entry.key,
        role: GroupRole.fromString(memberData['role'] as String),
        status: GroupMemberStatus.fromString(memberData['status'] as String),
        joinedAt: (memberData['joinedAt'] as Timestamp).toDate(),
      );
    }).toList();

    return Group(
      groupId: groupId,
      name: data['name'] as String,
      ownerUid: data['ownerUid'] as String,
      members: members,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Future<void> _createNotification({
    required String toUid,
    required String type,
    required String title,
    required String body,
    required Map<String, String> payload,
  }) async {
    await _firestore.collection('notifications').add({
      'toUid': toUid,
      'type': type,
      'title': title,
      'body': body,
      'payload': payload,
      'isRead': false,
      'createdAt': Timestamp.now(),
    });
  }
}
