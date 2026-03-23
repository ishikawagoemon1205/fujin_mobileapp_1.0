/*
====================================================
目的:
  - サインアウト処理

処理構造:
  - Repository 経由でサインアウト実行
====================================================
*/

import '../repositories/auth_repository.dart';

/// サインアウトする UseCase
class SignOutUseCase {
  final AuthRepository _repository;

  const SignOutUseCase(this._repository);

  /// サインアウトを実行する
  Future<void> execute() {
    return _repository.signOut();
  }
}
