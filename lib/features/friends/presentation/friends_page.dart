/*
====================================================
目的:
  - 友達一覧画面
  - 友達の表示・削除・QR追加・招待リンク生成

処理構造:
  - 友達一覧の取得・表示
  - QRコードでの友達追加へのナビゲーション
  - 招待リンクの生成・共有
  - 友達の削除
====================================================
*/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:beamer/beamer.dart';

import '../../../shared/models/friend_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/repositories/box_repository.dart';

/// 友達一覧画面
class FriendsPage extends ConsumerStatefulWidget {
  const FriendsPage({super.key});

  @override
  ConsumerState<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends ConsumerState<FriendsPage> {
  List<Friend> friends = [];
  Map<String, AppUser?> friendUsers = {};
  bool isLoading = true;
  String? errorMessage;
  int pendingRequestCount = 0;

  @override
  void initState() {
    super.initState();
    loadFriends();
    loadPendingRequestCount();
  }

  Future<void> loadPendingRequestCount() async {
    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) return;

      final friendsRepo = ref.read(friendsRepositoryProvider);
      final requests = await friendsRepo.getPendingRequests(userId);

      if (mounted) {
        setState(() => pendingRequestCount = requests.length);
      }
    } catch (_) {}
  }

  Future<void> loadFriends() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final userId = ref.read(currentUserIdProvider);
      if (userId == null) {
        setState(() {
          errorMessage = 'ユーザー情報が取得できません';
          isLoading = false;
        });
        return;
      }

      final getFriends = ref.read(getFriendsUseCaseProvider);
      final loadedFriends = await getFriends.execute(userId);

      final friendsRepo = ref.read(friendsRepositoryProvider);
      final users = <String, AppUser?>{};
      for (final friend in loadedFriends) {
        final otherUid = friend.getOtherUid(userId);
        users[otherUid] = await friendsRepo.getUserByUid(otherUid);
      }

      setState(() {
        friends = loadedFriends;
        friendUsers = users;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'データの取得に失敗しました: $e';
        isLoading = false;
      });
    }
  }

  Future<void> deleteFriend(Friend friend) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('友達を削除'),
        content: const Text('この友達を削除しますか？\n相手の友達一覧からも削除されます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final deleteFriendUseCase = ref.read(deleteFriendUseCaseProvider);
      await deleteFriendUseCase.execute(friend.friendshipId);
      await loadFriends();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('友達を削除しました'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('削除に失敗しました: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> generateInviteLink() async {
    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) return;

      final generateLink = ref.read(generateInviteLinkUseCaseProvider);
      final link = await generateLink.execute(userId);

      await Clipboard.setData(ClipboardData(text: link));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('招待リンクをコピーしました（72時間有効）'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('リンク生成に失敗しました: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('友達'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.beamToNamed('/'),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.person_add),
                tooltip: '友達申請一覧',
                onPressed: () {
                  context.beamToNamed('/friends/requests');
                  // 申請画面から戻ったら件数を再取得する（beamBack後）
                  Future.delayed(const Duration(milliseconds: 500), loadPendingRequestCount);
                },
              ),
              if (pendingRequestCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      pendingRequestCount > 9 ? '9+' : '$pendingRequestCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : _buildBody(),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'invite_link',
            onPressed: generateInviteLink,
            tooltip: '招待リンクを生成',
            child: const Icon(Icons.link),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'qr_add',
            onPressed: () => context.beamToNamed('/friends/my-qr'),
            tooltip: 'QRコードで追加',
            child: const Icon(Icons.qr_code),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (friends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'まだ友達がいません',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'QRコードや招待リンクで友達を追加しましょう',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final userId = ref.read(currentUserIdProvider) ?? '';

    return RefreshIndicator(
      onRefresh: loadFriends,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: friends.length,
        itemBuilder: (context, index) {
          final friend = friends[index];
          final otherUid = friend.getOtherUid(userId);
          final user = friendUsers[otherUid];
          return _buildFriendCard(friend, user);
        },
      ),
    );
  }

  Widget _buildFriendCard(Friend friend, AppUser? user) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
          child: user?.photoUrl == null ? const Icon(Icons.person) : null,
        ),
        title: Text(user?.displayName ?? user?.email ?? '不明なユーザー'),
        subtitle: user?.email != null ? Text(user!.email) : null,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => deleteFriend(friend),
        ),
      ),
    );
  }
}
