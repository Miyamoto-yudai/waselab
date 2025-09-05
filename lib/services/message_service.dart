import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message.dart';
import '../models/conversation.dart';
import 'notification_service.dart';

class MessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  Stream<List<Conversation>> getUserConversations(String userId) {
    return _firestore
        .collection('conversations')
        .where('participantIds', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Conversation.fromFirestore(doc))
            .toList());
  }

  Stream<List<Message>> getConversationMessages(String conversationId) {
    print('Getting messages for conversation: $conversationId');
    return _firestore
        .collection('messages')
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
          print('Snapshot received: ${snapshot.docs.length} messages');
          snapshot.docs.forEach((doc) {
            final data = doc.data();
            print('  Message: ${data['content']}, From: ${data['senderId']}, To: ${data['receiverId']}');
          });
          return snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList();
        });
  }

  Future<String> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
    required String senderName,
    required String receiverName,
  }) async {
    print('=== sendMessage called ===');
    print('From: $senderId ($senderName)');
    print('To: $receiverId ($receiverName)');
    print('Content: $content');
    
    String conversationId = await getOrCreateConversation(
      senderId,
      receiverId,
      senderName,
      receiverName,
    );
    
    print('ConversationId obtained: $conversationId');

    final message = Message(
      id: '',
      senderId: senderId,
      receiverId: receiverId,
      conversationId: conversationId,
      content: content,
      createdAt: DateTime.now(),
      isRead: false,
    );

    print('Adding message to Firestore...');
    final docRef = await _firestore.collection('messages').add(message.toFirestore());
    print('Message added with ID: ${docRef.id}');

    await _firestore.collection('conversations').doc(conversationId).update({
      'lastMessage': content,
      'lastMessageTime': Timestamp.fromDate(DateTime.now()),
      'unreadCounts.$receiverId': FieldValue.increment(1),
    });

    // 受信者に通知を送信
    try {
      // メッセージのプレビューを作成（最大30文字）
      final messagePreview = content.length > 30 
        ? '${content.substring(0, 30)}...' 
        : content;
      
      await _notificationService.createMessageNotification(
        userId: receiverId,
        senderName: senderName,
        messagePreview: messagePreview,
        conversationId: conversationId,
      );
    } catch (e) {
      // 通知送信に失敗してもメッセージ送信は成功とする
      print('通知送信エラー（無視）: $e');
    }

    return conversationId;
  }

  Future<String> getOrCreateConversation(
    String userId1,
    String userId2,
    String userName1,
    String userName2,
  ) async {
    print('=== getOrCreateConversation ===');
    print('User1: $userId1 ($userName1)');
    print('User2: $userId2 ($userName2)');
    
    final conversationQuery = await _firestore
        .collection('conversations')
        .where('participantIds', arrayContains: userId1)
        .get();

    print('Found ${conversationQuery.docs.length} conversations for $userId1');
    
    for (var doc in conversationQuery.docs) {
      final participantIds = List<String>.from(doc.data()['participantIds']);
      print('  Checking conversation ${doc.id}: $participantIds');
      if (participantIds.contains(userId2)) {
        print('  -> Found existing conversation: ${doc.id}');
        return doc.id;
      }
    }
    
    print('No existing conversation found, creating new one...');

    final conversation = Conversation(
      id: '',
      participantIds: [userId1, userId2],
      participantNames: {
        userId1: userName1,
        userId2: userName2,
      },
      unreadCounts: {
        userId1: 0,
        userId2: 0,
      },
      createdAt: DateTime.now(),
    );

    print('Creating conversation with data: ${conversation.toFirestore()}');
    
    final docRef = await _firestore
        .collection('conversations')
        .add(conversation.toFirestore());
    
    print('New conversation created with ID: ${docRef.id}');
    return docRef.id;
  }

  Future<void> markMessagesAsRead(String conversationId, String userId) async {
    final batch = _firestore.batch();

    final unreadMessages = await _firestore
        .collection('messages')
        .where('conversationId', isEqualTo: conversationId)
        .where('receiverId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in unreadMessages.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    batch.update(_firestore.collection('conversations').doc(conversationId), {
      'unreadCounts.$userId': 0,
    });

    await batch.commit();
  }

  Future<int> getUnreadMessageCount(String userId) async {
    final conversations = await _firestore
        .collection('conversations')
        .where('participantIds', arrayContains: userId)
        .get();

    int totalUnread = 0;
    for (var doc in conversations.docs) {
      final data = doc.data();
      final unreadCounts = Map<String, dynamic>.from(data['unreadCounts'] ?? {});
      totalUnread += (unreadCounts[userId] ?? 0) as int;
    }

    return totalUnread;
  }
}