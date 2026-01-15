/*
====================================================
目的:
  - 封印用のQRコードをスキャンする専用画面
  - フルスクリーンでの没入型スキャン体験

処理構造:
  - カメラの初期化と制御
  - QRコードの連続スキャン
  - 自動で元画面に戻る
  - エラーハンドリング
====================================================
*/

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/utils/qr_utils.dart';

/// 封印用QRスキャン画面
class SealQRScanPage extends StatefulWidget {
  final String? currentBoxId;
  final Set<String> scannedFaceIds;
  final Function(String qrCode) onQRScanned;

  const SealQRScanPage({
    super.key,
    this.currentBoxId,
    required this.scannedFaceIds,
    required this.onQRScanned,
  });

  @override
  State<SealQRScanPage> createState() => _SealQRScanPageState();
}

class _SealQRScanPageState extends State<SealQRScanPage> {
  MobileScannerController? scannerController;
  bool isProcessing = false;
  String? errorMessage;
  int scanCount = 0;

  @override
  void initState() {
    super.initState();
    scanCount = widget.scannedFaceIds.length;
    initializeScanner();
  }

  Future<void> initializeScanner() async {
    try {
      scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
      );
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('[SealQRScanPage] Failed to initialize scanner: $e');
      if (mounted) {
        setState(() {
          errorMessage = 'カメラの初期化に失敗しました';
        });
      }
    }
  }

  @override
  void dispose() {
    scannerController?.dispose();
    super.dispose();
  }

  Future<void> handleDetection(BarcodeCapture capture) async {
    if (isProcessing) {
      return;
    }

    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) {
      return;
    }

    final qrCode = barcode!.rawValue!;
    debugPrint('[SealQRScanPage] Detected QR: $qrCode');

    setState(() {
      isProcessing = true;
      errorMessage = null;
    });

    try {
      // QRコードの形式チェック
      if (!QRCodeUtils.validateQRCode(qrCode)) {
        showError('無効なQRコードです');
        return;
      }

      final parsed = QRCodeUtils.parseQRCode(qrCode);
      if (parsed == null) {
        showError('QRコードの解析に失敗しました');
        return;
      }

      final scannedBoxId = parsed['boxId']!;
      final faceId = parsed['faceId']!;

      // box-idのチェック
      if (widget.currentBoxId != null && widget.currentBoxId != scannedBoxId) {
        showError('異なる箱のQRコードです');
        return;
      }

      // 重複チェック
      if (widget.scannedFaceIds.contains(faceId)) {
        debugPrint('[SealQRScanPage] Duplicate face ID: $faceId');
        showError('このQRコード($faceId)は既にスキャン済みです');
        return;
      }

      // 成功
      debugPrint('[SealQRScanPage] Valid QR, calling callback');
      setState(() {
        scanCount++;
      });

      widget.onQRScanned(qrCode);

      // 成功のフィードバック表示
      if (mounted) {
        await showSuccessFeedback();
      }

      // 1秒後に自動的に戻る
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 1000));
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  void showError(String message) {
    setState(() {
      errorMessage = message;
    });

    // 2秒後にエラーメッセージをクリア
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          errorMessage = null;
        });
      }
    });
  }

  Future<void> showSuccessFeedback() async {
    // バイブレーション（将来的に追加可能）
    // HapticFeedback.mediumImpact();
    
    // 成功メッセージは画面上に表示
    setState(() {
      errorMessage = '✓ 読み取り成功！';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // カメラビュー
          if (scannerController != null && errorMessage != 'カメラの初期化に失敗しました')
            MobileScanner(
              controller: scannerController,
              onDetect: handleDetection,
            )
          else if (errorMessage == 'カメラの初期化に失敗しました')
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.camera_alt_outlined, size: 64, color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('戻る'),
                  ),
                ],
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // スキャンガイド枠
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  // コーナーマーカー
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.green.shade400, width: 4),
                          left: BorderSide(color: Colors.green.shade400, width: 4),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.green.shade400, width: 4),
                          right: BorderSide(color: Colors.green.shade400, width: 4),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.green.shade400, width: 4),
                          left: BorderSide(color: Colors.green.shade400, width: 4),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.green.shade400, width: 4),
                          right: BorderSide(color: Colors.green.shade400, width: 4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 上部: タイトルと閉じるボタン
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white, size: 32),
                      ),
                      const Text(
                        'QRコードをスキャン',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 48), // バランス調整
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 下部: スキャン状態表示
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // エラーメッセージまたは成功メッセージ
                    if (errorMessage != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: errorMessage!.startsWith('✓')
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              errorMessage!.startsWith('✓')
                                  ? Icons.check_circle
                                  : Icons.error,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                errorMessage!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // スキャン済み枚数
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.qr_code_2, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '$scanCount枚スキャン済み',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'QRコードを枠内に合わせてください',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 処理中オーバーレイ
          if (isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
