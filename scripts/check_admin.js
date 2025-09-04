// Firebase Admin SDK を使用した管理者アカウント確認スクリプト
// 
// 使用方法:
// 1. serviceAccountKey.json が同じディレクトリにあることを確認
// 2. node check_admin.js <email> を実行

const admin = require('firebase-admin');

// サービスアカウントキーのパス
const serviceAccount = require('./serviceAccountKey.json');

// Firebase Admin SDKの初期化
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
const auth = admin.auth();

async function checkAdmin(email) {
  try {
    console.log('========================================');
    console.log('管理者アカウント確認');
    console.log('========================================');
    console.log('検索メール:', email);

    // 1. Authentication からユーザーを検索
    let user;
    try {
      user = await auth.getUserByEmail(email);
      console.log('\n✓ ユーザーが見つかりました:');
      console.log('  - UID:', user.uid);
      console.log('  - Email:', user.email);
      console.log('  - Display Name:', user.displayName);
      console.log('  - Email Verified:', user.emailVerified);
      console.log('  - Disabled:', user.disabled);
    } catch (error) {
      console.log('\n✗ ユーザーが見つかりません');
      console.log('  エラー:', error.message);
      return;
    }

    // 2. Firestore から管理者ドキュメントを確認
    const adminDoc = await db.collection('admins').doc(user.uid).get();

    if (adminDoc.exists) {
      console.log('\n✓ 管理者権限が設定されています:');
      const data = adminDoc.data();
      console.log('  - Name:', data.name);
      console.log('  - Role:', data.role);
      console.log('  - Active:', data.isActive);
      console.log('  - Permissions:', data.permissions ? data.permissions.join(', ') : 'なし');
      console.log('  - Created At:', data.createdAt ? data.createdAt.toDate() : '不明');
      console.log('  - Last Login At:', data.lastLoginAt ? data.lastLoginAt.toDate() : 'まだログインしていません');
    } else {
      console.log('\n✗ 管理者権限が設定されていません');
      console.log('  admins/' + user.uid + ' ドキュメントが存在しません');
    }

    // 3. すべての管理者を表示
    console.log('\n========================================');
    console.log('登録済み管理者一覧:');
    console.log('========================================');
    const adminsSnapshot = await db.collection('admins').get();
    if (adminsSnapshot.empty) {
      console.log('管理者が登録されていません');
    } else {
      adminsSnapshot.forEach((doc, index) => {
        const data = doc.data();
        console.log(`${index + 1}. UID: ${doc.id}`);
        console.log(`   - Email: ${data.email}`);
        console.log(`   - Name: ${data.name}`);
        console.log(`   - Role: ${data.role}`);
        console.log(`   - Active: ${data.isActive}`);
      });
    }

  } catch (error) {
    console.error('\nエラーが発生しました:', error);
  } finally {
    process.exit();
  }
}

// コマンドライン引数を取得
const email = process.argv[2];

if (!email) {
  console.log('使用方法: node check_admin.js <email>');
  console.log('例: node check_admin.js admin@example.com');
  process.exit(1);
}

// スクリプトを実行
checkAdmin(email);