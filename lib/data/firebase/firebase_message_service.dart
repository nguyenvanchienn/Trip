import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../models/message_model.dart';
import '../../models/conversation_model.dart';

class FirebaseMessageService {
  // Singleton pattern
  static final FirebaseMessageService _instance =
      FirebaseMessageService._internal();
  factory FirebaseMessageService() => _instance;
  FirebaseMessageService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Tham chiếu đến các collection
  CollectionReference<Map<String, dynamic>> get _conversationsCollection =>
      _firestore.collection('conversations');

  String? get currentUserId => _auth.currentUser?.uid;

  // Tạo hoặc lấy cuộc trò chuyện riêng
  Future<ConversationModel?> getOrCreatePrivateConversation({
    required String otherUserId,
    required String otherUserName,
    String? otherUserPhoto,
    String? currentUserName,
    String? currentUserPhoto,
    bool isBusinessChat = false,
  }) async {
    final uid = currentUserId;
    if (uid == null) return null;

    // Kiểm tra xem cuộc trò chuyện đã tồn tại không (với cả hai thứ tự người tham gia)
    // trả về nếu có. Chúng ta cũng chuẩn hóa thứ tự người tham gia khi tạo
    // để tránh hai tài liệu khác nhau chỉ vì thứ tự khác nhau.
    QuerySnapshot<Map<String, dynamic>> existingQuery;
    try {
      existingQuery = await _conversationsCollection
          .where('type', isEqualTo: ConversationType.private.name)
          .where('participants', arrayContains: uid)
          .get();
    } catch (e) {
      print('Error querying conversations: $e');
      // If index is not ready, continue to create new conversation
      existingQuery = await _conversationsCollection
          .where('participants', arrayContains: uid)
          .get();
    }

    for (final doc in existingQuery.docs) {
      final data = doc.data();
      // Filter by type manually if the composite query failed
      if (data['type'] != ConversationType.private.name) continue;
      final participants = List<String>.from(data['participants'] ?? []);
      if (uid == otherUserId) {
        if (participants.length == 2 && participants.every((id) => id == uid)) {
          if (isBusinessChat && data['isBusinessChat'] != true) {
            await doc.reference.update({'isBusinessChat': true});
            return ConversationModel.fromFirestore(doc).copyWith(isBusinessChat: true);
          }
          return ConversationModel.fromFirestore(doc);
        }
      } else {
        if (participants.contains(uid) && participants.contains(otherUserId)) {
          if (isBusinessChat && data['isBusinessChat'] != true) {
            await doc.reference.update({'isBusinessChat': true});
            return ConversationModel.fromFirestore(doc).copyWith(isBusinessChat: true);
          }
          return ConversationModel.fromFirestore(doc);
        }
      }
    }

    // Tạo cuộc trò chuyện mới
    final docRef = _conversationsCollection.doc();
    // luôn lưu danh sách người tham gia theo thứ tự sắp xếp để A-B và B-A
    // trỏ tới cùng một danh sách chuẩn.
    final participantsList = [uid, otherUserId]..sort();
    final conversation = ConversationModel(
      id: docRef.id,
      type: ConversationType.private,
      participants: participantsList,
      participantNames: {
        uid: currentUserName ?? 'Me',
        otherUserId: otherUserName,
      },
      participantPhotos: {uid: currentUserPhoto, otherUserId: otherUserPhoto},
      lastMessageAt: DateTime.now(),
      createdAt: DateTime.now(),
      createdBy: uid,
      isBusinessChat: isBusinessChat,
    );

    await docRef.set(conversation.toFirestore());
    return conversation;
  }

  // Tạo cuộc trò chuyện nhóm
  Future<ConversationModel?> createGroupConversation({
    required String name,
    required List<String> participantIds,
    required Map<String, String> participantNames,
    Map<String, String?>? participantPhotos,
    String? photoUrl,
  }) async {
    final uid = currentUserId;
    if (uid == null) return null;

    final allParticipants = [uid, ...participantIds];

    final docRef = _conversationsCollection.doc();
    final conversation = ConversationModel(
      id: docRef.id,
      type: ConversationType.group,
      name: name,
      photoUrl: photoUrl,
      participants: allParticipants,
      participantNames: participantNames,
      participantPhotos: participantPhotos ?? {},
      lastMessageAt: DateTime.now(),
      createdAt: DateTime.now(),
      createdBy: uid,
    );

    await docRef.set(conversation.toFirestore());
    return conversation;
  }

