/*
====================================================
目的:
  - 友達申請一覧画面
  - 受信した友達申請の承認・拒否

処理構造:
  - 未承認申請の取得・表示
  - 承認・拒否操作
====================================================
*/

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:beamer/beamer.dart';

import '../../../shared/models/friend_request_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/repositories/box_repository.dart';

/// 友達申請一覧画面
class FriendRequestsPage extends ConsumerStatefulWidget {
  const FriendRequestsPage({super.key});

  @override
  ConsumerState<FriendRequestsPage> createState() => _FriendRequestsPageState();
}

class _FriendRequestsPageState extends ConsumerState<FriendRequestsPage> {
  List<FriendRequest> requests = [];
  Map<String, AppUser?> requestUsers = {};
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadRequests();
  }

  Future<void> loadRequests() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final userId = ref.read(currentUserIdProvider);
      if (userId == null) return;

      final friendsRepo = ref.read(friendsRepositoryProvider);
      final pendingRequests = await friendsRepo.getPendingRequests(userId);

      final users = <String, AppUser?>{};
      for (final request in pendingRequests) {
        users[request.fromUid] = await friendsRepo.getUserByUid(request.fromUid);
      }

      setState(() {
        requests = pendingRequests;
        requestUsers = users;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'データの取得に失敗しました: $e';
      });
    }
  }

  Future<void> acceptRequest(FriendRequest request) async {
    try {
      final accept = ref.read(acceptFriendRequestUseCaseProvider);
      await accept.execute(request.requestId);
      await loadRequests();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('友達申請を承認しました'), backgroundColor: Colors.green),
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

  Future<void> declineRequest(FriendRequest request) async {
    try {
      final decline = ref.read(declineFriendRequestUseCaseProvider);
      await decline.execute(request.requestId);
      await loadRequests();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('友達申請を拒否しました')),
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
        title: const Text('友達申請'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.beamToNamed('/friends'),
        ),
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
                          onPressed: loadRequests,
                          child: const Text('再試行'),
                        ),
                      ],
                    ),
                  ),
                )
              : requests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.mark_email_unread_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        '友達申請はありません',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadRequests,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      final request = requests[index];
                      final user = requestUsers[request.fromUid];
                      return _buildRequestCard(request, user);
                    },
                  ),
                ),
    );
  }

  Widget _buildRequestCard(FriendRequest request, AppUser? user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundImage: user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
              child: user?.photoUrl == null ? const Icon(Icons.person) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.displayName ?? user?.email ?? '不明なユーザー',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (user?.email != null)
                    Text(user!.email, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            TextButton(
              onPressed: () => declineRequest(request),
              child: const Text('拒否'),
            ),
            const SizedBox(width: 4),
            FilledButton(
              onPressed: () => acceptRequest(request),
              child: const Text('承認'),
            ),
          ],
        ),
      ),
    );
  }
}
