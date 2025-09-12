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
          for (var doc in snapshot.docs) {
            final data = doc.data();
            print('  Message: ${data['content']}, From: ${data['senderId']}, To: ${data['receiverId']}');
          }
          return snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList();
        });
  }

  Future<String> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
    required String senderName,
    required String receiverName,
    String? replyToMessageId,
    String? replyToContent,
    String? replyToSenderId,
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
      replyToMessageId: replyToMessageId,
      replyToContent: replyToContent,
      replyToSenderId: replyToSenderId,
    );

    print('Adding message to Firestore...');
    final docRef = await _firestore.collection('messages').add(message.toFirestore());
    print('Message added with ID: ${docRef.id}');

    await _firestore.collection('conversations').doc(conversationId).update({
      'lastMessage': content,
      'lastMessageTime': Timestamp.fromDate(DateTime.now()),
      'unreadCounts.$receiverId': FieldValue.increment(1),
    });

    // 受信者への通知は送信しない（メッセージ画面で確認できるため）
    // プッシュ通知はFCMサービス側で処理される

    return conversationId;
  }

  /// メッセージを編集
  Future<void> editMessage(String messageId, String newContent) async {
    try {
      // メッセージが存在するか確認
      final doc = await _firestore.collection('messages').doc(messageId).get();
      if (!doc.exists) {
        throw Exception('メッセージが見つかりません');
      }
      
      await _firestore.collection('messages').doc(messageId).update({
        'content': newContent,
        'isEdited': true,
        'editedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Error editing message: $e');
      throw e;
    }
  }

  /// メッセージを削除（論理削除）
  Future<void> deleteMessage(String messageId) async {
    try {
      // メッセージが存在するか確認
      final doc = await _firestore.collection('messages').doc(messageId).get();
      if (!doc.exists) {
        throw Exception('メッセージが見つかりません');
      }
      
      await _firestore.collection('messages').doc(messageId).update({
        'isDeleted': true,
        'content': '', // 内容をクリア
      });
    } catch (e) {
      print('Error deleting message: $e');
      throw e;
    }
  }
  
  /// メッセージを転送
  Future<String> forwardMessage({
    required String originalMessageId,
    required String senderId,
    required String receiverId,
    required String senderName,
    required String receiverName,
    required String forwardedContent,
    String? originalSenderName,
  }) async {
    try {
      final conversationId = await getOrCreateConversation(
        senderId,
        receiverId,
        senderName,
        receiverName,
      );
      
      // 転送メッセージの作成
      final forwardMessage = '「転送メッセージ」\n'
          '${originalSenderName != null ? "$originalSenderNameさんから：\n" : ""}'
          '$forwardedContent';
      
      final message = Message(
        id: '',
        senderId: senderId,
        receiverId: receiverId,
        conversationId: conversationId,
        content: forwardMessage,
        createdAt: DateTime.now(),
        isRead: false,
      );
      
      await _firestore.collection('messages').add(message.toFirestore());
      
      // 会話の最終メッセージを更新
      await _firestore.collection('conversations').doc(conversationId).update({
        'lastMessage': forwardMessage,
        'lastMessageTime': Timestamp.fromDate(DateTime.now()),
        'unreadCounts.$receiverId': FieldValue.increment(1),
      });
      
      return conversationId;
    } catch (e) {
      print('Error forwarding message: $e');
      throw e;
    }
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

  Stream<int> streamUnreadMessageCount(String userId) {
    return _firestore
        .collection('conversations')
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          int totalUnread = 0;
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final unreadCounts = Map<String, dynamic>.from(data['unreadCounts'] ?? {});
            totalUnread += (unreadCounts[userId] ?? 0) as int;
          }
          return totalUnread;
        });
  }
}