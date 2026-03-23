# 封神 (Fujin) - Mobile App

**「この梱包物は、誰にも開けられていない」ことをデジタルで証明するアプリ。**

QRコードシールを梱包物の開閉口に貼って封印し、スマートフォンで全シールを読み取ることで未開封を検証する、物理的改ざん検知システム。

## 📱 主な機能

| 機能 | 概要 |
|------|------|
| 🔒 **封印する** | 箱の中身を撮影・記録し、QRシールで封印状態をデジタル登録 |
| 🔍 **確認する** | QRコードをスキャンして封印状態と中身を確認（箱を開けずに） |
| 📦 **開封する** | 全QRを検証し、正常開封 or 破損（不正開封の可能性）を記録 |
| 📂 **封印一覧** | 登録した全ての箱をステータス別に一覧表示 |
| 📋 **箱詳細** | 箱の完全な情報（写真・メモ・QR情報・操作履歴）を表示 |

## 🔐 認証

- メールアドレス＋パスワード認証
- Google アカウント認証
- パスワードリセット（メール送信）
- 未ログインユーザーは全機能アクセス不可（認証ガード）

---

## 🚀 セットアップ

### 1. 依存関係のインストール

```bash
flutter pub get
```

### 2. Firebase の設定

本プロジェクトは Firebase（Firestore, Storage, Auth）を使用します。
`firebase_options.dart` は設定済みです。

#### Security Rules のデプロイ

```bash
# Firestore Rules
firebase deploy --only firestore:rules

# Storage Rules
./deploy_storage_rules.sh
```

### 3. アプリの起動

```bash
flutter run
```

---

## 📂 プロジェクト構造

Clean Architecture（presentation / domain / data の3層分離）を採用しています。

```
lib/
├── main.dart                 # エントリーポイント（Firebase初期化）
├── app.dart                  # ルートWidget（認証状態による画面切替）
├── core/                     # アプリ横断の基盤
│   ├── constants/           # 定数定義
│   ├── theme/               # テーマ設定（Material Design 3）
│   ├── utils/               # QRコードユーティリティ
│   └── router.dart          # Beamerルーティング定義
├── features/                 # 機能別モジュール（各3層構造）
│   ├── auth/                # 認証（ログイン・サインアップ・パスワードリセット）
│   ├── home/                # ホーム画面
│   ├── seal/                # 封印機能
│   ├── verify/              # 確認機能
│   ├── unseal/              # 開封機能
│   ├── box_list/            # 箱一覧
│   └── box_detail/          # 箱詳細
└── shared/                   # 機能横断の共有レイヤー
    ├── models/              # データモデル（Box, AppUser）
    ├── repositories/        # Riverpod Provider 定義
    └── widgets/             # 共有Widget（QRスキャン）
```

各 feature は以下の3層で構成されます：

| 層 | 責務 |
|----|------|
| `presentation/` | UI（Widget）と状態管理 |
| `domain/` | ビジネスロジック（UseCase）と Repository インターフェース |
| `data/` | 外部データアクセス（Firestore, Storage の実装） |

---

## 📚 ドキュメント

| 内容 | 参照先 |
|------|--------|
| Phase 1.0 の目的・機能要件 | [`docs/phase1.0/要件定義書.md`](docs/phase1.0/要件定義書.md) |
| Phase 1.0 の技術スタック・データモデル | [`docs/phase1.0/詳細設計書.md`](docs/phase1.0/詳細設計書.md) |
| Phase 1.1 の目的・Clean Architecture・認証要件 | [`docs/phase1.1/要件定義書.md`](docs/phase1.1/要件定義書.md) |
| Phase 1.1 の設計原則・ディレクトリ構成・認証フロー | [`docs/phase1.1/詳細設計書.md`](docs/phase1.1/詳細設計書.md) |
| クライアント保有特許の技術概要 | [`docs/patent/PATENT_SUMMARY.md`](docs/patent/PATENT_SUMMARY.md) |
| Copilot 向けプロジェクト規約 | [`.github/copilot-instructions.md`](.github/copilot-instructions.md) |

---

## 🛠️ 開発コマンド

```bash
# ビルド
flutter build apk      # Android
flutter build ios       # iOS

# テスト
flutter test

# コード解析
flutter analyze

# Firebase Rules デプロイ
firebase deploy --only firestore:rules
./deploy_storage_rules.sh
```

---

## � 開発フェーズ

| フェーズ | 状態 | 内容 |
|---------|------|------|
| Phase 1.0 | ✅ 完了 | 封印・確認・開封のMVP。Firebase連携。認証なし |
| Phase 1.1 | ✅ 完了 | Clean Architecture完全移行・ユーザー認証（Email+Google）・ドキュメント整理 |
| Phase 2 以降 | 📅 将来構想 | 共有・グループ管理・通知・統計 |

---

## 📝 コーディング規約

- **`dynamic` 型は絶対に使用禁止** — `Object?` または適切な型を使う
- **処理の途中にコメントを入れない** — 変数名・関数名で意図を表現する
- **全ファイル冒頭に目的と処理構造を記載**
- **全 public class / function にドキュメントコメント**

詳細は [`.github/copilot-instructions.md`](.github/copilot-instructions.md) を参照。

---

## 📄 ライセンス

Copyright © 2026 封神プロジェクト
