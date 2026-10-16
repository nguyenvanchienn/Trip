import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tourn/Ui/main/main_page.dart';
import 'package:tourn/Ui/domain/domain_data_sources/firebase_auth_sevice.dart';
import 'package:tourn/Ui/domain/domain_authentication_repository/authentication_repository.dart';
import 'package:tourn/Ui/splash/splash.dart';

/// Trang xác thực OTP
/// Sử dụng cho cả xác thực số điện thoại khi đăng nhập và đăng ký
class OTPVerificationPage extends StatefulWidget {
  final String phoneNumber; // Số điện thoại cần xác thực
  final String verificationId; // ID xác thực từ Firebase
  final bool isRegistration; // True nếu đây là đăng ký, false nếu đăng nhập
  final VoidCallback? onVerificationSuccess; // Callback khi xác thực thành công

  const OTPVerificationPage({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
    this.isRegistration = false,
    this.onVerificationSuccess,
  });

  @override
  State<OTPVerificationPage> createState() => _OTPVerificationPageState();
}

class _OTPVerificationPageState extends State<OTPVerificationPage> {
  // Controllers cho 6 ô nhập OTP
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );

  // Focus nodes cho 6 ô nhập OTP
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  // =====================================================
  // PHẦN TÍCH HỢP DATA LAYER
  // =====================================================
  final FirebaseAuthService _firebaseAuthService = FirebaseAuthService();
  late final AuthenticationRepository _authRepository;

  bool _isLoading = false;
  String? _errorMessage;
  int _resendCountdown = 60; // Đếm ngược để gửi lại OTP
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _authRepository = AuthenticationRepositoryImpl(
      firebaseAuthService: _firebaseAuthService,
    );
    _startResendCountdown();
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  // Bắt đầu đếm ngược để gửi lại OTP
  void _startResendCountdown() {
    _canResend = false;
    _resendCountdown = 60;

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _resendCountdown--;
          if (_resendCountdown <= 0) {
            _canResend = true;
          }
        });
      }
      return _resendCountdown > 0 && mounted;
    });
  }

  // Lấy mã OTP từ 6 ô nhập
  String _getOTP() {
    return _otpControllers.map((c) => c.text).join();
  }

  // =====================================================
  // HÀM XÁC THỰC OTP
  // =====================================================
  Future<void> _verifyOTP() async {
    final otp = _getOTP();

    // Kiểm tra đã nhập đủ 6 số chưa
    if (otp.length != 6) {
      setState(() {
        _errorMessage = 'Vui lòng nhập đủ 6 số OTP';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Xác thực OTP với Firebase
      await _authRepository.verifyOTPAndSignIn(
        otp: otp,
        verificationId: widget.verificationId,
      );

      // Thành công
      if (mounted) {
        if (widget.isRegistration && widget.onVerificationSuccess != null) {
          // Nếu là đăng ký, gọi callback để chuyển đến trang tiếp theo
          widget.onVerificationSuccess!();
        } else {
          // Nếu là đăng nhập, chuyển đến trang chính
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const SplashScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      // Lỗi - hiển thị thông báo
      if (mounted) {
        setState(() {
          _errorMessage = 'Mã OTP không đúng. Vui lòng thử lại.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // =====================================================
  // HÀM GỬI LẠI OTP
  // =====================================================
  Future<void> _resendOTP() async {
    if (!_canResend) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authRepository.sendOTPToPhone(
        phoneNumber: widget.phoneNumber,
        onCodeSent: (verificationId) {
          // OTP đã được gửi lại
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            _startResendCountdown();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã gửi lại mã OTP'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _errorMessage = error;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Không thể gửi lại OTP. Vui lòng thử lại.';
        });
      }
    }
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
        title: const Text(
          'Xác thực OTP',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.phone_android,
                  size: 40,
                  color: Color(0xFFFF9800),
                ),
              ),

              const SizedBox(height: 24),

              // Tiêu đề
              const Text(
                'Nhập mã xác thực',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 8),

              // Mô tả
              Text(
                'Mã OTP đã được gửi đến\n${widget.phoneNumber}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),

              const SizedBox(height: 32),

              // 6 ô nhập OTP
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) => _buildOTPField(index)),
              ),

              const SizedBox(height: 16),

              // Thông báo lỗi
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),

              const SizedBox(height: 32),

              // Nút xác thực
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOTP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9800),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Xác thực',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // Gửi lại OTP
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Không nhận được mã? ',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  GestureDetector(
                    onTap: _canResend ? _resendOTP : null,
                    child: Text(
                      _canResend ? 'Gửi lại' : 'Gửi lại ($_resendCountdown s)',
                      style: TextStyle(
                        color: _canResend
                            ? const Color(0xFFFF9800)
                            : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget cho mỗi ô nhập OTP
  Widget _buildOTPField(int index) {
    return SizedBox(
      width: 45,
      height: 55,
      child: TextFormField(
        controller: _otpControllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          counterText: '', // Ẩn counter
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: _errorMessage != null
                  ? Colors.red
                  : const Color(0xFFFF9800),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFF9800), width: 2),
          ),
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (value) {
          // Xóa lỗi khi người dùng nhập
          if (_errorMessage != null) {
            setState(() {
              _errorMessage = null;
            });
          }

          // Tự động chuyển sang ô tiếp theo
          if (value.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          }

          // Tự động xác thực khi nhập đủ 6 số
          if (_getOTP().length == 6) {
            _verifyOTP();
          }
        },
      ),
    );
  }
}
