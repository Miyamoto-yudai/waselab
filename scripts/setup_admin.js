// Firebase Admin SDK を使用した管理者アカウント設定スクリプト
// 
// 使用方法:
// 1. Firebase Consoleからサービスアカウントキーをダウンロード
//    (プロジェクト設定 → サービスアカウント → 新しい秘密鍵の生成)
// 2. ダウンロードしたファイルを serviceAccountKey.json として保存
// 3. npm install firebase-admin を実行
// 4. node setup_admin.js を実行

const admin = require('firebase-admin');

// サービスアカウントキーのパス
const serviceAccount = require('./serviceAccountKey.json');

// Firebase Admin SDKの初期化
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
const auth = admin.auth();

async function setupAdmin() {
  try {
    // 管理者アカウント情報
    const adminEmail = 'admin@example.com'; // 変更してください
    const adminPassword = 'your-secure-password'; // 変更してください
    const adminName = 'システム管理者';

    console.log('管理者アカウントを作成中...');

    // 1. Authentication にユーザーを作成
    let adminUser;
    try {
      adminUser = await auth.createUser({
        email: adminEmail,
        password: adminPassword,
        displayName: adminName,
        emailVerified: true
      });
      console.log('✓ 管理者ユーザーを作成しました:', adminUser.uid);
    } catch (error) {
      if (error.code === 'auth/email-already-exists') {
        // 既存のユーザーを取得
        adminUser = await auth.getUserByEmail(adminEmail);
        console.log('✓ 既存の管理者ユーザーを使用:', adminUser.uid);
      } else {
        throw error;
      }
    }

    // 2. Firestore に管理者ドキュメントを作成
    const adminDoc = {
      uid: adminUser.uid,
      email: adminEmail,
      name: adminName,
      role: 'super_admin',
      permissions: [
        'view_users',
        'edit_users',
        'view_chats',
        'send_support_messages',
        'send_announcements',
        'view_experiments',
        'edit_experiments',
        'view_statistics',
        'manage_admins'
      ],
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      isActive: true
    };

    await db.collection('admins').doc(adminUser.uid).set(adminDoc);
    console.log('✓ 管理者権限を設定しました');

    console.log('\n========================================');
    console.log('管理者アカウントの設定が完了しました！');
    console.log('========================================');
    console.log('メールアドレス:', adminEmail);
    console.log('パスワード: [設定したパスワード]');
    console.log('UID:', adminUser.uid);
    console.log('\nアプリのログイン画面下部の「管理者」ボタンから');
    console.log('このアカウントでログインできます。');

  } catch (error) {
    console.error('エラーが発生しました:', error);
  } finally {
    process.exit();
  }
}

// スクリプトを実行
setupAdmin();