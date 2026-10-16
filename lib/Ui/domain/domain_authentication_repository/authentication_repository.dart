import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tourn/Ui/domain/domain_data_sources/firebase_auth_sevice.dart';
import 'package:tourn/data/firebase/firebase_user_service.dart';
import 'package:tourn/data/firebase/firebase_notification_service.dart';
import 'package:tourn/models/notification_model.dart';

abstract class AuthenticationRepository {
  // Hàm đăng nhập bằng email (hỗ trợ cả primary và additional emails)
  Future<void> loginInWithEmailAndPassword({
    required String email,
    required String password,
  });

  // Hàm đăng ký tài khoản mới bằng email
  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  });

  // Hàm gửi lại email xác thực
  Future<void> sendEmailVerification();

  // Hàm gửi email đặt lại mật khẩu
  Future<void> sendPasswordResetEmail({required String email});

  // Thay đổi mật khẩu cho người dùng đã đăng nhập (reauth required)
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  });

  // Kiểm tra email đã tồn tại trong hệ thống (để tránh gửi link tới email chưa đăng ký)
  Future<bool> isEmailRegistered({required String email});

  // Lấy danh sách provider (debug/diagnose)
  Future<List<String>> fetchSignInMethodsForEmail({required String email});

  // Hàm kiểm tra email đã xác thực chưa
  Future<bool> isEmailVerified();

  // Hàm gửi OTP đến số điện thoại
  Future<void> sendOTPToPhone({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
    Function(PhoneAuthCredential credential)? onAutoVerified,
  });

  // Hàm xác thực OTP và đăng nhập
  Future<UserCredential> verifyOTPAndSignIn({
    required String otp,
    String? verificationId,
  });

  // Hàm đăng xuất
  Future<void> signOut();
}

class AuthenticationRepositoryImpl extends AuthenticationRepository {
  final FirebaseAuthService firebaseAuthService;
  final FirebaseUserService _userService = FirebaseUserService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseNotificationService _notificationService =
      FirebaseNotificationService();

  AuthenticationRepositoryImpl({required this.firebaseAuthService});

