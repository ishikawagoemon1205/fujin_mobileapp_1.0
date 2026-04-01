/*
====================================================
目的:
  - 友達機能の Repository インターフェース定義

処理構造:
  - 友達申請の送信・承認・拒否
  - 友達一覧の取得
  - 友達削除
  - 招待リンク・トークン管理
====================================================
*/

import '../../../../shared/models/friend_model.dart';
import '../../../../shared/models/friend_request_model.dart';
import '../../../../shared/models/user_model.dart';

/// 友達機能の Repository インターフェース
abstract class FriendsRepository {
  /// 友達申請を送信する
  ///
  /// [fromUid] 申請を送るユーザーの UID
  /// [toUid] 申請を受けるユーザーの UID
  Future<void> sendFriendRequest(String fromUid, String toUid);

  /// 自分宛の未承認友達申請一覧を取得する
  ///
  /// [uid] 自分の UID
  Future<List<FriendRequest>> getPendingRequests(String uid);

  /// 友達申請を承認する
  ///
  /// [requestId] 承認する申請のドキュメントID
  Future<void> acceptFriendRequest(String requestId);

  /// 友達申請を拒否する
  ///
  /// [requestId] 拒否する申請のドキュメントID
  Future<void> declineFriendRequest(String requestId);

  /// 友達一覧を取得する
  ///
  /// [uid] 自分の UID
  Future<List<Friend>> getFriends(String uid);

  /// 友達を削除する（相互削除）
  ///
  /// [friendshipId] 削除する友達関係のドキュメントID
  Future<void> deleteFriend(String friendshipId);

  /// 招待リンク用のトークンを生成・保存する
  ///
  /// [fromUid] 招待を送るユーザーの UID
  ///
  /// Returns 生成されたトークン文字列
  Future<String> generateInviteToken(String fromUid);

  /// 招待トークンを検証して送信者情報を取得する
  ///
  /// [token] 検証するトークン
  ///
  /// Returns 送信者の UID、無効な場合はnull
  Future<String?> validateInviteToken(String token);

  /// 招待トークンを無効化する
  ///
  /// [token] 無効化するトークン
  Future<void> invalidateInviteToken(String token);

  /// UID からユーザー情報を取得する
  ///
  /// [uid] ユーザーの UID
  Future<AppUser?> getUserByUid(String uid);

  /// 既に友達関係にあるか判定する
  ///
  /// [uid1] ユーザー1の UID
  /// [uid2] ユーザー2の UID
  Future<bool> areFriends(String uid1, String uid2);

  /// 既に友達申請を送信済みか判定する
  ///
  /// [fromUid] 申請者の UID
  /// [toUid] 被申請者の UID
  Future<bool> hasPendingRequest(String fromUid, String toUid);
}
