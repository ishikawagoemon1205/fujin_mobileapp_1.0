/*
====================================================
目的:
  - 封印機能の Repository インターフェース定義
  - 封印作成・重複チェック・写真アップロード・グループ通知の抽象化

処理構造:
  - 箱の作成操作の抽象メソッド定義
  - 写真アップロード操作の抽象メソッド定義
  - グループメンバーへの通知送信の抽象メソッド定義
====================================================
*/

import 'dart:io';

import '../../../../shared/models/box_model.dart';

/// 封印機能の Repository インターフェース
abstract class SealRepository {
  /// 箱を新規作成する
  ///
  /// [box] 作成する箱データ
  Future<void> createBox(Box box);

  /// 指定したboxIdの箱が既に存在するか確認する
  ///
  /// [boxId] 確認対象の箱ID
  ///
  /// Returns 存在する場合はtrue
  Future<bool> boxExists(String boxId);

  /// 写真をアップロードしてURLを取得する
  ///
  /// [boxId] 箱のID
  /// [file] アップロードする画像ファイル
  /// [index] 写真のインデックス番号
  ///
  /// Returns アップロード結果のBoxPhoto
  Future<BoxPhoto> uploadPhoto({
    required String boxId,
    required File file,
    required int index,
  });

  /// グループの自分以外の全メンバーに封印完了通知を送る
  ///
  /// [groupId] グループID
  /// [senderUid] 封印を実行したユーザーのUID（この人には通知しない）
  /// [boxId] 封印した箱のID
  /// [storageLocation] 保管場所（通知本文に使用）
  Future<void> notifyGroupMembers({
    required String groupId,
    required String senderUid,
    required String boxId,
    required String storageLocation,
  });
}
