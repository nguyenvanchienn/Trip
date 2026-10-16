import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tourn/data/firebase/firebase_notification_service.dart';
import 'package:tourn/models/menu_models.dart';
import 'package:tourn/models/notification_model.dart';

/// Helper class for sending trip-related notifications
class TripNotificationHelper {
  final FirebaseNotificationService _notificationService =
      FirebaseNotificationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get user display name from uid
  Future<String> _getUserName(String uid) async {
    final userDoc = await _firestore.collection('users').doc(uid).get();
    if (userDoc.exists) {
      final data = userDoc.data();
      return data?['displayName'] ?? data?['name'] ?? 'Người dùng';
    }
    return 'Người dùng';
  }

  /// Send notification when a user joins a trip
  Future<void> sendJoinNotifications({
    required TripModel trip,
    required String joinerId,
    required bool isFull,
  }) async {
    // Get joiner's name
    final joinerName = await _getUserName(joinerId);

    // Notify the trip owner that someone joined (with joiner name)
    await _notificationService.sendSystemNotification(
      recipientId: trip.userId,
      message:
          '$joinerName đã tham gia chuyến đi "${trip.name}"! '
          'Thành viên: ${trip.members.length}/${trip.maxMembers}',
      senderName: 'Trip',
      type: NotificationType.custom,
      tripId: trip.id,
    );

    // Notify the joiner that they successfully joined
    await _notificationService.sendSystemNotification(
      recipientId: joinerId,
      message:
          'Bạn đã tham gia chuyến đi "${trip.name}" thành công! '
          'Địa điểm: ${trip.allLocations.join(" → ")}',
      senderName: 'Trip',
      type: NotificationType.custom,
      tripId: trip.id,
    );

    // If trip is now full, notify all members
    if (isFull) {
      await sendTripFullNotifications(trip);
    }
  }

  /// Send notifications when trip is full
  Future<void> sendTripFullNotifications(TripModel trip) async {
    for (final memberId in trip.members) {
      await _notificationService.sendSystemNotification(
        recipientId: memberId,
        message:
            'Chuyến đi "${trip.name}" đã đủ người! '
            '${trip.members.length}/${trip.maxMembers} thành viên.',
        senderName: 'Trip',
        type: NotificationType.custom,
        tripId: trip.id,
      );
    }
  }

  /// Send notification when trip is created
  Future<void> sendTripCreatedNotification(TripModel trip) async {
    await _notificationService.sendSystemNotification(
      recipientId: trip.userId,
      message:
          'Chuyến đi "${trip.name}" đã được tạo thành công! '
          'Địa điểm: ${trip.allLocations.join(" → ")}',
      senderName: 'Trip',
      type: NotificationType.custom,
      tripId: trip.id,
    );
  }

  /// Send notifications when trip is cancelled
  Future<void> sendTripCancelledNotifications(TripModel trip) async {
    for (final memberId in trip.members) {
      await _notificationService.sendSystemNotification(
        recipientId: memberId,
        message: 'Chuyến đi "${trip.name}" đã bị hủy.',
        senderName: 'Trip',
        type: NotificationType.custom,
        tripId: trip.id,
      );
    }
  }

  /// Send notifications when trip is starting soon (10 hours)
  Future<void> sendTripStartingNotifications(TripModel trip) async {
    final hoursUntilStart = trip.startDate.difference(DateTime.now()).inHours;

    for (final memberId in trip.members) {
      await _notificationService.sendSystemNotification(
        recipientId: memberId,
        message:
            'Chuyến đi "${trip.name}" sẽ bắt đầu trong $hoursUntilStart giờ nữa! '
            'Thành viên: ${trip.members.length}/${trip.maxMembers}',
        senderName: 'Trip',
        type: NotificationType.custom,
        tripId: trip.id,
      );
    }
  }

  /// Send notification when trip starts (status changes to active)
  Future<void> sendTripStartedNotifications(TripModel trip) async {
    for (final memberId in trip.members) {
      await _notificationService.sendSystemNotification(
        recipientId: memberId,
        message:
            'Chuyến đi "${trip.name}" đã bắt đầu! Chúc bạn có chuyến đi vui vẻ!',
        senderName: 'Trip',
        type: NotificationType.custom,
        tripId: trip.id,
      );
    }
  }

  /// Send notification when a member leaves
  Future<void> sendMemberLeftNotifications({
    required TripModel trip,
    required String leaverId,
  }) async {
    // Get leaver's name
    final leaverName = await _getUserName(leaverId);

    // Notify leaver
    await _notificationService.sendSystemNotification(
      recipientId: leaverId,
      message: 'Bạn đã rời khỏi chuyến đi "${trip.name}".',
      senderName: 'Trip',
      type: NotificationType.custom,
      tripId: trip.id,
    );

    // Notify owner with leaver name
    await _notificationService.sendSystemNotification(
      recipientId: trip.userId,
      message:
          '$leaverName đã rời khỏi chuyến đi "${trip.name}". '
          'Thành viên còn lại: ${trip.members.length - 1}/${trip.maxMembers}',
      senderName: 'Trip',
      type: NotificationType.custom,
      tripId: trip.id,
    );
  }

  /// Send notification when trip completes
  Future<void> sendTripCompletedNotifications(TripModel trip) async {
    for (final memberId in trip.members) {
      await _notificationService.sendSystemNotification(
        recipientId: memberId,
        message:
            'Chuyến đi "${trip.name}" đã hoàn thành! '
            'Cảm ơn bạn đã tham gia.',
        senderName: 'Trip',
        type: NotificationType.custom,
        tripId: trip.id,
      );
    }
  }

  /// Send notification when trip is edited (to all members except owner)
  Future<void> sendTripEditedNotifications(TripModel trip) async {
    for (final memberId in trip.members) {
      // Skip the owner - they made the changes
      if (memberId == trip.userId) continue;

      await _notificationService.sendSystemNotification(
        recipientId: memberId,
        message:
            'Chuyến đi "${trip.name}" đã được cập nhật! '
            'Kiểm tra thông tin mới nhất.',
        senderName: 'Trip',
        type: NotificationType.custom,
        tripId: trip.id,
      );
    }
  }
}
