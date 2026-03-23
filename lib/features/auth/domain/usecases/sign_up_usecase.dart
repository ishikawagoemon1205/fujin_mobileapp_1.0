/*
====================================================
目的:
  - メールアドレスとパスワードによる新規アカウント作成

処理構造:
  - 入力バリデーション
  - Repository 経由でアカウント作成実行
====================================================
*/

import '../../../../shared/models/user_model.dart';
import '../repositories/auth_repository.dart';

/// 新規アカウントを作成する UseCase
class SignUpUseCase {
  final AuthRepository _repository;

  const SignUpUseCase(this._repository);

  /// アカウント作成を実行する
  ///
  /// [email] メールアドレス
  /// [password] パスワード
  ///
  /// Returns 作成されたユーザー情報
  Future<AppUser> execute({
    required String email,
    required String password,
  }) {
    return _repository.signUp(email: email, password: password);
  }
}
