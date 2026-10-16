import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  like,
  comment,
  mention,
  share,
  live,
  follow,
  followRequest,
  message,
  welcome,
  completeProfile,
  businessAccount,
  custom,
}

NotificationType _notificationTypeFromString(String? value) {
  if (value == null) return NotificationType.custom;
  return NotificationType.values.firstWhere(
    (e) => e.name == value,
    orElse: () => NotificationType.custom,
  );
}

class NotificationModel {
  final String id;
  final String recipientId;
  final String senderId;
  final String senderName;
  final String? senderPhotoUrl;
  final String message;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;
  final String? postId; // optional related post identifier
  final String? conversationId; // optional related conversation for messages
  final String? tripId; // optional related trip identifier
  final String? bookingId; // optional related booking identifier
  final String? bookingType; // hotel, guide, photographer, clothes
  final bool isBusinessNotification; // true = business notification, false = personal

  NotificationModel({
    required this.id,
    required this.recipientId,
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl,
    required this.message,
    this.type = NotificationType.custom,
    this.isRead = false,
    required this.createdAt,
    this.postId,
    this.conversationId,
    this.tripId,
    this.bookingId,
    this.bookingType,
    this.isBusinessNotification = false,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return NotificationModel(
      id: doc.id,
      recipientId: data['recipientId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderPhotoUrl: data['senderPhotoUrl'],
      message: data['message'] ?? '',
      type: _notificationTypeFromString(data['type']),
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      postId: data['postId'] as String?,
      conversationId: data['conversationId'] as String?,
      tripId: data['tripId'] as String?,
      bookingId: data['bookingId'] as String?,
      bookingType: data['bookingType'] as String?,
      isBusinessNotification: data['isBusinessNotification'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'recipientId': recipientId,
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'message': message,
      'type': type.name,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      if (postId != null) 'postId': postId,
      if (conversationId != null) 'conversationId': conversationId,
      if (tripId != null) 'tripId': tripId,
      if (bookingId != null) 'bookingId': bookingId,
      if (bookingType != null) 'bookingType': bookingType,
      'isBusinessNotification': isBusinessNotification,
    };
  }

  NotificationModel copyWith({
    bool? isRead,
    String? postId,
    String? conversationId,
    String? tripId,
    String? bookingId,
    String? bookingType,
    bool? isBusinessNotification,
  }) {
    return NotificationModel(
      id: id,
      recipientId: recipientId,
      senderId: senderId,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      message: message,
      type: type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      postId: postId ?? this.postId,
      conversationId: conversationId ?? this.conversationId,
      tripId: tripId ?? this.tripId,
      bookingId: bookingId ?? this.bookingId,
      bookingType: bookingType ?? this.bookingType,
      isBusinessNotification: isBusinessNotification ?? this.isBusinessNotification,
    );
  }
}
