# Flutter実機デバッグログの確認方法

## 方法1: ターミナルでリアルタイム確認（推奨）

```bash
# Flutter起動中のターミナルで確認
# flutter run を実行したターミナルに [Flutter xxxxx] というログが表示されます

flutter run --verbose
```

## 方法2: Xcodeコンソールでフィルタリング

1. **Xcodeを開く**
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **デバイスでアプリを実行**
   - Xcodeで「Run」ボタンをクリック
   - またはターミナルで `flutter run` を実行

3. **コンソールでフィルタを設定**
   - Xcodeの下部の「Console」タブを開く
   - 検索ボックスに以下を入力:
     ```
     [Flutter
     ```
   - これでFlutterのデバッグログだけが表示されます

## 方法3: システムログから抽出（現在実行中のアプリ）

```bash
# リアルタイムでFlutterログを監視
xcrun simctl spawn booted log stream --predicate 'processImagePath contains "Runner"' --level debug | grep "\[Flutter"

# または実機の場合
idevicesyslog | grep "\[Flutter"
```

## 方法4: flutter logsコマンド

```bash
# アプリ実行後に別のターミナルで実行
flutter logs
```

## デバッグログの見方

追加したログは以下のフォーマットで出力されます:

```
[Flutter QRScan] Detected QR: fujin://bHWCBwSb/F5/AD7B
[Flutter QRScan] Valid QR code, processing...
[Flutter QRScan] Stopping scanner...
[Flutter QRScan] Scanner stopped
[Flutter QRScan] Calling onQRCodeDetected callback
[Flutter SealPage] onQRCodeDetected callback triggered
[Flutter SealPage] Delayed callback executing, mounted=true
[Flutter SealPage] Setting isScanning=false
[Flutter SealPage] Calling handleQRCodeScanned
[Flutter SealPage] handleQRCodeScanned called with: fujin://bHWCBwSb/F5/AD7B
```

## 白い画面になった場合のチェックポイント

ログで以下を確認してください:

1. **コールバックが呼ばれているか**
   ```
   [Flutter QRScan] Calling onQRCodeDetected callback
   ```

2. **setState が実行されているか**
   ```
   [Flutter SealPage] Setting isScanning=false
   ```

3. **build() が呼ばれているか**
   ```
   [Flutter SealPage] build() called, isScanning=false
   ```

4. **エラーが発生していないか**
   ```
   [Flutter QRScan] Callback error: ...
   ```

## 次のステップ

1. アプリを再起動
2. QRコードをスキャン
3. ターミナルまたはXcodeコンソールで `[Flutter` でフィルタ
4. 上記のログが出力されるか確認
5. どこで止まっているかを報告してください
