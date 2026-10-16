import 'dart:io';
import 'package:tourn/data/firebase/firebase_message_service.dart';
import 'package:tourn/models/message_model.dart';
import 'package:tourn/models/conversation_model.dart';

abstract class MessageRepository {
  String? get currentUserId;
  Future<ConversationModel?> getOrCreatePrivateConversation({
    required String otherUserId,
    required String otherUserName,
    String? otherUserPhoto,
    String? currentUserName,
    String? currentUserPhoto,
    bool isBusinessChat = false,
  });
  Future<ConversationModel?> createGroupConversation({
    required String name,
    required List<String> participantIds,
    required Map<String, String> participantNames,
    Map<String, String?>? participantPhotos,
    String? photoUrl,
  });
  Future<ConversationModel?> getConversationById(String conversationId);
  Future<MessageModel?> sendMessage({
    required String conversationId,
    required String content,
    required String senderName,
    String? senderPhotoUrl,
    MessageType type,
    File? mediaFile,
    Map<String, dynamic>? metadata,
    String? senderIdOverride,
  });
  Future<void> setMute(
    String conversationId,
    String userId,
    bool muted, {
    DateTime? until,
  });
  Stream<List<MessageModel>> getMessages(String conversationId, {int limit});
  Future<void> markAsRead(String conversationId);
  Future<void> markAsUnread(String conversationId);
  Stream<List<ConversationModel>> getConversations();
  Stream<ConversationModel?> streamConversation(String conversationId);
  Future<void> deleteMessage(String conversationId, String messageId);

  /// Recall a message (delete for everyone) - only sender can recall
  Future<void> recallMessage(String conversationId, String messageId);

  /// Delete message for current user only (hide from their view)
  Future<void> deleteMessageForMe(String conversationId, String messageId);

  Future<void> archiveConversation(String conversationId);
  Future<void> unarchiveConversation(String conversationId);

  /// Permanently deletes a conversation and all its messages.  This is a
  /// destructive operation and cannot be undone.  Only the local user may
  /// initiate it; the backend will only delete the document if the current
  /// user is a participant.
  Future<void> deleteConversation(String conversationId);

  /// Return snapshot of all messages in a conversation (used for undo).
  Future<List<MessageModel>> getAllMessages(String conversationId);

  /// Restore a previously deleted conversation/document with its messages.
  Future<void> restoreConversation(
    ConversationModel conversation,
    List<MessageModel> messages,
  );

  Future<void> leaveGroup(String conversationId);
  Future<void> addParticipantsToGroup({
    required String conversationId,
    required List<String> participantIds,
    required Map<String, String> participantNames,
    Map<String, String?>? participantPhotos,
  });
  Future<void> updateGroupName(String conversationId, String name);
  Future<String?> updateGroupPhoto(String conversationId, File imageFile);
  Stream<int> getTotalUnreadCount();
  Future<void> setTyping(String conversationId, bool isTyping);

  /// Accept a message request - adds current user to acceptedBy list
  Future<void> acceptConversation(String conversationId);

  /// Reject/delete a message request
  Future<void> rejectConversation(String conversationId);
}

class FirestoreMessageRepository implements MessageRepository {
  final FirebaseMessageService _messageService = FirebaseMessageService();

  @override
  String? get currentUserId => _messageService.currentUserId;

  @override
  Future<ConversationModel?> getOrCreatePrivateConversation({
    required String otherUserId,
    required String otherUserName,
    String? otherUserPhoto,
    String? currentUserName,
    String? currentUserPhoto,
    bool isBusinessChat = false,
  }) async {
    return _messageService.getOrCreatePrivateConversation(
      otherUserId: otherUserId,
      otherUserName: otherUserName,
      otherUserPhoto: otherUserPhoto,
      currentUserName: currentUserName,
      currentUserPhoto: currentUserPhoto,
      isBusinessChat: isBusinessChat,
    );
  }

  @override
  Future<ConversationModel?> createGroupConversation({
    required String name,
    required List<String> participantIds,
    required Map<String, String> participantNames,
    Map<String, String?>? participantPhotos,
    String? photoUrl,
  }) async {
    return _messageService.createGroupConversation(
      name: name,
      participantIds: participantIds,
      participantNames: participantNames,
      participantPhotos: participantPhotos,
      photoUrl: photoUrl,
    );
  }

