/*
====================================================
目的:
  - 通知機能の Repository インターフェース定義

処理構造:
  - 通知の取得・既読・削除のメソッド定義
====================================================
*/

import '../../../../shared/models/notification_model.dart';

/// 通知 Repository のインターフェース
///
/// domain 層は Firebase に依存しない純粋な Dart コード
abstract class NotificationsRepository {
  /// 指定ユーザーの全通知を取得する
  ///
  /// [uid] 対象ユーザーのUID
  ///
  /// Returns 通知リスト（新しい順）
  Future<List<AppNotification>> getNotifications(String uid);

  /// 指定ユーザーの未読通知数を取得する
  ///
  /// [uid] 対象ユーザーのUID
  ///
  /// Returns 未読件数
  Future<int> getUnreadCount(String uid);

  /// 通知を既読にする
  ///
  /// [notificationId] 対象通知のID
  Future<void> markAsRead(String notificationId);

  /// 全通知を既読にする
  ///
  /// [uid] 対象ユーザーのUID
  Future<void> markAllAsRead(String uid);

  /// 通知を削除する
  ///
  /// [notificationId] 対象通知のID
  Future<void> deleteNotification(String notificationId);
}
