/*
====================================================
目的:
  - FCMトークンの取得とFirestoreへの保存
  - トークンリフレッシュ時の自動更新

処理構造:
  - FCMトークン取得
  - Firestore users/{uid} の fcmToken フィールドに保存
  - トークンリフレッシュのリスナー登録
====================================================
*/

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// FCMトークンの管理サービス
class FcmTokenService {
  static final FcmTokenService _instance = FcmTokenService._internal();
  factory FcmTokenService() => _instance;
  FcmTokenService._internal();

  StreamSubscription<String>? _tokenRefreshSubscription;
  String? _currentUid;

  /// FCMトークンを取得してFirestoreに保存する
  ///
  /// [uid] 現在ログイン中のユーザーUID
  Future<void> saveToken(String uid) async {
    _currentUid = uid;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _updateTokenInFirestore(uid, token);
      }
    } catch (e) {
      debugPrint('[FcmTokenService] Failed to get/save FCM token: $e');
    }

    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription =
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      if (_currentUid != null) {
        _updateTokenInFirestore(_currentUid!, newToken);
      }
    });
  }

  Future<void> _updateTokenInFirestore(String uid, String token) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': Timestamp.now(),
      });
      debugPrint('[FcmTokenService] FCM token saved for user $uid');
    } catch (e) {
      debugPrint('[FcmTokenService] Failed to update FCM token: $e');
    }
  }

  /// ログアウト時にトークンをクリアする
  Future<void> clearToken(String uid) async {
    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _currentUid = null;

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcmToken': FieldValue.delete(),
        'fcmTokenUpdatedAt': FieldValue.delete(),
      });
    } catch (e) {
      debugPrint('[FcmTokenService] Failed to clear FCM token: $e');
    }
  }

  /// リソースを解放する
  void dispose() {
    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _currentUid = null;
  }
}
