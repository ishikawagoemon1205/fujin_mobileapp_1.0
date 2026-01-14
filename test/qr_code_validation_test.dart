/*
====================================================
目的:
  - Web側から生成されたQRコードの検証テスト

処理構造:
  - Web側のQRコードをパース
  - checksumを検証
  - 問題点を特定
====================================================
*/

import 'package:flutter_test/flutter_test.dart';
import 'package:wcm_fujin_mobile_app/core/utils/qr_utils.dart';

void main() {
  group('QR Code Validation Tests', () {
    test('Web側から生成されたQRコード群を検証', () {
      // Web側で生成されたQRコード
      final testCases = [
        'fujin://bHWCBwSb/F5/AD7B',
        'fujin://TEST0001/F1/64F4',
        'fujin://ABC12xyz/F1/7D70',
        'fujin://B7K9M3X2/F1/6D77',
        'fujin://B7K9M3X2/F2/6C37',
        'fujin://B7K9M3X2/F6/AF36',
      ];
      
      for (final webQRCode in testCases) {
        print('\n=== QRコード検証: $webQRCode ===');
        
        // パース
        final parsed = QRCodeUtils.parseQRCode(webQRCode);
        expect(parsed, isNotNull, reason: 'QRコードのフォーマットは正しい');
        
        print('Box ID: ${parsed!['boxId']}');
        print('Face ID: ${parsed['faceId']}');
        print('Web側のChecksum: ${parsed['checksum']}');
        
        // Flutter側でchecksumを計算
        final boxId = parsed['boxId']!;
        final faceId = parsed['faceId']!;
        final flutterChecksum = QRCodeUtils.generateChecksum(boxId, faceId);
        
        print('Flutter側のChecksum: $flutterChecksum');
        print('一致: ${parsed['checksum'] == flutterChecksum}');
        
        // 検証
        final isValid = QRCodeUtils.validateQRCode(webQRCode);
        print('検証結果: $isValid');
      }
    });
    
    test('Base62文字チェック', () {
      const boxId = 'bHWCBwSb';
      final base62Chars = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
      
      print('=== Box ID文字チェック ===');
      for (int i = 0; i < boxId.length; i++) {
        final char = boxId[i];
        final isValid = base62Chars.contains(char);
        print('$char: ${isValid ? "✅" : "❌"}');
      }
    });
  });
}
