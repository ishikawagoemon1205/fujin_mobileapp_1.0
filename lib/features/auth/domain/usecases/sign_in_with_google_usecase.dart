/*
====================================================
目的:
  - Google アカウントによるサインイン

処理構造:
  - Repository 経由でGoogleサインイン実行
====================================================
*/

import '../../../../shared/models/user_model.dart';
import '../repositories/auth_repository.dart';

/// Google アカウントでサインインする UseCase
class SignInWithGoogleUseCase {
  final AuthRepository _repository;

  const SignInWithGoogleUseCase(this._repository);

  /// Googleサインインを実行する
  ///
  /// Returns ログインしたユーザー情報
  Future<AppUser> execute() {
    return _repository.signInWithGoogle();
  }
}
