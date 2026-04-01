/*
====================================================
目的:
  - 招待リンクからアプリが起動された際の友達申請確認画面

処理構造:
  - 招待トークンの検証
  - 送信者情報の表示
  - 友達申請送信
  - トークン無効化
====================================================
*/

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:beamer/beamer.dart';

import '../../../shared/models/user_model.dart';
import '../../../shared/repositories/box_repository.dart';

/// 招待リンクからの友達申請確認画面
class InviteAcceptPage extends ConsumerStatefulWidget {
  final String fromUid;
  final String token;

  const InviteAcceptPage({
    super.key,
    required this.fromUid,
    required this.token,
  });

  @override
  ConsumerState<InviteAcceptPage> createState() => _InviteAcceptPageState();
}

class _InviteAcceptPageState extends ConsumerState<InviteAcceptPage> {
  bool isLoading = true;
  bool isProcessing = false;
  bool isTokenValid = false;
  AppUser? senderUser;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    validateInvite();
  }

  Future<void> validateInvite() async {
    try {
      final friendsRepo = ref.read(friendsRepositoryProvider);

      final validFromUid = await friendsRepo.validateInviteToken(widget.token);
      if (validFromUid == null || validFromUid != widget.fromUid) {
        setState(() {
          isLoading = false;
          isTokenValid = false;
          errorMessage = '招待リンクが無効です（期限切れまたは使用済み）';
        });
        return;
      }

      final myUid = ref.read(currentUserIdProvider);
      if (myUid == widget.fromUid) {
        setState(() {
          isLoading = false;
          isTokenValid = false;
          errorMessage = '自分自身の招待リンクです';
        });
        return;
      }

      final user = await friendsRepo.getUserByUid(widget.fromUid);

      setState(() {
        isLoading = false;
        isTokenValid = true;
        senderUser = user;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        isTokenValid = false;
        errorMessage = '招待リンクの検証に失敗しました: $e';
      });
    }
  }

  Future<void> sendRequest() async {
    setState(() => isProcessing = true);

    try {
      final myUid = ref.read(currentUserIdProvider);
      if (myUid == null) {
        setState(() {
          isProcessing = false;
          errorMessage = 'ログインが必要です';
        });
        return;
      }

      final sendFriendRequest = ref.read(sendFriendRequestUseCaseProvider);
      await sendFriendRequest.execute(myUid, widget.fromUid);

      final friendsRepo = ref.read(friendsRepositoryProvider);
      await friendsRepo.invalidateInviteToken(widget.token);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('友達申請を送信しました'),
            backgroundColor: Colors.green,
          ),
        );
        context.beamToNamed('/');
      }
    } catch (e) {
      setState(() {
        isProcessing = false;
        errorMessage = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('友達招待'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.beamToNamed('/'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : isTokenValid
                ? _buildValidContent()
                : _buildInvalidContent(),
      ),
    );
  }

  Widget _buildValidContent() {
    final senderName = senderUser?.displayName
        ?? senderUser?.email
        ?? '不明なユーザー';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_add, size: 64, color: Colors.indigo),
          const SizedBox(height: 24),
          Text(
            '友達申請を送りますか？',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: senderUser?.photoUrl != null
                        ? NetworkImage(senderUser!.photoUrl!)
                        : null,
                    child: senderUser?.photoUrl == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    senderName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isProcessing ? null : sendRequest,
              icon: isProcessing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send),
              label: Text(isProcessing ? '送信中...' : '友達申請を送る'),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: isProcessing ? null : () => context.beamToNamed('/'),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }

  Widget _buildInvalidContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.link_off, size: 64, color: Colors.grey),
          const SizedBox(height: 24),
          Text(
            '無効な招待リンク',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            errorMessage ?? '招待リンクが無効です',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () => context.beamToNamed('/'),
            child: const Text('ホームに戻る'),
          ),
        ],
      ),
    );
  }
}
