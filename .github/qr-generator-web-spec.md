# 封神QRコード発行システム - Web版仕様書 (React)

## 📋 目次
1. [システム概要](#システム概要)
2. [技術スタック推奨](#技術スタック推奨)
3. [QRコード仕様](#qrコード仕様)
4. [機能要件](#機能要件)
5. [API仕様](#api仕様)
6. [UI/UX設計](#uiux設計)
7. [データ連携](#データ連携)
8. [印刷仕様](#印刷仕様)
9. [セキュリティ考慮事項](#セキュリティ考慮事項)

---

## システム概要

### 目的
封神モバイルアプリで使用するQRコードシールを生成・印刷するためのWebアプリケーション

### 主要機能
1. **QRコード一括生成**: box-id + 複数face-idのQRコードセットを生成
2. **印刷レイアウト最適化**: A4用紙やシールシートに対応したレイアウト
3. **プレビュー機能**: 印刷前の確認
4. **CSV/PDFエクスポート**: 生成したQRコードの管理用データ出力
5. **Firestore連携**: 生成したbox-idをデータベースに事前登録(オプション)

---

## 技術スタック推奨

### フロントエンド
```json
{
  "framework": "React 18+",
  "language": "TypeScript",
  "buildTool": "Vite",
  "stateManagement": "Zustand または Jotai",
  "routing": "React Router v6",
  "styling": "TailwindCSS + shadcn/ui",
  "qrCodeGeneration": "qrcode.react",
  "pdfGeneration": "jsPDF + html2canvas",
  "printLayout": "react-to-print"
}
```

### バックエンド (オプション)
```json
{
  "backend": "Firebase (Firestore, Storage, Functions)",
  "alternative": "完全クライアントサイドでも可能"
}
```

### 推奨パッケージ
```bash
npm install react react-dom typescript
npm install @vitejs/plugin-react
npm install zustand # 状態管理
npm install react-router-dom
npm install tailwindcss postcss autoprefixer
npm install qrcode.react # QRコード生成
npm install jspdf html2canvas # PDF生成
npm install react-to-print # 印刷
npm install firebase # Firebase連携(オプション)
npm install crc # Checksum計算
```

---

## QRコード仕様

### フォーマット定義
封神アプリとの互換性を保つため、以下のフォーマットに厳密に従う必要があります。

```
fujin://{box-id}/{face-id}/{checksum}
```

### 各要素の詳細

#### 1. box-id (8文字)
- **文字セット**: Base62 (`0-9a-zA-Z`)
- **長さ**: 固定8文字
- **例**: `B7K9M3X2`, `A1C4E8F2`

**TypeScript実装例**:
```typescript
const BASE62_CHARS = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';

export function generateBoxId(): string {
  return Array.from({ length: 8 }, () => 
    BASE62_CHARS[Math.floor(Math.random() * BASE62_CHARS.length)]
  ).join('');
}
```

#### 2. face-id
- **フォーマット**: `F` + 番号 (F1, F2, F3, ..., F9, FA, FB, ...)
- **範囲**: F1〜F9, FA〜FZ, Fa〜Fz (最大62面まで対応可能)
- **推奨**: 通常は F1〜F6 (箱の6面分)

**TypeScript実装例**:
```typescript
export function generateFaceId(index: number): string {
  if (index < 1 || index > 62) {
    throw new Error('Face index must be between 1 and 62');
  }
  
  if (index <= 9) {
    return `F${index}`;
  }
  
  // 10以降はBase62で表現: FA, FB, ... FZ, Fa, Fb, ...
  const base62Index = index - 10;
  const base62Char = BASE62_CHARS[base62Index + 10]; // Skip 0-9
  return `F${base62Char}`;
}
```

#### 3. checksum (4文字)
- **アルゴリズム**: CRC-16
- **入力**: `box-id` + `face-id` の結合文字列
- **出力**: 16進数大文字4桁 (例: `A3C9`, `B8D1`)

**TypeScript実装例**:
```typescript
import crc from 'crc';

export function generateChecksum(boxId: string, faceId: string): string {
  const input = boxId + faceId;
  const crcValue = crc.crc16(input);
  return crcValue.toString(16).toUpperCase().padStart(4, '0');
}
```

### 完全なQRコード生成関数

```typescript
export interface QRCodeData {
  boxId: string;
  faceId: string;
  checksum: string;
  fullUrl: string;
}

export function generateQRCode(boxId: string, faceIndex: number): QRCodeData {
  const faceId = generateFaceId(faceIndex);
  const checksum = generateChecksum(boxId, faceId);
  const fullUrl = `fujin://${boxId}/${faceId}/${checksum}`;
  
  return {
    boxId,
    faceId,
    checksum,
    fullUrl,
  };
}

export function generateQRCodeSet(boxId: string, faceCount: number): QRCodeData[] {
  return Array.from({ length: faceCount }, (_, i) => 
    generateQRCode(boxId, i + 1)
  );
}
```

---

## 機能要件

### 1. QRコード生成画面

#### 入力項目
```typescript
interface QRGenerationForm {
  // 必須項目
  faceCount: number; // QRコードの枚数 (1〜62)
  
  // オプション項目
  boxId?: string; // 指定しない場合は自動生成
  setCount: number; // 一度に生成するセット数 (デフォルト: 1)
  
  // レイアウト設定
  layoutType: 'A4' | 'Label_24' | 'Label_48' | 'Custom';
  qrSize: number; // QRコードのサイズ (mm)
  includeText: boolean; // box-idをテキストでも表示するか
}
```

#### バリデーション
- `faceCount`: 1以上62以下の整数
- `setCount`: 1以上100以下の整数
- `qrSize`: 10mm以上100mm以下

#### UI例
```tsx
<form>
  <label>
    QRコードの枚数 (箱の面の数):
    <input type="number" min="1" max="62" defaultValue="6" />
    <span className="hint">通常は6枚(箱の6面分)を推奨</span>
  </label>
  
  <label>
    生成するセット数:
    <input type="number" min="1" max="100" defaultValue="1" />
    <span className="hint">複数の箱分をまとめて生成できます</span>
  </label>
  
  <label>
    レイアウト:
    <select>
      <option value="A4">A4用紙 (6面/ページ)</option>
      <option value="Label_24">24面ラベルシート</option>
      <option value="Label_48">48面ラベルシート</option>
      <option value="Custom">カスタム</option>
    </select>
  </label>
  
  <label>
    QRコードサイズ:
    <input type="range" min="10" max="100" defaultValue="30" />
    <span>{qrSize}mm</span>
  </label>
  
  <label>
    <input type="checkbox" defaultChecked />
    box-idをテキストでも表示する
  </label>
  
  <button type="submit">生成する</button>
</form>
```

---

### 2. プレビュー画面

#### 表示内容
```typescript
interface QRCodeSet {
  id: string; // セットのID (UUID)
  boxId: string;
  qrCodes: QRCodeData[];
  createdAt: Date;
}
```

#### UI構成
```tsx
<div className="preview-container">
  {/* ヘッダー */}
  <div className="header">
    <h2>生成されたQRコード</h2>
    <div className="actions">
      <button onClick={handlePrint}>印刷</button>
      <button onClick={handleDownloadPDF}>PDFダウンロード</button>
      <button onClick={handleDownloadCSV}>CSVダウンロード</button>
      <button onClick={handleSaveToFirestore}>Firestoreに保存</button>
    </div>
  </div>
  
  {/* QRコード一覧 */}
  {qrCodeSets.map(set => (
    <div key={set.id} className="qr-set">
      <h3>Box ID: {set.boxId}</h3>
      <div className="qr-grid">
        {set.qrCodes.map(qr => (
          <div key={qr.faceId} className="qr-item">
            <QRCodeSVG value={qr.fullUrl} size={qrSize} />
            {includeText && (
              <div className="qr-text">
                <div className="box-id">{qr.boxId}</div>
                <div className="face-id">{qr.faceId}</div>
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  ))}
</div>
```

---

### 3. 印刷レイアウト

#### A4用紙レイアウト (推奨)
```typescript
const A4_LAYOUT = {
  pageWidth: 210, // mm
  pageHeight: 297, // mm
  margin: 10, // mm
  columns: 3,
  rows: 2,
  qrSize: 50, // mm
  gap: 10, // mm
};
```

#### 24面ラベルシートレイアウト
```typescript
const LABEL_24_LAYOUT = {
  pageWidth: 210, // mm (A4)
  pageHeight: 297, // mm
  margin: 5, // mm
  columns: 3,
  rows: 8,
  qrSize: 25, // mm
  gap: 5, // mm
};
```

#### React Component例
```tsx
import { useRef } from 'react';
import { useReactToPrint } from 'react-to-print';
import { QRCodeSVG } from 'qrcode.react';

interface PrintLayoutProps {
  qrCodeSets: QRCodeSet[];
  layout: typeof A4_LAYOUT;
  includeText: boolean;
}

export const PrintLayout: React.FC<PrintLayoutProps> = ({
  qrCodeSets,
  layout,
  includeText,
}) => {
  const printRef = useRef<HTMLDivElement>(null);
  
  const handlePrint = useReactToPrint({
    content: () => printRef.current,
    pageStyle: `
      @page {
        size: A4;
        margin: ${layout.margin}mm;
      }
      @media print {
        body { -webkit-print-color-adjust: exact; }
      }
    `,
  });
  
  return (
    <>
      <button onClick={handlePrint}>印刷</button>
      
      <div ref={printRef} className="print-container">
        {qrCodeSets.map(set => (
          <div key={set.id} className="page" style={{
            width: `${layout.pageWidth}mm`,
            height: `${layout.pageHeight}mm`,
            padding: `${layout.margin}mm`,
            display: 'grid',
            gridTemplateColumns: `repeat(${layout.columns}, 1fr)`,
            gridTemplateRows: `repeat(${layout.rows}, 1fr)`,
            gap: `${layout.gap}mm`,
            pageBreakAfter: 'always',
          }}>
            {set.qrCodes.map(qr => (
              <div key={qr.faceId} className="qr-cell" style={{
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                justifyContent: 'center',
                border: '1px dashed #ccc',
              }}>
                <QRCodeSVG
                  value={qr.fullUrl}
                  size={layout.qrSize * 3.78} // mm to px (96dpi)
                  level="H"
                  includeMargin={true}
                />
                {includeText && (
                  <div style={{
                    fontSize: '8pt',
                    fontFamily: 'monospace',
                    textAlign: 'center',
                    marginTop: '4px',
                  }}>
                    <div style={{ fontWeight: 'bold' }}>{qr.boxId}</div>
                    <div>{qr.faceId}</div>
                  </div>
                )}
              </div>
            ))}
          </div>
        ))}
      </div>
    </>
  );
};
```

---

### 4. エクスポート機能

#### CSV出力
```typescript
export function generateCSV(qrCodeSets: QRCodeSet[]): string {
  const headers = ['Set ID', 'Box ID', 'Face ID', 'Checksum', 'Full URL', 'Created At'];
  
  const rows = qrCodeSets.flatMap(set =>
    set.qrCodes.map(qr => [
      set.id,
      qr.boxId,
      qr.faceId,
      qr.checksum,
      qr.fullUrl,
      set.createdAt.toISOString(),
    ])
  );
  
  return [
    headers.join(','),
    ...rows.map(row => row.join(',')),
  ].join('\n');
}

export function downloadCSV(qrCodeSets: QRCodeSet[], filename: string = 'qr-codes.csv') {
  const csv = generateCSV(qrCodeSets);
  const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
  const link = document.createElement('a');
  link.href = URL.createObjectURL(blob);
  link.download = filename;
  link.click();
}
```

#### PDF出力
```typescript
import jsPDF from 'jspdf';
import html2canvas from 'html2canvas';

export async function generatePDF(
  element: HTMLElement,
  filename: string = 'qr-codes.pdf'
): Promise<void> {
  const canvas = await html2canvas(element, {
    scale: 2,
    useCORS: true,
  });
  
  const imgData = canvas.toDataURL('image/png');
  const pdf = new jsPDF({
    orientation: 'portrait',
    unit: 'mm',
    format: 'a4',
  });
  
  const imgWidth = 210; // A4 width in mm
  const imgHeight = (canvas.height * imgWidth) / canvas.width;
  
  pdf.addImage(imgData, 'PNG', 0, 0, imgWidth, imgHeight);
  pdf.save(filename);
}
```

---

## API仕様

### Firestore連携 (オプション)

#### データ構造
生成したQRコードをFirestoreに事前登録することで、モバイルアプリ側でのバリデーションを強化できます。

```typescript
// Firestore Collection: qr_codes
interface QRCodeDocument {
  boxId: string;
  faceIds: string[]; // ["F1", "F2", "F3", ...]
  qrCodes: {
    faceId: string;
    checksum: string;
    fullUrl: string;
  }[];
  createdAt: FirebaseFirestore.Timestamp;
  status: 'unused' | 'registered' | 'sealed';
  metadata?: {
    generatedBy?: string; // Web app version
    printedAt?: FirebaseFirestore.Timestamp;
  };
}
```

#### 登録処理
```typescript
import { collection, addDoc, Timestamp } from 'firebase/firestore';
import { db } from './firebase'; // Your Firebase config

export async function saveQRCodeSetToFirestore(
  qrCodeSet: QRCodeSet
): Promise<void> {
  const docData: QRCodeDocument = {
    boxId: qrCodeSet.boxId,
    faceIds: qrCodeSet.qrCodes.map(qr => qr.faceId),
    qrCodes: qrCodeSet.qrCodes.map(qr => ({
      faceId: qr.faceId,
      checksum: qr.checksum,
      fullUrl: qr.fullUrl,
    })),
    createdAt: Timestamp.now(),
    status: 'unused',
    metadata: {
      generatedBy: 'web-app-v1',
    },
  };
  
  await addDoc(collection(db, 'qr_codes'), docData);
}
```

#### モバイルアプリ側での検証
モバイルアプリは封印時に、このドキュメントの存在を確認し、`status`を更新します。

```typescript
// Mobile app (参考)
const qrCodeDoc = await getDoc(doc(db, 'qr_codes', boxId));
if (qrCodeDoc.exists() && qrCodeDoc.data().status === 'unused') {
  // 未使用QRコード → OK
  await updateDoc(doc(db, 'qr_codes', boxId), { status: 'sealed' });
} else {
  // 既に使用済みまたは存在しない → エラー
  throw new Error('Invalid or already used QR code');
}
```

---

## UI/UX設計

### デザインガイドライン

#### カラーパレット
モバイルアプリと統一感を持たせる

```typescript
const colors = {
  primary: '#3F51B5', // Indigo (封印・信頼感)
  secondary: '#FFC107', // Amber (警告・注意)
  success: '#4CAF50',
  error: '#F44336',
  background: '#FAFAFA',
  surface: '#FFFFFF',
  text: '#212121',
  textSecondary: '#757575',
};
```

#### タイポグラフィ
```css
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Roboto+Mono&display=swap');

body {
  font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
}

.qr-text, .box-id {
  font-family: 'Roboto Mono', 'Courier New', monospace;
}
```

### 画面フロー

```
┌─────────────────┐
│  ホーム画面     │
│  - 新規生成     │
│  - 履歴一覧     │
└────────┬────────┘
         │
         v
┌─────────────────┐
│  生成設定画面   │
│  - 枚数設定     │
│  - レイアウト   │
│  - オプション   │
└────────┬────────┘
         │
         v
┌─────────────────┐
│  プレビュー画面 │
│  - QR表示       │
│  - 印刷/DL      │
└────────┬────────┘
         │
         v
┌─────────────────┐
│  印刷/保存      │
│  - PDF/CSV      │
│  - Firestore    │
└─────────────────┘
```

### レスポンシブ対応

```tsx
// Tailwind CSS classes
<div className="container mx-auto px-4">
  {/* Mobile: 1 column, Tablet: 2 columns, Desktop: 3 columns */}
  <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
    {qrCodes.map(qr => (
      <div key={qr.faceId} className="qr-card">
        {/* QR Code */}
      </div>
    ))}
  </div>
</div>
```

---

## データ連携

### ローカルストレージ
生成履歴をブラウザに保存

```typescript
interface QRGenerationHistory {
  id: string;
  boxIds: string[];
  faceCount: number;
  createdAt: string;
  exported: boolean;
}

export function saveToLocalStorage(history: QRGenerationHistory): void {
  const existing = JSON.parse(localStorage.getItem('qr_history') || '[]');
  existing.push(history);
  localStorage.setItem('qr_history', JSON.stringify(existing));
}

export function getHistory(): QRGenerationHistory[] {
  return JSON.parse(localStorage.getItem('qr_history') || '[]');
}
```

### Firebase連携 (フルスタック構成の場合)

```typescript
// firebase.ts
import { initializeApp } from 'firebase/app';
import { getFirestore } from 'firebase/firestore';
import { getAuth } from 'firebase/auth';

const firebaseConfig = {
  apiKey: process.env.VITE_FIREBASE_API_KEY,
  authDomain: process.env.VITE_FIREBASE_AUTH_DOMAIN,
  projectId: process.env.VITE_FIREBASE_PROJECT_ID,
  storageBucket: process.env.VITE_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: process.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
  appId: process.env.VITE_FIREBASE_APP_ID,
};

const app = initializeApp(firebaseConfig);
export const db = getFirestore(app);
export const auth = getAuth(app);
```

---

## 印刷仕様

### プリンターの推奨設定

#### A4普通紙
- **用紙サイズ**: A4 (210 x 297 mm)
- **印刷品質**: 高品質 (300dpi以上)
- **カラー**: モノクロでOK (QRコードは白黒)
- **余白**: 10mm (設定で調整可能)

#### ラベルシール
推奨商品:
- **24面**: KOKUYO LBP-A96N (70 x 35 mm)
- **48面**: KOKUYO LBP-A97N (35 x 35 mm)

### 印刷時の注意事項

```tsx
// Print styles
const printStyles = `
  @media print {
    /* 背景色を印刷 */
    * {
      -webkit-print-color-adjust: exact !important;
      print-color-adjust: exact !important;
    }
    
    /* ページ区切り */
    .page {
      page-break-after: always;
    }
    
    /* 最後のページは区切らない */
    .page:last-child {
      page-break-after: auto;
    }
    
    /* 印刷時に非表示 */
    .no-print {
      display: none !important;
    }
  }
`;
```

### QRコードの品質設定

```tsx
<QRCodeSVG
  value={qrCode.fullUrl}
  size={256} // 大きめのサイズで生成
  level="H" // エラー訂正レベル: 最高 (30%まで復元可能)
  includeMargin={true}
  bgColor="#FFFFFF"
  fgColor="#000000"
/>
```

---

## セキュリティ考慮事項

### 1. box-idの衝突回避
```typescript
// 既存のbox-idをチェック (Firestore連携時)
export async function generateUniqueBoxId(): Promise<string> {
  let boxId: string;
  let exists = true;
  
  while (exists) {
    boxId = generateBoxId();
    const docRef = doc(db, 'qr_codes', boxId);
    const docSnap = await getDoc(docRef);
    exists = docSnap.exists();
  }
  
  return boxId!;
}
```

### 2. checksumの検証
Web側でも生成時に検証を実施

```typescript
export function validateQRCode(qrCode: QRCodeData): boolean {
  const expectedChecksum = generateChecksum(qrCode.boxId, qrCode.faceId);
  return qrCode.checksum === expectedChecksum;
}
```

### 3. 環境変数管理
```bash
# .env
VITE_FIREBASE_API_KEY=your_api_key
VITE_FIREBASE_AUTH_DOMAIN=your_auth_domain
VITE_FIREBASE_PROJECT_ID=your_project_id
VITE_FIREBASE_STORAGE_BUCKET=your_storage_bucket
VITE_FIREBASE_MESSAGING_SENDER_ID=your_sender_id
VITE_FIREBASE_APP_ID=your_app_id
```

```typescript
// .env を git管理から除外
// .gitignore
.env
.env.local
.env.production
```

---

## 開発ガイドライン

### プロジェクト構造 (推奨)

```
qr-generator-web/
├── src/
│   ├── components/
│   │   ├── QRGenerator/
│   │   │   ├── GeneratorForm.tsx
│   │   │   ├── QRPreview.tsx
│   │   │   └── PrintLayout.tsx
│   │   └── common/
│   │       ├── Button.tsx
│   │       └── Input.tsx
│   ├── utils/
│   │   ├── qrCodeUtils.ts  # QR生成ロジック
│   │   ├── checksumUtils.ts # Checksum計算
│   │   ├── exportUtils.ts   # CSV/PDF出力
│   │   └── printUtils.ts    # 印刷処理
│   ├── hooks/
│   │   ├── useQRGenerator.ts
│   │   └── useFirestore.ts
│   ├── store/
│   │   └── qrStore.ts       # Zustand store
│   ├── types/
│   │   └── qr.types.ts
│   ├── config/
│   │   ├── firebase.ts
│   │   └── layouts.ts       # 印刷レイアウト定義
│   ├── App.tsx
│   └── main.tsx
├── public/
├── .env
├── package.json
├── tsconfig.json
├── vite.config.ts
└── tailwind.config.js
```

### コーディング規約

#### TypeScript必須ルール
- **`any`型は禁止** - 必ず適切な型を定義
- **変数・関数名は英語** - 処理内容が明確になる命名
- **関数はPure Functionを優先** - 副作用を最小化
- **ESLint + Prettier** - コードフォーマット統一

#### ファイル冒頭のコメント
```typescript
/**
 * ====================================================
 * 目的:
 *   - QRコードの生成・検証ユーティリティ関数群
 * 
 * 処理構造:
 *   - box-id生成 (Base62, 8文字)
 *   - face-id生成 (F + Base62)
 *   - checksum計算 (CRC-16)
 *   - QRコード文字列組み立て
 *   - バリデーション
 * ====================================================
 */
```

### テスト戦略

```typescript
// qrCodeUtils.test.ts
import { describe, it, expect } from 'vitest';
import { generateBoxId, generateChecksum, validateQRCode } from './qrCodeUtils';

describe('QR Code Utils', () => {
  it('should generate 8-character box-id', () => {
    const boxId = generateBoxId();
    expect(boxId).toHaveLength(8);
    expect(/^[0-9a-zA-Z]{8}$/.test(boxId)).toBe(true);
  });
  
  it('should generate correct checksum', () => {
    const checksum = generateChecksum('B7K9M3X2', 'F1');
    expect(checksum).toHaveLength(4);
    expect(/^[0-9A-F]{4}$/.test(checksum)).toBe(true);
  });
  
  it('should validate QR code correctly', () => {
    const qrCode = generateQRCode('B7K9M3X2', 1);
    expect(validateQRCode(qrCode)).toBe(true);
  });
});
```

---

## 実装の優先順位

### Phase 1: 基本機能 (必須)
- [x] QRコード生成ロジック (box-id, face-id, checksum)
- [x] 生成フォーム (枚数、セット数)
- [x] プレビュー表示
- [x] A4用紙印刷レイアウト
- [x] CSV/PDFエクスポート

### Phase 2: 高度な機能 (推奨)
- [ ] Firestore連携 (事前登録)
- [ ] 複数レイアウト対応 (ラベルシート)
- [ ] 生成履歴管理 (LocalStorage)
- [ ] バッチ生成 (複数セット)

### Phase 3: 拡張機能 (オプション)
- [ ] ユーザー認証 (Firebase Auth)
- [ ] クラウド保存 (Firestore)
- [ ] QRコードデザインカスタマイズ
- [ ] 多言語対応

---

## 動作確認チェックリスト

### 生成機能
- [ ] box-idが8文字のBase62で生成される
- [ ] face-idが正しいフォーマット (F1, F2, ...)
- [ ] checksumがCRC-16で正しく計算される
- [ ] 生成したQRコードが `fujin://` で始まる

### 表示機能
- [ ] QRコードが正しくレンダリングされる
- [ ] box-idとface-idのテキストが表示される
- [ ] レスポンシブデザインが機能する

### 印刷機能
- [ ] A4用紙に正しくレイアウトされる
- [ ] QRコードが読み取れるサイズで印刷される
- [ ] ページ区切りが適切に動作する

### エクスポート機能
- [ ] CSVファイルが正しい形式で出力される
- [ ] PDFファイルが生成される
- [ ] ファイル名が適切に設定される

### モバイルアプリ連携
- [ ] 生成したQRコードをモバイルアプリでスキャンできる
- [ ] checksumが正しく検証される
- [ ] 複数のQRコードが同じbox-idで認識される

---

## トラブルシューティング

### QRコードがスキャンできない
- **QRコードのサイズを大きくする**: 最低30mm推奨
- **エラー訂正レベルを上げる**: `level="H"`
- **印刷品質を上げる**: 300dpi以上

### checksumが一致しない
- **CRCアルゴリズムの確認**: Dart版とJavaScript版で同じライブラリを使用
- **文字エンコーディング**: UTF-8で統一
- **大文字小文字**: checksumは大文字で統一

### Firestore保存エラー
- **認証の確認**: Firebase Authが正しく設定されているか
- **Security Rulesの確認**: 書き込み権限があるか
- **ネットワーク**: インターネット接続を確認

---

## 参考資料

### QRコード
- [QR Code Specification (ISO/IEC 18004)](https://www.iso.org/standard/62021.html)
- [qrcode.react Documentation](https://www.npmjs.com/package/qrcode.react)

### CRC-16
- [CRC Wikipedia](https://en.wikipedia.org/wiki/Cyclic_redundancy_check)
- [crc npm package](https://www.npmjs.com/package/crc)

### React / TypeScript
- [React Documentation](https://react.dev/)
- [TypeScript Handbook](https://www.typescriptlang.org/docs/)
- [Vite Documentation](https://vitejs.dev/)

### Firebase
- [Firebase Web Documentation](https://firebase.google.com/docs/web/setup)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)

---

## 変更履歴
- 2025/12/04: 初版作成 (Reactベース仕様書)

---

## モバイルアプリとの互換性マトリクス

| 項目 | Web (React) | Mobile (Flutter) | 互換性 |
|------|-------------|------------------|--------|
| box-id形式 | Base62, 8文字 | Base62, 8文字 | ✅ |
| face-id形式 | F + Base62 | F + Base62 | ✅ |
| checksum | CRC-16 | CRC-16 | ✅ |
| QRフォーマット | `fujin://...` | `fujin://...` | ✅ |
| Firestore構造 | `qr_codes` collection | `boxes` collection | △ 別コレクション |
| 画像圧縮 | - | JPEG, 2MB/枚 | - |

**注意**: WebとMobileでFirestoreのコレクションが異なる場合、連携処理が必要です。
