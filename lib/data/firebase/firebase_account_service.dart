import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../../models/account_settings_model.dart';
import '../../models/notification_model.dart';
import 'firebase_notification_service.dart';
import 'dart:async';

/// Service quản lý thông tin tài khoản người dùng với Firebase
class FirebaseAccountService {
  // Singleton pattern
  static final FirebaseAccountService _instance =
      FirebaseAccountService._internal();
  factory FirebaseAccountService() => _instance;
  FirebaseAccountService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseNotificationService _notificationService =
      FirebaseNotificationService();

  // Collection references
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _accountSettingsCollection =>
      _firestore.collection('account_settings');

  CollectionReference<Map<String, dynamic>> get _activityHistoryCollection =>
      _firestore.collection('activity_history');

  String? get currentUserId => _auth.currentUser?.uid;

  // ======================== THÔNG TIN TÀI KHOẢN ========================

  /// Lấy thông tin tài khoản hiện tại
  Future<UserModel?> getCurrentUser() async {
    final uid = currentUserId;
    if (uid == null) return null;

    final doc = await _usersCollection.doc(uid).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    return null;
  }

  /// Lấy cài đặt tài khoản của một người dùng bất kỳ
  Future<AccountSettingsModel> getAccountSettingsForUser(String uid) async {
    try {
      final doc = await _accountSettingsCollection.doc(uid).get();
      if (doc.exists) {
        return AccountSettingsModel.fromFirestore(doc);
      }
    } catch (_) {
      // Fall back to public user profile when account_settings is restricted.
    }

    try {
      final userDoc = await _usersCollection.doc(uid).get();
      final isPrivate = userDoc.data()?['isPrivate'] as bool? ?? false;
      return AccountSettingsModel(isPrivate: isPrivate);
    } catch (_) {
      return AccountSettingsModel.defaults();
    }
  }

  /// Cập nhật tên đầy đủ (Họ + Tên đệm + Tên)
  Future<({bool success, String? error})> updateFullName({
    required String firstName,
    String? middleName,
    required String lastName,
    String? displayNameFormat, // 'first_last' hoặc 'last_first'
  }) async {
    final uid = currentUserId;
    if (uid == null) return (success: false, error: 'Chưa đăng nhập');

    try {
      // Kiểm tra xem có thể đổi tên không (60 ngày hạn chế)
      final doc = await _usersCollection.doc(uid).get();
      final data = doc.data();
      if (data != null) {
        final lastChange = (data['lastNameChange'] as Timestamp?)?.toDate();
        if (lastChange != null) {
          final daysSinceChange = DateTime.now().difference(lastChange).inDays;
          if (daysSinceChange < 60) {
            return (
              success: false,
              error:
                  'Bạn chỉ có thể đổi tên sau ${60 - daysSinceChange} ngày nữa',
            );
          }
        }
      }

      final middlePart = (middleName != null && middleName.isNotEmpty)
          ? ' $middleName'
          : '';

      // Tạo displayName theo format được chọn
      String fullName;
      if (displayNameFormat == 'first_last') {
        fullName = '$firstName$middlePart $lastName';
      } else {
        // Default: last_first (Họ Tên đệm Tên)
        fullName = '$lastName$middlePart $firstName';
      }

      await _usersCollection.doc(uid).update({
        'displayName': fullName,
        'firstName': firstName,
        'middleName': middleName ?? '',
        'lastName': lastName,
        'displayNameFormat': displayNameFormat ?? 'last_first',
        'lastNameChange': Timestamp.fromDate(DateTime.now()),
      });

      // Ghi lịch sử thay đổi tên
      await _recordAccountHistory('name_change', {
        'oldName': data?['displayName'],
        'newName': fullName,
      });

      return (success: true, error: null);
    } catch (e) {
      return (success: false, error: e.toString());
    }
  }

