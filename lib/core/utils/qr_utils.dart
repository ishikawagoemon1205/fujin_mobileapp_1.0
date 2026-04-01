/*
====================================================
目的:
  - QRコードの生成・解析・検証を行うユーティリティ

処理構造:
  - QRコード文字列のパース
  - box-idとface-idの抽出
  - チェックサムの生成と検証
  - QRコードの生成（Phase 2用）
====================================================
*/

import 'dart:math';

/// QRコードのフォーマット: fujin://{box-id}/{face-id}/{checksum}
/// ユーザーQRのフォーマット: fujin-user://{uid}
class QRCodeUtils {
  QRCodeUtils._();

  static const String _scheme = 'fujin://';
  static const String _userScheme = 'fujin-user://';
  static const String _base62Chars =
      '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';

  /// box-idを生成する (8文字のBase62)
  static String generateBoxId() {
    final random = Random.secure();
    return List.generate(
      8,
      (index) => _base62Chars[random.nextInt(_base62Chars.length)],
    ).join();
  }

  /// face-idを生成する (F1, F2, F3...)
  static String generateFaceId(int faceNumber) {
    if (faceNumber < 1 || faceNumber > 62) {
      throw ArgumentError('Face number must be between 1 and 62');
    }
    
    if (faceNumber <= 9) {
      return 'F$faceNumber';
    }
    
    return 'F${_base62Chars[faceNumber + 9]}';
  }

  /// チェックサムを生成する (CRC16)
  /// 
  /// Node.jsの `crc` パッケージ v4.3.2 の crc16関数と互換性のある実装
  /// アルゴリズム: CRC-16-IBM/ANSI (polynomial: 0x8005), table-less reflected implementation
  /// - poly (normal): 0x8005
  /// - poly (reversed): 0xA001
  /// - init: 0x0000
  /// - xorOut: 0x0000
  /// - reflect input: true
  /// - reflect output: true
  static String generateChecksum(String boxId, String faceId) {
    final input = '$boxId$faceId';
    final bytes = input.codeUnits;

    // CRC-16-IBM reflected implementation (poly reversed 0xA001)
    int crc = 0x0000;

    for (final byte in bytes) {
      crc ^= (byte & 0xFF);
      for (int i = 0; i < 8; i++) {
        if ((crc & 0x0001) != 0) {
          crc = (crc >> 1) ^ 0xA001;
        } else {
          crc = crc >> 1;
        }
      }
      crc &= 0xFFFF;
    }

    return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
  }


  /// QRコード文字列を生成する
  static String generateQRCode(String boxId, String faceId) {
    final checksum = generateChecksum(boxId, faceId);
    return '$_scheme$boxId/$faceId/$checksum';
  }

  /// QRコード文字列をパースする
  /// 
  /// Returns パース結果のMap、失敗時はnull
  static Map<String, String>? parseQRCode(String qrCode) {
    if (!qrCode.startsWith(_scheme)) {
      return null;
    }

    final withoutScheme = qrCode.substring(_scheme.length);
    final segments = withoutScheme.split('/');

    if (segments.length != 3) {
      return null;
    }

    final boxId = segments[0];
    final faceId = segments[1];
    final checksum = segments[2];

    if (boxId.length != 8) {
      return null;
    }

    if (!faceId.startsWith('F') || faceId.length < 2) {
      return null;
    }

    if (checksum.length != 4) {
      return null;
    }

    return {
      'boxId': boxId,
      'faceId': faceId,
      'checksum': checksum,
      'qrCode': qrCode,
    };
  }

  /// QRコードの正当性を検証する
  /// 
  /// [qrCode] 検証するQRコード文字列
  /// 
  /// Returns 正当な場合true、不正な場合false
  static bool validateQRCode(String qrCode) {
    final parsed = parseQRCode(qrCode);
    if (parsed == null) {
      return false;
    }

    final boxId = parsed['boxId']!;
    final faceId = parsed['faceId']!;
    final checksum = parsed['checksum']!;

    final expectedChecksum = generateChecksum(boxId, faceId);
    return checksum == expectedChecksum;
  }

  /// QRコードからbox-idを抽出する
  /// 
  /// [qrCode] QRコード文字列
  /// 
  /// Returns box-id、失敗時はnull
  static String? extractBoxId(String qrCode) {
    final parsed = parseQRCode(qrCode);
    return parsed?['boxId'];
  }

  /// QRコードからface-idを抽出する
  /// 
  /// [qrCode] QRコード文字列
  /// 
  /// Returns face-id、失敗時はnull
  static String? extractFaceId(String qrCode) {
    final parsed = parseQRCode(qrCode);
    return parsed?['faceId'];
  }

  /// ユーザーQRコード文字列を生成する
  ///
  /// [uid] Firebase Auth の UID
  ///
  /// Returns fujin-user://{uid} 形式の文字列
  static String generateUserQRCode(String uid) {
    return '$_userScheme$uid';
  }

  /// ユーザーQRコードかどうか判定する
  ///
  /// [qrCode] QRコード文字列
  ///
  /// Returns ユーザーQRの場合true
  static bool isUserQR(String qrCode) {
    return qrCode.startsWith(_userScheme);
  }

  /// ユーザーQRコードから UID を抽出する
  ///
  /// [qrCode] ユーザーQRコード文字列
  ///
  /// Returns UID、形式が不正な場合はnull
  static String? extractUidFromUserQR(String qrCode) {
    if (!isUserQR(qrCode)) return null;
    final uid = qrCode.substring(_userScheme.length);
    if (uid.isEmpty) return null;
    return uid;
  }
}
