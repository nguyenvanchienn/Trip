import 'package:firebase_auth/firebase_auth.dart';
import 'package:tourn/Ui/domain/domain_data_sources/firebase_auth_sevice.dart';

abstract class AuthenticationRepository {
  // Hàm đăng nhập bằng email
  Future<void> loginInWithEmailAndPassword({
    required String email,
    required String password,
  });

  // Hàm đăng ký tài khoản mới bằng email
  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
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

  AuthenticationRepositoryImpl({required this.firebaseAuthService});

  @override
  Future<void> loginInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      await firebaseAuthService.loginInWithEmailAndPassword(
        email: email,
        password: password,
      );
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
  }) async {
    try {
      await firebaseAuthService.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
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
    await firebaseAuthService.signOut();
  }
}
