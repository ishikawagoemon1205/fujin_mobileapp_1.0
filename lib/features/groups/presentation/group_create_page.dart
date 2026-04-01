/*
====================================================
目的:
  - グループ作成画面
  - グループ名入力と友達選択によるグループ作成

処理構造:
  - 友達一覧の取得
  - メンバー選択UI
  - バリデーション（名前・人数制限）
  - グループ作成処理
====================================================
*/

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:beamer/beamer.dart';

import '../../../shared/models/friend_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/repositories/box_repository.dart';
import '../domain/usecases/create_group_usecase.dart';

/// グループ作成画面
class GroupCreatePage extends ConsumerStatefulWidget {
  const GroupCreatePage({super.key});

  @override
  ConsumerState<GroupCreatePage> createState() => _GroupCreatePageState();
}

class _GroupCreatePageState extends ConsumerState<GroupCreatePage> {
  final TextEditingController nameController = TextEditingController();
  List<Friend> friends = [];
  Map<String, AppUser?> friendUsers = {};
  Set<String> selectedUids = {};
  bool isLoading = true;
  bool isCreating = false;

  @override
  void initState() {
    super.initState();
    loadFriends();
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> loadFriends() async {
    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) return;

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
      setState(() => isLoading = false);
    }
  }

  Future<void> createGroup() async {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('グループ名を入力してください'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (selectedUids.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('メンバーを1人以上選択してください'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => isCreating = true);

    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) return;

      final createGroupUseCase = ref.read(createGroupUseCaseProvider);
      await createGroupUseCase.execute(
        CreateGroupParams(
          name: name,
          ownerUid: userId,
          inviteeUids: selectedUids.toList(),
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('「$name」を作成しました'),
            backgroundColor: Colors.green,
          ),
        );
        context.beamToNamed('/groups');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('作成に失敗しました: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.read(currentUserIdProvider) ?? '';
    final maxInvitees = 4;
    final remainingSlots = maxInvitees - selectedUids.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('グループ作成'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.beamToNamed('/groups'),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'グループ名',
                      hintText: '例：家族の荷物管理',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.group),
                    ),
                    maxLength: 50,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text(
                        'メンバーを選択',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Spacer(),
                      Text(
                        '${selectedUids.length}/$maxInvitees 人選択中',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: remainingSlots <= 0 ? Colors.red : Colors.grey,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '自分を含めて最大5人まで',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  if (friends.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 8),
                              Text(
                                '友達がいません',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'まず友達を追加してからグループを作成してください',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ...friends.map((friend) {
                      final otherUid = friend.getOtherUid(userId);
                      final user = friendUsers[otherUid];
                      final isSelected = selectedUids.contains(otherUid);
                      final canSelect = isSelected || remainingSlots > 0;

                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: canSelect
                            ? (checked) {
                                setState(() {
                                  if (checked == true) {
                                    selectedUids.add(otherUid);
                                  } else {
                                    selectedUids.remove(otherUid);
                                  }
                                });
                              }
                            : null,
                        secondary: CircleAvatar(
                          backgroundImage:
                              user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
                          child: user?.photoUrl == null ? const Icon(Icons.person) : null,
                        ),
                        title: Text(user?.displayName ?? user?.email ?? '不明なユーザー'),
                        subtitle: user?.email != null ? Text(user!.email) : null,
                      );
                    }),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: isCreating ? null : createGroup,
                      icon: isCreating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.group_add),
                      label: Text(isCreating ? '作成中...' : 'グループを作成'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
