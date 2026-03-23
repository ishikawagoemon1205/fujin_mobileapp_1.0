/*
====================================================
目的:
  - Riverpod プロバイダーの集約定義
  - 各 feature の Repository / UseCase の依存性注入

処理構造:
  - Repository プロバイダー定義
  - UseCase プロバイダー定義
====================================================
*/

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/repositories/firebase_auth_repository.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/sign_out_usecase.dart';
import '../../features/box_detail/data/repositories/firestore_box_detail_repository.dart';
import '../../features/box_detail/domain/repositories/box_detail_repository.dart';
import '../../features/box_detail/domain/usecases/get_box_detail_usecase.dart';
import '../../features/box_list/data/repositories/firestore_box_list_repository.dart';
import '../../features/box_list/domain/repositories/box_list_repository.dart';
import '../../features/box_list/domain/usecases/get_all_boxes_usecase.dart';
import '../../features/seal/data/repositories/firestore_seal_repository.dart';
import '../../features/seal/domain/repositories/seal_repository.dart';
import '../../features/seal/domain/usecases/create_box_usecase.dart';
import '../../features/unseal/data/repositories/firestore_unseal_repository.dart';
import '../../features/unseal/domain/repositories/unseal_repository.dart';
import '../../features/unseal/domain/usecases/unseal_box_usecase.dart';
import '../../features/verify/data/repositories/firestore_verify_repository.dart';
import '../../features/verify/domain/repositories/verify_repository.dart';
import '../../features/verify/domain/usecases/get_box_usecase.dart';

/// 認証 Repository プロバイダー（AuthGate で再利用）
final authRepositoryImplProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
});

/// 封印 Repository プロバイダー
final sealRepositoryProvider = Provider<SealRepository>((ref) {
  return FirestoreSealRepository();
});

/// 確認 Repository プロバイダー
final verifyRepositoryProvider = Provider<VerifyRepository>((ref) {
  return FirestoreVerifyRepository();
});

/// 開封 Repository プロバイダー
final unsealRepositoryProvider = Provider<UnsealRepository>((ref) {
  return FirestoreUnsealRepository();
});

/// 箱詳細 Repository プロバイダー
final boxDetailRepositoryProvider = Provider<BoxDetailRepository>((ref) {
  return FirestoreBoxDetailRepository();
});

/// 箱一覧 Repository プロバイダー
final boxListRepositoryProvider = Provider<BoxListRepository>((ref) {
  return FirestoreBoxListRepository();
});

/// 封印 UseCase プロバイダー
final createBoxUseCaseProvider = Provider<CreateBoxUseCase>((ref) {
  return CreateBoxUseCase(ref.watch(sealRepositoryProvider));
});

/// 確認 UseCase プロバイダー
final getBoxUseCaseProvider = Provider<GetBoxUseCase>((ref) {
  return GetBoxUseCase(ref.watch(verifyRepositoryProvider));
});

/// 開封 UseCase プロバイダー
final unsealBoxUseCaseProvider = Provider<UnsealBoxUseCase>((ref) {
  return UnsealBoxUseCase(ref.watch(unsealRepositoryProvider));
});

/// 箱詳細 UseCase プロバイダー
final getBoxDetailUseCaseProvider = Provider<GetBoxDetailUseCase>((ref) {
  return GetBoxDetailUseCase(ref.watch(boxDetailRepositoryProvider));
});

/// 箱一覧 UseCase プロバイダー
final getAllBoxesUseCaseProvider = Provider<GetAllBoxesUseCase>((ref) {
  return GetAllBoxesUseCase(ref.watch(boxListRepositoryProvider));
});

/// サインアウト UseCase プロバイダー
final signOutUseCaseProvider = Provider<SignOutUseCase>((ref) {
  return SignOutUseCase(ref.watch(authRepositoryImplProvider));
});

/// 現在のユーザーID を取得するヘルパー Provider
final currentUserIdProvider = Provider<String?>((ref) {
  final authRepo = ref.watch(authRepositoryImplProvider);
  return authRepo.currentUser?.uid;
});
