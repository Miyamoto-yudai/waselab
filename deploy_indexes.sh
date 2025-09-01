#!/bin/bash

echo "Firestore インデックスをデプロイしています..."

# Firebase CLIがインストールされているか確認
if ! command -v firebase &> /dev/null; then
    echo "Firebase CLIがインストールされていません。"
    echo "以下のコマンドでインストールしてください:"
    echo "npm install -g firebase-tools"
    exit 1
fi

# Firebaseにログインしているか確認
firebase projects:list &> /dev/null
if [ $? -ne 0 ]; then
    echo "Firebaseにログインしてください:"
    firebase login
fi

# インデックスのデプロイ
echo "インデックスをデプロイ中..."
firebase deploy --only firestore:indexes

if [ $? -eq 0 ]; then
    echo "✅ インデックスのデプロイが完了しました！"
    echo "数分待ってから、アプリを再度試してください。"
else
    echo "❌ デプロイに失敗しました。"
    echo "手動でインデックスを作成する必要があります。"
fi