import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String conversationId;
  final String content;
  final DateTime createdAt;
  final bool isRead;
  final bool isEdited;
  final bool isDeleted;
  final DateTime? editedAt;
  final String? replyToMessageId;
  final String? replyToContent;
  final String? replyToSenderId;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.conversationId,
    required this.content,
    required this.createdAt,
    this.isRead = false,
    this.isEdited = false,
    this.isDeleted = false,
    this.editedAt,
    this.replyToMessageId,
    this.replyToContent,
    this.replyToSenderId,
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      conversationId: data['conversationId'] ?? '',
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      isEdited: data['isEdited'] ?? false,
      isDeleted: data['isDeleted'] ?? false,
      editedAt: data['editedAt'] != null ? (data['editedAt'] as Timestamp).toDate() : null,
      replyToMessageId: data['replyToMessageId'],
      replyToContent: data['replyToContent'],
      replyToSenderId: data['replyToSenderId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'conversationId': conversationId,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'isEdited': isEdited,
      'isDeleted': isDeleted,
      if (editedAt != null) 'editedAt': Timestamp.fromDate(editedAt!),
      if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
      if (replyToContent != null) 'replyToContent': replyToContent,
      if (replyToSenderId != null) 'replyToSenderId': replyToSenderId,
    };
  }
  
  Message copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? conversationId,
    String? content,
    DateTime? createdAt,
    bool? isRead,
    bool? isEdited,
    bool? isDeleted,
    DateTime? editedAt,
    String? replyToMessageId,
    String? replyToContent,
    String? replyToSenderId,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      conversationId: conversationId ?? this.conversationId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
      editedAt: editedAt ?? this.editedAt,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToContent: replyToContent ?? this.replyToContent,
      replyToSenderId: replyToSenderId ?? this.replyToSenderId,
    );
  }
}