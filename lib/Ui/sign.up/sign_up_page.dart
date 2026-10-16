import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:tourn/Ui/login/login.dart';
import 'package:tourn/Ui/sign.up/cccd_verification_page.dart';

// Import các file data layer để xử lý đăng ký với Firebase
import 'package:tourn/Ui/domain/domain_data_sources/firebase_auth_sevice.dart';
import 'package:tourn/Ui/domain/domain_authentication_repository/authentication_repository.dart';

/// Trang 3 của luồng đăng ký: Nhập tên, mật khẩu, CCCD và hoàn tất đăng ký
/// Trang này được hiển thị sau khi người dùng đã xác thực OTP thành công
class RegistrationFormPage extends StatefulWidget {
  final String emailOrPhone; // Email hoặc số điện thoại đã xác thực
  final bool isPhoneVerified; // True nếu là SĐT đã xác thực OTP

  const RegistrationFormPage({
    super.key,
    required this.emailOrPhone,
    required this.isPhoneVerified,
  });

  @override
  State<RegistrationFormPage> createState() => _RegistrationFormPageState();
}

/// Compatibility widget for older references named `signuppage`.
/// Small wrapper to avoid breaking existing navigation calls.
class signuppage extends StatelessWidget {
  const signuppage({super.key});

  @override
  Widget build(BuildContext context) {
    // Provide benign defaults so old navigation still works.
    return const RegistrationFormPage(emailOrPhone: '', isPhoneVerified: false);
  }
}

class _RegistrationFormPageState extends State<RegistrationFormPage> {
  // Controllers
  final TextEditingController _hoCtrl = TextEditingController(); // Họ
  final TextEditingController _tenCtrl = TextEditingController(); // Tên
  final TextEditingController _emailPhoneCtrl =
      TextEditingController(); // Controller cho email hoặc số điện thoại
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmPasswordCtrl = TextEditingController();
  final TextEditingController otpCtrl = TextEditingController();

  // Lỗi cho trường tài khoản
  String? _accountError;

  // Màu cam làm điểm nhấn
  final Color _accent = const Color(0xFFFF9800);

  // =====================================================
  // PHẦN TÍCH HỢP DATA LAYER
  // =====================================================

  final FirebaseAuthService _firebaseAuthService = FirebaseAuthService();
  late final AuthenticationRepository _authRepository;

  // Biến trạng thái
  bool _isLoading = false;
  bool _isFormValid = false;
  // Trạng thái hiển thị mật khẩu
  bool _passwordObscured = true;
  bool _confirmPasswordObscured = true;

  // Các biến lỗi
  String? _hoError;
  String? _tenError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _otpError;

  // Định dạng số điện thoại sang +84 nếu bắt đầu bằng 0
  String _formatPhoneNumber(String phone) {
    if (phone.startsWith('0')) {
      return '+84${phone.substring(1)}';
    }
    return phone;
  }

  // Hàm kiểm tra mã OTP 6 chữ số
  bool _isValidOTP(String otp) {
    final otpRegex = RegExp(r'^[0-9]{6}$');
    return otpRegex.hasMatch(otp);
  }

  // Resend OTP state
  int _resendCountdown = 0;
  bool _canResend = false;
  Timer? _resendTimer;
  bool _otpSent = false;