  /// Lấy thông tin tên chi tiết
  Future<({String? firstName, String? middleName, String? lastName})>
  getNameParts() async {
    final uid = currentUserId;
    if (uid == null) return (firstName: null, middleName: null, lastName: null);

    final doc = await _usersCollection.doc(uid).get();
    final data = doc.data();
    if (data == null) {
      return (firstName: null, middleName: null, lastName: null);
    }

    return (
      firstName: data['firstName'] as String?,
      middleName: data['middleName'] as String?,
      lastName: data['lastName'] as String?,
    );
  }

  /// Cập nhật ngày sinh
  Future<({bool success, String? error})> updateBirthday(
    DateTime birthday,
  ) async {
    final uid = currentUserId;
    if (uid == null) return (success: false, error: 'Chưa đăng nhập');

    try {
      final doc = await _usersCollection.doc(uid).get();
      final oldBirthday = doc.data()?['birthday'];

      await _usersCollection.doc(uid).update({
        'birthday': Timestamp.fromDate(birthday),
      });

      await _recordAccountHistory('birthday_change', {
        'oldBirthday': oldBirthday,
        'newBirthday': Timestamp.fromDate(birthday),
      });

      return (success: true, error: null);
    } catch (e) {
      return (success: false, error: e.toString());
    }
  }

  /// Lấy ngày sinh
  Future<DateTime?> getBirthday() async {
    final uid = currentUserId;
    if (uid == null) return null;

    final doc = await _usersCollection.doc(uid).get();
    final data = doc.data();
    if (data == null) return null;

    return (data['birthday'] as Timestamp?)?.toDate();
  }

  /// Cập nhật email
  Future<({bool success, String? error})> updateEmail(String newEmail) async {
    final uid = currentUserId;
    if (uid == null) return (success: false, error: 'Chưa đăng nhập');

    try {
      final user = _auth.currentUser;
      if (user == null) return (success: false, error: 'Chưa đăng nhập');

      // Gửi email xác minh
      await user.verifyBeforeUpdateEmail(newEmail);

      await _recordAccountHistory('email_change_request', {
        'oldEmail': user.email,
        'newEmail': newEmail,
      });

      return (success: true, error: null);
    } on FirebaseAuthException catch (e) {
      return (success: false, error: e.message);
    } catch (e) {
      return (success: false, error: e.toString());
    }
  }

  /// Lấy danh sách email (chính + phụ)
  Future<List<String>> getEmails() async {
    final uid = currentUserId;
    if (uid == null) return [];

    final user = _auth.currentUser;
    final primaryEmail = user?.email;

    final doc = await _usersCollection.doc(uid).get();
    final data = doc.data();
    final secondaryEmails = List<String>.from(data?['secondaryEmails'] ?? []);

    return [if (primaryEmail != null) primaryEmail, ...secondaryEmails];
  }

  /// Cập nhật số điện thoại
  Future<({bool success, String? error})> updatePhoneNumber(
    String phoneNumber,
  ) async {
    final uid = currentUserId;
    if (uid == null) return (success: false, error: 'Chưa đăng nhập');

    try {
      final doc = await _usersCollection.doc(uid).get();
      final oldPhone = doc.data()?['phone'];

      await _usersCollection.doc(uid).update({'phone': phoneNumber});

      await _recordAccountHistory('phone_change', {
        'oldPhone': oldPhone,
        'newPhone': phoneNumber,
      });

      return (success: true, error: null);
    } catch (e) {
      return (success: false, error: e.toString());
    }
  }

  /// Lấy số điện thoại
  Future<String?> getPhoneNumber() async {
    final uid = currentUserId;
    if (uid == null) return null;

    final doc = await _usersCollection.doc(uid).get();
    return doc.data()?['phone'] as String?;
  }

  // ======================== CÀI ĐẶT QUYỀN RIÊNG TƯ ========================

  /// Lấy cài đặt quyền riêng tư
  Future<AccountSettingsModel> getAccountSettings() async {
    final uid = currentUserId;
    if (uid == null) return AccountSettingsModel.defaults();
    try {
      final doc = await _accountSettingsCollection.doc(uid).get();
      if (doc.exists) {
        final settings = AccountSettingsModel.fromFirestore(doc);
        try {
          await _usersCollection.doc(uid).set({
            'isPrivate': settings.isPrivate,
          }, SetOptions(merge: true));
        } catch (_) {
          // Best-effort sync; ignore errors.
        }
        return settings;
      }
      return AccountSettingsModel.defaults();
    } catch (e) {
      return AccountSettingsModel.defaults();
    }
  }

