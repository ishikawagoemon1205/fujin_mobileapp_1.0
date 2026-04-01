/*
====================================================
目的:
  - 全封印箱の一覧を表示する画面
  - ステータス別(封印中/開封済み)にリスト表示

処理構造:
  - Firestoreから全箱データ取得
  - ステータス別にソート・表示
  - 箱詳細画面への遷移
  - リアルタイム更新対応
====================================================
*/

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:beamer/beamer.dart';
import 'package:intl/intl.dart';
import '../../../shared/models/box_model.dart';
import '../../../shared/models/group_model.dart';
import '../../../shared/repositories/box_repository.dart';
import '../../auth/presentation/auth_gate.dart';

/// 箱一覧画面
class BoxListPage extends ConsumerStatefulWidget {
  const BoxListPage({super.key});

  @override
  ConsumerState<BoxListPage> createState() => _BoxListPageState();
}

class _BoxListPageState extends ConsumerState<BoxListPage> {
  List<Box> boxes = [];
  List<Group> userGroups = [];
  bool isLoading = true;
  String? errorMessage;
  String? selectedFilter;

  @override
  void initState() {
    super.initState();
    loadBoxes();
    loadUserGroups();
  }

  Future<void> loadUserGroups() async {
    try {
      final getGroupsUseCase = ref.read(getGroupsUseCaseProvider);
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) return;

      final groups = await getGroupsUseCase.execute(userId);
      final joinedGroups =
          groups.where((g) => g.isJoinedMember(userId)).toList();
      if (mounted) {
        setState(() {
          userGroups = joinedGroups;
        });
      }
    } catch (_) {}
  }

  List<Box> get filteredBoxes {
    if (selectedFilter == null) return boxes;
    if (selectedFilter == 'personal') {
      return boxes.where((b) => b.groupId == null || b.groupId!.isEmpty).toList();
    }
    return boxes.where((b) => b.groupId == selectedFilter).toList();
  }

  Future<void> loadBoxes() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final getAllBoxesUseCase = ref.read(getAllBoxesUseCaseProvider);
      final userId = ref.read(currentUserIdProvider);

      if (userId == null) {
        setState(() {
          errorMessage = 'ユーザー情報が取得できません';
          isLoading = false;
        });
        return;
      }

      final allBoxes = await getAllBoxesUseCase.execute(userId);

      setState(() {
        boxes = allBoxes;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'データの取得に失敗しました: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (previous, next) {
      final prevUid = previous?.value?.uid;
      final nextUid = next.value?.uid;
      if (prevUid != nextUid) {
        setState(() {
          boxes = [];
          errorMessage = null;
          isLoading = true;
        });
        loadBoxes();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('封印一覧'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.beamToNamed('/');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadBoxes,
          ),
        ],
      ),
      body: buildBody(),
    );
  }

  Widget buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: loadBoxes,
                child: const Text('再読み込み'),
              ),
            ],
          ),
        ),
      );
    }

    if (boxes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'まだ封印された箱はありません',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.beamToNamed('/seal');
              },
              icon: const Icon(Icons.add),
              label: const Text('最初の箱を封印する'),
            ),
          ],
        ),
      );
    }

    final displayBoxes = filteredBoxes;
    final sealedBoxes = displayBoxes.where((box) => box.status == BoxStatus.sealed).toList();
    final openedBoxes = displayBoxes.where((box) => box.status == BoxStatus.opened).toList();
    final tamperedBoxes = displayBoxes.where((box) => box.status == BoxStatus.tampered).toList();

    return RefreshIndicator(
      onRefresh: loadBoxes,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          buildFilterChips(),
          const SizedBox(height: 12),
          buildSummaryCard(sealedBoxes.length, openedBoxes.length, tamperedBoxes.length),
          const SizedBox(height: 16),
          if (displayBoxes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  '該当する箱がありません',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ),
            ),
          if (sealedBoxes.isNotEmpty) ...[
            buildSectionHeader('封印中', sealedBoxes.length, Colors.green),
            ...sealedBoxes.map((box) => buildBoxCard(box)),
            const SizedBox(height: 16),
          ],
          if (openedBoxes.isNotEmpty) ...[
            buildSectionHeader('開封済み', openedBoxes.length, Colors.blue),
            ...openedBoxes.map((box) => buildBoxCard(box)),
            const SizedBox(height: 16),
          ],
          if (tamperedBoxes.isNotEmpty) ...[
            buildSectionHeader('破損検知', tamperedBoxes.length, Colors.red),
            ...tamperedBoxes.map((box) => buildBoxCard(box)),
          ],
        ],
      ),
    );
  }

  Widget buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterChip(
            label: const Text('すべて'),
            selected: selectedFilter == null,
            onSelected: (_) {
              setState(() {
                selectedFilter = null;
              });
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('個人'),
            selected: selectedFilter == 'personal',
            onSelected: (_) {
              setState(() {
                selectedFilter = 'personal';
              });
            },
          ),
          ...userGroups.map(
            (group) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: FilterChip(
                avatar: const Icon(Icons.group, size: 16),
                label: Text(group.name),
                selected: selectedFilter == group.groupId,
                onSelected: (_) {
                  setState(() {
                    selectedFilter = group.groupId;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSummaryCard(int sealed, int opened, int tampered) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            buildSummaryItem('封印中', sealed, Colors.green),
            Container(
              width: 1,
              height: 40,
              color: Colors.grey[300],
            ),
            buildSummaryItem('開封済み', opened, Colors.blue),
            if (tampered > 0) ...[
              Container(
                width: 1,
                height: 40,
                color: Colors.grey[300],
              ),
              buildSummaryItem('破損', tampered, Colors.red),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildSummaryItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[700],
              ),
        ),
      ],
    );
  }

  Widget buildSectionHeader(String title, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildBoxCard(Box box) {
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');
    final statusColor = getStatusColor(box.status);
    final statusLabel = getStatusLabel(box.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: () {
          context.beamToNamed('/box/${box.boxId}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          getStatusIcon(box.status),
                          size: 16,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'ID: ${box.boxId}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontFamily: 'monospace',
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (box.groupId != null && box.groupId!.isNotEmpty) ...[
                _buildGroupBadge(box.groupId!),
                const SizedBox(height: 8),
              ],
              if (box.storageLocation.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(
                      Icons.place,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        box.storageLocation,
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              if (box.memo.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(
                      Icons.note,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        box.memo,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[700],
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              Row(
                children: [
                  Icon(
                    Icons.qr_code,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${box.qrFaceCount}面',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.photo,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${box.photos.length}枚',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const Spacer(),
                  Text(
                    dateFormat.format(box.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color getStatusColor(BoxStatus status) {
    switch (status) {
      case BoxStatus.sealed:
        return Colors.green;
      case BoxStatus.opened:
        return Colors.blue;
      case BoxStatus.tampered:
        return Colors.red;
    }
  }

  String getStatusLabel(BoxStatus status) {
    switch (status) {
      case BoxStatus.sealed:
        return '封印中';
      case BoxStatus.opened:
        return '開封済み';
      case BoxStatus.tampered:
        return '破損';
    }
  }

  IconData getStatusIcon(BoxStatus status) {
    switch (status) {
      case BoxStatus.sealed:
        return Icons.lock;
      case BoxStatus.opened:
        return Icons.lock_open;
      case BoxStatus.tampered:
        return Icons.warning;
    }
  }

  Widget _buildGroupBadge(String groupId) {
    final groupName = userGroups
        .where((g) => g.groupId == groupId)
        .map((g) => g.name)
        .firstOrNull;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.indigo.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.indigo.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.group, size: 14, color: Colors.indigo[400]),
          const SizedBox(width: 4),
          Text(
            groupName ?? 'グループ',
            style: TextStyle(
              color: Colors.indigo[700],
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
