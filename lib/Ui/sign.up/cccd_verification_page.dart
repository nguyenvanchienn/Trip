import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tourn/Ui/login/login.dart';

// Import các file data layer để xử lý đăng ký với Firebase
import 'package:tourn/Ui/domain/domain_data_sources/firebase_auth_sevice.dart';
import 'package:tourn/Ui/domain/domain_authentication_repository/authentication_repository.dart';

/// Trang xác thực Căn cước công dân
/// Nhận thông tin từ trang đăng ký và xử lý đăng ký sau khi xác thực CCCD
class CCCDVerificationPage extends StatefulWidget {
  final String name;
  final String emailOrPhone;
  final String password;

  const CCCDVerificationPage({
    super.key,
    required this.name,
    required this.emailOrPhone,
    required this.password,
  });

  @override
  State<CCCDVerificationPage> createState() => _CCCDVerificationPageState();
}

class _CCCDVerificationPageState extends State<CCCDVerificationPage> {
  // Controller cho trường nhập CCCD
  final TextEditingController _cccdCtrl = TextEditingController();

  // Màu cam làm điểm nhấn
  final Color _accent = const Color(0xFFFF9800);

  // =====================================================
  // PHẦN TÍCH HỢP DATA LAYER - ĐĂNG KÝ VỚI FIREBASE
  // =====================================================

  // Khởi tạo FirebaseAuthService
  final FirebaseAuthService _firebaseAuthService = FirebaseAuthService();

  // Biến để khởi tạo AuthenticationRepository
  late final AuthenticationRepository _authRepository;

  // Biến để hiển thị trạng thái loading
  bool _isLoading = false;

  // Biến để kiểm tra form có hợp lệ không
  bool _isFormValid = false;

  // Biến để hiển thị lỗi dưới TextField
  String? _cccdError;

  // Biến để lưu trạng thái đồng ý điều khoản
  bool _accept = false;

  @override
  void initState() {
    super.initState();
    // Khởi tạo AuthenticationRepository
    _authRepository = AuthenticationRepositoryImpl(
      firebaseAuthService: _firebaseAuthService,
    );

    // Thêm listener để validate form
    _cccdCtrl.addListener(_validateForm);
  }

  // Hàm kiểm tra CCCD có đúng định dạng không (12 số)
  bool _isValidCCCD(String cccd) {
    final cccdRegex = RegExp(r'^[0-9]{12}$');
    return cccdRegex.hasMatch(cccd);
  }

  // Hàm validate form
  void _validateForm() {
    final cccd = _cccdCtrl.text.trim();
    String? error;

    if (cccd.isNotEmpty && !_isValidCCCD(cccd)) {
      error = 'CCCD phải có đúng 12 số';
    }

    setState(() {
      _cccdError = error;
      _isFormValid = cccd.isNotEmpty && _isValidCCCD(cccd);
    });
  }

  // Hàm chuyển đổi số điện thoại sang định dạng quốc tế
  String _formatPhoneNumber(String phone) {
    if (phone.startsWith('0')) {
      return '+84${phone.substring(1)}';
    }
    return phone;
  }

  @override
  void dispose() {
    _cccdCtrl.dispose();
    super.dispose();
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
          'Xác thực CCCD',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),

