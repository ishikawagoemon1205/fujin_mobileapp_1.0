/*
====================================================
目的:
  - アプリケーションのエントリーポイント
  - Firebaseの初期化とアプリ起動

処理構造:
  - Firebase初期化
  - Riverpodプロバイダースコープの設定
  - アプリケーションの起動
====================================================
*/

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'features/auth/data/repositories/firebase_auth_repository.dart';
import 'features/auth/presentation/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(FirebaseAuthRepository()),
      ],
      child: const FujinApp(),
    ),
  );
}
