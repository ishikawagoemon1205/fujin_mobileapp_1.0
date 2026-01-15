#!/bin/bash

# Firebase Storage Security Rules デプロイスクリプト
# 使い方: ./deploy_storage_rules.sh

echo "🚀 Firebase Storage Security Rules をデプロイします..."

# Firebase CLIがインストールされているか確認
if ! command -v firebase &> /dev/null
then
    echo "❌ Firebase CLI がインストールされていません"
    echo "📦 インストール方法:"
    echo "   npm install -g firebase-tools"
    exit 1
fi

# ログイン状態を確認
firebase login:list &> /dev/null
if [ $? -ne 0 ]; then
    echo "🔐 Firebase にログインしてください"
    firebase login
fi

# Storage Rules のみをデプロイ
echo "📤 storage.rules をデプロイ中..."
firebase deploy --only storage --project fujin-634db

if [ $? -eq 0 ]; then
    echo "✅ デプロイ完了！"
    echo ""
    echo "📋 確認方法:"
    echo "   1. Firebase Console を開く"
    echo "   2. Storage → Rules タブを確認"
    echo "   3. ルールが反映されていることを確認"
else
    echo "❌ デプロイに失敗しました"
    exit 1
fi
