/*
====================================================
目的:
  - 友達申請送信ユースケース

処理構造:
  - 重複チェック
  - 申請の作成
  - 通知の作成
====================================================
*/

import '../repositories/friends_repository.dart';

/// 友達申請を送信する UseCase
class SendFriendRequestUseCase {
  final FriendsRepository _repository;

  const SendFriendRequestUseCase(this._repository);

  /// 友達申請を送信する
  ///
  /// [fromUid] 申請を送るユーザーの UID
  /// [toUid] 申請を受けるユーザーの UID
  Future<void> execute(String fromUid, String toUid) async {
    if (fromUid == toUid) {
      throw FriendRequestException('自分自身に友達申請は送れません');
    }

    final alreadyFriends = await _repository.areFriends(fromUid, toUid);
    if (alreadyFriends) {
      throw FriendRequestException('既に友達です');
    }

    final hasPending = await _repository.hasPendingRequest(fromUid, toUid);
    if (hasPending) {
      throw FriendRequestException('既に友達申請を送信済みです');
    }

    await _repository.sendFriendRequest(fromUid, toUid);
  }
}

/// 友達申請関連の例外
class FriendRequestException implements Exception {
  final String message;
  const FriendRequestException(this.message);

  @override
  String toString() => 'FriendRequestException: $message';
}
