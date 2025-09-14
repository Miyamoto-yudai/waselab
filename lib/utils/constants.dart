/// アプリケーション全体で使用する定数
class AppConstants {
  AppConstants._();

  // 外部URL
  static const String privacyPolicyUrl = 'https://waselab-support.notion.site/privacy-policy';
  static const String termsOfServiceUrl = 'https://waselab-support.notion.site/terms-of-service';
  
  // 支援関連URL
  static const String payPayDonationUrl = 'https://qr.paypay.ne.jp/p2p01_7K0lVcK1GgYSHfg6';
  static const String githubSponsorsUrl = 'https://github.com/sponsors/Miyamoto-yudai';
  
  // 開発依頼フォーム
  static const String developmentRequestFormUrl = 'https://forms.gle/example123';  // 仮のURL
  
  // サポート情報
  static const String supportEmail = 'support@waselab.example.com';  // 仮のメールアドレス
  
  // アプリ情報
  static const String appVersion = '1.0.0';
  static const String appName = 'わせラボ';
  static const String teamName = 'WaseLab Team';
  
  // メッセージテンプレート
  static const String donationMessage = 
      'このサービスは皆様の支援の元無償で成り立っています。\n'
      'ご支援頂けると大変励みになります。';
      
  static const String developmentServiceMessage = 
      'わせラボチームでは研究用システムの開発、'
      '就活用のマイページの作成、その他開発案件を承っております。\n'
      'いつでもお気軽にお問い合わせください。';
      
  static const String externalLinkWarning = '外部サイトへ移動します';
}