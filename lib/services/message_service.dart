import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message.dart';
import '../models/conversation.dart';

class MessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
        .map((snapshot) =>
            snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList());
  }

  Future<String> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
    required String senderName,
    required String receiverName,
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
    );

    await _firestore.collection('messages').add(message.toFirestore());

    await _firestore.collection('conversations').doc(conversationId).update({
      'lastMessage': content,
      'lastMessageTime': Timestamp.fromDate(DateTime.now()),
      'unreadCounts.$receiverId': FieldValue.increment(1),
    });

    return conversationId;
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
}