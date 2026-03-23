/*
====================================================
目的:
  - 認証機能の例外クラス定義
  - domain 層で定義することで presentation 層が
    Firebase に依存せずにエラーハンドリングできる

処理構造:
  - 認証エラーコード別の例外クラス
  - Google サインインキャンセル例外
====================================================
*/

/// 認証処理で発生する例外の基底クラス
///
/// [code] Firebase Auth のエラーコードに対応する識別子
/// [description] ユーザー向けのエラーメッセージ
class AuthException implements Exception {
  final String code;
  final String description;

  const AuthException({
    required this.code,
    required this.description,
  });

  @override
  String toString() => 'AuthException($code): $description';
}

/// Google サインインがユーザーによってキャンセルされた場合の例外
class GoogleSignInCancelledException implements Exception {
  const GoogleSignInCancelledException();

  @override
  String toString() =>
      'GoogleSignInCancelledException: Google サインインがキャンセルされました';
}
