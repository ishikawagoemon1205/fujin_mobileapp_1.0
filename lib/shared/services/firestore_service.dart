/*
====================================================
目的:
  - Cloud Firestoreへのデータアクセス機能
  - 箱情報のCRUD操作

処理構造:
  - 箱の作成
  - 箱の取得
  - 箱の更新
  - 箱の削除
  - 箱の一覧取得
====================================================
*/

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/box_model.dart';

/// Firestoreサービス
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _boxesCollection =>
      _firestore.collection('boxes');

  /// 箱を作成する
  /// 
  /// [box] 作成する箱のデータ
  Future<void> createBox(Box box) async {
    await _boxesCollection.doc(box.boxId).set(box.toFirestore());
  }

  /// 箱を取得する
  /// 
  /// [boxId] 箱のID
  /// 
  /// Returns 箱のデータ、存在しない場合はnull
  Future<Box?> getBox(String boxId) async {
    final doc = await _boxesCollection.doc(boxId).get();
    
    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return Box.fromFirestore(boxId, doc.data()!);
  }

  /// 箱を更新する
  /// 
  /// [box] 更新する箱のデータ
  Future<void> updateBox(Box box) async {
    await _boxesCollection.doc(box.boxId).update(box.toFirestore());
  }

  /// 箱を削除する
  /// 
  /// [boxId] 削除する箱のID
  Future<void> deleteBox(String boxId) async {
    await _boxesCollection.doc(boxId).delete();
  }

  /// すべての箱を取得する（Phase 2）
  /// 
  /// Returns 箱のリスト
  Future<List<Box>> getAllBoxes() async {
    final snapshot = await _boxesCollection.get();
    
    return snapshot.docs.map((doc) {
      return Box.fromFirestore(doc.id, doc.data());
    }).toList();
  }

  /// 箱の一覧をストリームで取得する（Phase 2）
  /// 
  /// Returns 箱のリストのストリーム
  Stream<List<Box>> watchAllBoxes() {
    return _boxesCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Box.fromFirestore(doc.id, doc.data());
      }).toList();
    });
  }

  /// 最終閲覧日時を更新する
  /// 
  /// [boxId] 箱のID
  Future<void> updateLastViewedAt(String boxId) async {
    await _boxesCollection.doc(boxId).update({
      'metadata.lastViewedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 箱のステータスを更新する
  /// 
  /// [boxId] 箱のID
  /// [status] 新しいステータス
  Future<void> updateBoxStatus(String boxId, BoxStatus status) async {
    final updates = <String, dynamic>{
      'metadata.status': status.value,
      'metadata.updatedAt': FieldValue.serverTimestamp(),
    };

    if (status == BoxStatus.opened || status == BoxStatus.tampered) {
      updates['metadata.openedAt'] = FieldValue.serverTimestamp();
    }

    await _boxesCollection.doc(boxId).update(updates);
  }

  /// 履歴を追加する
  /// 
  /// [boxId] 箱のID
  /// [history] 追加する履歴
  Future<void> addHistory(String boxId, BoxHistory history) async {
    await _boxesCollection.doc(boxId).update({
      'history': FieldValue.arrayUnion([history.toMap()]),
    });
  }
}
