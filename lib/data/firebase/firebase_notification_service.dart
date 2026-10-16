import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/notification_model.dart';

class FirebaseNotificationService {
  // Singleton pattern
  static final FirebaseNotificationService _instance =
      FirebaseNotificationService._internal();
  factory FirebaseNotificationService() => _instance;
  FirebaseNotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _notificationsCollection =>
      _firestore.collection('notifications');

  String? get currentUserId => _auth.currentUser?.uid;

  Future<void> sendNotification({
    required String recipientId,
    required String message,
    NotificationType type = NotificationType.custom,
    String? senderName,
    String? senderPhotoUrl,
    String? senderId,
    Map<String, dynamic>? extraData,
    bool isBusinessNotification = false,
  }) async {
    final uid = currentUserId;
    if ((uid == null && senderId == null) || recipientId.isEmpty) return;
    final resolvedSenderId = senderId ?? uid;
    if (resolvedSenderId == null) return;

    await _notificationsCollection.add({
      'recipientId': recipientId,
      'senderId': resolvedSenderId,
      'senderName': senderName ?? _auth.currentUser?.displayName ?? '',
      'senderPhotoUrl': senderPhotoUrl,
      'message': message,
      'type': type.name,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      'isBusinessNotification': isBusinessNotification,
      if (extraData != null) ...extraData,
    });
  }

  Stream<List<NotificationModel>> getNotificationsForUser({int limit = 50}) {
    // Trước đây ta dùng orderBy `createdAt` để thông báo mới nhất luôn
    // được trả về. Thật không may truy vấn đó cần một chỉ mục ghép
    // (`recipientId` + `createdAt`), khiến app crash với người dùng chưa
    // tạo chỉ mục.
    //
    // Để tăng độ bền, giờ ta bỏ ordering và chỉ dựa vào sắp xếp phía
    // client trong UI. Firestore vẫn tuân `limit` nhưng có thể trả tập
    // con ngẫu nhiên; UI sẽ sort lại nên thông báo mới thường xuất hiện
    // đầu tiên.
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) return Stream.value(<NotificationModel>[]);
      final query = _notificationsCollection
          .where('recipientId', isEqualTo: user.uid)
          .limit(limit);
      return query
          .snapshots()
          .handleError((e) {
            print('[NotificationService] getNotifications error: $e');
          })
          .map(
            (snap) => snap.docs
                .map((d) => NotificationModel.fromFirestore(d))
                .toList(),
          );
    });
  }

  Stream<int> getUnreadCountForUser() {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) return Stream.value(0);
      return _notificationsCollection
          .where('recipientId', isEqualTo: user.uid)
          .snapshots()
          .handleError((e) {
            print('[NotificationService] getUnreadCount error: $e');
          })
          .map((snap) {
            int count = 0;
            for (final doc in snap.docs) {
              final data = doc.data();
              final isRead = data['isRead'] as bool?;
              if (isRead != true) {
                count += 1;
              }
            }
            return count;
          });
    });
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).update({'isRead': true});
    } catch (e) {
      print('[NotificationService] markAsRead error: $e');
    }
  }

  Future<void> markAllAsReadForUser() async {
    final uid = currentUserId;
    if (uid == null) return;

    final querySnapshot = await _notificationsCollection
        .where('recipientId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .get();
    if (querySnapshot.docs.isEmpty) return;

    WriteBatch batch = _firestore.batch();
    int opCount = 0;

    for (final doc in querySnapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
      opCount += 1;
      if (opCount == 450) {
        await batch.commit();
        batch = _firestore.batch();
        opCount = 0;
      }
    }

    if (opCount > 0) {
      await batch.commit();
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    await _notificationsCollection.doc(notificationId).delete();
  }

  /// Xóa mọi thông báo thuộc về người dùng đang đăng nhập.
  Future<void> clearNotificationsForUser() async {
    final uid = currentUserId;
    if (uid == null) return;
    final querySnapshot = await _notificationsCollection
        .where('recipientId', isEqualTo: uid)
        .get();
    for (final doc in querySnapshot.docs) {
      await doc.reference.delete();
    }
  }

  /// Xóa thông báo theo phân loại cá nhân / kinh doanh.
  /// Nếu [isBusiness] là true, chỉ xóa thông báo kinh doanh;
  /// nếu false, chỉ xóa thông báo cá nhân.
  Future<void> clearNotificationsByCategory({required bool isBusiness}) async {
    final uid = currentUserId;
    if (uid == null) return;
    final querySnapshot = await _notificationsCollection
        .where('recipientId', isEqualTo: uid)
        .get();
    for (final doc in querySnapshot.docs) {
      final data = doc.data();
      final flag = data['isBusinessNotification'] ?? false;
      if (flag == isBusiness) {
        await doc.reference.delete();
      }
    }
  }

  /// Gửi thông báo hệ thống (từ app, không phải người dùng)
  Future<void> sendSystemNotification({
    required String recipientId,
    required String message,
    required String senderName,
    NotificationType type = NotificationType.custom,
    String? tripId,
    String? bookingId,
    String? bookingType,
    bool isBusinessNotification = false,
  }) async {
    if (recipientId.isEmpty) return;

    print('[NotificationService] sendSystemNotification to $recipientId');
    try {
      await _notificationsCollection.add({
        'recipientId': recipientId,
        'senderId': 'system',
        'senderName': senderName,
        'senderPhotoUrl': null,
        'message': message,
        'type': type.name,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'isBusinessNotification': isBusinessNotification,
        if (tripId != null) 'tripId': tripId,
        if (bookingId != null) 'bookingId': bookingId,
        if (bookingType != null) 'bookingType': bookingType,
      });
      print('[NotificationService] sendSystemNotification completed');
    } catch (e) {
      print('[NotificationService] sendSystemNotification ERROR: $e');
      rethrow;
    }
  }
}
