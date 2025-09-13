# Google Apps Script デプロイメントガイド

## Google Apps Scriptを使用したGoogle Forms API代替実装

### セットアップ手順

#### 1. Google Apps Scriptプロジェクトの作成

1. [Google Apps Script](https://script.google.com/) にアクセス
2. 「新しいプロジェクト」をクリック
3. プロジェクト名を「Forms API Service」に変更

#### 2. コードのデプロイ

1. `forms_api.gs` の内容をコピー
2. Google Apps Scriptエディタに貼り付け
3. 「プロジェクトを保存」（Ctrl+S または Cmd+S）

#### 3. Web Appとしてデプロイ

1. エディタ右上の「デプロイ」ボタンをクリック
2. 「新しいデプロイ」を選択
3. 設定：
   - **種類**: ウェブアプリ
   - **説明**: Forms API v1
   - **次のユーザーとして実行**: 自分
   - **アクセスできるユーザー**: 全員
4. 「デプロイ」をクリック
5. **Web AppのURLをコピーして保存**

#### 4. Firebase Functionsの環境変数に設定

コピーしたWeb App URLを使用して、Firebase Functionsから呼び出します。

```bash
# Firebase Functions環境変数に設定
firebase functions:config:set googleappsscript.url="コピーしたWeb App URL"
```

### 重要な注意事項

- **アクセス権限**: 「全員」に設定することで、認証なしでアクセス可能
- **実行権限**: 「自分」として実行するため、作成されるフォームはあなたのGoogleアカウント所有
- **レート制限**: Google Apps Scriptには実行時間と回数の制限があります

### テスト方法

1. Google Apps Scriptエディタで「test」関数を実行
2. 実行ログを確認してフォームが作成されることを確認

### トラブルシューティング

- **403エラー**: デプロイ設定の「アクセスできるユーザー」を確認
- **500エラー**: コードにエラーがないか確認
- **タイムアウト**: 処理時間が長すぎる場合は質問数を減らす