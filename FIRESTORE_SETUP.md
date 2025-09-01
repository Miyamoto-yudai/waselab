# Firestore セキュリティルールのセットアップ

## 問題の解決方法

メッセージ画面で「Missing or insufficient permissions」エラーが発生する問題を解決するため、Firestoreのセキュリティルールを設定する必要があります。

## 方法1: Firebase CLIを使用してデプロイ（推奨）

### 1. Firebase CLIのインストール
```bash
npm install -g firebase-tools
```

### 2. Firebaseにログイン
```bash
firebase login
```

### 3. プロジェクトの初期化（既に初期化済みの場合はスキップ）
```bash
firebase init
```
- Firestoreを選択
- 既存のプロジェクトを選択

### 4. ルールのデプロイ
```bash
firebase deploy --only firestore:rules
```

### 5. インデックスのデプロイ（パフォーマンス向上のため）
```bash
firebase deploy --only firestore:indexes
```

## 方法2: Firebase Consoleから直接設定

### 1. Firebase Consoleにアクセス
1. [Firebase Console](https://console.firebase.google.com)にアクセス
2. プロジェクトを選択

### 2. Firestoreルールを更新
1. 左メニューから「Firestore Database」を選択
2. 上部タブから「ルール」を選択
3. 以下のルールをコピーして貼り付け：

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper function to check if user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Helper function to check if user owns the document
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    // Users collection - users can read all profiles, write only their own
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow write: if isOwner(userId);
    }
    
    // Experiments collection - all authenticated users can read, only creators can write
    match /experiments/{experimentId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update, delete: if isAuthenticated() && 
        request.auth.uid == resource.data.creatorId;
    }
    
    // Conversations collection - users can only access conversations they're part of
    match /conversations/{conversationId} {
      allow read: if isAuthenticated() && 
        request.auth.uid in resource.data.participantIds;
      allow create: if isAuthenticated() && 
        request.auth.uid in request.resource.data.participantIds &&
        request.resource.data.participantIds.size() == 2;
      allow update: if isAuthenticated() && 
        request.auth.uid in resource.data.participantIds;
      allow delete: if false; // Conversations should not be deleted
    }
    
    // Messages collection - users can read/write messages in their conversations
    match /messages/{messageId} {
      allow read: if isAuthenticated() && 
        (request.auth.uid == resource.data.senderId || 
         request.auth.uid == resource.data.receiverId);
      allow create: if isAuthenticated() && 
        request.auth.uid == request.resource.data.senderId &&
        request.resource.data.senderId != null &&
        request.resource.data.receiverId != null &&
        request.resource.data.conversationId != null &&
        request.resource.data.content != null;
      allow update: if isAuthenticated() && 
        request.auth.uid == resource.data.receiverId &&
        // Only allow updating isRead field
        request.resource.data.diff(resource.data).affectedKeys().hasOnly(['isRead']);
      allow delete: if false; // Messages should not be deleted
    }
    
    // Allow reading and writing to any other collections for authenticated users (for future collections)
    match /{document=**} {
      allow read, write: if false; // Default deny for any other collections
    }
  }
}
```

4. 「公開」ボタンをクリック

### 3. インデックスの作成（オプション、推奨）
1. 「インデックス」タブを選択
2. 「インデックスを追加」をクリック
3. 以下のインデックスを追加：

#### conversations コレクション
- フィールド1: `participantIds` (配列)
- フィールド2: `lastMessageTime` (降順)

#### messages コレクション (インデックス1)
- フィールド1: `conversationId` (昇順)
- フィールド2: `createdAt` (昇順)

#### messages コレクション (インデックス2)
- フィールド1: `conversationId` (昇順)
- フィールド2: `receiverId` (昇順)
- フィールド3: `isRead` (昇順)

## セキュリティルールの説明

### users コレクション
- 認証済みユーザーは全てのユーザープロフィールを読み取り可能
- 自分のプロフィールのみ編集可能

### experiments コレクション
- 認証済みユーザーは全ての実験情報を読み取り可能
- 実験作成者のみが自分の実験を編集・削除可能

### conversations コレクション
- ユーザーは自分が参加している会話のみアクセス可能
- 新規会話作成時は必ず2人のユーザーが必要
- 会話の削除は禁止

### messages コレクション
- 送信者と受信者のみがメッセージを読み取り可能
- 送信者のみが新規メッセージを作成可能
- 受信者のみが既読フラグを更新可能
- メッセージの削除は禁止

## トラブルシューティング

### エラーが継続する場合
1. ユーザーが正しくログインしているか確認
2. Firebase Consoleでルールが正しく公開されているか確認
3. ブラウザのキャッシュをクリアして再試行
4. Firebase Authentication でユーザーが正しく作成されているか確認

### デバッグ方法
Firebase Consoleの「ルール」タブにある「ルールプレイグラウンド」を使用して、特定のリクエストがルールに合致するかテストできます。

## 注意事項
- このルールは本番環境向けの基本的なセキュリティを提供します
- 必要に応じて、より厳格なルールに調整してください
- 定期的にセキュリティルールを見直すことを推奨します