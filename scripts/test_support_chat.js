const admin = require('firebase-admin');
const serviceAccount = require('./waselab-30308-firebase-adminsdk-3grs5-f5ac57e00f.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://waselab-30308.firebaseio.com"
});

const db = admin.firestore();

async function checkSupportMessages() {
  console.log('=== Checking Support Messages ===\n');
  
  // 1. Check all conversations with support_team
  console.log('1. Conversations with support_team:');
  const conversationsSnapshot = await db.collection('conversations')
    .where('participantIds', 'array-contains', 'support_team')
    .get();
  
  console.log(`Found ${conversationsSnapshot.size} conversations`);
  conversationsSnapshot.forEach(doc => {
    const data = doc.data();
    console.log(`  - ID: ${doc.id}`);
    console.log(`    Participants: ${JSON.stringify(data.participantIds)}`);
    console.log(`    Names: ${JSON.stringify(data.participantNames)}`);
    console.log(`    Last Message: ${data.lastMessage}`);
    console.log(`    Last Time: ${data.lastMessageTime?.toDate()}`);
  });
  
  console.log('\n2. Messages to/from support_team:');
  
  // 2. Check messages TO support_team
  const messagesToSupport = await db.collection('messages')
    .where('receiverId', '==', 'support_team')
    .orderBy('createdAt', 'desc')
    .limit(10)
    .get();
  
  console.log(`\nMessages TO support_team: ${messagesToSupport.size}`);
  messagesToSupport.forEach(doc => {
    const data = doc.data();
    console.log(`  - From: ${data.senderId}`);
    console.log(`    Content: ${data.content}`);
    console.log(`    ConversationId: ${data.conversationId}`);
    console.log(`    Time: ${data.createdAt?.toDate()}`);
    console.log(`    IsRead: ${data.isRead}`);
    console.log('  ---');
  });
  
  // 3. Check messages FROM support_team
  const messagesFromSupport = await db.collection('messages')
    .where('senderId', '==', 'support_team')
    .orderBy('createdAt', 'desc')
    .limit(10)
    .get();
  
  console.log(`\nMessages FROM support_team: ${messagesFromSupport.size}`);
  messagesFromSupport.forEach(doc => {
    const data = doc.data();
    console.log(`  - To: ${data.receiverId}`);
    console.log(`    Content: ${data.content}`);
    console.log(`    ConversationId: ${data.conversationId}`);
    console.log(`    Time: ${data.createdAt?.toDate()}`);
    console.log('  ---');
  });
  
  // 4. Check all messages with conversationId containing support_team
  console.log('\n3. Checking conversation IDs:');
  const allMessages = await db.collection('messages')
    .orderBy('createdAt', 'desc')
    .limit(20)
    .get();
  
  const supportConversationIds = new Set();
  allMessages.forEach(doc => {
    const data = doc.data();
    if (data.conversationId && data.conversationId.includes('support_team')) {
      supportConversationIds.add(data.conversationId);
    }
  });
  
  console.log('Unique conversation IDs with support_team:');
  supportConversationIds.forEach(id => {
    console.log(`  - ${id}`);
  });
}

checkSupportMessages()
  .then(() => {
    console.log('\n=== Check Complete ===');
    process.exit(0);
  })
  .catch(error => {
    console.error('Error:', error);
    process.exit(1);
  });