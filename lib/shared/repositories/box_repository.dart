/*
====================================================
目的:
  - Riverpodプロバイダーの定義
  - 依存性注入の管理

処理構造:
  - Firestore/Storageサービスのプロバイダー
  - 状態管理プロバイダー
====================================================
*/

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

/// Firestoreサービスのプロバイダー
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

/// Storageサービスのプロバイダー
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});