  /// Cập nhật cài đặt tài khoản riêng tư
  Future<void> updatePrivateAccount(bool isPrivate) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _accountSettingsCollection.doc(uid).set({
      'isPrivate': isPrivate,
    }, SetOptions(merge: true));

    await _usersCollection.doc(uid).set({
      'isPrivate': isPrivate,
    }, SetOptions(merge: true));

    await _recordAccountHistory('privacy_change', {
      'setting': 'isPrivate',
      'value': isPrivate,
    });
  }

  /// Cập nhật trạng thái hoạt động
  Future<void> updateActivityStatus(bool showActivityStatus) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _accountSettingsCollection.doc(uid).set({
      'showActivityStatus': showActivityStatus,
    }, SetOptions(merge: true));
  }

  /// Cập nhật cài đặt bình luận
  Future<void> updateCommentSettings(String allowComments) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _accountSettingsCollection.doc(uid).set({
      'allowComments': allowComments, // 'everyone', 'followers', 'no_one'
    }, SetOptions(merge: true));
  }

  /// Cập nhật cài đặt nhắc đến
  Future<void> updateMentionSettings(String allowMentions) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _accountSettingsCollection.doc(uid).set({
      'allowMentions': allowMentions,
    }, SetOptions(merge: true));
  }

  /// Cập nhật cài đặt tin nhắn
  Future<void> updateMessageSettings(String allowMessages) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _accountSettingsCollection.doc(uid).set({
      'allowMessages': allowMessages,
    }, SetOptions(merge: true));
  }

  /// Cập nhật cài đặt tải về
  Future<void> updateDownloadSettings(bool allowDownloads) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _accountSettingsCollection.doc(uid).set({
      'allowDownloads': allowDownloads,
    }, SetOptions(merge: true));
  }

  /// Cập nhật cài đặt gắn thẻ
  Future<void> updateTagSettings(String allowTags) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _accountSettingsCollection.doc(uid).set({
      'allowTags': allowTags,
    }, SetOptions(merge: true));
  }

  Future<void> updateBusinessMode(bool isBusiness) async {
    final uid = currentUserId;
    if (uid == null) return;

    // Optimistic update (fire and forget) để tránh treo UI khi mạng yếu
    unawaited(_accountSettingsCollection.doc(uid).set({
      'isBusiness': isBusiness,
    }, SetOptions(merge: true)));

    unawaited(_usersCollection.doc(uid).set({
      'isBusiness': isBusiness,
    }, SetOptions(merge: true)));

    unawaited(_recordAccountHistory('business_mode_change', {
      'isBusiness': isBusiness,
    }));

    final message = isBusiness
        ? 'Tài khoản của bạn đã được nâng cấp lên doanh nghiệp. Hãy khám phá các công cụ hỗ trợ kinh doanh.'
        : 'Tài khoản đã chuyển về cá nhân. Một số tính năng kinh doanh sẽ không còn hiển thị.';
    unawaited(
      _notificationService.sendSystemNotification(
        recipientId: uid,
        senderName: 'Trip',
        message: message,
        type: NotificationType.businessAccount,
        isBusinessNotification: true,
      ),
    );
  }

  // ======================== DANH SÁCH HẠN CHẾ & CHẶN ========================

  /// Lấy danh sách tài khoản bị hạn chế
  Future<List<String>> getRestrictedUsers() async {
    final uid = currentUserId;
    if (uid == null) return [];

    final doc = await _usersCollection.doc(uid).get();
    return List<String>.from(doc.data()?['restricted'] ?? []);
  }

  /// Hạn chế một tài khoản
  Future<void> restrictUser(String targetUserId) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _usersCollection.doc(uid).update({
      'restricted': FieldValue.arrayUnion([targetUserId]),
    });
  }

  /// Bỏ hạn chế một tài khoản
  Future<void> unrestrictUser(String targetUserId) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _usersCollection.doc(uid).update({
      'restricted': FieldValue.arrayRemove([targetUserId]),
    });
  }

  /// Lấy danh sách tài khoản bị chặn
  Future<List<String>> getBlockedUsers() async {
    final uid = currentUserId;
    if (uid == null) return [];

    final doc = await _usersCollection.doc(uid).get();
    return List<String>.from(doc.data()?['blocked'] ?? []);
  }

  /// Chặn một tài khoản
  Future<void> blockUser(String targetUserId) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _usersCollection.doc(uid).update({
      'blocked': FieldValue.arrayUnion([targetUserId]),
    });

    await _recordAccountHistory('block_user', {'targetUserId': targetUserId});
  }

  /// Bỏ chặn một tài khoản
  Future<void> unblockUser(String targetUserId) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _usersCollection.doc(uid).update({
      'blocked': FieldValue.arrayRemove([targetUserId]),
    });
  }

  // ======================== LỊCH SỬ TÀI KHOẢN ========================

  /// Ghi lịch sử thay đổi tài khoản
  Future<void> _recordAccountHistory(
    String action,
    Map<String, dynamic> details,
  ) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _activityHistoryCollection.doc(uid).collection('account').add({
      'action': action,
      'details': details,
      'timestamp': Timestamp.now(),
      'deviceInfo': await _getDeviceInfo(),
    });
  }

  /// Lấy thông tin thiết bị
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    return {'platform': 'mobile', 'timestamp': Timestamp.now()};
  }

  /// Lấy lịch sử tài khoản
  Future<List<Map<String, dynamic>>> getAccountHistory({int limit = 50}) async {
    final uid = currentUserId;
    if (uid == null) return [];

    final snapshot = await _activityHistoryCollection
        .doc(uid)
        .collection('account')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  /// Ghi đăng nhập mới
  Future<void> recordLogin() async {
    final uid = currentUserId;
    if (uid == null) return;

    await _recordAccountHistory('login', {'method': 'normal'});

    await _usersCollection.doc(uid).update({
      'lastLoginAt': Timestamp.now(),
      'isOnline': true,
    });
  }

  /// Đăng xuất
  Future<void> recordLogout() async {
    final uid = currentUserId;
    if (uid == null) return;

    await _recordAccountHistory('logout', {});

    await _usersCollection.doc(uid).update({
      'isOnline': false,
      'lastSeen': Timestamp.now(),
    });
  }

  // ======================== MỞ RỘNG THÔNG TIN PROFILE ========================

  /// Lấy thông tin mở rộng cho trang chỉnh sửa profile
  Future<Map<String, dynamic>?> getExtendedProfile() async {
    final uid = currentUserId;
    if (uid == null) return null;

    try {
      final doc = await _firestore.collection('user_profiles').doc(uid).get();

      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Lấy thông tin mở rộng của một người dùng bất kỳ
  Future<Map<String, dynamic>?> getUserExtendedProfile(String userId) async {
    try {
      final doc = await _firestore.collection('user_profiles').doc(userId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Cập nhật thông tin mở rộng profile
  Future<({bool success, String? error})> updateExtendedProfile(
    Map<String, dynamic> data,
  ) async {
    final uid = currentUserId;
    if (uid == null) return (success: false, error: 'Chưa đăng nhập');

    try {
      await _firestore.collection('user_profiles').doc(uid).set({
        ...data,
        'updatedAt': Timestamp.now(),
      }, SetOptions(merge: true));

      return (success: true, error: null);
    } catch (e) {
      return (success: false, error: e.toString());
    }
  }

  // ======================== HO TRO ========================

  Future<({bool success, String? error})> submitSupportRequest({
    required String subject,
    required String message,
  }) async {
    final uid = currentUserId;
    if (uid == null) return (success: false, error: 'Chưa đăng nhập');

    try {
      await _firestore.collection('support_requests').add({
        'uid': uid,
        'subject': subject,
        'message': message,
        'status': 'open',
        'createdAt': Timestamp.now(),
      });
      return (success: true, error: null);
    } catch (e) {
      return (success: false, error: e.toString());
    }
  }
}
