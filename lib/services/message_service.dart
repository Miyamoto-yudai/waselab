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
    return _firestore
        .collection('messages')
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
          for (var doc in snapshot.docs) {
            final data = doc.data();
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
    
    String conversationId = await getOrCreateConversation(
      senderId,
      receiverId,
      senderName,
      receiverName,
    );
    

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

    final docRef = await _firestore.collection('messages').add(message.toFirestore());

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
      rethrow;
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
      rethrow;
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
      rethrow;
    }
  }

  Future<String> getOrCreateConversation(
    String userId1,
    String userId2,
    String userName1,
    String userName2,
  ) async {
    
    final conversationQuery = await _firestore
        .collection('conversations')
        .where('participantIds', arrayContains: userId1)
        .get();

    
    for (var doc in conversationQuery.docs) {
      final participantIds = List<String>.from(doc.data()['participantIds']);
      if (participantIds.contains(userId2)) {
        return doc.id;
      }
    }
    

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

    
    final docRef = await _firestore
        .collection('conversations')
        .add(conversation.toFirestore());
    
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