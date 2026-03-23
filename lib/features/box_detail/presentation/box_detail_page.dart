/*
====================================================
目的:
  - 箱の詳細情報を表示する画面
  - 写真、メモ、保管場所、QR情報を表示

処理構造:
  - Firestoreから箱データ取得
  - 写真ギャラリー表示
  - 開封ボタン（封印中の場合）
  - ステータス表示
====================================================
*/

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:beamer/beamer.dart';
import 'package:intl/intl.dart';
import '../../../shared/models/box_model.dart';
import '../../../shared/repositories/box_repository.dart';
import '../../auth/presentation/auth_gate.dart';

/// 箱詳細画面
class BoxDetailPage extends ConsumerStatefulWidget {
  final String boxId;

  const BoxDetailPage({
    super.key,
    required this.boxId,
  });

  @override
  ConsumerState<BoxDetailPage> createState() => _BoxDetailPageState();
}

class _BoxDetailPageState extends ConsumerState<BoxDetailPage> {
  Box? boxData;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadBoxData();
  }

  Future<void> loadBoxData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final getBoxDetailUseCase = ref.read(getBoxDetailUseCaseProvider);
      final userId = ref.read(authStateProvider).value?.uid ?? '';
      final box = await getBoxDetailUseCase.execute(widget.boxId, userId);

      if (box == null) {
        setState(() {
          errorMessage = '箱が見つかりませんでした';
          isLoading = false;
        });
        return;
      }

      setState(() {
        boxData = box;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('箱の詳細'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.beamToNamed('/box-list');
          },
        ),
      ),
      body: buildBody(),
      floatingActionButton: buildFloatingActionButton(),
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
                onPressed: () {
                  context.beamToNamed('/box-list');
                },
                child: const Text('一覧に戻る'),
              ),
            ],
          ),
        ),
      );
    }

    if (boxData == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          buildStatusBanner(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                buildInfoCard(),
                const SizedBox(height: 16),
                if (boxData!.photos.isNotEmpty) ...[
                  buildPhotosSection(),
                  const SizedBox(height: 16),
                ],
                if (boxData!.memo.isNotEmpty) ...[
                  buildMemoSection(),
                  const SizedBox(height: 16),
                ],
                buildQRSection(),
                const SizedBox(height: 16),
                buildDatesSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildStatusBanner() {
    final statusColor = getStatusColor(boxData!.status);
    final statusLabel = getStatusLabel(boxData!.status);
    final statusIcon = getStatusIcon(boxData!.status);

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: statusColor,
            width: 2,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            statusIcon,
            size: 32,
            color: statusColor,
          ),
          const SizedBox(width: 12),
          Text(
            statusLabel,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '基本情報',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(height: 24),
            buildInfoRow(Icons.fingerprint, 'Box ID', boxData!.boxId, isMonospace: true),
            const SizedBox(height: 12),
            if (boxData!.storageLocation.isNotEmpty)
              buildInfoRow(Icons.place, '保管場所', boxData!.storageLocation),
          ],
        ),
      ),
    );
  }

  Widget buildInfoRow(IconData icon, String label, String value, {bool isMonospace = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontFamily: isMonospace ? 'monospace' : null,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildPhotosSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.photo_library,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '写真 (${boxData!.photos.length}枚)',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Divider(height: 24),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: boxData!.photos.length,
                itemBuilder: (context, index) {
                  final photo = boxData!.photos[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: GestureDetector(
                      onTap: () {
                        showPhotoDialog(index);
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          photo.url,
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 200,
                              height: 200,
                              color: Colors.grey[300],
                              child: const Icon(Icons.broken_image, size: 48),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: 200,
                              height: 200,
                              color: Colors.grey[200],
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showPhotoDialog(int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            PageView.builder(
              controller: PageController(initialPage: initialIndex),
              itemCount: boxData!.photos.length,
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  child: Image.network(
                    boxData!.photos[index].url,
                    fit: BoxFit.contain,
                  ),
                );
              },
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildMemoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.note,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'メモ',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              boxData!.memo,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildQRSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.qr_code,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'QRコード情報',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              '登録枚数: ${boxData!.qrFaceCount}面',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: boxData!.faces.keys.map((faceId) {
                return Chip(
                  label: Text(faceId),
                  avatar: const Icon(Icons.qr_code_2, size: 16),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDatesSection() {
    final dateFormat = DateFormat('yyyy年MM月dd日 HH:mm');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '日時情報',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Divider(height: 24),
            buildDateRow('封印日時', dateFormat.format(boxData!.createdAt)),
            if (boxData!.openedAt != null) ...[
              const SizedBox(height: 8),
              buildDateRow('開封日時', dateFormat.format(boxData!.openedAt!)),
            ],
            const SizedBox(height: 8),
            buildDateRow('最終確認', dateFormat.format(boxData!.lastViewedAt)),
          ],
        ),
      ),
    );
  }

  Widget buildDateRow(String label, String date) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        Text(
          date,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget? buildFloatingActionButton() {
    if (boxData == null || boxData!.status != BoxStatus.sealed) {
      return null;
    }

    return FloatingActionButton.extended(
      onPressed: () {
        context.beamToNamed('/unseal/${boxData!.boxId}');
      },
      icon: const Icon(Icons.lock_open),
      label: const Text('開封する'),
      backgroundColor: Colors.red,
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
        return '破損検知';
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
}
