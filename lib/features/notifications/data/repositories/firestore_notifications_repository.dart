/*
====================================================
目的:
  - 通知機能の Firestore Repository 実装

処理構造:
  - 通知の取得
  - 既読更新
  - 通知の削除
====================================================
*/

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../shared/models/notification_model.dart';
import '../../domain/repositories/notifications_repository.dart';

/// Firestore を使った通知 Repository 実装
class FirestoreNotificationsRepository implements NotificationsRepository {
  final FirebaseFirestore _firestore;

  FirestoreNotificationsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<AppNotification>> getNotifications(String uid) async {
    // orderBy を外すことで toUid + createdAt の複合インデックス不要にする
    // Dart 側で createdAt 降順にソートする
    final snapshot = await _firestore
        .collection('notifications')
        .where('toUid', isEqualTo: uid)
        .get();

    final notifications = snapshot.docs
        .map((doc) => _fromFirestore(doc.id, doc.data()))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return notifications;
  }

  @override
  Future<int> getUnreadCount(String uid) async {
    final snapshot = await _firestore
        .collection('notifications')
        .where('toUid', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .get();

    return snapshot.size;
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }

  @override
  Future<void> markAllAsRead(String uid) async {
    final snapshot = await _firestore
        .collection('notifications')
        .where('toUid', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).delete();
  }

  AppNotification _fromFirestore(String notificationId, Map<String, Object?> data) {
    final payloadRaw = data['payload'] as Map<String, Object?>?;
    final payload = payloadRaw?.map((key, value) => MapEntry(key, value?.toString() ?? ''));

    return AppNotification(
      notificationId: notificationId,
      toUid: data['toUid'] as String,
      type: NotificationType.fromString(data['type'] as String),
      title: data['title'] as String,
      body: data['body'] as String,
      payload: payload ?? {},
      isRead: data['isRead'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}
