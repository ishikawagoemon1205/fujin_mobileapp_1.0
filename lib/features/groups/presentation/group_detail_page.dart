/*
====================================================
目的:
  - グループ詳細画面
  - メンバー管理・グループ設定

処理構造:
  - グループ情報の取得・表示
  - メンバー一覧表示
  - メンバー追加（招待）
  - メンバー削除・グループ脱退・解散
  - グループ名変更
====================================================
*/

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:beamer/beamer.dart';

import '../../../shared/models/group_model.dart';
import '../../../shared/models/friend_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/repositories/box_repository.dart';

/// グループ詳細画面
class GroupDetailPage extends ConsumerStatefulWidget {
  final String groupId;

  const GroupDetailPage({super.key, required this.groupId});

  @override
  ConsumerState<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends ConsumerState<GroupDetailPage> {
  Group? group;
  Map<String, AppUser?> memberUsers = {};
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadGroup();
  }

  Future<void> loadGroup() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final groupsRepo = ref.read(groupsRepositoryProvider);
      final loadedGroup = await groupsRepo.getGroup(widget.groupId);

      if (loadedGroup == null) {
        setState(() {
          errorMessage = 'グループが見つかりません';
          isLoading = false;
        });
        return;
      }

      final friendsRepo = ref.read(friendsRepositoryProvider);
      final users = <String, AppUser?>{};
      for (final member in loadedGroup.members) {
        users[member.uid] = await friendsRepo.getUserByUid(member.uid);
      }

      setState(() {
        group = loadedGroup;
        memberUsers = users;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'データの取得に失敗しました: $e';
        isLoading = false;
      });
    }
  }

  Future<void> editGroupName() async {
    if (group == null) return;

    final controller = TextEditingController(text: group!.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('グループ名を変更'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'グループ名',
            border: OutlineInputBorder(),
          ),
          maxLength: 50,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('変更'),
          ),
        ],
      ),
    );

    if (newName == null || newName.trim().isEmpty) return;

    try {
      final updateName = ref.read(updateGroupNameUseCaseProvider);
      await updateName.execute(widget.groupId, newName.trim());
      await loadGroup();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('グループ名を変更しました'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('変更に失敗しました: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> inviteFriend() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null || group == null) return;

    final getFriends = ref.read(getFriendsUseCaseProvider);
    final friends = await getFriends.execute(userId);

    final friendsRepo = ref.read(friendsRepositoryProvider);
    final existingMemberUids = group!.members.map((m) => m.uid).toSet();

    final availableFriends = <Friend>[];
    final availableUsers = <String, AppUser?>{};

    for (final friend in friends) {
      final otherUid = friend.getOtherUid(userId);
      if (!existingMemberUids.contains(otherUid)) {
        availableFriends.add(friend);
        availableUsers[otherUid] = await friendsRepo.getUserByUid(otherUid);
      }
    }

    if (!mounted) return;

    if (availableFriends.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('招待できる友達がいません')),
      );
      return;
    }

    if (group!.members.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('グループは最大5人までです'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final selectedUid = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('友達を招待'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableFriends.length,
            itemBuilder: (context, index) {
              final friend = availableFriends[index];
              final otherUid = friend.getOtherUid(userId);
              final user = availableUsers[otherUid];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage:
                      user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
                  child: user?.photoUrl == null ? const Icon(Icons.person) : null,
                ),
                title: Text(user?.displayName ?? user?.email ?? '不明なユーザー'),
                onTap: () => Navigator.pop(context, otherUid),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );

    if (selectedUid == null) return;

    try {
      final inviteMember = ref.read(inviteMemberUseCaseProvider);
      await inviteMember.execute(widget.groupId, selectedUid);
      await loadGroup();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('招待を送信しました'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('招待に失敗しました: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> removeMember(GroupMember member) async {
    final user = memberUsers[member.uid];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('メンバーを削除'),
        content: Text(
          '${user?.displayName ?? "このユーザー"}をグループから削除しますか？',
        ),
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
      final remove = ref.read(removeMemberUseCaseProvider);
      await remove.execute(widget.groupId, member.uid);
      await loadGroup();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('メンバーを削除しました'), backgroundColor: Colors.green),
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

  Future<void> leaveGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('グループを脱退'),
        content: const Text('このグループから脱退しますか？\nグループ内の共有荷物にはアクセスできなくなります。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('脱退'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) return;

      final leave = ref.read(leaveGroupUseCaseProvider);
      await leave.execute(widget.groupId, userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('グループを脱退しました'), backgroundColor: Colors.green),
        );
        context.beamToNamed('/groups');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('脱退に失敗しました: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> disbandGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('グループを解散'),
        content: const Text(
          'このグループを解散しますか？\nこの操作は取り消せません。\nグループ内の荷物は個人の荷物に変換されます。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('解散'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final disband = ref.read(disbandGroupUseCaseProvider);
      await disband.execute(widget.groupId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('グループを解散しました'), backgroundColor: Colors.green),
        );
        context.beamToNamed('/groups');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('解散に失敗しました: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.read(currentUserIdProvider) ?? '';
    final isOwner = group?.isOwner(userId) ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(group?.name ?? 'グループ'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.beamToNamed('/groups'),
        ),
        actions: [
          if (isOwner)
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit_name':
                    editGroupName();
                  case 'invite':
                    inviteFriend();
                  case 'disband':
                    disbandGroup();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit_name',
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('グループ名を変更'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'invite',
                  child: ListTile(
                    leading: Icon(Icons.person_add),
                    title: Text('メンバーを招待'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'disband',
                  child: ListTile(
                    leading: Icon(Icons.delete_forever, color: Colors.red),
                    title: Text('グループを解散', style: TextStyle(color: Colors.red)),
                    contentPadding: EdgeInsets.zero,
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
              : _buildBody(userId, isOwner),
    );
  }

  Widget _buildBody(String userId, bool isOwner) {
    if (group == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: Icon(
                        Icons.group,
                        size: 32,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group!.name,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'メンバー ${group!.joinedMembers.length}人 / 最大5人',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'メンバー',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...group!.members.map((member) => _buildMemberTile(member, userId, isOwner)),
        const SizedBox(height: 24),
        if (!isOwner)
          OutlinedButton.icon(
            onPressed: leaveGroup,
            icon: const Icon(Icons.exit_to_app, color: Colors.red),
            label: const Text('グループを脱退', style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
          ),
      ],
    );
  }

  Widget _buildMemberTile(GroupMember member, String userId, bool isOwner) {
    final user = memberUsers[member.uid];
    final isCurrentUser = member.uid == userId;
    final isInvited = member.status == GroupMemberStatus.invited;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
          child: user?.photoUrl == null ? const Icon(Icons.person) : null,
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                user?.displayName ?? user?.email ?? '不明なユーザー',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isCurrentUser) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'あなた',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ],
            if (member.role == GroupRole.owner) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'オーナー',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.amber[900]),
                ),
              ),
            ],
          ],
        ),
        subtitle: isInvited
            ? const Text('招待中', style: TextStyle(color: Colors.orange))
            : null,
        trailing: isOwner && !isCurrentUser
            ? IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                onPressed: () => removeMember(member),
              )
            : null,
      ),
    );
  }
}
