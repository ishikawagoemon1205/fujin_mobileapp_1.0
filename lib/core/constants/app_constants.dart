/*
====================================================
目的:
  - アプリケーション全体で使用する定数の定義

処理構造:
  - QRコード関連の定数
  - UI関連の定数
  - データ制約の定数
====================================================
*/

/// QRコード関連の定数
class QRConstants {
  QRConstants._();

  static const String scheme = 'fujin://';
  static const int boxIdLength = 8;
  static const int checksumLength = 4;
}

/// データ制約の定数
class DataConstraints {
  DataConstraints._();

  static const int maxPhotos = 10;
  static const int maxPhotoSizeBytes = 2 * 1024 * 1024; // 2MB
  static const int maxMemoLength = 1000;
  static const int maxStorageLocationLength = 100;
  static const int qrScanTimeoutMinutes = 5;
}

/// UI関連の定数
class UIConstants {
  UIConstants._();

  static const double defaultPadding = 16.0;
  static const double cardElevation = 4.0;
  static const double cardBorderRadius = 12.0;
}
