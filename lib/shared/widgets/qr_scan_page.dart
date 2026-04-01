/*
====================================================
目的:
  - QRコードをスキャンする画面
  - カメラを使ったQRコード読み取り

処理構造:
  - カメラの初期化
  - QRコードの検出
  - 検出結果の処理
  - エラーハンドリング
====================================================
*/

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/utils/qr_utils.dart';

/// QRスキャン画面
class QRScanPage extends StatefulWidget {
  final Function(String qrCode) onQRCodeDetected;
  final String? title;
  final String? instruction;
  
  /// 連続スキャンモード: trueの場合、QR検出後もカメラを停止せずスキャンを継続
  final bool continuousMode;

  const QRScanPage({
    super.key,
    required this.onQRCodeDetected,
    this.title,
    this.instruction,
    this.continuousMode = false,
  });

  @override
  State<QRScanPage> createState() => _QRScanPageState();
}

class _QRScanPageState extends State<QRScanPage> {
  MobileScannerController? scannerController;
  bool isProcessing = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    initializeScanner();
  }

  Future<void> initializeScanner() async {
    try {
      scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
      );

      // try to start the controller to trigger permission prompt early
      // some platforms may throw if camera is not available or permission denied
      await scannerController?.start();
    } catch (e) {
      // capture error and show a friendly message instead of freezing
      errorMessage = 'カメラの初期化に失敗しました。\n設定でカメラ権限を許可してください。\nエラー: $e';
      // ensure controller is disposed if partially created
      try {
        await scannerController?.dispose();
      } catch (_) {}
      scannerController = null;
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    scannerController?.dispose();
    super.dispose();
  }

  Future<void> handleQRCodeDetected(BarcodeCapture capture) async {
    if (isProcessing) {
      debugPrint('[Flutter QRScan] Already processing, ignoring');
      return;
    }

    if (errorMessage != null) {
      debugPrint('[Flutter QRScan] Error state, ignoring detection');
      return;
    }

    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) {
      debugPrint('[Flutter QRScan] No barcode data');
      return;
    }

    final qrCode = barcode.rawValue!;
    debugPrint('[Flutter QRScan] Detected QR: $qrCode');

    // ユーザーQR (fujin-user://) は validateQRCode の対象外のため個別に判定する
    final isValidBoxQR = QRCodeUtils.validateQRCode(qrCode);
    final isValidUserQR = QRCodeUtils.isUserQR(qrCode) &&
        QRCodeUtils.extractUidFromUserQR(qrCode) != null;

    if (!isValidBoxQR && !isValidUserQR) {
      debugPrint('[Flutter QRScan] Invalid QR code format');
      showInvalidQRError();
      return;
    }

    debugPrint('[Flutter QRScan] Valid QR code, processing...');
    setState(() {
      isProcessing = true;
    });

    // 連続モードでない場合のみカメラを停止
    if (!widget.continuousMode) {
      try {
        debugPrint('[Flutter QRScan] Stopping scanner...');
        await scannerController?.stop();
        debugPrint('[Flutter QRScan] Scanner stopped');
      } catch (e) {
        debugPrint('[Flutter QRScan] Scanner stop error: $e');
      }
    } else {
      debugPrint('[Flutter QRScan] Continuous mode: keeping scanner running');
    }

    // mounted チェック: 画面がまだ存在するか確認
    if (!mounted) {
      debugPrint('[Flutter QRScan] Widget unmounted, aborting callback');
      return;
    }

    // コールバックを呼ぶ
    debugPrint('[Flutter QRScan] Calling onQRCodeDetected callback');
    try {
      widget.onQRCodeDetected(qrCode);
      debugPrint('[Flutter QRScan] Callback completed');
    } catch (e, stackTrace) {
      debugPrint('[Flutter QRScan] Callback error: $e');
      debugPrint('[Flutter QRScan] Stack trace: $stackTrace');
    }
    
    // 連続モードの場合は処理完了後すぐに次のスキャンを受け付ける
    if (widget.continuousMode) {
      // 短い遅延を入れて同じQRを連続で読み取らないようにする
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
        debugPrint('[Flutter QRScan] Ready for next scan');
      }
    }
  }

  void showInvalidQRError() {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('無効なQRコードです'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildErrorView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('カメラエラー'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.camera_alt, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              errorMessage ?? 'カメラを使用できません',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                // ユーザーが設定を確認できるよう再試行
                setState(() {
                  errorMessage = null;
                });
                await initializeScanner();
              },
              child: const Text('再試行'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                // ユーザーにアプリの設定を開くよう促す (手動)
                showDialog(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('案内'),
                    content: const Text('iOS の設定 → アプリ名 → カメラ を有効にしてください。'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(c).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('設定を確認する方法を見る'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // エラーがある場合はエラービューを表示
    if (errorMessage != null) return _buildErrorView();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'QRコードをスキャン'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () {
              scannerController?.toggleTorch();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          if (scannerController != null)
            MobileScanner(
              controller: scannerController!,
              onDetect: handleQRCodeDetected,
            )
          else
            const Center(
              child: CircularProgressIndicator(),
            ),
          _buildScanOverlay(),
          if (widget.instruction != null)
            Positioned(
              bottom: 60,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.instruction!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScanOverlay() {
    return Center(
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.white,
            width: 3,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