  /// Tìm user bằng additional email và trả về auth email của họ
  Future<String?> _findAuthEmailByAdditionalEmail(String email) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('additionalEmails', arrayContains: email.toLowerCase())
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final data = query.docs.first.data();
        return data['email'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> loginInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Try to login with the email directly first
      try {
        await firebaseAuthService.loginInWithEmailAndPassword(
          email: email,
          password: password,
        );
        // Update online status after successful login
        await _userService.setOnlineStatus(true);
        return;
      } on Exception {
        // If direct login fails, check if it's an additional email
      }

      // Check if this email is in someone's additionalEmails
      final authEmail = await _findAuthEmailByAdditionalEmail(email);
      if (authEmail != null) {
        // Try to login with the primary auth email
        await firebaseAuthService.loginInWithEmailAndPassword(
          email: authEmail,
          password: password,
        );
        // Update online status after successful login
        await _userService.setOnlineStatus(true);
        return;
      }

      // If no match found, throw original error
      throw Exception('Email hoặc mật khẩu không đúng');
    } catch (e) {
      rethrow;
    }
  }

  // =====================================================
  // HÀM ĐĂNG KÝ TÀI KHOẢN MỚI BẰNG EMAIL
  // =====================================================
  @override
  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      print('[AuthRepo] Starting registration for $email');
      final credential = await firebaseAuthService
          .createUserWithEmailAndPassword(email: email, password: password);
      print('[AuthRepo] Firebase Auth user created: ${credential?.user?.uid}');

      // Tạo user document trong Firestore sau khi đăng ký thành công
      if (credential?.user != null) {
        // Update Firebase Auth profile with display name
        if (displayName != null) {
          print('[AuthRepo] Updating display name...');
          await credential!.user!.updateDisplayName(displayName);
          print('[AuthRepo] Display name updated');
        }

        print('[AuthRepo] Creating Firestore user document...');
        await _userService.createUser(
          credential!.user!,
          displayName: displayName,
        );
        print('[AuthRepo] Firestore user document created');

        // Gửi thông báo chào mừng (không throw lỗi nếu thất bại)
        try {
          print('[AuthRepo] Sending welcome notification...');
          await _notificationService.sendSystemNotification(
            recipientId: credential.user!.uid,
            senderName: 'Trip',
            message: 'Chào mừng bạn đến với Trip! Hãy bắt đầu khám phá ngay.',
            type: NotificationType.welcome,
          );
          print('[AuthRepo] Welcome notification sent');

          print('[AuthRepo] Sending complete-profile notification...');
          await _notificationService.sendSystemNotification(
            recipientId: credential.user!.uid,
            senderName: 'Trip',
            message:
                'Hãy làm các bước cuối cùng để hoàn thiện hồ sơ của bạn để giúp mọi người dễ dàng kết nối, theo dõi và hiểu rõ hơn về bạn.',
            type: NotificationType.completeProfile,
          );
          print('[AuthRepo] Complete-profile notification sent');
        } catch (e) {
          // Ignore notification errors - registration should still succeed
          print('Warning: Failed to send welcome notification: $e');
        }
      }
      print('[AuthRepo] Registration complete');
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      print('[AuthRepo] Registration error: $e');
      rethrow;
    }
  }

  // =====================================================
  // HÀM GỬI LẠI EMAIL XÁC THỰC
  // =====================================================
  @override
  Future<void> sendEmailVerification() async {
    try {
      await firebaseAuthService.sendEmailVerification();
    } catch (e) {
      rethrow;
    }
  }

  // =====================================================
  // HÀM KIỂM TRA EMAIL ĐÃ XÁC THỰC CHƯA
  // =====================================================
  @override
  Future<bool> isEmailVerified() async {
    return await firebaseAuthService.isEmailVerified();
  }

  // =====================================================
  // HÀM GỬI EMAIL ĐẶT LẠI MẬT KHẨU
  // =====================================================
  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await firebaseAuthService.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  // HÀM THAY ĐỔI MẬT KHẨU CHO NGƯỜI DÙNG ĐÃ ĐĂNG NHẬP
  // =====================================================
  @override
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await firebaseAuthService.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    } catch (e) {
      rethrow;
    }
  }

  // =====================================================
  // KIỂM TRA EMAIL ĐÃ TỒN TẠI TRÊN HỆ THỐNG
  // =====================================================
  @override
  Future<bool> isEmailRegistered({required String email}) async {
    try {
      return await firebaseAuthService.isEmailRegistered(email: email);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<String>> fetchSignInMethodsForEmail({
    required String email,
  }) async {
    try {
      return await firebaseAuthService.fetchSignInMethodsForEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  // =====================================================
  // HÀM GỬI OTP ĐẾN SỐ ĐIỆN THOẠI
  // =====================================================
  @override
  Future<void> sendOTPToPhone({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
    Function(PhoneAuthCredential credential)? onAutoVerified,
  }) async {
    await firebaseAuthService.sendOTPToPhone(
      phoneNumber: phoneNumber,
      onCodeSent: onCodeSent,
      onError: onError,
      onAutoVerified: onAutoVerified,
    );
  }

  // =====================================================
  // HÀM XÁC THỰC OTP VÀ ĐĂNG NHẬP
  // =====================================================
  @override
  Future<UserCredential> verifyOTPAndSignIn({
    required String otp,
    String? verificationId,
  }) async {
    try {
      return await firebaseAuthService.verifyOTPAndSignIn(
        otp: otp,
        verificationId: verificationId,
      );
    } catch (e) {
      rethrow;
    }
  }

  // =====================================================
  // HÀM ĐĂNG XUẤT
  // =====================================================
  @override
  Future<void> signOut() async {
    // Update offline status without blocking logout (avoid UI hangs on slow IO)
    Future<void>.microtask(() async {
      try {
        await _userService.setOnlineStatus(false);
      } catch (_) {
        // ignore errors on best-effort offline update
      }
    });
    await firebaseAuthService.signOut();
  }
}
