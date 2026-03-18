#!/bin/bash

# Android APKビルド & Firebase App Distribution アップロードスクリプト
# 使い方: ./deploy_android.sh [release-notes]

set -e

echo "🚀 封神 Android APK ビルド & デプロイ"
echo "======================================"

# 引数でリリースノートを受け取る
RELEASE_NOTES="${1:-新しいバージョンをリリースしました}"

# ステップ1: ビルド
echo ""
echo "📦 ステップ1: APKをビルド中..."
flutter clean
flutter pub get
flutter build apk --release

# ビルド結果を確認
APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
if [ ! -f "$APK_PATH" ]; then
    echo "❌ エラー: APKファイルが見つかりません"
    exit 1
fi

echo "✅ ビルド完了: $APK_PATH"
ls -lh "$APK_PATH"

# ステップ2: Firebase App Distributionにアップロード
echo ""
echo "📤 ステップ2: Firebase App Distributionにアップロード中..."

# Firebase CLIがインストールされているか確認
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLIがインストールされていません"
    echo "📦 インストール方法: npm install -g firebase-tools"
    exit 1
fi

# アップロード
firebase appdistribution:distribute "$APK_PATH" \
  --app 1:569091665840:android:e7e0d3c6b224820eacb075 \
  --groups testers \
  --release-notes "$RELEASE_NOTES"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ デプロイ完了！"
    echo ""
    echo "📋 次のステップ:"
    echo "   1. Firebase Console でテスターを招待"
    echo "      https://console.firebase.google.com/project/fujin-634db/appdistribution"
    echo "   2. テスターに招待メールが送信されます"
    echo "   3. テスターはFirebase App Distributionアプリからインストール"
else
    echo "❌ デプロイに失敗しました"
    exit 1
fi
