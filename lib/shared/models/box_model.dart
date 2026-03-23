/*
====================================================
目的:
  - 箱（Box）のデータモデル定義
  - アプリ全体で使用するドメインオブジェクト

処理構造:
  - データ構造の定義
  - ステータス管理
  - コピーメソッド
====================================================
*/

/// 箱のステータス
enum BoxStatus {
  sealed('sealed', '未開封'),
  opened('opened', '開封済み'),
  tampered('tampered', '破損');

  const BoxStatus(this.value, this.label);
  final String value;
  final String label;

  /// 文字列からステータスを取得する
  static BoxStatus fromString(String value) {
    return BoxStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => BoxStatus.sealed,
    );
  }
}

/// QR面の情報
class QRFace {
  final String faceId;
  final String qrCode;
  final DateTime scannedAt;
  final String checksum;

  const QRFace({
    required this.faceId,
    required this.qrCode,
    required this.scannedAt,
    required this.checksum,
  });
}

/// 写真情報
class BoxPhoto {
  final String url;
  final String storagePath;
  final DateTime uploadedAt;

  const BoxPhoto({
    required this.url,
    required this.storagePath,
    required this.uploadedAt,
  });
}

/// 箱の履歴情報
class BoxHistory {
  final DateTime timestamp;
  final String action;
  final String details;

  const BoxHistory({
    required this.timestamp,
    required this.action,
    required this.details,
  });
}

/// 箱のデータモデル
class Box {
  final String boxId;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final BoxStatus status;
  final String storageLocation;
  final int qrFaceCount;
  final DateTime? openedAt;
  final DateTime lastViewedAt;
  final Map<String, QRFace> faces;
  final List<BoxPhoto> photos;
  final String memo;
  final List<BoxHistory> history;

  const Box({
    required this.boxId,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    required this.storageLocation,
    required this.qrFaceCount,
    this.openedAt,
    required this.lastViewedAt,
    required this.faces,
    required this.photos,
    required this.memo,
    required this.history,
  });

  /// コピーを作成する
  Box copyWith({
    String? userId,
    DateTime? updatedAt,
    BoxStatus? status,
    String? storageLocation,
    DateTime? openedAt,
    DateTime? lastViewedAt,
    Map<String, QRFace>? faces,
    List<BoxPhoto>? photos,
    String? memo,
    List<BoxHistory>? history,
  }) {
    return Box(
      boxId: boxId,
      userId: userId ?? this.userId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      storageLocation: storageLocation ?? this.storageLocation,
      qrFaceCount: qrFaceCount,
      openedAt: openedAt ?? this.openedAt,
      lastViewedAt: lastViewedAt ?? this.lastViewedAt,
      faces: faces ?? this.faces,
      photos: photos ?? this.photos,
      memo: memo ?? this.memo,
      history: history ?? this.history,
    );
  }
}
