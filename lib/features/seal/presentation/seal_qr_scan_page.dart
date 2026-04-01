/*
====================================================
目的:
  - 封印用のQRコードを連続スキャンする専用画面
  - フルスクリーンでの没入型スキャン体験

処理構造:
  - カメラの初期化と制御
  - QRコードの連続スキャン（複数枚を1回のセッションで読み取り）
  - スキャン済みFace IDのリアルタイム表示
  - 完了ボタンでまとめて返却
  - エラーハンドリング
====================================================
*/

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/utils/qr_utils.dart';

/// 封印用QRスキャンの結果を保持するデータクラス
class SealQRScanResult {
  /// このセッションで新たにスキャンされたQRコード（faceId → qrCode）
  final Map<String, String> scannedCodes;

  /// 1枚目のQRから取得した箱ID
  final String? boxId;

  const SealQRScanResult({
    required this.scannedCodes,
    this.boxId,
  });
}

/// 封印用QRスキャン画面（連続スキャン対応）
///
/// 1回のカメラセッションで複数のQRコードを読み取り、
/// ユーザーが「完了」ボタンを押した時点でまとめて結果を返す。
class SealQRScanPage extends StatefulWidget {
  /// 既にスキャン済みの箱ID（2回目以降のスキャンセッションで使用）
  final String? currentBoxId;

  /// 既にスキャン済みのFace IDセット（重複排除用）
  final Set<String> scannedFaceIds;

  const SealQRScanPage({
    super.key,
    this.currentBoxId,
    required this.scannedFaceIds,
  });

  @override
  State<SealQRScanPage> createState() => _SealQRScanPageState();
}

class _SealQRScanPageState extends State<SealQRScanPage> {
  MobileScannerController? scannerController;
  bool _isHandling = false;
  String? statusMessage;
  bool isStatusSuccess = false;

  String? _resolvedBoxId;
  final Map<String, String> _sessionScannedCodes = {};
  late Set<String> _allScannedFaceIds;

  int get totalScanCount => widget.scannedFaceIds.length + _sessionScannedCodes.length;

  @override
  void initState() {
    super.initState();
    _resolvedBoxId = widget.currentBoxId;
    _allScannedFaceIds = Set<String>.from(widget.scannedFaceIds);
    _initializeScanner();
  }

  Future<void> _initializeScanner() async {
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
          statusMessage = 'カメラの初期化に失敗しました';
          isStatusSuccess = false;
        });
      }
    }
  }

  @override
  void dispose() {
    scannerController?.dispose();
    super.dispose();
  }

  Future<void> _handleDetection(BarcodeCapture capture) async {
    if (_isHandling) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    final qrCode = barcode!.rawValue!;
    debugPrint('[SealQRScanPage] Detected QR: $qrCode');

    _isHandling = true;
    setState(() {
      statusMessage = null;
    });

    try {
      if (!QRCodeUtils.validateQRCode(qrCode)) {
        _showStatus('無効なQRコードです', isSuccess: false);
        return;
      }

      final parsed = QRCodeUtils.parseQRCode(qrCode);
      if (parsed == null) {
        _showStatus('QRコードの解析に失敗しました', isSuccess: false);
        return;
      }

      final scannedBoxId = parsed['boxId']!;
      final faceId = parsed['faceId']!;

      if (_resolvedBoxId != null && _resolvedBoxId != scannedBoxId) {
        _showStatus('異なる箱のQRコードです', isSuccess: false);
        return;
      }

      if (_allScannedFaceIds.contains(faceId)) {
        debugPrint('[SealQRScanPage] Duplicate face ID: $faceId');
        _showStatus('$faceId は既にスキャン済みです', isSuccess: false);
        return;
      }

      debugPrint('[SealQRScanPage] Valid QR: $faceId');
      setState(() {
        _resolvedBoxId ??= scannedBoxId;
        _sessionScannedCodes[faceId] = qrCode;
        _allScannedFaceIds.add(faceId);
      });

      _showStatus('✓ $faceId を読み取りました', isSuccess: true);
    } finally {
      // isProcessing は即座に解除する（オーバーレイでタッチをブロックしない）
      _isHandling = false;
    }

    // 次の検出を受け付けるまでの短いクールダウン（isProcessing とは分離）
    await Future.delayed(const Duration(milliseconds: 800));
  }

  void _showStatus(String message, {required bool isSuccess}) {
    setState(() {
      statusMessage = message;
      isStatusSuccess = isSuccess;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          statusMessage = null;
        });
      }
    });
  }

  void _onComplete() {
    final result = SealQRScanResult(
      scannedCodes: Map<String, String>.from(_sessionScannedCodes),
      boxId: _resolvedBoxId,
    );
    Navigator.of(context).pop(result);
  }

  void _onClose() {
    final result = SealQRScanResult(
      scannedCodes: Map<String, String>.from(_sessionScannedCodes),
      boxId: _resolvedBoxId,
    );
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (scannerController != null && statusMessage != 'カメラの初期化に失敗しました')
            MobileScanner(
              controller: scannerController,
              onDetect: _handleDetection,
            )
          else if (statusMessage == 'カメラの初期化に失敗しました')
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.camera_alt_outlined, size: 64, color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    statusMessage!,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    child: const Text('戻る'),
                  ),
                ],
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          _buildScanGuide(),
          _buildTopBar(),
          _buildBottomPanel(),
        ],
      ),
    );
  }

  Widget _buildScanGuide() {
    return Center(
      child: Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
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
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: _onClose,
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
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withOpacity(0.9),
                Colors.black.withOpacity(0.7),
                Colors.transparent,
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (statusMessage != null) _buildStatusBanner(),
              if (_sessionScannedCodes.isNotEmpty) _buildScannedFaceList(),
              const SizedBox(height: 12),
              _buildScanCountBadge(),
              const SizedBox(height: 16),
              _buildCompleteButton(),
              const SizedBox(height: 8),
              Text(
                _sessionScannedCodes.isEmpty
                    ? 'QRコードを枠内に合わせてください'
                    : '続けて次のQRコードを読み取れます',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isStatusSuccess ? Colors.green.shade700 : Colors.red.shade700,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isStatusSuccess ? Icons.check_circle : Icons.error,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              statusMessage!,
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
    );
  }

  Widget _buildScannedFaceList() {
    final faceIds = _sessionScannedCodes.keys.toList();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: faceIds.map((faceId) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.shade700.withOpacity(0.8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.shade400, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  faceId,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildScanCountBadge() {
    return Container(
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
            '$totalScanCount枚スキャン済み',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteButton() {
    final hasNewScans = _sessionScannedCodes.isNotEmpty;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: hasNewScans ? _onComplete : null,
        icon: const Icon(Icons.done),
        label: Text(
          hasNewScans
              ? 'スキャン完了（${_sessionScannedCodes.length}枚）'
              : 'QRコードを読み取ってください',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: hasNewScans ? Colors.green.shade600 : Colors.grey.shade700,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade800,
          disabledForegroundColor: Colors.grey.shade500,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
