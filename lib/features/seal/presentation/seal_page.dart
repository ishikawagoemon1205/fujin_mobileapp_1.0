/*
====================================================
目的:
  - 箱を封印する機能の画面
  - 内容物登録 + QRスキャン → 保存

処理構造:
  - 写真・メモ・保管場所の入力（箱が開いている状態）
  - QRコードの連続スキャン（埋め込み型スキャナー）
  - Firestoreへの保存
  - エラーハンドリング
====================================================
*/

import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:beamer/beamer.dart';
import '../../../core/utils/qr_utils.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/box_model.dart';
import '../../../shared/models/group_model.dart';
import '../../../shared/repositories/box_repository.dart';
import '../domain/usecases/create_box_usecase.dart';
import 'seal_qr_scan_page.dart';

/// 封印画面
class SealPage extends ConsumerStatefulWidget {
  const SealPage({super.key});

  @override
  ConsumerState<SealPage> createState() => _SealPageState();
}

class _SealPageState extends ConsumerState<SealPage> {
  String? boxId;
  String? selectedGroupId;
  List<Group> userGroups = [];
  final Map<String, String> scannedQRCodes = {};
  final List<File> selectedPhotos = [];
  final TextEditingController memoController = TextEditingController();
  final TextEditingController storageLocationController = TextEditingController();
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    loadUserGroups();
  }

  Future<void> loadUserGroups() async {
    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) return;

      final getGroups = ref.read(getGroupsUseCaseProvider);
      final groups = await getGroups.execute(userId);

      if (mounted) {
        setState(() {
          userGroups = groups.where((g) => g.isJoinedMember(userId)).toList();
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    memoController.dispose();
    storageLocationController.dispose();
    super.dispose();
  }

  Future<void> handleQRCodeScanned(String qrCode) async {
    debugPrint('[Flutter SealPage] handleQRCodeScanned called with: $qrCode');
    debugPrint('[Flutter SealPage] Current state - boxId: $boxId, scannedQRCodes: ${scannedQRCodes.length}');
    
    final parsed = QRCodeUtils.parseQRCode(qrCode);
    if (parsed == null) {
      debugPrint('[Flutter SealPage] Failed to parse QR code');
      return;
    }

    final scannedBoxId = parsed['boxId']!;
    final faceId = parsed['faceId']!;
    debugPrint('[Flutter SealPage] Parsed - boxId: $scannedBoxId, faceId: $faceId');

    if (boxId == null) {
      debugPrint('[Flutter SealPage] First QR, setting boxId to $scannedBoxId');
      boxId = scannedBoxId;
    } else if (boxId != scannedBoxId) {
      debugPrint('[Flutter SealPage] Different box ID detected (expected: $boxId, got: $scannedBoxId)');
      showErrorDialog('異なる箱のQRコードです');
      return;
    }

    if (scannedQRCodes.containsKey(faceId)) {
      debugPrint('[Flutter SealPage] Duplicate face ID: $faceId, ignoring silently');
      return;
    }

    // QRコードを追加
    debugPrint('[Flutter SealPage] Adding QR to scannedQRCodes');
    setState(() {
      scannedQRCodes[faceId] = qrCode;
    });
    debugPrint('[Flutter SealPage] setState completed, scannedQRCodes.length=${scannedQRCodes.length}');

    if (mounted) {
      debugPrint('[Flutter SealPage] Showing success snackbar');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${scannedQRCodes.length}枚目のQRを読み取りました'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );
    }
    debugPrint('[Flutter SealPage] handleQRCodeScanned completed');
  }

  Future<void> pickImages() async {
    if (selectedPhotos.length >= DataConstraints.maxPhotos) {
      showErrorDialog('写真は最大${DataConstraints.maxPhotos}枚までです');
      return;
    }

    final picker = ImagePicker();
    final images = await picker.pickMultiImage();

    if (images.isEmpty) return;

    final remainingSlots = DataConstraints.maxPhotos - selectedPhotos.length;
    final imagesToAdd = images.take(remainingSlots).map((xFile) => File(xFile.path)).toList();

    setState(() {
      selectedPhotos.addAll(imagesToAdd);
    });
  }

  Future<void> takePicture() async {
    if (selectedPhotos.length >= DataConstraints.maxPhotos) {
      showErrorDialog('写真は最大${DataConstraints.maxPhotos}枚までです');
      return;
    }

    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);

    if (image == null) return;

    setState(() {
      selectedPhotos.add(File(image.path));
    });
  }

  void removePhoto(int index) {
    setState(() {
      selectedPhotos.removeAt(index);
    });
  }

  Future<void> saveBox() async {
    debugPrint('[Flutter SealPage] saveBox called');
    
    if (boxId == null || scannedQRCodes.isEmpty) {
      debugPrint('[Flutter SealPage] Validation failed: No QR codes');
      showErrorDialog('QRコードをスキャンしてください');
      return;
    }

    final storageLocation = storageLocationController.text.trim();
    if (storageLocation.isEmpty) {
      showErrorDialog('保管場所を入力してください');
      return;
    }

    debugPrint('[Flutter SealPage] Starting save process...');
    setState(() {
      isSaving = true;
    });

    try {
      debugPrint('[Flutter SealPage] Getting UseCase...');
      final createBoxUseCase = ref.read(createBoxUseCaseProvider);
      final userId = ref.read(currentUserIdProvider);

      if (userId == null) {
        showErrorDialog('ユーザー情報が取得できません。再ログインしてください');
        return;
      }

      final faces = scannedQRCodes.map((faceId, qrCode) {
        final parsed = QRCodeUtils.parseQRCode(qrCode)!;
        return MapEntry(
          faceId,
          QRFace(
            faceId: faceId,
            qrCode: qrCode,
            scannedAt: DateTime.now(),
            checksum: parsed['checksum']!,
          ),
        );
      });

      debugPrint('[Flutter SealPage] Executing CreateBoxUseCase...');
      await createBoxUseCase.execute(
        CreateBoxParams(
          boxId: boxId!,
          userId: userId,
          storageLocation: storageLocationController.text.trim(),
          memo: memoController.text.trim(),
          faces: faces,
          photos: selectedPhotos,
          groupId: selectedGroupId,
        ),
      );
      debugPrint('[Flutter SealPage] UseCase execution completed!');

      if (mounted) {
        debugPrint('[Flutter SealPage] Showing success message and navigating home');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('封印が完了しました！'),
            backgroundColor: Colors.green,
          ),
        );

        context.beamToNamed('/');
      }
    } catch (e, stackTrace) {
      debugPrint('[Flutter SealPage] ERROR: $e');
      debugPrint('[Flutter SealPage] StackTrace: $stackTrace');
      if (mounted) {
        if (e is BoxAlreadyExistsException) {
          showErrorDialog('この箱（ID: $boxId）は既に登録されています');
        } else {
          showErrorDialog('保存中にエラーが発生しました: $e');
        }
      }
    } finally {
      debugPrint('[Flutter SealPage] Cleanup: setting isSaving=false');
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[Flutter SealPage] build() called, scannedQRCodes=${scannedQRCodes.length}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('新しく封印する'),
      ),
      body: isSaving
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('保存中...'),
                ],
              ),
            )
          : GestureDetector(
              onTap: () {
                // body部分をタップした時にキーボードを閉じる
                FocusScope.of(context).unfocus();
              },
              behavior: HitTestBehavior.opaque,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildPhotosSection(),
                          const SizedBox(height: 16),
                          _buildMemoSection(),
                          const SizedBox(height: 16),
                          _buildStorageLocationSection(),
                          const SizedBox(height: 16),
                          _buildGroupSelectionSection(),
                          const SizedBox(height: 16),
                          _buildQRScanSection(),
                          const SizedBox(height: 80), // 下部ボタン分の余白
                        ],
                      ),
                    ),
                  ),
                  // 固定配置のボタン
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: SafeArea(
                      child: ElevatedButton.icon(
                        onPressed: scannedQRCodes.isEmpty ? null : saveBox,
                        icon: const Icon(Icons.lock, size: 24),
                        label: const Text('封印する', style: TextStyle(fontSize: 18)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey,
                          disabledForegroundColor: Colors.white70,
                          padding: const EdgeInsets.all(16),
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildQRScanSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.qr_code_2, color: Colors.indigo),
                const SizedBox(width: 8),
                Text(
                  'QRコードをスキャン',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              scannedQRCodes.isEmpty
                  ? '箱を閉じてQRシールを貼り、スキャンしてください'
                  : '${scannedQRCodes.length}面スキャン済み',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scannedQRCodes.isEmpty ? Colors.grey.shade700 : Colors.green.shade700,
                    fontWeight: scannedQRCodes.isEmpty ? FontWeight.normal : FontWeight.bold,
                  ),
            ),
            if (boxId != null) ...[
              const SizedBox(height: 4),
              Text(
                '箱ID: $boxId',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
              ),
            ],
            if (scannedQRCodes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: scannedQRCodes.keys.map((faceId) {
                  return Chip(
                    label: Text(faceId),
                    backgroundColor: Colors.indigo.shade50,
                    labelStyle: TextStyle(
                      color: Colors.indigo.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () {
                      setState(() {
                        scannedQRCodes.remove(faceId);
                        if (scannedQRCodes.isEmpty) {
                          boxId = null;
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: openQRScanPage,
              icon: const Icon(Icons.qr_code_scanner, size: 28),
              label: Text(
                scannedQRCodes.isEmpty ? 'QRをスキャン' : 'QRを追加スキャン',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(double.infinity, 56),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> openQRScanPage() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SealQRScanPage(
          currentBoxId: boxId,
          scannedFaceIds: scannedQRCodes.keys.toSet(),
          onQRScanned: handleQRCodeScanned,
        ),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.photo_library, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      '写真 (${selectedPhotos.length}/${DataConstraints.maxPhotos})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: takePicture,
                      icon: const Icon(Icons.camera_alt),
                      tooltip: '撮影',
                    ),
                    IconButton(
                      onPressed: pickImages,
                      icon: const Icon(Icons.add_photo_alternate),
                      tooltip: 'ギャラリーから選択',
                    ),
                  ],
                ),
              ],
            ),
            if (selectedPhotos.isNotEmpty) ...[
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: selectedPhotos.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          selectedPhotos[index],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: IconButton(
                          onPressed: () => removePhoto(index),
                          icon: const Icon(Icons.close),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black54,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(4),
                            minimumSize: const Size(24, 24),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMemoSection() {
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
            TextField(
              controller: memoController,
              maxLines: 5,
              maxLength: DataConstraints.maxMemoLength,
              decoration: const InputDecoration(
                hintText: '箱の中身について記録してください\n例: 冬物の服、毛布類',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageLocationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  '保管場所',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: storageLocationController,
              maxLength: DataConstraints.maxStorageLocationLength,
              decoration: const InputDecoration(
                hintText: '例: 押入れ2F、倉庫A-3',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupSelectionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.group, color: Colors.indigo),
                const SizedBox(width: 8),
                Text(
                  '共有グループ',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'グループを選択すると、メンバー全員がこの箱を確認・開封できます',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              value: selectedGroupId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('個人（自分だけ）'),
                ),
                ...userGroups.map(
                  (group) => DropdownMenuItem<String?>(
                    value: group.groupId,
                    child: Text(group.name),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  selectedGroupId = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
