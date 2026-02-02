import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  // Instance của FirebaseAuth để sử dụng trong các hàm
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Biến lưu verificationId khi xác thực số điện thoại
  String? _verificationId;

  // Getter để lấy verificationId
  String? get verificationId => _verificationId;

  // HÀM ĐĂNG NHẬP VỚI EMAIL VÀ PASSWORD
  Future<void> loginInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // HÀM ĐĂNG KÝ TÀI KHOẢN MỚI VỚI EMAIL
  /// Tạo tài khoản mới với email và password
  /// Sau khi tạo xong sẽ tự động gửi email xác thực
  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Tạo tài khoản mới
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Gửi email xác thực sau khi tạo tài khoản
      await userCredential.user?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // HÀM GỬI LẠI EMAIL XÁC THỰC
  /// Gửi lại email xác thực cho người dùng hiện tại
  Future<void> sendEmailVerification() async {
    try {
      User? user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // HÀM GỬI EMAIL ĐẶT LẠI MẬT KHẨU
  /// Gửi email để người dùng đặt lại mật khẩu
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException {
      // Re-throw the original FirebaseAuthException so caller can check the error code
      rethrow;
    }
  }

  // HÀM KIỂM TRA EMAIL ĐÃ TỒN TẠI
  /// Kiểm tra xem email đã được đăng ký trên hệ thống hay chưa
  Future<bool> isEmailRegistered({required String email}) async {
    try {
      final methods =
          await (_auth as dynamic).fetchSignInMethodsForEmail(email)
              as List<dynamic>;
      return methods.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Trả về danh sách phương thức đăng nhập cho email (dùng để debug)
  Future<List<String>> fetchSignInMethodsForEmail({
    required String email,
  }) async {
    try {
      final methods =
          await (_auth as dynamic).fetchSignInMethodsForEmail(email)
              as List<dynamic>;
      return methods.map((m) => m.toString()).toList();
    } catch (e) {
      rethrow;
    }
  }

  // HÀM KIỂM TRA EMAIL ĐÃ XÁC THỰC CHƯA
  /// Kiểm tra xem email đã được xác thực chưa
  /// Cần reload user trước khi kiểm tra
  Future<bool> isEmailVerified() async {
    try {
      User? user = _auth.currentUser;
      await user?.reload(); // Reload để lấy trạng thái mới nhất
      user = _auth.currentUser;
      return user?.emailVerified ?? false;
    } catch (e) {
      return false;
    }
  }

  // HÀM GỬI OTP ĐẾN SỐ ĐIỆN THOẠI
  /// Gửi mã OTP đến số điện thoại
  /// [phoneNumber] - Số điện thoại (phải có mã quốc gia, vd: +84123456789)
  /// [onCodeSent] - Callback khi OTP được gửi thành công
  /// [onError] - Callback khi có lỗi
  /// [onAutoVerified] - Callback khi tự động xác thực (Android)
  Future<void> sendOTPToPhone({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
    Function(PhoneAuthCredential credential)? onAutoVerified,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),

        // Tự động xác thực trên Android (khi nhận được SMS)
        verificationCompleted: (PhoneAuthCredential credential) async {
          _verificationId = null;
          if (onAutoVerified != null) {
            onAutoVerified(credential);
          }
        },

        // Xảy ra lỗi
        verificationFailed: (FirebaseAuthException e) {
          onError(e.message ?? 'Lỗi xác thực số điện thoại');
        },

        // OTP đã được gửi, lưu verificationId để xác thực sau
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          onCodeSent(verificationId);
        },

        // Timeout - mã OTP hết hạn
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      onError(e.toString());
    }
  }

  // HÀM XÁC THỰC OTP VÀ ĐĂNG NHẬP/ĐĂNG KÝ
  /// Xác thực mã OTP và đăng nhập/đăng ký với số điện thoại
  /// [otp] - Mã OTP người dùng nhập
  /// [verificationId] - ID xác thực từ bước gửi OTP
  Future<UserCredential> verifyOTPAndSignIn({
    required String otp,
    String? verificationId,
  }) async {
    try {
      // Sử dụng verificationId được truyền vào hoặc từ biến lưu
      final verId = verificationId ?? _verificationId;
      if (verId == null) {
        throw Exception('Không tìm thấy mã xác thực. Vui lòng gửi lại OTP.');
      }

      // Tạo credential từ verificationId và OTP
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verId,
        smsCode: otp,
      );

      // Đăng nhập với credential
      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Mã OTP không đúng');
    }
  }

  // Đăng nhập trực tiếp bằng PhoneAuthCredential (dùng khi nhận được credential tự động)
  Future<UserCredential> signInWithCredential(
    PhoneAuthCredential credential,
  ) async {
    try {
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // HÀM ĐĂNG XUẤT
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // HÀM LẤY USER HIỆN TẠI
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // HÀM CẬP NHẬT MẬT KHẨU (YÊU CẦU XÁC THỰC LẠI)
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Lỗi cập nhật mật khẩu');
    }
  }
}
