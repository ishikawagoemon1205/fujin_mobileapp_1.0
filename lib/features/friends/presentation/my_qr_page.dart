/*
====================================================
目的:
  - マイQRコード表示画面
  - 自分のユーザーQRコードを表示し、相手にスキャンしてもらう

処理構造:
  - ユーザーQRコードの生成・表示
  - QRスキャン機能（相手のQR読み取り用）
====================================================
*/

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:beamer/beamer.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/utils/qr_utils.dart';
import '../../../shared/repositories/box_repository.dart';
import '../../../shared/widgets/qr_scan_page.dart';
import '../domain/usecases/send_friend_request_usecase.dart';

/// マイQRコード画面
class MyQrPage extends ConsumerStatefulWidget {
  const MyQrPage({super.key});

  @override
  ConsumerState<MyQrPage> createState() => _MyQrPageState();
}

class _MyQrPageState extends ConsumerState<MyQrPage> {
  bool isShowingMyQr = true;

  Future<void> handleQrScanned(String qrCode) async {
    if (!QRCodeUtils.isUserQR(qrCode)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ユーザーQRコードではありません'), backgroundColor: Colors.orange),
        );
      }
      return;
    }

    final targetUid = QRCodeUtils.extractUidFromUserQR(qrCode);
    if (targetUid == null) return;

    final myUid = ref.read(currentUserIdProvider);
    if (myUid == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('友達申請'),
        content: const Text('このユーザーに友達申請を送りますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('送る'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final sendRequest = ref.read(sendFriendRequestUseCaseProvider);
      await sendRequest.execute(myUid, targetUid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('友達申請を送りました'), backgroundColor: Colors.green),
        );
        setState(() => isShowingMyQr = true);
      }
    } on FriendRequestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.orange),
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
    final userId = ref.watch(currentUserIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isShowingMyQr ? 'マイQRコード' : '友達のQRをスキャン'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.beamToNamed('/friends'),
        ),
      ),
      body: isShowingMyQr ? _buildMyQr(userId) : _buildScanner(),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton.icon(
              onPressed: () => setState(() => isShowingMyQr = true),
              icon: const Icon(Icons.qr_code),
              label: const Text('マイQR'),
              style: TextButton.styleFrom(
                foregroundColor: isShowingMyQr ? Colors.indigo : Colors.grey,
              ),
            ),
            TextButton.icon(
              onPressed: () => setState(() => isShowingMyQr = false),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('スキャン'),
              style: TextButton.styleFrom(
                foregroundColor: !isShowingMyQr ? Colors.indigo : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyQr(String? userId) {
    if (userId == null) {
      return const Center(child: Text('ユーザー情報を取得できません'));
    }

    final qrData = QRCodeUtils.generateUserQRCode(userId);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '相手にこのQRコードを\nスキャンしてもらいましょう',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 250,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanner() {
    return QRScanPage(
      onQRCodeDetected: handleQrScanned,
      title: null,
      instruction: '友達のQRコードをスキャンしてください',
      continuousMode: false,
    );
  }
}
