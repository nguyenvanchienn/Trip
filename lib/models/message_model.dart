import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  text,
  image,
  video,
  audio,
  file,
  location,
  voiceCall,
  videoCall,
  sharedPost, // Bài viết được chia sẻ qua tin nhắn
}

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String? senderPhotoUrl;
  final MessageType type;
  final String content;
  final String? mediaUrl;
  final Map<String, dynamic>? metadata;
  final List<String> readBy;
  final DateTime createdAt;
  final bool isDeleted;
  // Track which users have deleted this message (for "delete for me" feature)
  final List<String> deletedFor;
  // Whether this message was recalled (deleted for everyone)
  final bool isRecalled;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl,
    this.type = MessageType.text,
    required this.content,
    this.mediaUrl,
    this.metadata,
    this.readBy = const [],
    required this.createdAt,
    this.isDeleted = false,
    this.deletedFor = const [],
    this.isRecalled = false,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Safe list parsing helper
    List<String> safeStringList(dynamic value) {
      if (value == null) return [];
      if (value is List) return List<String>.from(value);
      return [];
    }

    return MessageModel(
      id: doc.id,
      conversationId: data['conversationId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderPhotoUrl: data['senderPhotoUrl'],
      type: MessageType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => MessageType.text,
      ),
      content: data['content'] ?? '',
      mediaUrl: data['mediaUrl'],
      metadata: data['metadata'] as Map<String, dynamic>?,
      readBy: safeStringList(data['readBy']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isDeleted: data['isDeleted'] ?? false,
      deletedFor: safeStringList(data['deletedFor']),
      isRecalled: data['isRecalled'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'type': type.name,
      'content': content,
      'mediaUrl': mediaUrl,
      'metadata': metadata,
      'readBy': readBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'isDeleted': isDeleted,
      'deletedFor': deletedFor,
      'isRecalled': isRecalled,
    };
  }

  MessageModel copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    String? senderPhotoUrl,
    MessageType? type,
    String? content,
    String? mediaUrl,
    Map<String, dynamic>? metadata,
    List<String>? readBy,
    DateTime? createdAt,
    bool? isDeleted,
    List<String>? deletedFor,
    bool? isRecalled,
  }) {
    return MessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderPhotoUrl: senderPhotoUrl ?? this.senderPhotoUrl,
      type: type ?? this.type,
      content: content ?? this.content,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      metadata: metadata ?? this.metadata,
      readBy: readBy ?? this.readBy,
      createdAt: createdAt ?? this.createdAt,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedFor: deletedFor ?? this.deletedFor,
      isRecalled: isRecalled ?? this.isRecalled,
    );
  }
}
