/*
====================================================
目的:
  - 箱を開封する画面
  - 全QRコードの検証と開封処理

処理構造:
  - 箱情報の取得
  - 全QRコードの連続スキャン
  - 検証処理
  - ステータス更新（opened/tampered）
====================================================
*/

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:beamer/beamer.dart';
import '../../../core/utils/qr_utils.dart';
import '../../../shared/models/box_model.dart';
import '../../../shared/repositories/box_repository.dart';
import '../../../shared/widgets/qr_scan_page.dart';
import '../domain/usecases/unseal_box_usecase.dart';
import '../../auth/presentation/auth_gate.dart';

/// 開封画面
class UnsealPage extends ConsumerStatefulWidget {
  final String boxId;

  const UnsealPage({
    super.key,
    required this.boxId,
  });

  @override
  ConsumerState<UnsealPage> createState() => _UnsealPageState();
}

class _UnsealPageState extends ConsumerState<UnsealPage> {
  Box? boxData;
  final Set<String> scannedFaces = {};
  bool isLoading = true;
  bool isScanning = false;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    loadBoxData();
  }

  Future<void> loadBoxData() async {
    try {
      final unsealRepo = ref.read(unsealRepositoryProvider);
      final userId = ref.read(authStateProvider).value?.uid ?? '';
      final box = await unsealRepo.getBox(widget.boxId, userId);

      if (box == null) {
        showErrorDialog('箱が見つかりませんでした');
        if (mounted) {
          context.beamBack();
        }
        return;
      }

      if (box.status != BoxStatus.sealed) {
        showErrorDialog('この箱は既に開封されています');
        if (mounted) {
          context.beamBack();
        }
        return;
      }

      setState(() {
        boxData = box;
        isLoading = false;
      });
    } catch (e) {
      showErrorDialog('データの取得に失敗しました: $e');
      if (mounted) {
        context.beamBack();
      }
    }
  }

  void startScanning() {
    setState(() {
      isScanning = true;
      scannedFaces.clear();
    });
  }

  Future<void> handleQRCodeScanned(String qrCode) async {
    final parsed = QRCodeUtils.parseQRCode(qrCode);
    if (parsed == null) return;

    final scannedBoxId = parsed['boxId']!;
    final faceId = parsed['faceId']!;

    if (scannedBoxId != widget.boxId) {
      showErrorDialog('異なる箱のQRコードです');
      // エラー時もスキャンを継続（isScanningは変更しない）
      return;
    }

    if (!boxData!.faces.containsKey(faceId)) {
      showErrorDialog('登録されていないQRコードです');
      // エラー時もスキャンを継続（isScanningは変更しない）
      return;
    }

    // 重複チェック: 既にスキャン済みの場合は静かに無視
    if (scannedFaces.contains(faceId)) {
      debugPrint('[UnsealPage] Face $faceId already scanned, ignoring');
      return;
    }

    setState(() {
      scannedFaces.add(faceId);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${scannedFaces.length}/${boxData!.qrFaceCount}枚スキャン完了'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );
    }

    if (scannedFaces.length == boxData!.qrFaceCount) {
      await completeUnseal(success: true);
    }
    // 全QRスキャン完了していない場合は、そのままスキャンを継続
    // isScanning は既に true なので、再設定不要
  }

  Future<void> completeUnseal({required bool success}) async {
    setState(() {
      isScanning = false;
      isProcessing = true;
    });

    try {
      final unsealUseCase = ref.read(unsealBoxUseCaseProvider);
      final userId = ref.read(authStateProvider).value?.uid ?? '';
      final newStatus = await unsealUseCase.execute(
        UnsealBoxParams(
          boxId: widget.boxId,
          userId: userId,
          scannedFaceIds: scannedFaces,
        ),
      );

      final isSuccess = newStatus == BoxStatus.opened;

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.warning,
                  color: isSuccess ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(isSuccess ? '開封完了' : '検証失敗'),
              ],
            ),
            content: Text(
              isSuccess
                  ? '全てのQRコードが検証され、正常に開封されました。'
                  : 'QRコードの検証に失敗しました。\n箱が破損している可能性があります。',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  context.beamToNamed('/');
                },
                child: const Text('ホームに戻る'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      showErrorDialog('開封処理に失敗しました: $e');
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
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
    if (isScanning) {
      return WillPopScope(
        onWillPop: () async {
          // ホームに戻る
          context.beamToNamed('/');
          return false;
        },
        child: QRScanPage(
          title: '開封検証',
          instruction: '${scannedFaces.length}/${boxData?.qrFaceCount ?? 0}枚スキャン済み\n続けてQRコードをスキャンしてください',
          continuousMode: true, // 連続スキャンモード有効化
          onQRCodeDetected: (qrCode) {
            if (!mounted) return;
            handleQRCodeScanned(qrCode);
          },
        ),
      );
    }

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('読み込み中'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              context.beamToNamed('/');
            },
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (isProcessing) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('処理中'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              context.beamToNamed('/');
            },
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('開封処理中...'),
            ],
          ),
        ),
      );
    }

    if (boxData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('エラー'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              context.beamToNamed('/');
            },
          ),
        ),
        body: const Center(
          child: Text('箱情報を取得できませんでした'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('開封する'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.beamToNamed('/');
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.amber.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(
                      Icons.warning_amber,
                      size: 48,
                      color: Colors.amber,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '開封の確認',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'この箱を開封しますか？',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          '開封手順',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildStep(
                      '1',
                      '登録した全てのQRコード(${boxData!.qrFaceCount}枚)を順番にスキャンしてください',
                    ),
                    const SizedBox(height: 8),
                    _buildStep(
                      '2',
                      '全てのQRコードが読み取れれば正常開封となります',
                    ),
                    const SizedBox(height: 8),
                    _buildStep(
                      '3',
                      '1枚でも読み取れない場合、破損として記録されます',
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: startScanning,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('QRスキャンを開始'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => context.beamBack(),
              child: const Text('キャンセル'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.indigo,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text),
        ),
      ],
    );
  }
}
