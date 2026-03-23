/*
====================================================
目的:
  - アプリユーザーのデータモデル定義
  - Firebase Auth のユーザー情報をアプリ内で扱う構造体

処理構造:
  - データ構造の定義
====================================================
*/

/// アプリユーザーのデータモデル
class AppUser {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final DateTime createdAt;

  const AppUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.createdAt,
  });
}