                // Icon CCCD
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.credit_card, size: 50, color: _accent),
                ),

                const SizedBox(height: 24),

                // Tiêu đề
                const Text(
                  'Nhập số Căn cước công dân',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 12),

                // Mô tả
                Text(
                  'Vui lòng nhập số CCCD 12 số của bạn để xác thực danh tính',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),

                const SizedBox(height: 32),

                // Hiển thị thông tin đã nhập
                _buildInfoCard(),

                const SizedBox(height: 24),

                // Trường nhập CCCD
                _buildCCCDField(),

                const SizedBox(height: 20),

                // Checkbox đồng ý điều khoản — chỉ hiển thị khi CCCD hợp lệ
                if (_isFormValid) ...[
                  _buildAcceptRow(),
                  const SizedBox(height: 24),
                ],

                // Nút Đăng ký
                _buildRegisterButton(),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget hiển thị thông tin đã nhập từ trang trước
  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông tin đăng ký:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.person, size: 16, color: _accent),
              const SizedBox(width: 8),
              Text(widget.name, style: const TextStyle(fontSize: 14)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                widget.emailOrPhone.startsWith('0') ? Icons.phone : Icons.email,
                size: 16,
                color: _accent,
              ),
              const SizedBox(width: 8),
              Text(widget.emailOrPhone, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  // Widget trường nhập CCCD
  Widget _buildCCCDField() {
    final bool hasError = _cccdError != null;
    final Color borderColor = hasError ? Colors.red : _accent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Số Căn cước công dân',
          style: TextStyle(fontSize: 14, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _cccdCtrl,
          keyboardType: TextInputType.number,
          maxLength: 12,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: 'Nhập 12 số CCCD',
            counterText: '', // Ẩn bộ đếm ký tự
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
              child: Icon(Icons.credit_card, color: borderColor, size: 20),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: borderColor, width: 2),
            ),
            errorText: _cccdError,
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

  // Widget checkbox đồng ý điều khoản
  Widget _buildAcceptRow() {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _accept,
            activeColor: _accent,
            onChanged: (v) => setState(() => _accept = v ?? false),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _accept = !_accept),
            child: const Text(
              'Tôi đồng ý với điều khoản sử dụng',
              style: TextStyle(color: Colors.black87, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  // Widget nút Đăng ký
  Widget _buildRegisterButton() {
    // Chỉ enable nút khi form hợp lệ VÀ đã đồng ý điều khoản VÀ không đang loading
    final bool isButtonEnabled = _isFormValid && _accept && !_isLoading;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () =>
            isButtonEnabled ? _onRegister() : _showFormIncompleteReason(),
        style: ElevatedButton.styleFrom(
          backgroundColor: isButtonEnabled ? _accent : _accent.withOpacity(0.5),
          disabledBackgroundColor: _accent.withOpacity(0.5),
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
                'Đăng ký',

                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  // Hiển thị lý do form CCCD chưa hoàn thành (SnackBar)
  void _showFormIncompleteReason() {
    if (!_isFormValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số CCCD hợp lệ (12 số)')),
      );
      return;
    }
    if (!_accept) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đồng ý với điều khoản sử dụng')),
      );
      return;
    }
  }

  // =====================================================
  // HÀM XỬ LÝ ĐĂNG KÝ
  // =====================================================
  Future<void> _onRegister() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.emailOrPhone.contains('@')) {
        // Đăng ký bằng email
        await _registerWithEmail();
      } else {
        // Đăng ký bằng số điện thoại
        await _registerWithPhone();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog('Không thể đăng ký. Vui lòng thử lại.');
      }
    }
  }

  /// Đăng ký bằng email và password
  Future<void> _registerWithEmail() async {
    final String email = widget.emailOrPhone;
    final String password = widget.password;

    try {
      // Tạo tài khoản với email và password
      await _authRepository.createUserWithEmailAndPassword(
        email: email,
        password: password,
        displayName: widget.name,
      );

      // Đăng ký thành công
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSuccessDialog(
          'Đăng ký tài khoản thành công!\n\nChúng tôi đã gửi email xác thực đến địa chỉ email của bạn. Vui lòng kiểm tra hộp thư và xác thực email trước khi đăng nhập.',
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog(_mapAuthError(e));
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog('Không thể lưu hồ sơ người dùng. ${e.message ?? ''}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog('Không thể đăng ký. Vui lòng thử lại.');
      }
    }
  }

  /// Đăng ký bằng số điện thoại
  Future<void> _registerWithPhone() async {
    final String phone = widget.emailOrPhone;
    final String formatted = phone.startsWith('0')
        ? _formatPhoneNumber(phone)
        : phone;
    // Create a synthetic email for phone-based accounts (must be unique)
    final String emailForPhone = '${formatted.replaceAll('+', '')}@phone.tourn';
    final String password = widget.password;

    try {
      await _authRepository.createUserWithEmailAndPassword(
        email: emailForPhone,
        password: password,
        displayName: widget.name,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSuccessDialog(
          'Đăng ký tài khoản thành công!\n\nSố điện thoại của bạn đã được xác thực.',
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog(_mapAuthError(e));
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog('Không thể lưu hồ sơ người dùng. ${e.message ?? ''}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog('Tạo tài khoản thất bại. ${e.toString()}');
      }
    }
  }

  /// Hiển thị dialog thành công
  void _showSuccessDialog(String message) {
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
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 8),
              Text('Thành công'),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Quay về trang đăng nhập
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const loginpage()),
                  (route) => false,
                );
              },
              child: const Text(
                'Đăng nhập',
                style: TextStyle(
                  color: Color(0xFFFF9800),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
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
          content: Text('$message\n\nBạn có muốn thử lại không?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pop(context); // Quay lại trang đăng ký
              },
              child: const Text(
                'Thử lại',
                style: TextStyle(
                  color: Color(0xFFFF9800),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Email đã được sử dụng. Vui lòng dùng email khác.';
      case 'invalid-email':
        return 'Email không hợp lệ. Vui lòng kiểm tra lại.';
      case 'weak-password':
        return 'Mật khẩu quá yếu. Vui lòng dùng mật khẩu mạnh hơn.';
      case 'operation-not-allowed':
        return 'Email/Password chưa được bật trong Firebase Authentication.';
      case 'network-request-failed':
        return 'Không có kết nối mạng. Vui lòng thử lại.';
      case 'too-many-requests':
        return 'Thao tác bị giới hạn. Vui lòng thử lại sau.';
      default:
        return e.message ?? 'Đăng ký thất bại. Vui lòng thử lại.';
    }
  }
}
