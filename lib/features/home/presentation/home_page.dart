/*
====================================================
目的:
  - アプリケーションのホーム画面
  - プロフィール表示・メイン機能・友達/グループ/通知ナビ

処理構造:
  - プロフィール情報の表示
  - 封印・確認・一覧への遷移
  - 友達・グループ・通知画面への遷移
  - 通知バッジ表示
  - ログアウト処理
====================================================
*/

import 'package:flutter/material.dart';
import 'package:beamer/beamer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/repositories/box_repository.dart';

/// ホーム画面
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int unreadNotificationCount = 0;
  late BeamerDelegate _beamerDelegate;

  @override
  void initState() {
    super.initState();
    loadUnreadCount();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Beamer のルート変化を監視し、/notifications から戻ったときに未読数を再取得する
    _beamerDelegate = Beamer.of(context);
    _beamerDelegate.addListener(_onRouteChanged);
  }

  @override
  void dispose() {
    _beamerDelegate.removeListener(_onRouteChanged);
    super.dispose();
  }

  void _onRouteChanged() {
    final uri = _beamerDelegate.currentBeamLocation.state.routeInformation.uri.toString();
    // ホーム画面（/）に戻ったときに未読数を再取得する
    if (uri == '/') {
      loadUnreadCount();
    }
  }

  Future<void> loadUnreadCount() async {
    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) return;

      final getUnread = ref.read(getUnreadCountUseCaseProvider);
      final count = await getUnread.execute(userId);

      if (mounted) {
        setState(() => unreadNotificationCount = count);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('封神'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                tooltip: '通知',
                onPressed: () => context.beamToNamed('/notifications'),
              ),
              if (unreadNotificationCount > 0)
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
                      unreadNotificationCount > 9 ? '9+' : '$unreadNotificationCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'ログアウト',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('ログアウト'),
                  content: const Text('ログアウトしますか？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('キャンセル'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('ログアウト'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                final signOut = ref.read(signOutUseCaseProvider);
                await signOut.execute();
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProfileCard(context, profileAsync),
            const SizedBox(height: 24),
            Text(
              'メイン機能',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildFeatureCard(
              context,
              icon: Icons.lock,
              title: '新しく封印する',
              subtitle: '箱や封筒にQRシールを貼って内容物を記録',
              color: Colors.indigo,
              onTap: () => context.beamToNamed('/seal'),
            ),
            const SizedBox(height: 12),
            _buildFeatureCard(
              context,
              icon: Icons.search,
              title: '中身を確認する',
              subtitle: 'QRコードをスキャンして箱の中身を確認',
              color: Colors.blue,
              onTap: () => context.beamToNamed('/verify'),
            ),
            const SizedBox(height: 12),
            _buildFeatureCard(
              context,
              icon: Icons.list_alt,
              title: '封印一覧',
              subtitle: '封印した箱を一覧で確認',
              color: Colors.amber,
              onTap: () => context.beamToNamed('/box-list'),
            ),
            const SizedBox(height: 24),
            Text(
              'つながり',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildSmallCard(
                    context,
                    icon: Icons.people,
                    title: '友達',
                    color: Colors.teal,
                    onTap: () => context.beamToNamed('/friends'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSmallCard(
                    context,
                    icon: Icons.groups,
                    title: 'グループ',
                    color: Colors.deepPurple,
                    onTap: () => context.beamToNamed('/groups'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, AsyncValue<Map<String, String?>> profileAsync) {
    final profile = profileAsync.valueOrNull ?? {};
    final displayName = profile['displayName'] ?? profile['email'] ?? 'ユーザー';
    final email = profile['email'];
    final photoUrl = profile['photoUrl'];

    return Card(
      child: InkWell(
        onTap: () {
          context.beamToNamed('/profile/edit');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                    ? NetworkImage(photoUrl)
                    : null,
                child: photoUrl == null || photoUrl.isEmpty
                    ? const Icon(Icons.person, size: 28)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (email != null && email.isNotEmpty)
                      Text(
                        email,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                  ],
                ),
              ),
              Icon(Icons.edit, size: 18, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
