# アプリケーションアーキテクチャ

## 重要: main.dartとmain_demo.dartの共通化について

このアプリケーションは2つのエントリーポイントを持っています：
- `lib/main.dart` - 本番用（Firebase使用）
- `lib/main_demo.dart` - デモ用（Firebase不使用、高速起動）

### 共通コンポーネントの配置ルール

**必ず守ること：**
1. 両方のエントリーポイントで使用される共通コンポーネントは `lib/shared/` フォルダに配置する
2. main.dartとmain_demo.dartには最小限のコードのみ記述する
3. 新機能を追加する際は、必ず両方のエントリーポイントに対応する実装を行う

### ディレクトリ構造

```
lib/
├── main.dart                 # 本番用エントリーポイント（最小限のコード）
├── main_demo.dart            # デモ用エントリーポイント（最小限のコード）
├── shared/                   # 共通コンポーネント
│   ├── app_wrapper.dart      # アプリケーションのルートウィジェット
│   └── app_theme.dart        # テーマ設定
├── screens/                  # 画面
│   ├── *.dart               # 本番用画面
│   └── *_demo.dart          # デモ用画面
├── services/                 # サービス
│   ├── auth_service.dart    # 本番用認証サービス
│   └── demo_auth_service.dart # デモ用認証サービス
└── models/                   # データモデル（共通）
```

### 新機能追加時のチェックリスト

新機能を追加する際は、以下を確認してください：

- [ ] 本番用の実装を作成（Firebase使用）
- [ ] デモ用の実装を作成（Firebase不使用）
- [ ] 共通部分を `lib/shared/` に配置
- [ ] main.dartを更新（必要な場合）
- [ ] main_demo.dartを更新（必要な場合）
- [ ] 両方のエントリーポイントでテスト

### 画面の命名規則

- 本番用: `*Screen.dart` (例: `HomeScreen`, `MyPageScreen`)
- デモ用: `*ScreenDemo.dart` (例: `HomeScreenDemo`, `MyPageScreenDemo`)

### サービスの命名規則

- 本番用: `*Service.dart` (例: `AuthService`, `MessageService`)
- デモ用: `Demo*Service.dart` (例: `DemoAuthService`, `DemoMessageService`)

## 現在実装されている機能

### 1. ナビゲーション
- **本番**: `NavigationScreen` - BottomNavigationBar（スマホ）/ NavigationRail（PC）
- **デモ**: `NavigationScreenDemo` - 同様のレスポンシブ対応

### 2. マイページ機能
- ユーザープロフィール表示・編集
- 参加実験数の表示
- 早稲田/Googleアカウントの識別

### 3. ダイレクトメッセージ機能
- メッセージ一覧
- 個別チャット
- 未読メッセージ数表示

## レスポンシブ対応

画面幅に応じて自動的にレイアウトが切り替わります：
- **600px未満**: BottomNavigationBar（画面下部）
- **600px以上**: NavigationRail（画面左側）