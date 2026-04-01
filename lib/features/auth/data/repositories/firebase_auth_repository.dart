/*
====================================================
目的:
  - Firebase Auth を使った認証 Repository の具体的実装
  - AuthRepository インターフェースの実装
  - Firebase 固有の例外を domain 層の AuthException に変換
  - 認証成功時に Firestore users コレクションへプロフィール自動保存

処理構造:
  - Firebase Auth 操作
  - Google Sign-In 操作
  - Firestore ユーザープロフィール保存
  - ユーザーモデル変換
  - 例外変換
====================================================
*/

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../shared/models/user_model.dart';
import '../../domain/exceptions/auth_exceptions.dart';
import '../../domain/repositories/auth_repository.dart';

/// Firebase Auth による認証 Repository 実装
class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  FirebaseAuthRepository({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  @override
  AppUser? get currentUser {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    return _toAppUser(user);
  }

  @override
  Stream<AppUser?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((user) {
      if (user == null) return null;
      return _toAppUser(user);
    });
  }

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final appUser = _toAppUser(credential.user!);
      await _saveUserProfile(credential.user!);
      return appUser;
    } on FirebaseAuthException catch (e) {
      throw AuthException(code: e.code, description: e.message ?? '');
    }
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn().timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw AuthException(
          code: 'google-sign-in-timeout',
          description: 'Google サインインがタイムアウトしました。'
              'iOS の場合、GoogleService-Info.plist に CLIENT_ID が'
              '設定されていない可能性があります。',
        ),
      );
      if (googleUser == null) {
        throw const GoogleSignInCancelledException();
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      final appUser = _toAppUser(userCredential.user!);
      await _saveUserProfile(userCredential.user!);
      return appUser;
    } on GoogleSignInCancelledException {
      rethrow;
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthException(code: e.code, description: e.message ?? '');
    } catch (e) {
      throw AuthException(
        code: 'google-sign-in-error',
        description: 'Google サインインに失敗しました: $e',
      );
    }
  }

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final appUser = _toAppUser(credential.user!);
      await _saveUserProfile(credential.user!);
      return appUser;
    } on FirebaseAuthException catch (e) {
      throw AuthException(code: e.code, description: e.message ?? '');
    }
  }

  @override
  Future<void> signOut() async {
    await FirebaseFirestore.instance.terminate();
    await FirebaseFirestore.instance.clearPersistence();
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }

  @override
  Future<void> sendPasswordReset({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(code: e.code, description: e.message ?? '');
    }
  }

  AppUser _toAppUser(User user) {
    return AppUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
    );
  }

  /// 認証成功時に Firestore users/{uid} へプロフィールを保存する
  ///
  /// 既存ドキュメントがある場合は merge で更新し、ユーザーが手動で設定した値を上書きしない。
  /// Google 認証時は displayName と photoUrl が Firebase Auth から取得できるため保存される。
  Future<void> _saveUserProfile(User user) async {
    final docRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      await docRef.set({
        'email': user.email ?? '',
        'displayName': user.displayName,
        'photoUrl': user.photoURL,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
    } else {
      final updateData = <String, Object?>{
        'email': user.email ?? '',
        'updatedAt': Timestamp.now(),
      };

      final existingData = doc.data()!;
      final existingDisplayName = existingData['displayName'] as String?;
      if ((existingDisplayName == null || existingDisplayName.isEmpty) &&
          user.displayName != null &&
          user.displayName!.isNotEmpty) {
        updateData['displayName'] = user.displayName;
      }

      final existingPhotoUrl = existingData['photoUrl'] as String?;
      if ((existingPhotoUrl == null || existingPhotoUrl.isEmpty) &&
          user.photoURL != null &&
          user.photoURL!.isNotEmpty) {
        updateData['photoUrl'] = user.photoURL;
      }

      await docRef.update(updateData);
    }
  }
}
