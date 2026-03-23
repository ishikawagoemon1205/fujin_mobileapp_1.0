/*
====================================================
目的:
  - 箱の中身を確認する画面
  - QRスキャン → 箱情報表示

処理構造:
  - QRコードスキャン
  - Firestoreから箱情報取得
  - 写真・メモ・保管場所の表示
  - 開封機能への遷移
====================================================
*/

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:beamer/beamer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/qr_utils.dart';
import '../../../shared/models/box_model.dart';
import '../../../shared/repositories/box_repository.dart';
import '../../../shared/widgets/qr_scan_page.dart';

/// 確認画面
class VerifyPage extends ConsumerStatefulWidget {
  const VerifyPage({super.key});

  @override
  ConsumerState<VerifyPage> createState() => _VerifyPageState();
}

class _VerifyPageState extends ConsumerState<VerifyPage> {
  bool isScanning = true;
  Box? boxData;
  bool isLoading = false;

  Future<void> handleQRCodeScanned(String qrCode) async {
    setState(() {
      isScanning = false;
      isLoading = true;
    });

    final boxId = QRCodeUtils.extractBoxId(qrCode);
    if (boxId == null) {
      showErrorDialog('無効なQRコードです');
      setState(() {
        isLoading = false;
        isScanning = true;
      });
      return;
    }

    try {
      final getBoxUseCase = ref.read(getBoxUseCaseProvider);
      final box = await getBoxUseCase.execute(boxId);

      if (box == null) {
        showErrorDialog('箱が見つかりませんでした');
        setState(() {
          isLoading = false;
          isScanning = true;
        });
        return;
      }

      setState(() {
        boxData = box;
        isLoading = false;
      });
    } catch (e) {
      showErrorDialog('データの取得に失敗しました: $e');
      setState(() {
        isLoading = false;
        isScanning = true;
      });
    }
  }

  void showErrorDialog(String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('エラー'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void navigateToUnseal() {
    if (boxData == null) return;
    context.beamToNamed('/unseal/${boxData!.boxId}');
  }

  @override
  Widget build(BuildContext context) {
    if (isScanning) {
      return QRScanPage(
        title: '中身を確認',
        instruction: '箱に貼られたQRコードをスキャンしてください',
        onQRCodeDetected: (qrCode) {
          if (!mounted) return;
          handleQRCodeScanned(qrCode);
        },
      );
    }

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('読み込み中')),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (boxData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('エラー')),
        body: const Center(
          child: Text('箱情報を取得できませんでした'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('箱の詳細'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 16),
            _buildInfoCard(),
            const SizedBox(height: 16),
            if (boxData!.photos.isNotEmpty) _buildPhotosSection(),
            if (boxData!.photos.isNotEmpty) const SizedBox(height: 16),
            _buildMemoSection(),
            const SizedBox(height: 24),
            if (boxData!.status == BoxStatus.sealed)
              ElevatedButton.icon(
                onPressed: navigateToUnseal,
                icon: const Icon(Icons.lock_open),
                label: const Text('開封する'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.all(16),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    Color statusColor;
    IconData statusIcon;

    switch (boxData!.status) {
      case BoxStatus.sealed:
        statusColor = Colors.green;
        statusIcon = Icons.lock;
        break;
      case BoxStatus.opened:
        statusColor = Colors.blue;
        statusIcon = Icons.lock_open;
        break;
      case BoxStatus.tampered:
        statusColor = Colors.red;
        statusIcon = Icons.warning;
        break;
    }

    return Card(
      color: statusColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              statusIcon,
              size: 48,
              color: statusColor,
            ),
            const SizedBox(height: 8),
            Text(
              boxData!.status.label,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              '${boxData!.qrFaceCount}面のQRで封印',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(
              Icons.inventory_2,
              '箱ID',
              boxData!.boxId,
            ),
            const Divider(),
            _buildInfoRow(
              Icons.location_on,
              '保管場所',
              boxData!.storageLocation,
            ),
            const Divider(),
            _buildInfoRow(
              Icons.access_time,
              '封印日時',
              dateFormat.format(boxData!.createdAt),
            ),
            if (boxData!.openedAt != null) ...[
              const Divider(),
              _buildInfoRow(
                Icons.lock_open,
                '開封日時',
                dateFormat.format(boxData!.openedAt!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.photo_library, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  '写真 (${boxData!.photos.length}枚)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: boxData!.photos.length,
              itemBuilder: (context, index) {
                final photo = boxData!.photos[index];
                return GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        child: CachedNetworkImage(
                          imageUrl: photo.url,
                          fit: BoxFit.contain,
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: photo.url,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) => const Icon(Icons.error),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemoSection() {
    if (boxData!.memo.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.note, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'メモ',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              boxData!.memo,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
