/*
====================================================
目的:
  - 箱（Box）のデータモデル定義
  - FirestoreとDartオブジェクト間の変換

処理構造:
  - データ構造の定義
  - Firestore変換処理
  - ステータス管理
====================================================
*/

import 'package:cloud_firestore/cloud_firestore.dart';

/// 箱のステータス
enum BoxStatus {
  sealed('sealed', '未開封'),
  opened('opened', '開封済み'),
  tampered('tampered', '破損');

  const BoxStatus(this.value, this.label);
  final String value;
  final String label;

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

  Map<String, dynamic> toMap() {
    return {
      'qrCode': qrCode,
      'scannedAt': Timestamp.fromDate(scannedAt),
      'checksum': checksum,
    };
  }

  factory QRFace.fromMap(String faceId, Map<String, dynamic> map) {
    return QRFace(
      faceId: faceId,
      qrCode: map['qrCode'] as String,
      scannedAt: (map['scannedAt'] as Timestamp).toDate(),
      checksum: map['checksum'] as String,
    );
  }
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

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'storagePath': storagePath,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
    };
  }

  factory BoxPhoto.fromMap(Map<String, dynamic> map) {
    return BoxPhoto(
      url: map['url'] as String,
      storagePath: map['storagePath'] as String,
      uploadedAt: (map['uploadedAt'] as Timestamp).toDate(),
    );
  }
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

  Map<String, dynamic> toMap() {
    return {
      'timestamp': Timestamp.fromDate(timestamp),
      'action': action,
      'details': details,
    };
  }

  factory BoxHistory.fromMap(Map<String, dynamic> map) {
    return BoxHistory(
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      action: map['action'] as String,
      details: map['details'] as String,
    );
  }
}

/// 箱のデータモデル
class Box {
  final String boxId;
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

  /// Firestoreドキュメントに変換
  Map<String, dynamic> toFirestore() {
    return {
      'metadata': {
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'status': status.value,
        'storageLocation': storageLocation,
        'qrFaceCount': qrFaceCount,
        'openedAt': openedAt != null ? Timestamp.fromDate(openedAt!) : null,
        'lastViewedAt': Timestamp.fromDate(lastViewedAt),
      },
      'faces': faces.map((key, value) => MapEntry(key, value.toMap())),
      'contents': {
        'photos': photos.map((photo) => photo.toMap()).toList(),
        'memo': memo,
      },
      'history': history.map((h) => h.toMap()).toList(),
    };
  }

  /// Firestoreドキュメントから変換
  factory Box.fromFirestore(String boxId, Map<String, dynamic> doc) {
    final metadata = doc['metadata'] as Map<String, dynamic>;
    final facesData = doc['faces'] as Map<String, dynamic>? ?? {};
    final contents = doc['contents'] as Map<String, dynamic>;
    final historyData = doc['history'] as List<dynamic>? ?? [];

    return Box(
      boxId: boxId,
      createdAt: (metadata['createdAt'] as Timestamp).toDate(),
      updatedAt: (metadata['updatedAt'] as Timestamp).toDate(),
      status: BoxStatus.fromString(metadata['status'] as String),
      storageLocation: metadata['storageLocation'] as String,
      qrFaceCount: metadata['qrFaceCount'] as int,
      openedAt: metadata['openedAt'] != null
          ? (metadata['openedAt'] as Timestamp).toDate()
          : null,
      lastViewedAt: (metadata['lastViewedAt'] as Timestamp).toDate(),
      faces: facesData.map(
        (key, value) => MapEntry(
          key,
          QRFace.fromMap(key, value as Map<String, dynamic>),
        ),
      ),
      photos: (contents['photos'] as List<dynamic>)
          .map((p) => BoxPhoto.fromMap(p as Map<String, dynamic>))
          .toList(),
      memo: contents['memo'] as String,
      history: historyData
          .map((h) => BoxHistory.fromMap(h as Map<String, dynamic>))
          .toList(),
    );
  }

  /// コピーを作成
  Box copyWith({
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
