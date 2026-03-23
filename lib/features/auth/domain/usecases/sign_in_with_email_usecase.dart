/*
====================================================
目的:
  - メールアドレスとパスワードによるサインイン

処理構造:
  - 入力バリデーション
  - Repository 経由でサインイン実行
====================================================
*/

import '../../../../shared/models/user_model.dart';
import '../repositories/auth_repository.dart';

/// メールアドレスとパスワードでサインインする UseCase
class SignInWithEmailUseCase {
  final AuthRepository _repository;

  const SignInWithEmailUseCase(this._repository);

  /// サインインを実行する
  ///
  /// [email] メールアドレス
  /// [password] パスワード
  ///
  /// Returns ログインしたユーザー情報
  Future<AppUser> execute({
    required String email,
    required String password,
  }) {
    return _repository.signInWithEmail(email: email, password: password);
  }
}
