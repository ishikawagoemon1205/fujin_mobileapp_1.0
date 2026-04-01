/*
====================================================
目的:
  - 通知一覧画面
  - アプリ内通知の表示と管理

処理構造:
  - 通知一覧の取得・表示
  - 既読操作
  - 通知タップ時の遷移
====================================================
*/

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:beamer/beamer.dart';

import '../../../shared/models/notification_model.dart';
import '../../../shared/repositories/box_repository.dart';

/// 通知一覧画面
class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  List<AppNotification> notifications = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final userId = ref.read(currentUserIdProvider);
      if (userId == null) return;

      final getNotifications = ref.read(getNotificationsUseCaseProvider);
      final loaded = await getNotifications.execute(userId);

      setState(() {
        notifications = loaded;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'データの取得に失敗しました: $e';
      });
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) return;

      final markAll = ref.read(markAllAsReadUseCaseProvider);
      await markAll.execute(userId);
      await loadNotifications();
    } catch (_) {}
  }

  Future<void> onNotificationTap(AppNotification notification) async {
    if (!notification.isRead) {
      final markRead = ref.read(markAsReadUseCaseProvider);
      await markRead.execute(notification.notificationId);
    }

    if (!mounted) return;

    switch (notification.type) {
      case NotificationType.friendRequested:
        context.beamToNamed('/friends/requests');
      case NotificationType.friendAccepted:
        context.beamToNamed('/friends');
      case NotificationType.groupInvited:
        context.beamToNamed('/groups');
      case NotificationType.groupMemberJoined:
      case NotificationType.groupMemberLeft:
        final groupId = notification.payload['groupId'];
        if (groupId != null) {
          context.beamToNamed('/groups/$groupId');
        }
      case NotificationType.boxSealed:
      case NotificationType.boxOpened:
      case NotificationType.boxTampered:
      case NotificationType.boxUnsealed:
        final boxId = notification.payload['boxId'];
        if (boxId != null) {
          context.beamToNamed('/box/$boxId');
        }
    }
  }

  IconData _iconForType(NotificationType type) {
    switch (type) {
      case NotificationType.friendRequested:
        return Icons.person_add;
      case NotificationType.friendAccepted:
        return Icons.people;
      case NotificationType.groupInvited:
        return Icons.group_add;
      case NotificationType.groupMemberJoined:
        return Icons.group;
      case NotificationType.groupMemberLeft:
        return Icons.group_remove;
      case NotificationType.boxSealed:
        return Icons.lock;
      case NotificationType.boxOpened:
        return Icons.lock_open;
      case NotificationType.boxTampered:
        return Icons.warning;
      case NotificationType.boxUnsealed:
        return Icons.lock_open;
    }
  }

  Color _colorForType(NotificationType type) {
    switch (type) {
      case NotificationType.friendRequested:
      case NotificationType.friendAccepted:
        return Colors.blue;
      case NotificationType.groupInvited:
      case NotificationType.groupMemberJoined:
        return Colors.green;
      case NotificationType.groupMemberLeft:
        return Colors.orange;
      case NotificationType.boxSealed:
        return Colors.indigo;
      case NotificationType.boxOpened:
        return Colors.teal;
      case NotificationType.boxTampered:
      case NotificationType.boxUnsealed:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = notifications.any((n) => !n.isRead);

    return Scaffold(
      appBar: AppBar(
        title: const Text('通知'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.beamToNamed('/'),
        ),
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: markAllAsRead,
              child: const Text('すべて既読'),
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: loadNotifications,
                          child: const Text('再試行'),
                        ),
                      ],
                    ),
                  ),
                )
              : notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        '通知はありません',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadNotifications,
                  child: ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return _buildNotificationTile(notification);
                    },
                  ),
                ),
    );
  }

  Widget _buildNotificationTile(AppNotification notification) {
    final isRead = notification.isRead;
    final timeDiff = DateTime.now().difference(notification.createdAt);
    final timeText = _formatTimeDiff(timeDiff);

    return ListTile(
      tileColor: isRead ? null : Theme.of(context).colorScheme.primaryContainer.withAlpha(50),
      leading: CircleAvatar(
        backgroundColor: _colorForType(notification.type).withAlpha(30),
        child: Icon(
          _iconForType(notification.type),
          color: _colorForType(notification.type),
        ),
      ),
      title: Text(
        notification.title,
        style: TextStyle(
          fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(notification.body, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(
            timeText,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey),
          ),
        ],
      ),
      isThreeLine: true,
      onTap: () => onNotificationTap(notification),
    );
  }

  String _formatTimeDiff(Duration diff) {
    if (diff.inMinutes < 1) return 'たった今';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分前';
    if (diff.inHours < 24) return '${diff.inHours}時間前';
    if (diff.inDays < 7) return '${diff.inDays}日前';
    return '${diff.inDays ~/ 7}週間前';
  }
}