  // Lấy cuộc trò chuyện theo ID
  Future<ConversationModel?> getConversationById(String conversationId) async {
    final doc = await _conversationsCollection.doc(conversationId).get();
    if (doc.exists) {
      return ConversationModel.fromFirestore(doc);
    }
    return null;
  }

  // Gửi tin nhắn
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
    final uid = currentUserId;
    if (uid == null) return null;

    final senderId = senderIdOverride ?? uid;

    String? mediaUrl;

    // Tải lên media nếu có
    if (mediaFile != null && type != MessageType.text) {
      // kiểm tra file thực sự tồn tại trên đĩa trước khi tải lên
      if (!await mediaFile.exists()) {
        print('Media file does not exist: ${mediaFile.path}');
        // quay lại tin nhắn chỉ văn bản để gửi vẫn được thực hiện
      } else {
        // xác định phần mở rộng để biết đúng kiểu nội dung
        final filePath = mediaFile.path;
        String ext = '';
        if (filePath.contains('.')) {
          ext = filePath.substring(filePath.lastIndexOf('.'));
        }
        final fileName = '${DateTime.now().millisecondsSinceEpoch}$ext';
        final ref = _storage.ref().child('messages/$conversationId/$fileName');

        // đặt content type để Firebase Storage biết MIME type
        SettableMetadata? metadata;
        if (type == MessageType.image) {
          metadata = SettableMetadata(contentType: 'image/jpeg');
        } else if (type == MessageType.video) {
          metadata = SettableMetadata(contentType: 'video/mp4');
        } else if (type == MessageType.audio) {
          metadata = SettableMetadata(contentType: 'audio/m4a');
        }

        try {
          if (metadata != null) {
            await ref.putFile(mediaFile, metadata);
          } else {
            await ref.putFile(mediaFile);
          }
          mediaUrl = await ref.getDownloadURL();
        } catch (e) {
          print('Error uploading media to Firebase Storage: $e');
          // tiếp tục; tin nhắn sẽ được gửi mà không có mediaUrl
        }
      }
    }

    final messagesCollection = _conversationsCollection
        .doc(conversationId)
        .collection('messages');
    final docRef = messagesCollection.doc();

    final message = MessageModel(
      id: docRef.id,
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      type: type,
      content: content,
      mediaUrl: mediaUrl,
      metadata: metadata,
      createdAt: DateTime.now(),
      readBy: [senderId],
    );

    await docRef.set(message.toFirestore());

    // Cập nhật cuộc trò chuyện với tin nhắn cuối
    await _conversationsCollection.doc(conversationId).update({
      'lastMessage': content,
      'lastMessageSenderId': senderId,
      'lastMessageAt': Timestamp.fromDate(DateTime.now()),
    });

    // Tăng bộ đếm chưa đọc cho các thành viên khác
    final conversation = await getConversationById(conversationId);
    if (conversation != null) {
      final Map<String, dynamic> unreadUpdates = {};
      for (final participantId in conversation.participants) {
        if (participantId == senderId) continue;
        // nếu người khác đã hạn chế *chúng ta* (chúng ta là người gửi), đừng
        // tăng số chưa đọc của họ. họ sẽ không được thông báo và biểu tượng
        // nên giữ ở 0.
        final blockedByRecipient = await hasUserRestricted(
          participantId,
          senderId,
        );
        if (blockedByRecipient) continue;
        unreadUpdates['unreadCount.$participantId'] = FieldValue.increment(1);
      }
      if (unreadUpdates.isNotEmpty) {
        await _conversationsCollection
            .doc(conversationId)
            .update(unreadUpdates);
      }

      // Nếu ai đó đã ẩn cuộc trò chuyện, tin nhắn mới sẽ mở lại nó
      await _conversationsCollection.doc(conversationId).update({
        'deletedFor': FieldValue.arrayRemove(conversation.participants),
      });
    }