  // Bắt đầu đếm ngược gửi lại mã
  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() {
      _canResend = false;
      _resendCountdown = 60;
    });

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() {
        _resendCountdown--;
        if (_resendCountdown <= 0) {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  void _stopResendTimer() {
    _resendTimer?.cancel();
    _resendTimer = null;
  }

  // Gửi OTP (mô phỏng cho cả email và SĐT)
  Future<void> _resendOTP() async {
    final accountValue = _emailPhoneCtrl.text.trim().isNotEmpty
        ? _emailPhoneCtrl.text.trim()
        : widget.emailOrPhone;

    // Nếu đã gửi trước đó và chưa đủ thời gian chờ thì thông báo
    if (_otpSent && !_canResend) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Vui lòng chờ $_resendCountdown giây trước khi gửi lại',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (accountValue.startsWith('0')) {
        // Gửi thật cho SĐT
        final formatted = _formatPhoneNumber(accountValue);
        await _authRepository.sendOTPToPhone(
          phoneNumber: formatted,
          onCodeSent: (verificationId) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _otpSent = true;
              });
              _startResendTimer();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Mã OTP đã được gửi'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
          onError: (error) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(error), backgroundColor: Colors.red),
              );
            }
          },
        );
      } else {
        // Mô phỏng gửi cho email (không gọi API)
        await Future.delayed(const Duration(milliseconds: 250));
        if (mounted) {
          setState(() {
            _isLoading = false;
            _otpSent = true;
          });
          _startResendTimer();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mã OTP đã được gửi'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể gửi mã OTP. Vui lòng thử lại.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Khởi tạo AuthenticationRepository
    _authRepository = AuthenticationRepositoryImpl(
      firebaseAuthService: _firebaseAuthService,
    );

    // Thêm listener để validate form
    _hoCtrl.addListener(_validateForm);
    _tenCtrl.addListener(_validateForm);
    _emailPhoneCtrl.addListener(_validateForm);
    _passwordCtrl.addListener(_validateForm);
    _confirmPasswordCtrl.addListener(_validateForm);
    otpCtrl.addListener(_validateForm);

    // Prefill account field nếu có giá trị từ bước trước
    if (widget.emailOrPhone.isNotEmpty) {
      _emailPhoneCtrl.text = widget.emailOrPhone;
    }

    // Note: don't auto-start resend countdown here. The countdown
    // should begin only after an OTP has actually been sent (onCodeSent callback).
  }

  @override
  void dispose() {
    _hoCtrl.dispose();
    _tenCtrl.dispose();
    _emailPhoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    otpCtrl.dispose();
    _stopResendTimer();
    super.dispose();
  }

  // Hàm validate form
  void _validateForm() {
    final ho = _hoCtrl.text.trim();
    final ten = _tenCtrl.text.trim();
    final emailPhoneInput = _emailPhoneCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final confirmPassword = _confirmPasswordCtrl.text.trim();
    final otp = otpCtrl.text.trim();
    String? hoErr;
    String? tenErr;
    String? accountErr;
    String? passwordErr;
    String? confirmErr;
    String? otpErr;

    // Regex cho tên tiếng Việt (chữ cái có dấu, không có số và ký tự đặc biệt)
    // Bao gồm tất cả các ký tự tiếng Việt với dấu
    final nameRegex = RegExp(r'^[a-zA-ZàáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐ\s]+$');

    // Validate Họ
    if (ho.isNotEmpty) {
      if (ho.length < 2) {
        hoErr = 'Họ phải có ít nhất 2 ký tự';
      } else if (!nameRegex.hasMatch(ho)) {
        hoErr = 'Họ không được chứa số hoặc ký tự đặc biệt';
      }
    }

    // Validate Tên
    if (ten.isNotEmpty) {
      if (ten.length < 2) {
        tenErr = 'Tên phải có ít nhất 2 ký tự';
      } else if (!nameRegex.hasMatch(ten)) {
        tenErr = 'Tên không được chứa số hoặc ký tự đặc biệt';
      }
    }

    // Validate account (email hoặc SĐT)
    final accountValue = emailPhoneInput.isNotEmpty
        ? emailPhoneInput
        : widget.emailOrPhone;
    if (accountValue.isEmpty) {
    } else if (accountValue.contains('@')) {
      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
      if (!emailRegex.hasMatch(accountValue)) {
        accountErr = 'Số điện thoại hoặc email không hợp lệ';
      }
    } else {
      final phoneRegex = RegExp(r'^[0-9]+$');
      if (!phoneRegex.hasMatch(accountValue) || accountValue.length < 9) {
        accountErr = 'Số điện thoại hoặc email không hợp lệ';
      }
    }

    // Validate password
    if (password.isNotEmpty && password.length < 6) {
      passwordErr = 'Mật khẩu phải có ít nhất 6 ký tự';
    }

    // mật khẩu xác nhận
    if (confirmPassword.isNotEmpty && confirmPassword != password) {
      confirmErr = 'Mật khẩu không khớp';
    }

    if (otp.isNotEmpty && !_isValidOTP(otp)) {
      otpErr = 'Mã OTP phải gồm 6 số';
    }

    bool isValid =
        ho.isNotEmpty &&
        ho.length >= 2 &&
        hoErr == null &&
        ten.isNotEmpty &&
        ten.length >= 2 &&
        tenErr == null &&
        accountErr == null &&
        password.isNotEmpty &&
        password.length >= 6 &&
        confirmPassword.isNotEmpty &&
        confirmPassword == password &&
        otp.isNotEmpty &&
        _isValidOTP(otp);

    setState(() {
      _hoError = hoErr;
      _tenError = tenErr;
      _accountError = accountErr;
      _passwordError = passwordErr;
      _confirmPasswordError = confirmErr;
      _otpError = otpErr;
      _isFormValid = isValid;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_outlined,
            color: Colors.black,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // Hiển thị email/SĐT đã xác thực
                _buildVerifiedInfo(),

                const SizedBox(height: 24),

                // Form nhập thông tin
                _buildHoField(),
                const SizedBox(height: 16),
                _buildTenField(),
                const SizedBox(height: 16),
                _buildemailandsdtField(),
                const SizedBox(height: 16),
                _buildPasswordField(),
                const SizedBox(height: 16),
                _buildConfirmPasswordField(),
                const SizedBox(height: 16),
                _buildOTPField(),
                const SizedBox(height: 20),

                // Checkbox đồng ý điều khoản
                const SizedBox(height: 24),

                // Nút đăng ký
                _buildRegisterButton(),

                const SizedBox(height: 20),
                _buildorsplitoivider(),
                _buildsocialicons(),
                _buildhavenotaccount(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget hiển thị thông tin đã xác thực
  Widget _buildVerifiedInfo() {
    return Container(
      alignment: Alignment.center,
      margin: EdgeInsets.only(top: 90),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Logo
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: Center(
              child: Image.asset(
                'asset/icon/logo.png',
                width: 75,
                height: 75,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            "signin_title".tr(),
            style: const TextStyle(
              fontSize: 28,
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  // Widget trường nhập họ
  Widget _buildHoField() {
    return _buildTextField(
      label: 'Họ',
      hint: 'Nhập họ của bạn',
      controller: _hoCtrl,
      icon: Icons.person,
      errorText: _hoError,
    );
  }

  // Widget trường nhập tên
  Widget _buildTenField() {
    return _buildTextField(
      label: 'Tên',
      hint: 'Nhập tên của bạn',
      controller: _tenCtrl,
      icon: Icons.person_outline,
      errorText: _tenError,
    );
  }

  Widget _buildemailandsdtField() {
    return _buildTextField(
      label: 'Tài khoản',
      hint: 'Nhập email hoặc số điện thoại',
      controller: _emailPhoneCtrl,
      icon: Icons.email,
      obscure: false,
      errorText: _accountError,
    );
  }

  // Widget trường nhập mật khẩu
  Widget _buildPasswordField() {
    final bool hasError = _passwordError != null;
    final Color borderColor = hasError ? Colors.red : _accent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mật khẩu',
          style: TextStyle(fontSize: 14, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordCtrl,
          obscureText: _passwordObscured,
          decoration: InputDecoration(
            hintText: 'Nhập mật khẩu (ít nhất 6 ký tự)',
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 14,
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.all(8),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 1.6),
              ),
              child: Icon(Icons.lock, color: borderColor, size: 20),
            ),
            suffixIcon: IconButton(
              onPressed: () =>
                  setState(() => _passwordObscured = !_passwordObscured),
              icon: Icon(
                _passwordObscured ? Icons.visibility_off : Icons.visibility,
                color: borderColor,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: borderColor, width: 2),
            ),
            errorText: _passwordError,
            errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
          ),
          style: const TextStyle(color: Colors.black87, fontSize: 16),
        ),
      ],
    );
  }

  // Widget trường xác nhận mật khẩu
  Widget _buildConfirmPasswordField() {
    final bool hasError = _confirmPasswordError != null;
    final Color borderColor = hasError ? Colors.red : _accent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Xác nhận mật khẩu',
          style: TextStyle(fontSize: 14, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _confirmPasswordCtrl,
          obscureText: _confirmPasswordObscured,
          decoration: InputDecoration(
            hintText: 'Nhập lại mật khẩu',
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 14,
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.all(8),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 1.6),
              ),
              child: Icon(Icons.lock_outline, color: borderColor, size: 20),
            ),
            suffixIcon: IconButton(
              onPressed: () => setState(
                () => _confirmPasswordObscured = !_confirmPasswordObscured,
              ),
              icon: Icon(
                _confirmPasswordObscured
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: borderColor,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: borderColor, width: 2),
            ),
            errorText: _confirmPasswordError,
            errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
          ),
          style: const TextStyle(color: Colors.black87, fontSize: 16),
        ),
      ],
    );
  }

  // Widget trường nhập OTP (Mã xác thực 6 chữ số)
  Widget _buildOTPField() {
    final bool hasError = _otpError != null;
    final Color borderColor = hasError ? Colors.red : _accent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mã số OTP',
          style: TextStyle(fontSize: 14, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: otpCtrl,
          keyboardType: TextInputType.number,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: 'Nhập OTP gồm 6 số',
            counterText: '',
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 14,
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.all(8),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 1.6),
              ),
              child: Icon(Icons.pin, color: borderColor, size: 20),
            ),
            // Nút/Ghi chú gửi lại mã ở phía phải
            suffixIcon: TextButton(
              onPressed: (_otpSent && !_canResend) ? null : _resendOTP,
              child: Text(
                !_otpSent
                    ? 'Gửi mã'
                    : (_canResend
                          ? 'Gửi lại mã'
                          : 'Gửi lại ($_resendCountdown s)'),
                style: TextStyle(
                  color: (_otpSent && !_canResend)
                      ? Colors.grey
                      : const Color(0xFFFF9800),
                  fontSize: 13,
                ),
              ),
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: borderColor, width: 2),
            ),
            errorText: _otpError,
            errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
          ),
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 16,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  // Widget helper để tạo TextField
  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    bool obscure = false,
    String? errorText,
  }) {
    final bool hasError = errorText != null;
    final Color borderColor = hasError ? Colors.red : _accent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 14,
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.all(8),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 1.6),
              ),
              child: Icon(icon, color: borderColor, size: 20),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: borderColor, width: 2),
            ),
            errorText: errorText,
            errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
          ),
          style: const TextStyle(color: Colors.black87, fontSize: 16),
        ),
      ],
    );
  }

  // Widget nút đăng ký (kích thước nhỏ hơn để phù hợp giao diện trước)
  Widget _buildRegisterButton() {
    final bool isButtonEnabled = _isFormValid && !_isLoading;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        width: double.infinity,
        height: 46,
        child: ElevatedButton(
          onPressed: () =>
              isButtonEnabled ? _onRegister() : _showFormIncompleteReason(),
          style: ElevatedButton.styleFrom(
            backgroundColor: isButtonEnabled
                ? _accent
                : _accent.withOpacity(0.5),
            disabledBackgroundColor: _accent.withOpacity(0.5),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            elevation: isButtonEnabled ? 0 : 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'Tiếp theo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.white,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildorsplitoivider() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Divider(
              color: Colors.grey[300],
              thickness: 1,
              indent: 10,
              endIndent: 10,
            ),
          ),
          Text("login_desc".tr(), style: TextStyle(color: Colors.grey[500])),
          Expanded(
            child: Divider(
              color: Colors.grey[300],
              thickness: 1,
              indent: 10,
              endIndent: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildsocialicons() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: () {},
            icon: Image.asset('asset/icon/facebook.png', width: 28, height: 28),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () {},
            icon: Image.asset('asset/icon/google.png', width: 28, height: 28),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildhavenotaccount(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20, bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "signin_desc1".tr(),
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
          GestureDetector(
            // Thêm khả năng nhấn vào văn bản
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const loginpage()),
              );
              // Xử lý khi nhấn vào "Sign Up"
            },
            child: Text(
              "login_buttom".tr(),
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFFFF9800),
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Hiển thị lý do form chưa hoàn thành (SnackBar)
  void _showFormIncompleteReason() {
    // Ensure errors are up-to-date
    _validateForm();

    String message = 'Vui lòng kiểm tra thông tin đăng ký.';
    if (_hoCtrl.text.trim().isEmpty) {
      message = 'Vui lòng nhập họ.';
    } else if (_tenCtrl.text.trim().isEmpty) {
      message = 'Vui lòng nhập tên.';
    } else if (_accountError != null) {
      message = _accountError!;
    } else if (_passwordError != null) {
      message = _passwordError!;
    } else if (_confirmPasswordError != null) {
      message = _confirmPasswordError!;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: _accent));
  }

  // =====================================================
  // XỬ LÝ ĐĂNG KÝ
  // =====================================================
  Future<void> _onRegister() async {
    setState(() {
      _isLoading = true;
    });

    final String password = _passwordCtrl.text.trim();
    final String accountValue = _emailPhoneCtrl.text.trim().isNotEmpty
        ? _emailPhoneCtrl.text.trim()
        : widget.emailOrPhone;

    try {
      // Chuyển sang trang xác thực CCCD trước khi tạo tài khoản
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CCCDVerificationPage(
            name: '${_hoCtrl.text.trim()} ${_tenCtrl.text.trim()}',
            emailOrPhone: accountValue,
            password: password,
          ),
        ),
      );
      // dừng loading (nút không còn thực hiện việc tạo tài khoản trực tiếp tại đây)
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog('Lỗi chuyển trang. Vui lòng thử lại.');
      }
    }
  }

  /// Hiển thị dialog lỗi
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red, size: 28),
              SizedBox(width: 8),
              Text('Đăng ký thất bại'),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Đóng',
                style: TextStyle(color: _accent, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}
