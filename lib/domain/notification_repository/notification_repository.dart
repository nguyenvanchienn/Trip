import 'package:tourn/data/firebase/firebase_notification_service.dart';
import 'package:tourn/models/notification_model.dart';

abstract class NotificationRepository {
  String? get currentUserId;

  Stream<List<NotificationModel>> getNotifications({int limit});
  Stream<int> getUnreadCount();
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead();

  /// Xóa một thông báo theo id.
  Future<void> deleteNotification(String notificationId);

  Future<void> sendNotification({
    required String recipientId,
    required String message,
    NotificationType type,
  });

  /// Xóa tất cả thông báo của người dùng hiện tại trên backend.
  Future<void> clearAll();

  /// Gửi thông báo hệ thống (từ app) đến người dùng cụ thể
  Future<void> sendSystemNotification({
    required String recipientId,
    required String message,
    required String senderName,
    NotificationType type,
    String? tripId,
    String? bookingId,
    String? bookingType,
    bool isBusinessNotification,
  });
}

class FirestoreNotificationRepository implements NotificationRepository {
  final FirebaseNotificationService _service = FirebaseNotificationService();

  @override
  String? get currentUserId => _service.currentUserId;

  @override
  Stream<List<NotificationModel>> getNotifications({int limit = 50}) {
    return _service.getNotificationsForUser(limit: limit);
  }

  @override
  Stream<int> getUnreadCount() {
    return _service.getUnreadCountForUser();
  }

  @override
  Future<void> markAsRead(String notificationId) {
    return _service.markAsRead(notificationId);
  }

  @override
  Future<void> markAllAsRead() {
    return _service.markAllAsReadForUser();
  }

  @override
  Future<void> deleteNotification(String notificationId) {
    return _service.deleteNotification(notificationId);
  }

  @override
  Future<void> sendNotification({
    required String recipientId,
    required String message,
    NotificationType type = NotificationType.custom,
  }) {
    return _service.sendNotification(
      recipientId: recipientId,
      message: message,
      type: type,
    );
  }

  @override
  Future<void> clearAll() {
    return _service.clearNotificationsForUser();
  }

  @override
  Future<void> sendSystemNotification({
    required String recipientId,
    required String message,
    required String senderName,
    NotificationType type = NotificationType.custom,
    String? tripId,
    String? bookingId,
    String? bookingType,
    bool isBusinessNotification = false,
  }) {
    return _service.sendSystemNotification(
      recipientId: recipientId,
      message: message,
      senderName: senderName,
      type: type,
      tripId: tripId,
      bookingId: bookingId,
      bookingType: bookingType,
      isBusinessNotification: isBusinessNotification,
    );
  }
}
