/*
====================================================
目的:
  - Web側とFlutter側のCRC-16計算を詳細に比較

処理構造:
  - バイト単位での計算過程を出力
  - 中間値を確認
====================================================
*/

import 'package:flutter_test/flutter_test.dart';
import 'package:wcm_fujin_mobile_app/core/utils/qr_utils.dart';

void main() {
  test('CRC-16 詳細デバッグ', () {
    const input = 'bHWCBwSbF5';
    final bytes = input.codeUnits;
    
    print('=== 入力情報 ===');
    print('Input: $input');
    print('Input length: ${input.length}');
    print('Bytes (decimal): $bytes');
    print('Bytes (hex): ${bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
    
    // Web側の期待値
    const expectedCRC = 0xAD7B; // 44411
    print('\n=== Web側の結果 ===');
    print('Expected CRC (decimal): $expectedCRC');
    print('Expected CRC (hex): ${expectedCRC.toRadixString(16).toUpperCase()}');
    print('Expected CRC (binary): ${expectedCRC.toRadixString(2).padLeft(16, '0')}');
    
    // Flutter側の計算 (現在の実装)
    print('\n=== Flutter側の計算 (CCITT 0x1021) ===');
    int crc1 = 0xFFFF;
    for (int i = 0; i < bytes.length; i++) {
      final byte = bytes[i];
      crc1 ^= byte << 8;
      print('Byte $i: 0x${byte.toRadixString(16)} -> CRC after XOR: 0x${crc1.toRadixString(16).padLeft(4, '0')}');
      
      for (int j = 0; j < 8; j++) {
        if ((crc1 & 0x8000) != 0) {
          crc1 = (crc1 << 1) ^ 0x1021;
        } else {
          crc1 = crc1 << 1;
        }
      }
      crc1 &= 0xFFFF;
      print('  After shift: 0x${crc1.toRadixString(16).padLeft(4, '0')}');
    }
    
    print('\nFinal CRC: 0x${crc1.toRadixString(16).toUpperCase().padLeft(4, '0')}');
    print('Match: ${crc1 == expectedCRC}');
    
    // 別のバリアント試行: init=0x0000
    print('\n=== 試行2: init=0x0000 ===');
    int crc2 = 0x0000;
    for (final byte in bytes) {
      crc2 ^= byte << 8;
      for (int i = 0; i < 8; i++) {
        if ((crc2 & 0x8000) != 0) {
          crc2 = (crc2 << 1) ^ 0x1021;
        } else {
          crc2 = crc2 << 1;
        }
      }
      crc2 &= 0xFFFF;
    }
    print('CRC: 0x${crc2.toRadixString(16).toUpperCase().padLeft(4, '0')}');
    print('Match: ${crc2 == expectedCRC}');
    
    // 別のバリアント試行: XOR位置を変更
    print('\n=== 試行3: XOR at low byte ===');
    int crc3 = 0xFFFF;
    for (final byte in bytes) {
      crc3 ^= byte;
      for (int i = 0; i < 8; i++) {
        if ((crc3 & 0x0001) != 0) {
          crc3 = (crc3 >> 1) ^ 0x8408; // 0x1021 reversed
        } else {
          crc3 = crc3 >> 1;
        }
      }
    }
    print('CRC: 0x${crc3.toRadixString(16).toUpperCase().padLeft(4, '0')}');
    print('Match: ${crc3 == expectedCRC}');
    
    // 別のバリアント試行: XOR at low byte, init=0x0000
    print('\n=== 試行4: XOR at low byte, init=0x0000 ===');
    int crc4 = 0x0000;
    for (final byte in bytes) {
      crc4 ^= byte;
      for (int i = 0; i < 8; i++) {
        if ((crc4 & 0x0001) != 0) {
          crc4 = (crc4 >> 1) ^ 0x8408;
        } else {
          crc4 = crc4 >> 1;
        }
      }
    }
    print('CRC: 0x${crc4.toRadixString(16).toUpperCase().padLeft(4, '0')}');
    print('Match: ${crc4 == expectedCRC}');
  });
}
