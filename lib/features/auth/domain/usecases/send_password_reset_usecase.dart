/*
====================================================
目的:
  - パスワードリセットメールの送信

処理構造:
  - Repository 経由でリセットメール送信
====================================================
*/

import '../repositories/auth_repository.dart';

/// パスワードリセットメールを送信する UseCase
class SendPasswordResetUseCase {
  final AuthRepository _repository;

  const SendPasswordResetUseCase(this._repository);

  /// パスワードリセットメールを送信する
  ///
  /// [email] リセットメール送信先
  Future<void> execute({required String email}) {
    return _repository.sendPasswordReset(email: email);
  }
}