    return message;
  }

  // truy vấn xem [userId] có hạn chế [otherId] không. không yêu cầu người
  // dùng đang xác thực phải trùng; đây chỉ là đọc tài liệu của người khác.
  // dùng trong logic thông báo để tránh gửi cảnh báo cho những người họ đã hạn chế.
  Future<bool> hasUserRestricted(String userId, String otherId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return false;
    final restricted = List<String>.from(doc.data()?['restricted'] ?? []);
    return restricted.contains(otherId);
  }

  // Đặt cờ tắt tiếng cho cuộc trò chuyện của người dùng
  Future<void> setMute(
    String conversationId,
    String userId,
    bool muted, {
    DateTime? until,
  }) async {
    final Map<String, dynamic> updates = {'mutedUsers.$userId': muted};
    if (muted) {
      // nếu đang tắt tiếng và có hạn chế thời gian, đặt nó; nếu không
      // xóa hạn chế hiện có để bản đồ không lớn mãi.
      if (until != null) {
        updates['muteExpiry.$userId'] = Timestamp.fromDate(until);
      } else {
        updates['muteExpiry.$userId'] = FieldValue.delete();
      }
    } else {
      // mở tiếng: xóa trường expiry (backendMuted==false nghĩa là không còn
      // cần lo hạn chế nữa). điều này giữ tài liệu gọn gàng.
      updates['muteExpiry.$userId'] = FieldValue.delete();
    }
    await _conversationsCollection.doc(conversationId).update(updates);
  }

  // Lấy tin nhắn cho cuộc trò chuyện
  Stream<List<MessageModel>> getMessages(
    String conversationId, {
    int limit = 50,
  }) {
    final uid = currentUserId;
    return _conversationsCollection
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MessageModel.fromFirestore(doc))
              .where((msg) => uid == null || !msg.deletedFor.contains(uid))
              .toList(),
        );
  }

  // Đánh dấu tin nhắn là đã đọc
  Future<void> markAsRead(String conversationId) async {
    final uid = currentUserId;
    if (uid == null) return;

    try {
      // Đặt lại số lượng chưa đọc
      await _conversationsCollection.doc(conversationId).update({
        'unreadCount.$uid': 0,
      });

      // Lấy một lô tin nhắn gần đây và tự lọc các tin chưa đọc
      final recentMessages = await _conversationsCollection
          .doc(conversationId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .limit(200)
          .get();

      final batch = _firestore.batch();
      for (final doc in recentMessages.docs) {
        final data = doc.data();
        final readBy = List<String>.from(data['readBy'] ?? []);
        if (!readBy.contains(uid)) {
          batch.update(doc.reference, {
            'readBy': FieldValue.arrayUnion([uid]),
          });
        }
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      // Avoid crashing on permission issues; log for debugging.
      print('markAsRead permission error: ${e.code}');
    } catch (e) {
      print('markAsRead failed: $e');
    }
  }

  Future<void> markAsUnread(String conversationId) async {
    final uid = currentUserId;
    if (uid == null) return;

    // tăng bộ đếm chưa đọc cho người dùng hiện tại để cuộc trò chuyện hiển thị chưa đọc
    await _conversationsCollection.doc(conversationId).update({
      'unreadCount.$uid': FieldValue.increment(1),
    });
  }

  // Lấy các cuộc trò chuyện của người dùng
  Stream<List<ConversationModel>> getConversations() {
    return _auth.authStateChanges().asyncExpand((user) {
      final uid = user?.uid;
      if (uid == null) return Stream.value(<ConversationModel>[]);

      return _conversationsCollection
          .where('participants', arrayContains: uid)
          .where('isArchived', isEqualTo: false)
          .orderBy('lastMessageAt', descending: true)
          .snapshots()
          .handleError((error) {
            print('Error in getConversations: $error');
            // Return empty list if index is not ready
            return <QueryDocumentSnapshot<Map<String, dynamic>>>[];
          })
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => ConversationModel.fromFirestore(doc))
                .toList(),
          );
    });
  }

  // Luồng cuộc trò chuyện
  Stream<ConversationModel?> streamConversation(String conversationId) {
    return _conversationsCollection
        .doc(conversationId)
        .snapshots()
        .map((doc) => doc.exists ? ConversationModel.fromFirestore(doc) : null);
  }

  // Xóa tin nhắn (chỉ dành cho người gửi)
  Future<void> deleteMessage(String conversationId, String messageId) async {
    final uid = currentUserId;
    if (uid == null) return;

    final messageDoc = await _conversationsCollection
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .get();

    if (messageDoc.exists && messageDoc.data()?['senderId'] == uid) {
      await messageDoc.reference.update({
        'isDeleted': true,
        'content': 'Tin nhắn đã bị xóa',
        'mediaUrl': null,
      });
    }
  }

  // Gọi lại tin nhắn (xóa cho mọi người) - chỉ người gửi mới có thể
  Future<void> recallMessage(String conversationId, String messageId) async {
    final uid = currentUserId;
    if (uid == null) return;

    final messageDoc = await _conversationsCollection
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .get();

    if (messageDoc.exists && messageDoc.data()?['senderId'] == uid) {
      await messageDoc.reference.update({
        'isRecalled': true,
        'content': 'Tin nhắn đã được thu hồi',
        'mediaUrl': null,
      });
    }
  }

  // Xóa tin nhắn chỉ cho người dùng hiện tại (ẩn khỏi họ)
  Future<void> deleteMessageForMe(
    String conversationId,
    String messageId,
  ) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _conversationsCollection
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .update({
          'deletedFor': FieldValue.arrayUnion([uid]),
        });
  }

  // Lưu trữ cuộc trò chuyện
  Future<void> archiveConversation(String conversationId) async {
    await _conversationsCollection.doc(conversationId).update({
      'isArchived': true,
    });
  }

  // Hủy lưu trữ cuộc trò chuyện
  Future<void> unarchiveConversation(String conversationId) async {
    await _conversationsCollection.doc(conversationId).update({
      'isArchived': false,
    });
  }

  // Xóa vĩnh viễn cuộc trò chuyện và tất cả tin nhắn của nó.
  // Thao tác này là "xóa phía người dùng" để tránh lỗi quyền trên
  // subcollection tin nhắn (người dùng chỉ được xóa tin do mình gửi).
  Future<void> deleteConversation(String conversationId) async {
    final uid = currentUserId;
    if (uid == null) return;

    final docRef = _conversationsCollection.doc(conversationId);
    final snapshot = await docRef.get();
    if (!snapshot.exists) return;

    // tùy chọn, kiểm tra UID là thành viên không. nếu không thì bỏ qua.
    final participants = List<String>.from(
      snapshot.data()?['participants'] ?? [],
    );
    if (!participants.contains(uid)) return;

    // Soft-delete: chỉ ẩn cuộc trò chuyện cho người hiện tại
    await docRef.update({
      'deletedFor': FieldValue.arrayUnion([uid]),
    });

    // Also mark all existing messages as deleted for this user
    try {
      final messagesSnapshot = await docRef.collection('messages').get();
      if (messagesSnapshot.docs.isNotEmpty) {
        var batch = _firestore.batch();
        var count = 0;
        for (var m in messagesSnapshot.docs) {
          batch.update(m.reference, {
            'deletedFor': FieldValue.arrayUnion([uid])
          });
          count++;
          if (count >= 490) {
            await batch.commit();
            batch = _firestore.batch();
            count = 0;
          }
        }
        if (count > 0) {
          await batch.commit();
        }
      }
    } catch (e) {
      // Ignore if batch fails
    }
  }

  // return a one‑time snapshot of all messages (used when preparing undo)
  Future<List<MessageModel>> getMessagesOnce(String conversationId) async {
    final snap = await _conversationsCollection
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .get();
    return snap.docs.map((d) => MessageModel.fromFirestore(d)).toList();
  }

  /// Recreate a deleted conversation and its messages.  The provided
  /// conversation object must represent the document prior to deletion; the
  /// messages list should contain all messages (including IDs) so they can be
  /// re‑written with their original IDs.
  Future<void> restoreConversation(
    ConversationModel conversation,
    List<MessageModel> messages,
  ) async {
    final docRef = _conversationsCollection.doc(conversation.id);
    final uid = currentUserId;
    final existing = await docRef.get();
    if (existing.exists && uid != null) {
      await docRef.update({
        'deletedFor': FieldValue.arrayRemove([uid]),
      });

      // Also restore messages
      try {
        final messagesSnapshot = await docRef.collection('messages').get();
        if (messagesSnapshot.docs.isNotEmpty) {
          var batch = _firestore.batch();
          var count = 0;
          for (var m in messagesSnapshot.docs) {
            batch.update(m.reference, {
              'deletedFor': FieldValue.arrayRemove([uid])
            });
            count++;
            if (count >= 490) {
              await batch.commit();
              batch = _firestore.batch();
              count = 0;
            }
          }
          if (count > 0) {
            await batch.commit();
          }
        }
      } catch (e) {
        // Ignore
      }

      return;
    }

    await docRef.set(conversation.toFirestore());

    final batch = _firestore.batch();
    int writeCount = 0;
    for (final msg in messages) {
      final msgRef = docRef.collection('messages').doc(msg.id);
      batch.set(msgRef, msg.toFirestore());
      writeCount += 1;
      if (writeCount >= 450) {
        await batch.commit();
        writeCount = 0;
      }
    }
    if (writeCount > 0) await batch.commit();
  }

  // Leave group conversation
  Future<void> leaveGroup(String conversationId) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _conversationsCollection.doc(conversationId).update({
      'participants': FieldValue.arrayRemove([uid]),
      'participantNames.$uid': FieldValue.delete(),
      'participantPhotos.$uid': FieldValue.delete(),
    });
  }

  // Add participants to group
  Future<void> addParticipantsToGroup({
    required String conversationId,
    required List<String> participantIds,
    required Map<String, String> participantNames,
    Map<String, String?>? participantPhotos,
  }) async {
    final updates = <String, dynamic>{
      'participants': FieldValue.arrayUnion(participantIds),
    };

    for (final entry in participantNames.entries) {
      updates['participantNames.${entry.key}'] = entry.value;
    }

    if (participantPhotos != null) {
      for (final entry in participantPhotos.entries) {
        updates['participantPhotos.${entry.key}'] = entry.value;
      }
    }

    await _conversationsCollection.doc(conversationId).update(updates);
  }

  // Update group name
  Future<void> updateGroupName(String conversationId, String name) async {
    await _conversationsCollection.doc(conversationId).update({'name': name});
  }

  // Update group photo
  Future<String?> updateGroupPhoto(
    String conversationId,
    File imageFile,
  ) async {
    try {
      final ref = _storage.ref().child('group_photos/$conversationId.jpg');
      await ref.putFile(imageFile);
      final downloadUrl = await ref.getDownloadURL();

      await _conversationsCollection.doc(conversationId).update({
        'photoUrl': downloadUrl,
      });

      return downloadUrl;
    } catch (e) {
      print('Error uploading group photo: $e');
      return null;
    }
  }

  // Get unread messages count
  Stream<int> getTotalUnreadCount() {
    final uid = currentUserId;
    if (uid == null) return Stream.value(0);

    return _conversationsCollection
        .where('participants', arrayContains: uid)
        .where('isArchived', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
          int total = 0;
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final deletedFor = List<String>.from(data['deletedFor'] ?? []);
            if (deletedFor.contains(uid)) continue;

            final participants = List<String>.from(data['participants'] ?? []);
            if (participants.contains('trip_ai')) continue;

            final unreadCount = data['unreadCount'] as Map<String, dynamic>?;
            total += (unreadCount?[uid] as int?) ?? 0;
          }
          return total;
        });
  }

  // Typing indicator
  Future<void> setTyping(String conversationId, bool isTyping) async {
    final uid = currentUserId;
    if (uid == null) return;

    if (isTyping) {
      await _conversationsCollection.doc(conversationId).update({
        'typing': FieldValue.arrayUnion([uid]),
      });
    } else {
      await _conversationsCollection.doc(conversationId).update({
        'typing': FieldValue.arrayRemove([uid]),
      });
    }
  }

  /// Accept a message request - adds current user to acceptedBy list
  Future<void> acceptConversation(String conversationId) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _conversationsCollection.doc(conversationId).update({
      'acceptedBy': FieldValue.arrayUnion([uid]),
    });
  }

  /// Reject/delete a message request - removes the conversation
  /// Same as deleteConversation but can add additional logic later
  Future<void> rejectConversation(String conversationId) async {
    return deleteConversation(conversationId);
  }
}