  @override
  Future<ConversationModel?> getConversationById(String conversationId) async {
    return _messageService.getConversationById(conversationId);
  }

  @override
  Future<MessageModel?> sendMessage({
    required String conversationId,
    required String content,
    required String senderName,
    String? senderPhotoUrl,
    MessageType type = MessageType.text,
    File? mediaFile,
    Map<String, dynamic>? metadata,
    String? senderIdOverride,
  }) async {
    return _messageService.sendMessage(
      conversationId: conversationId,
      content: content,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      type: type,
      mediaFile: mediaFile,
      metadata: metadata,
      senderIdOverride: senderIdOverride,
    );
  }

  @override
  Future<void> setMute(
    String conversationId,
    String userId,
    bool muted, {
    DateTime? until,
  }) async {
    return _messageService.setMute(conversationId, userId, muted, until: until);
  }

  @override
  Stream<List<MessageModel>> getMessages(
    String conversationId, {
    int limit = 50,
  }) {
    return _messageService.getMessages(conversationId, limit: limit);
  }

  @override
  Future<void> markAsRead(String conversationId) async {
    return _messageService.markAsRead(conversationId);
  }

  @override
  Future<void> markAsUnread(String conversationId) async {
    return _messageService.markAsUnread(conversationId);
  }

  @override
  Stream<List<ConversationModel>> getConversations() {
    return _messageService.getConversations();
  }

  @override
  Stream<ConversationModel?> streamConversation(String conversationId) {
    return _messageService.streamConversation(conversationId);
  }

  @override
  Future<void> deleteMessage(String conversationId, String messageId) async {
    return _messageService.deleteMessage(conversationId, messageId);
  }

  @override
  Future<void> recallMessage(String conversationId, String messageId) async {
    return _messageService.recallMessage(conversationId, messageId);
  }

  @override
  Future<void> deleteMessageForMe(
    String conversationId,
    String messageId,
  ) async {
    return _messageService.deleteMessageForMe(conversationId, messageId);
  }

  @override
  @override
  Future<void> archiveConversation(String conversationId) async {
    return _messageService.archiveConversation(conversationId);
  }

  @override
  Future<void> unarchiveConversation(String conversationId) async {
    return _messageService.unarchiveConversation(conversationId);
  }

  @override
  Future<void> deleteConversation(String conversationId) async {
    return _messageService.deleteConversation(conversationId);
  }

  /// Retrieve all messages from a conversation in a single batch.  Used by
  /// the UI when offering an undo after deletion.
  @override
  Future<List<MessageModel>> getAllMessages(String conversationId) async {
    return _messageService.getMessagesOnce(conversationId);
  }

  /// Restore a previously deleted conversation along with its messages.
  @override
  Future<void> restoreConversation(
    ConversationModel conversation,
    List<MessageModel> messages,
  ) async {
    return _messageService.restoreConversation(conversation, messages);
  }

  @override
  Future<void> leaveGroup(String conversationId) async {
    return _messageService.leaveGroup(conversationId);
  }

  @override
  Future<void> addParticipantsToGroup({
    required String conversationId,
    required List<String> participantIds,
    required Map<String, String> participantNames,
    Map<String, String?>? participantPhotos,
  }) async {
    return _messageService.addParticipantsToGroup(
      conversationId: conversationId,
      participantIds: participantIds,
      participantNames: participantNames,
      participantPhotos: participantPhotos,
    );
  }

  @override
  Future<void> updateGroupName(String conversationId, String name) async {
    return _messageService.updateGroupName(conversationId, name);
  }

  @override
  Future<String?> updateGroupPhoto(
    String conversationId,
    File imageFile,
  ) async {
    return _messageService.updateGroupPhoto(conversationId, imageFile);
  }

  @override
  Stream<int> getTotalUnreadCount() {
    return _messageService.getTotalUnreadCount();
  }

  @override
  Future<void> setTyping(String conversationId, bool isTyping) async {
    return _messageService.setTyping(conversationId, isTyping);
  }

  @override
  Future<void> acceptConversation(String conversationId) async {
    return _messageService.acceptConversation(conversationId);
  }

  @override
  Future<void> rejectConversation(String conversationId) async {
    return _messageService.rejectConversation(conversationId);
  }
}
