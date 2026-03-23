/*
====================================================
目的:
  - 認証機能の Repository インターフェース定義
  - domain 層が data 層の実装に依存しないための抽象化

処理構造:
  - 認証操作の抽象メソッド定義
  - 認証状態の監視
====================================================
*/

import '../../../../shared/models/user_model.dart';

/// 認証 Repository のインターフェース
///
/// Firebase Auth などの具体的な認証実装を抽象化する。
/// data 層で実装を提供する。
abstract class AuthRepository {
  /// 現在のログインユーザーを取得する
  ///
  /// Returns 未ログインの場合はnull
  AppUser? get currentUser;

  /// 認証状態の変化を監視する
  ///
  /// Returns ログイン/ログアウト時にユーザー情報を流すStream
  Stream<AppUser?> get authStateChanges;

  /// メールアドレスとパスワードでサインインする
  ///
  /// [email] メールアドレス
  /// [password] パスワード
  ///
  /// Returns ログインしたユーザー情報
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  });

  /// Google アカウントでサインインする
  ///
  /// Returns ログインしたユーザー情報
  Future<AppUser> signInWithGoogle();

  /// メールアドレスとパスワードで新規アカウントを作成する
  ///
  /// [email] メールアドレス
  /// [password] パスワード
  ///
  /// Returns 作成されたユーザー情報
  Future<AppUser> signUp({
    required String email,
    required String password,
  });

  /// サインアウトする
  Future<void> signOut();

  /// パスワードリセットメールを送信する
  ///
  /// [email] リセットメール送信先
  Future<void> sendPasswordReset({required String email});
}
