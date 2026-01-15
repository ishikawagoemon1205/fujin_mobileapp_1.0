# Firebase Storage セットアップガイド

## 📋 概要
封神アプリで写真アップロード機能を使用するために、Firebase Storageを有効化し、適切なセキュリティルールを設定します。

---

## 🚀 セットアップ手順

### 1. Firebase Console でStorageを有効化

#### 手順
1. [Firebase Console](https://console.firebase.google.com/) にアクセス
2. プロジェクト「封神 (Fujin)」を選択
3. 左メニューから「**Storage**」をクリック
4. 「**始める**」または「**Get Started**」ボタンをクリック

#### セキュリティルールの選択
初期設定では以下の2つの選択肢が表示されます：

**本番環境モード（推奨）:**
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

**テストモード（開発時のみ）:**
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if true;
    }
  }
}
```

➡️ **Phase 1 (MVP) では「テストモード」を選択**
   - 認証機能がないため、誰でもアクセス可能にする必要があります
   - ⚠️ 本番リリース前に必ずルールを変更してください

5. 「**次へ**」をクリック
6. ロケーション（リージョン）を選択
   - 推奨: `asia-northeast1` (東京)
   - Firestoreと同じリージョンにすることを推奨
7. 「**完了**」をクリック

### 2. Storage バケット情報の確認

Storageが有効化されると、以下の情報が表示されます：

```
gs://your-project-id.appspot.com
```

この値は `firebase_options.dart` に自動的に設定されています。

---

## 🔒 セキュリティルール（Phase 1 用）

Phase 1では認証機能がないため、以下のルールを使用します：

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // boxes配下のファイルは誰でも読み書き可能（Phase 1のみ）
    match /boxes/{boxId}/{allPaths=**} {
      allow read, write: if true;
    }
  }
}
```

### ルールの設定方法

#### Firebase Console から設定
1. Firebase Console の Storage → **Rules** タブを選択
2. 上記のルールをコピー＆ペースト
3. 「**公開**」ボタンをクリック

#### Firebase CLI から設定（推奨）
```bash
# storage.rules ファイルを編集後、デプロイ
firebase deploy --only storage
```

---

## 📁 ストレージ構造

封神アプリでは以下のディレクトリ構造で画像を保存します：

```
boxes/
  {box-id}/
    photos/
      photo_0.jpg
      photo_1.jpg
      photo_2.jpg
      ...
      photo_9.jpg  (最大10枚)
```

### 例
```
boxes/
  B7K9M3X2/
    photos/
      photo_0.jpg
      photo_1.jpg
      photo_2.jpg
```

---

## 🧪 動作確認

### 1. アプリから写真アップロード
1. アプリを起動
2. 「新しく封印する」を選択
3. 写真を追加（カメラ撮影 or ギャラリーから選択）
4. 保管場所を入力
5. QRをスキャン
6. 「封印する」をタップ

### 2. Firebase Console で確認
1. Firebase Console → Storage → Files
2. `boxes/{box-id}/photos/` 配下にファイルが作成されていることを確認
3. ファイルをクリックして、画像が正しくアップロードされているか確認

### 3. アプリで確認
1. 「中身を確認する」を選択
2. QRをスキャン
3. 写真が正しく表示されることを確認

---

## ⚠️ 注意事項

### Phase 1（現在）
- **認証なし**: 誰でもStorageにアクセス可能
- **本番利用不可**: セキュリティリスクがあります
- **開発・テスト専用**: MVP検証目的でのみ使用

### Phase 2（次期バージョン）で対応すること
- ユーザー認証の実装
- セキュリティルールの厳格化
- ユーザーごとのアクセス制御

---

## 🔧 トラブルシューティング

### エラー: "Firebase Storage: Object 'xxx' does not exist."
**原因**: ファイルが削除されたか、パスが間違っています

**解決策**:
1. Firebase Console でファイルの存在を確認
2. Firestore の `storagePath` が正しいか確認

### エラー: "Firebase Storage: User does not have permission"
**原因**: Security Rules が厳しすぎます

**解決策**:
1. Firebase Console → Storage → Rules を確認
2. Phase 1では `allow read, write: if true;` になっているか確認

### エラー: "Failed to compress image"
**原因**: 画像ファイルが壊れているか、サポートされていない形式です

**解決策**:
1. JPEG/PNG 形式の画像を使用
2. 画像ファイルが正常に読み込めるか確認

---

## 📊 容量制限

### Firebase Spark プラン（無料）
- **Storage**: 5 GB まで無料
- **ダウンロード**: 1 GB/日 まで無料
- **アップロード**: 無制限（無料）

### 写真1枚あたりのサイズ
- 圧縮後: 約 200KB - 500KB
- 最大10枚/箱

### 概算
- 1箱あたり: 約 2-5 MB
- 5 GB で保存可能な箱数: **約 1,000 - 2,500 箱**

---

## 🔄 次のステップ（Phase 2）

Phase 2でセキュリティを強化する際のルール例：

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /boxes/{boxId}/{allPaths=**} {
      // 認証済みユーザーのみ読み取り可能
      allow read: if request.auth != null;
      
      // 箱の所有者のみ書き込み可能
      allow write: if request.auth != null 
        && request.auth.uid == resource.metadata.userId;
    }
  }
}
```

---

## 📝 チェックリスト

- [ ] Firebase Console で Storage を有効化
- [ ] ロケーションを `asia-northeast1` (東京) に設定
- [ ] Security Rules を Phase 1 用に設定
- [ ] アプリから写真をアップロードしてテスト
- [ ] Firebase Console でファイルが作成されていることを確認
- [ ] アプリで写真が正しく表示されることを確認

---

## 📚 参考資料

- [Firebase Storage 公式ドキュメント](https://firebase.google.com/docs/storage)
- [Security Rules リファレンス](https://firebase.google.com/docs/storage/security)
- [Flutter × Firebase Storage](https://firebase.flutter.dev/docs/storage/overview)
