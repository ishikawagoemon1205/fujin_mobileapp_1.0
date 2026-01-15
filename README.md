# 封神 (Fujin) - Mobile App

段ボール箱や封筒の中身を記録・管理し、開封せずに内容物を確認できる革新的な管理システム。

## 📱 アプリ概要

複数のQRコードシールを使った「封印性の証明」により、未開封状態を検証可能にする管理アプリ。

### 主な機能
- 🔒 **封印する**: 箱の中身を記録してQRシールで封印
- 🔍 **確認する**: QRコードをスキャンして中身を確認
- 📦 **封印一覧**: 封印した箱を一覧で管理

---

## 🚀 セットアップ

### 1. 依存関係のインストール

```bash
flutter pub get
```

### 2. Firebase の設定

#### Firestore
すでに設定済みです。

#### Storage（写真アップロード機能）
詳細は [FIREBASE_STORAGE_SETUP.md](./FIREBASE_STORAGE_SETUP.md) を参照してください。

**簡単な手順:**
1. [Firebase Console](https://console.firebase.google.com/) でStorageを有効化
2. ロケーション: `asia-northeast1` (東京)
3. テストモードで開始
4. Security Rulesをデプロイ:
   ```bash
   ./deploy_storage_rules.sh
   ```

### 3. アプリの起動

```bash
flutter run
```

---

## 📂 プロジェクト構造

```
lib/
├── main.dart                 # エントリーポイント
├── app.dart                  # アプリケーションルート
├── core/                     # コア機能
│   ├── constants/           # 定数
│   ├── theme/               # テーマ設定
│   ├── utils/               # ユーティリティ
│   └── router.dart          # ルーティング設定
├── features/                 # 機能別モジュール
│   ├── home/                # ホーム画面
│   ├── seal/                # 封印機能
│   ├── verify/              # 確認機能
│   ├── unseal/              # 開封機能
│   ├── box_list/            # 箱一覧
│   └── box_detail/          # 箱詳細
└── shared/                   # 共有モジュール
    ├── models/              # データモデル
    ├── repositories/        # リポジトリ
    ├── services/            # サービス（Firebase等）
    └── widgets/             # 共有ウィジェット
```

---

## 📚 ドキュメント

- [開発仕様書](./.github/copilot-instructions.md) - 詳細な設計・仕様
- [Firebase Storage セットアップ](./FIREBASE_STORAGE_SETUP.md) - ストレージ設定手順
- [QRコード仕様](./QR_CODE_SPECIFICATION.txt) - QRコードフォーマット
- [デバッグガイド](./DEBUG_LOG_GUIDE.md) - デバッグログの見方
- [特許概要](./PATENT_SUMMARY.md) - 「封神プロトコル」の特許情報

---

## 🛠️ 開発コマンド

### ビルド
```bash
# Android
flutter build apk

# iOS
flutter build ios
```

### テスト
```bash
flutter test
```

### コード解析
```bash
flutter analyze
```

### Firebase Rulesデプロイ
```bash
# Storage Rules
./deploy_storage_rules.sh

# Firestore Rules（将来）
firebase deploy --only firestore:rules
```

---

## 🔧 トラブルシューティング

### 写真がアップロードできない
→ [FIREBASE_STORAGE_SETUP.md](./FIREBASE_STORAGE_SETUP.md) の「トラブルシューティング」を参照

### QRコードがスキャンできない
→ カメラ権限が許可されているか確認

---

## 📝 開発ガイドライン

### コーディング規約
- **処理の中にコメントを入れない** - 変数名・関数名で処理内容を表現
- **`dynamic`型は絶対に使用禁止** - 適切な型定義を使用
- ファイル冒頭に必ず「目的」「処理構造」を記載

詳細は [開発仕様書](./.github/copilot-instructions.md) を参照。

---

## 📅 開発フェーズ

### Phase 1: MVP（現在）
- [x] 基本的な封印・確認・開封機能
- [x] QRコードスキャン
- [x] 写真アップロード
- [ ] ストレージ有効化・テスト

### Phase 2: ユーザー管理（次期）
- [ ] 認証機能
- [ ] オフライン対応
- [ ] 検索・フィルタリング

### Phase 3: コラボレーション（将来）
- [ ] 箱の共有機能
- [ ] グループ管理
- [ ] 統計ダッシュボード

---

## 📄 ライセンス

Copyright © 2026 封神プロジェクト

---

## 🤝 コントリビューション

開発に参加する場合は、必ず [開発仕様書](./.github/copilot-instructions.md) を読んでください。

