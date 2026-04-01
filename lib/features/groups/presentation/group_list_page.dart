/*
====================================================
目的:
  - グループ一覧画面
  - 所属グループの表示・新規作成へのナビゲーション

処理構造:
  - グループ一覧の取得・表示
  - 招待中グループの承認・拒否
  - グループ作成画面への遷移
====================================================
*/

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:beamer/beamer.dart';

import '../../../shared/models/group_model.dart';
import '../../../shared/repositories/box_repository.dart';

/// グループ一覧画面
class GroupListPage extends ConsumerStatefulWidget {
  const GroupListPage({super.key});

  @override
  ConsumerState<GroupListPage> createState() => _GroupListPageState();
}

class _GroupListPageState extends ConsumerState<GroupListPage> {
  List<Group> groups = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadGroups();
  }

  Future<void> loadGroups() async {
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

      final getGroups = ref.read(getGroupsUseCaseProvider);
      final loadedGroups = await getGroups.execute(userId);

      setState(() {
        groups = loadedGroups;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'データの取得に失敗しました: $e';
        isLoading = false;
      });
    }
  }

  Future<void> acceptInvite(Group group) async {
    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) return;

      final accept = ref.read(acceptGroupInviteUseCaseProvider);
      await accept.execute(group.groupId, userId);
      await loadGroups();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('「${group.name}」に参加しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> declineInvite(Group group) async {
    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) return;

      final decline = ref.read(declineGroupInviteUseCaseProvider);
      await decline.execute(group.groupId, userId);
      await loadGroups();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('招待を辞退しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('グループ'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.beamToNamed('/'),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.beamToNamed('/groups/create'),
        tooltip: 'グループを作成',
        child: const Icon(Icons.group_add),
      ),
    );
  }

  Widget _buildBody() {
    if (groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'グループがありません',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              '友達とグループを作成して荷物を共有しましょう',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final userId = ref.read(currentUserIdProvider) ?? '';

    final invitedGroups = groups.where((g) {
      final member = g.members.where((m) => m.uid == userId).firstOrNull;
      return member != null && member.status == GroupMemberStatus.invited;
    }).toList();

    final joinedGroups = groups.where((g) => g.isJoinedMember(userId)).toList();

    return RefreshIndicator(
      onRefresh: loadGroups,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (invitedGroups.isNotEmpty) ...[
            Text(
              '招待されています',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...invitedGroups.map(_buildInviteCard),
            const SizedBox(height: 24),
          ],
          if (joinedGroups.isNotEmpty) ...[
            Text(
              '参加中のグループ',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...joinedGroups.map(_buildGroupCard),
          ],
          if (invitedGroups.isEmpty && joinedGroups.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 48),
                child: Text(
                  'グループがありません',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInviteCard(Group group) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.group, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    'メンバー ${group.joinedMembers.length}人',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => declineInvite(group),
              child: const Text('辞退'),
            ),
            const SizedBox(width: 4),
            FilledButton(
              onPressed: () => acceptInvite(group),
              child: const Text('参加'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupCard(Group group) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(Icons.group, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(group.name),
        subtitle: Text('メンバー ${group.joinedMembers.length}人'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.beamToNamed('/groups/${group.groupId}'),
      ),
    );
  }
}
