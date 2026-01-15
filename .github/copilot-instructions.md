# 封神 (Fujin) - 開発仕様書

## 📋 目次
1. [アプリ概要](#アプリ概要)
2. [コアコンセプト](#コアコンセプト)
3. [技術スタック](#技術スタック)
4. [開発フェーズ](#開発フェーズ)
5. [機能仕様](#機能仕様)
6. [QRコード仕様](#qrコード仕様)
7. [データベース設計](#データベース設計)
8. [UI/UX設計](#uiux設計)
9. [セキュリティ設計](#セキュリティ設計)

---

## アプリ概要

### アプリ名
**封神 (Fujin / ふうじん)**

### 目的
段ボール箱や封筒などの「閉じた容器」の中身を記録・管理し、開封せずに内容物を確認できるようにする。複数のQRコードシールを使った「封印性の証明」により、未開封状態を検証可能にする革新的な管理システム。

### ターゲットユーザー
- 引越しや季節ごとの衣替えで多くの箱を保管する個人
- 倉庫管理が必要な小規模事業者
- 重要書類を封印保管したい企業・組織
- 遺品整理や長期保管が必要な家庭

---

## コアコンセプト

### 「封神プロトコル」
**空間的分散認証 + 物理的タンパーエビデンス**

1. **複数面認証**: 箱の複数面にQRシールを貼ることで封印性を高める
2. **開封検知**: 全てのQRが読み取れる = 未開封、1つでも読み取れない = 開封済み/破損
3. **ユーザー選択の柔軟性**: QRの枚数はユーザーが決定(1枚〜任意の枚数)
4. **非破壊確認**: 1枚のQRを読むだけで中身を確認可能

---

## 技術スタック

### フロントエンド
- **Framework**: Flutter (iOS / Android / Web対応)
- **状態管理**: Riverpod または Provider
- **ルーティング**: Beamer
- **QRスキャン**: mobile_scanner
- **画像処理**: image_picker, cached_network_image
- **ローカルストレージ**: shared_preferences, sqflite(Phase 2)

### バックエンド
- **Firebase Authentication**: ユーザー認証(Phase 2)
- **Cloud Firestore**: データベース
- **Firebase Storage**: 画像ストレージ
- **Firebase Cloud Functions**: サーバーサイドロジック(必要に応じて)

### 開発ツール
- **バージョン管理**: Git / GitHub
- **CI/CD**: GitHub Actions (将来的に)
- **デザイン**: Material Design 3
- **Linter**: flutter_lints

---

## 開発フェーズ

### Phase 1: MVP (Minimum Viable Product) 🎯 **現在のターゲット**
**目標**: 基本的な封印・確認・開封機能の実装

#### 実装機能
- ✅ 3つのメイン機能
  - 封印する (Seal)
  - 確認する (Verify)
  - 開封する (Unseal)
- ✅ QRコードスキャン機能
- ✅ 写真撮影・アップロード (最大10枚)
- ✅ メモ・保管場所の記録
- ✅ Firebase基本連携 (Firestore, Storage)
- ✅ シンプルなリスト表示

#### 技術的制約
- 認証機能は未実装 (匿名認証のみ)
- オンライン専用 (オフライン対応なし)
- 基本的なUI/UX

---

### Phase 2: ユーザー管理・高度な管理機能 📅 **次期開発**

#### 実装機能
- 🔐 **ユーザー認証・ログイン**
  - Firebase Authentication (Email/Password, Google Sign-in)
  - ユーザープロフィール管理
- 📊 **管理機能の強化**
  - 自分が封印した箱の一覧
  - 時系列表示 (カレンダー、タイムライン)
  - 封印日・開封日でのフィルタリング
- 🏠 **階層的な保管場所管理**
  - ロケーション階層: 家 → 部屋 → 場所
  - ツリービューでの視覚的管理
  - 場所ごとの箱の集計
- 🔍 **検索・フィルタリング**
  - キーワード検索
  - ステータス別フィルタ
  - 保管場所別フィルタ
- 📱 **オフライン対応**
  - ローカルキャッシュ (sqflite)
  - 未送信データの管理
  - オンライン復帰時の自動同期

---

### Phase 3: コラボレーション機能 🚀 **将来構想**

#### 実装機能
- 👥 **箱の共有機能**
  - 他のユーザーとの箱情報共有
  - 閲覧権限・編集権限の管理
  - 共有リンクの生成
- 👨‍👩‍👧‍👦 **家族・チーム管理**
  - グループ作成
  - グループ内での箱の共有
- 📈 **統計・ダッシュボード**
  - 封印箱の総数
  - 場所別の分布グラフ
  - 最近の活動履歴
- 🔔 **通知機能**
  - 長期未開封の箱のリマインダー
  - 共有箱の更新通知

---

## 機能仕様

### 1. 封印する (Seal) 🔒

#### 目的
箱の内容物を記録し、物理的に封印してQRシールをスキャンして封印状態を作り出す

#### フロー
1. ホーム画面で「新しく封印する」を選択
2. **内容物の登録（箱が開いている状態）**
   - 📷 写真撮影/選択 (最大10枚)
   - 📝 メモ入力 (自由記述)
   - 📍 保管場所入力 (テキスト入力)
3. **「QRスキャンへ進む」ボタンをタップ**
   - 画面に「箱を閉じてQRシールを貼ってください」と案内表示
4. **物理的な封印作業**
   - ユーザーが箱に中身を入れる
   - 箱を閉じる
   - QRシールを箱の各面に貼る
5. **QRコード連続スキャン**
   - 1枚目のQRをスキャン → box-idを取得
   - 「1枚目を読み取りました」表示
   - 「続けて次のQRを読み取ってください」
   - 2枚目以降をスキャン (任意の枚数)
   - スキャン完了後、情報入力画面に戻る
6. **「封印する」ボタンで保存**
7. 「封印完了!」メッセージ表示
8. Firestoreに保存 (status: "sealed")

#### 技術仕様
- 最初に情報入力画面を表示 (isScanning: false)
- 「QRスキャンへ進む」で QRスキャンモードに切り替え (isScanning: true)
- QRスキャン後、自動的に情報入力画面に戻る
- 同じbox-idのQRは複数枚登録可能
- 写真は圧縮してFirebase Storageにアップロード
- メタデータはFirestoreに保存

---

### 2. 確認する (Verify) 🔍

#### 目的
開封せずに箱の中身を確認する (最も頻繁に使用される機能)

#### フロー
1. ホーム画面で「中身を確認する」を選択
2. **任意の1面のQRをスキャン**
3. **箱情報を表示**
   ```
   ┌─────────────────────────┐
   │ 📦 段ボール箱 #B7K9M3   │
   ├─────────────────────────┤
   │ 📍 保管場所: 押入れ2F   │
   │ 📅 封印日: 2025/12/03   │
   │ 🔒 状態: 未開封 (3面)   │
   ├─────────────────────────┤
   │ 📷 写真 (3枚)           │
   │ [写真サムネイル表示]    │
   ├─────────────────────────┤
   │ 📝 メモ:                │
   │ 冬物の服、毛布類       │
   ├─────────────────────────┤
   │ [開封する]              │
   └─────────────────────────┘
   ```
4. 写真をタップで拡大表示可能
5. 「開封する」ボタンで開封フローへ遷移

#### 技術仕様
- box-idから箱情報を取得
- 最終確認日時を更新 (lastViewedAt)
- 写真はキャッシュして高速表示

---

### 3. 開封する (Unseal) 🔓

#### 目的
箱を開封し、封印状態を解除する。全QRの検証により正常開封か破損かを判定

#### フロー
1. 確認画面で「開封する」ボタンをタップ
2. 確認ダイアログ表示
   - 「この箱を開封しますか?」
   - 「登録した全てのQR(○枚)を順番にスキャンしてください」
3. **全QRの連続スキャン**
   - 「1/3枚目 ✅」「2/3枚目 ✅」と進捗表示
   - 全て成功 → 正常開封
   - 1枚でも失敗 → 破損検知
4. **結果表示**
   - ✅ 成功: 「正常に開封されました」(status: "opened")
   - ❌ 失敗: 「⚠️ QRコードが破損しています」(status: "tampered")
5. 開封日時を記録 (openedAt)

#### 技術仕様
- 登録時のface数と一致する必要がある
- スキャン順序は任意 (どの順番でもOK)
- タイムアウト: 5分以内に全QRをスキャン
- 履歴にアクション記録

---

## QRコード仕様

### フォーマット
```
fujin://{box-id}/{face-id}/{checksum}
```

### 各要素の説明

#### 1. box-id (8文字)
- 箱を一意に識別するID
- Base62エンコード (0-9, a-z, A-Z)
- 例: `B7K9M3X2`, `A1C4E8F2`

**生成方法**:
```dart
String generateBoxId() {
  const chars = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
  final random = Random.secure();
  return List.generate(8, (index) => chars[random.nextInt(chars.length)]).join();
}
```

#### 2. face-id (F1〜F9, FA, FB...)
- QRシールが貼られた面を識別
- F1, F2, F3... (最大62面まで対応可能)

#### 3. checksum (4文字)
- 改ざん検知用のチェックサム
- box-id + face-id から生成されるCRC16

**生成方法**:
```dart
String generateChecksum(String boxId, String faceId) {
  final input = '$boxId$faceId';
  final crc = Crc16().convert(utf8.encode(input));
  return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
}
```

### 実例
```
fujin://B7K9M3X2/F1/A3C9
fujin://B7K9M3X2/F2/B8D1
fujin://B7K9M3X2/F3/C2E7
```

### QRコード生成 (事前準備用)
Phase 1では事前印刷されたQRシールを使用するが、将来的にアプリ内生成も可能にする

```dart
// Phase 2以降で実装
import 'package:qr_flutter/qr_flutter.dart';

QrImageView(
  data: 'fujin://B7K9M3X2/F1/A3C9',
  version: QrVersions.auto,
  size: 200.0,
)
```

---

## データベース設計

### Firestore構造

```
users/ (Phase 2)
  {userId}/
    profile:
      - displayName: string
      - email: string
      - createdAt: timestamp

boxes/
  {box-id}/
    metadata:
      - userId: string (Phase 2)
      - createdAt: timestamp
      - updatedAt: timestamp
      - status: "sealed" | "opened" | "tampered"
      - storageLocation: string
      - qrFaceCount: number
      - openedAt: timestamp | null
      - lastViewedAt: timestamp
    
    faces:
      - F1:
          qrCode: "fujin://B7K9M3X2/F1/A3C9"
          scannedAt: timestamp
          checksum: "A3C9"
      - F2:
          qrCode: "fujin://B7K9M3X2/F2/B8D1"
          scannedAt: timestamp
          checksum: "B8D1"
      ... (登録された数だけ)
    
    contents:
      - photos: [
          { url: string, storagePath: string, uploadedAt: timestamp }
        ]
      - memo: string
    
    history:
      - [
          { timestamp: timestamp, action: "sealed", details: string }
          { timestamp: timestamp, action: "viewed", details: string }
          { timestamp: timestamp, action: "opened", details: string }
        ]
```

### Firebase Storage構造
```
boxes/
  {box-id}/
    photos/
      photo_1.jpg
      photo_2.jpg
      ...
```

### データ制約
- 写真: 最大10枚/箱
- 写真サイズ: 圧縮後 最大2MB/枚
- メモ: 最大1000文字
- 保管場所: 最大100文字

---

## UI/UX設計

### カラースキーム (Material Design 3)
```dart
final colorScheme = ColorScheme.fromSeed(
  seedColor: Colors.indigo,
  brightness: Brightness.light,
);

// プライマリカラー: Indigo (封印・信頼感)
// セカンダリカラー: Amber (警告・注意喚起)
// エラーカラー: Red (破損・不正)
```

### 画面構成

#### 1. ホーム画面
```
AppBar: 封神
├─ 📦 新しく封印する (大きなカードボタン)
├─ 🔍 中身を確認する (大きなカードボタン)
└─ 📂 封印済みリスト
    └─ ListTile (箱ごと)
```

#### 2. QRスキャン画面
- フルスクリーンカメラビュー
- 中央にスキャンガイド枠
- 下部に進捗表示 (「1/3枚スキャン済み」)
- 「スキップして登録へ」ボタン

#### 3. 封印登録画面
```
Form:
├─ 写真追加セクション (GridView, 最大10枚)
├─ メモ入力 (TextField, 複数行)
├─ 保管場所入力 (TextField)
└─ [封印する] ボタン
```

#### 4. 箱詳細画面
```
AppBar: 箱の詳細
├─ ステータスバッジ (Chip)
│   - 🟢 未開封 (緑)
│   - 🔵 開封済み (青)
│   - 🔴 破損 (赤)
├─ 保管場所 (ListTile)
├─ 封印日時 (ListTile)
├─ 写真ギャラリー (PageView)
├─ メモ (Card)
└─ [開封する] ボタン (FAB)
```

### ナビゲーション (Beamer)

```dart
final routerDelegate = BeamerDelegate(
  locationBuilder: RoutesLocationBuilder(
    routes: {
      '/': (context, state, data) => HomePage(),
      '/seal': (context, state, data) => SealPage(),
      '/scan': (context, state, data) => QRScanPage(),
      '/box/:boxId': (context, state, data) {
        final boxId = state.pathParameters['boxId']!;
        return BoxDetailPage(boxId: boxId);
      },
      '/unseal/:boxId': (context, state, data) {
        final boxId = state.pathParameters['boxId']!;
        return UnsealPage(boxId: boxId);
      },
    },
  ),
);
```

---

## セキュリティ設計

### 1. QRコード検証
- Checksumによる改ざん検知
- box-idとface-idの整合性チェック
- 重複スキャンの防止

### 2. Firebase Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Phase 1: 誰でも読み書き可能 (MVP)
    match /boxes/{boxId} {
      allow read, write: if true;
    }
    
    // Phase 2: ユーザー認証後
    match /boxes/{boxId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null 
        && request.resource.data.userId == request.auth.uid;
      allow update, delete: if request.auth != null 
        && resource.data.userId == request.auth.uid;
    }
    
    // Phase 3: 共有機能
    match /boxes/{boxId} {
      allow read: if request.auth != null 
        && (resource.data.userId == request.auth.uid 
            || request.auth.uid in resource.data.sharedWith);
    }
  }
}
```

### 3. データバリデーション
- 写真枚数: 最大10枚
- ファイルサイズ: 最大2MB/枚
- メモ長: 最大1000文字
- QRフォーマットの正規表現チェック

```dart
final qrRegex = RegExp(r'^fujin://[0-9a-zA-Z]{8}/F[0-9A-Z]+/[0-9A-F]{4}$');
```

---

## 開発ガイドライン

### コーディング規約

#### 全般
- **処理の中にコメントを入れない** - コメントは逃げ。変数名・関数名で処理内容を表現する
- **変数名・関数名は英語で記述** - 命名で処理内容が理解できるようにする
- **`dynamic`型は絶対に使用禁止** - `Object?`や適切な型定義を使用する
- Dart公式スタイルガイドに準拠
- flutter_lintsを使用
- コードは読みやすさと保守性を最優先
- 型安全性を徹底
- テストカバレッジ: 目標70%以上

#### ファイル冒頭のドキュメントコメント（必須）
すべてのDartファイルの冒頭に以下の形式でコメントを記載すること。非エンジニアでも概要が理解できるように記述する。

**重要:** 処理構造には具体的な関数名や変数名を記載せず、タイトルレベルで抽象的にまとめること。

```dart
/*
====================================================
目的:
  - このファイルが担う責務を1-2行で簡潔に記述

処理構造:
  - 初期化処理
  - データ取得・加工
  - UI描画/ビジネスロジック実行
  - エラーハンドリング
====================================================
*/
```

**例:**
```dart
/*
====================================================
目的:
  - QRコードをスキャンして箱の情報を取得・表示する画面

処理構造:
  - カメラ初期化
  - QRコードスキャン処理
  - 箱情報の取得と検証
  - UI描画
  - エラーハンドリング
====================================================
*/

class QRScanPage extends StatefulWidget {
  const QRScanPage({super.key});

  @override
  State<QRScanPage> createState() => _QRScanPageState();
}

class _QRScanPageState extends State<QRScanPage> {
  MobileScannerController? scannerController;
  
  @override
  void initState() {
    super.initState();
    initializeScanner();
  }
  
  Future<void> initializeScanner() async {
    scannerController = MobileScannerController();
  }
  
  Future<void> handleQRCodeDetected(BarcodeCapture capture) async {
    final scannedBoxId = extractBoxIdFromQRCode(capture.barcodes.first.rawValue);
    
    if (scannedBoxId == null) {
      showInvalidQRError();
      return;
    }
    
    final boxData = await fetchBoxById(scannedBoxId);
    navigateToBoxDetail(boxData);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MobileScanner(
        controller: scannerController,
        onDetect: handleQRCodeDetected,
      ),
    );
  }
}
```

#### Public APIのドキュメントコメント
すべてのpublic class、method、functionには以下の形式でドキュメントコメントを記載する。

```dart
/// QRコードから箱IDを抽出する
///
/// [qrCode] スキャンされたQRコードの文字列
/// 
/// Returns 抽出された箱ID、形式が不正な場合はnull
String? extractBoxIdFromQRCode(String? qrCode) {
  if (qrCode == null || !qrCode.startsWith('fujin://')) {
    return null;
  }
  
  final segments = qrCode.split('/');
  return segments.length >= 3 ? segments[2] : null;
}
```

### ファイル構造
```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/
│   ├── theme/
│   ├── utils/
│   └── router.dart
├── features/
│   ├── seal/
│   │   ├── data/
│   │   ├── domain/
│   │   ├── presentation/
│   │   └── seal_feature.dart
│   ├── verify/
│   └── unseal/
├── shared/
│   ├── models/
│   ├── repositories/
│   ├── services/
│   └── widgets/
└── firebase_options.dart
```

### 命名規則
- ファイル: `snake_case.dart`
- クラス: `PascalCase`
- 変数・関数: `camelCase`
- 定数: `kConstantName`
- プライベート: `_privateVariable`

---

## テスト戦略

### Unit Tests
- QRコード生成・検証ロジック
- Checksum計算
- データモデルのシリアライズ/デシリアライズ

### Widget Tests
- 各画面のUI表示
- フォームバリデーション
- ボタンのタップ動作

### Integration Tests
- 封印フローの完全動作
- QRスキャン → 登録 → 確認 → 開封
- Firebase連携

---

## リリース計画

### Phase 1: MVP (目標: 2026年Q1)
- [ ] プロジェクトセットアップ
- [ ] Firebase連携
- [ ] QRスキャン機能
- [ ] 3つのメイン機能実装
- [ ] 基本的なUI/UX
- [ ] 内部テスト

### Phase 2: ユーザー管理 (目標: 2026年Q2)
- [ ] 認証機能
- [ ] オフライン対応
- [ ] 階層的保管場所管理
- [ ] 検索・フィルタリング
- [ ] パフォーマンス最適化

### Phase 3: コラボレーション (目標: 2026年Q3-Q4)
- [ ] 共有機能
- [ ] グループ管理
- [ ] 統計・ダッシュボード
- [ ] 通知機能
- [ ] 多言語対応

---

## 参考資料

### QRコード関連
- QR Code Standard: ISO/IEC 18004
- CRC-16 Algorithm

### Firebase
- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire](https://firebase.flutter.dev/)

### Flutter
- [Flutter Documentation](https://flutter.dev/docs)
- [Beamer](https://pub.dev/packages/beamer)
- [mobile_scanner](https://pub.dev/packages/mobile_scanner)

---

## 変更履歴
- 2025/12/03: 初版作成
