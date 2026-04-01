/*
====================================================
目的:
  - 友達機能の Firestore Repository 実装

処理構造:
  - 友達申請のCRUD
  - 友達関係のCRUD
  - 招待トークン管理
  - 通知ドキュメントの作成
====================================================
*/

import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../shared/models/friend_model.dart';
import '../../../../shared/models/friend_request_model.dart';
import '../../../../shared/models/user_model.dart';
import '../../domain/repositories/friends_repository.dart';

/// Firestore を使った友達 Repository 実装
class FirestoreFriendsRepository implements FriendsRepository {
  final FirebaseFirestore _firestore;

  FirestoreFriendsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> sendFriendRequest(String fromUid, String toUid) async {
    final docRef = _firestore.collection('friend_requests').doc();
    await docRef.set({
      'fromUid': fromUid,
      'toUid': toUid,
      'status': FriendRequestStatus.pending.value,
      'createdAt': Timestamp.now(),
    });

    await _createNotification(
      toUid: toUid,
      type: 'friend_requested',
      title: '友達申請が届きました',
      body: '友達申請が届いています。確認してください。',
      payload: {'requestId': docRef.id, 'fromUid': fromUid},
    );
  }

  @override
  Future<List<FriendRequest>> getPendingRequests(String uid) async {
    // orderBy を外すことで複合インデックス不要にする
    // Dart 側で createdAt 降順にソートする
    final snapshot = await _firestore
        .collection('friend_requests')
        .where('toUid', isEqualTo: uid)
        .where('status', isEqualTo: FriendRequestStatus.pending.value)
        .get();

    final requests = snapshot.docs
        .map((doc) => _friendRequestFromFirestore(doc))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return requests;
  }

  @override
  Future<void> acceptFriendRequest(String requestId) async {
    final doc = await _firestore.collection('friend_requests').doc(requestId).get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final fromUid = data['fromUid'] as String;
    final toUid = data['toUid'] as String;

    final batch = _firestore.batch();

    batch.update(doc.reference, {
      'status': FriendRequestStatus.accepted.value,
    });

    final friendshipRef = _firestore.collection('friendships').doc();
    batch.set(friendshipRef, {
      'userIds': [fromUid, toUid],
      'createdAt': Timestamp.now(),
    });

    await batch.commit();

    await _createNotification(
      toUid: fromUid,
      type: 'friend_accepted',
      title: '友達になりました',
      body: '友達申請が承認されました。',
      payload: {'friendshipId': friendshipRef.id},
    );
  }

  @override
  Future<void> declineFriendRequest(String requestId) async {
    await _firestore.collection('friend_requests').doc(requestId).update({
      'status': FriendRequestStatus.declined.value,
    });
  }

  @override
  Future<List<Friend>> getFriends(String uid) async {
    final snapshot = await _firestore
        .collection('friendships')
        .where('userIds', arrayContains: uid)
        .get();

    return snapshot.docs.map((doc) => _friendFromFirestore(doc)).toList();
  }

  @override
  Future<void> deleteFriend(String friendshipId) async {
    await _firestore.collection('friendships').doc(friendshipId).delete();
  }

  @override
  Future<String> generateInviteToken(String fromUid) async {
    final random = Random.secure();
    final token = List.generate(32, (_) => random.nextInt(256))
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();

    await _firestore.collection('invite_tokens').doc(token).set({
      'fromUid': fromUid,
      'createdAt': Timestamp.now(),
      'expiresAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(hours: 72)),
      ),
      'used': false,
    });

    return token;
  }

  @override
  Future<String?> validateInviteToken(String token) async {
    final doc = await _firestore.collection('invite_tokens').doc(token).get();
    if (!doc.exists) return null;

    final data = doc.data()!;
    final used = data['used'] as bool;
    if (used) return null;

    final expiresAt = (data['expiresAt'] as Timestamp).toDate();
    if (DateTime.now().isAfter(expiresAt)) return null;

    return data['fromUid'] as String;
  }

  @override
  Future<void> invalidateInviteToken(String token) async {
    await _firestore.collection('invite_tokens').doc(token).update({
      'used': true,
    });
  }

  @override
  Future<AppUser?> getUserByUid(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    return AppUser(
      uid: uid,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String?,
      photoUrl: data['photoUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  @override
  Future<bool> areFriends(String uid1, String uid2) async {
    final snapshot = await _firestore
        .collection('friendships')
        .where('userIds', arrayContains: uid1)
        .get();

    return snapshot.docs.any((doc) {
      final userIds = List<String>.from(doc.data()['userIds'] as List);
      return userIds.contains(uid2);
    });
  }

  @override
  Future<bool> hasPendingRequest(String fromUid, String toUid) async {
    final snapshot = await _firestore
        .collection('friend_requests')
        .where('fromUid', isEqualTo: fromUid)
        .where('toUid', isEqualTo: toUid)
        .where('status', isEqualTo: FriendRequestStatus.pending.value)
        .get();

    if (snapshot.docs.isNotEmpty) return true;

    final reverseSnapshot = await _firestore
        .collection('friend_requests')
        .where('fromUid', isEqualTo: toUid)
        .where('toUid', isEqualTo: fromUid)
        .where('status', isEqualTo: FriendRequestStatus.pending.value)
        .get();

    return reverseSnapshot.docs.isNotEmpty;
  }

  FriendRequest _friendRequestFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, Object?>;
    return FriendRequest(
      requestId: doc.id,
      fromUid: data['fromUid'] as String,
      toUid: data['toUid'] as String,
      status: FriendRequestStatus.fromString(data['status'] as String),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Friend _friendFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, Object?>;
    return Friend(
      friendshipId: doc.id,
      userIds: List<String>.from(data['userIds'] as List),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
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
