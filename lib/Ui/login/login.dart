import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:tourn/Ui/login/forgetpassword.dart';
import 'package:tourn/Ui/main/main_page.dart';
import 'package:tourn/Ui/sign.up/sign_up_page.dart';
import 'package:tourn/Ui/welcome/welcome_page.dart';
import 'package:tourn/Ui/recommendation/recommendation_page_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import các file data layer để xử lý đăng nhập với Firebase
import 'package:tourn/Ui/domain/domain_data_sources/firebase_auth_sevice.dart';
import 'package:tourn/Ui/domain/domain_authentication_repository/authentication_repository.dart';

class loginpage extends StatefulWidget {
  const loginpage({super.key});

  @override
  State<loginpage> createState() => _loginpageState();
}

class _loginpageState extends State<loginpage> {
  final TextEditingController _usernameCtrl =
      TextEditingController(); // Controller cho trường email
  final TextEditingController _passwordCtrl =
      TextEditingController(); // Controller cho trường mật khẩu
  // Controller cho số điện thoại (sử dụng khi đăng nhập bằng số điện thoại)
  final TextEditingController _phoneCtrl = TextEditingController();

  // =====================================================
  // PHẦN TÍCH HỢP DATA LAYER - LOGIN WITH FIREBASE
  // =====================================================

  // Khởi tạo FirebaseAuthService - dịch vụ xử lý xác thực với Firebase
  final FirebaseAuthService _firebaseAuthService = FirebaseAuthService();

  // Biến để khởi tạo AuthenticationRepository (sẽ được khởi tạo trong initState)
  late final AuthenticationRepository _authRepository;

  // Biến để hiển thị trạng thái loading khi đang đăng nhập
  bool _isLoading = false;

  // Biến để kiểm tra xem form có hợp lệ không
  bool _isFormValid = false;

  // Trạng thái hiển thị mật khẩu
  bool _passwordObscured = true;

  // Biến để hiển thị lỗi dưới TextField khi đăng nhập thất bại
  String? _loginErrorMessage;

  // Biến để hiển thị lỗi email không đúng định dạng
  String? _emailErrorMessage;

  @override
  void initState() {
    super.initState();
    // Khởi tạo AuthenticationRepository với FirebaseAuthService
    _authRepository = AuthenticationRepositoryImpl(
      firebaseAuthService: _firebaseAuthService,
    );

    // Thêm listener để kiểm tra khi người dùng nhập
    _usernameCtrl.addListener(_validateForm);
    _passwordCtrl.addListener(_validateForm);
  }

  // Hàm kiểm tra email có đúng định dạng không
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  // Hàm kiểm tra form có hợp lệ không
  void _validateForm() {
    final email = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    String? emailError;

    // Kiểm tra email có đúng định dạng không
    if (email.isNotEmpty && !_isValidEmail(email)) {
      emailError = 'Email không đúng định dạng';
    }

    // Form hợp lệ khi email đúng định dạng và có password
    final bool isValid =
        email.isNotEmpty && _isValidEmail(email) && password.isNotEmpty;

    setState(() {
      _emailErrorMessage = emailError;
      _isFormValid = isValid;
      if (_loginErrorMessage != null) {
        _loginErrorMessage = null;
      }
    });
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _phoneCtrl.dispose();
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
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const WelcomePage(isFirsTimeinstallApp: false),
              ),
            );
          },
          icon: const Icon(
            Icons.arrow_back_ios_new_outlined,
            color: Colors.black,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: SizedBox(
            width: double.infinity, // Chiếm toàn bộ chiều rộng
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildpagetitle(),
                _buildformlogin(),
                _buildloginbutton(context),
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

  Widget _buildpagetitle() {
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
            "login_title".tr(),
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

  Widget _buildformlogin() {
    return Form(
      child: Container(
        margin: const EdgeInsets.only(top: 30, left: 20, right: 20),
        alignment: Alignment.centerLeft,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trường nhập email
            _buildusernamefield(),
            const SizedBox(height: 20),
            // Trường nhập mật khẩu
            _buildpasswordfield(),
            const SizedBox(height: 8),
            // Link Quên mật khẩu
            _buildforgotpassword(),
          ],
        ),
      ),
    );
  }

  Widget _buildforgotpassword() {
    return Container(
      margin: const EdgeInsets.only(top: 12, right: 20),
      alignment: Alignment.centerRight,
      child: InkWell(
        onTap: () {
          // Xử lý khi nhấn vào "Quên mật khẩu?"
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const Forgetpassword()),
          );
        },
        child: Text(
          "login_forgot_password".tr(),
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFFFF9800),
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }

  Column _buildusernamefield() {
    // Kiểm tra có lỗi email hoặc lỗi đăng nhập không để hiển thị border đỏ
    final bool hasError =
        _emailErrorMessage != null || _loginErrorMessage != null;
    final Color borderColor = hasError ? Colors.red : const Color(0xFFFF9800);

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "login_username".tr(),
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
        Container(
          margin: const EdgeInsets.only(top: 8),
          child: TextFormField(
            controller: _usernameCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: "login_username_desc".tr(),
              hintStyle: const TextStyle(color: Colors.black38),
              filled: true,
              fillColor: Colors.white,
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: borderColor),
                ),
                child: Icon(Icons.person, color: borderColor),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 12,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: borderColor, width: 2),
              ),
              // Hiển thị lỗi email không đúng định dạng
              errorText: _emailErrorMessage,
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
            style: const TextStyle(color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Column _buildpasswordfield() {
    // Kiểm tra có lỗi đăng nhập không để hiển thị border đỏ
    final bool hasError = _loginErrorMessage != null;
    final Color borderColor = hasError ? Colors.red : const Color(0xFFFF9800);

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "login_password".tr(),
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
        Container(
          margin: const EdgeInsets.only(top: 8),
          child: TextFormField(
            controller: _passwordCtrl,
            obscureText: _passwordObscured,
            decoration: InputDecoration(
              hintText: '*********',
              hintStyle: const TextStyle(color: Colors.black38),
              filled: true,
              fillColor: Colors.white,
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: borderColor),
                ),
                child: Icon(Icons.lock, color: borderColor),
              ),
              suffixIcon: IconButton(
                onPressed: () =>
                    setState(() => _passwordObscured = !_passwordObscured),
                icon: Icon(
                  _passwordObscured ? Icons.visibility_off : Icons.visibility,
                  color: borderColor,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 12,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: borderColor, width: 2),
              ),
              // Hiển thị thông báo lỗi màu đỏ dưới TextField
              errorText: _loginErrorMessage,
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
            style: const TextStyle(color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildloginbutton(BuildContext context) {
    // Kiểm tra nút có được enable không:
    // - Phải nhập cả email và password (_isFormValid = true)
    // - Không đang trong trạng thái loading
    final bool isButtonEnabled = _isFormValid && !_isLoading;

    return Container(
      margin: const EdgeInsets.only(top: 30, left: 20, right: 20),
      width: double.infinity,
      height: 46,
      child: ElevatedButton(
        // Nếu chưa nhập email/password hoặc đang loading thì disable nút
        onPressed: isButtonEnabled ? () => _handleLogin(context) : null,
        style: ElevatedButton.styleFrom(
          // Màu nút: sáng khi enable, mờ khi disable
          backgroundColor: isButtonEnabled
              ? const Color(0xFFFF9800)
              : const Color(0xFFFF9800).withOpacity(0.5),
          disabledBackgroundColor: const Color(0xFFFF9800).withOpacity(0.5),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            : Text(
                "login_buttom".tr(),
                style: TextStyle(
                  fontSize: 18,
                  // Màu chữ: trắng khi enable, trắng mờ khi disable
                  color: isButtonEnabled
                      ? Colors.white
                      : Colors.white.withOpacity(0.7),
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
            "login_desc1".tr(),
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
          GestureDetector(
            // Thêm khả năng nhấn vào văn bản
            onTap: () {
              _gotosignuppage(context);
              // Xử lý khi nhấn vào "Sign Up"
            },
            child: Text(
              "signin_buttom".tr(),
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

  void _gotosignuppage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const signuppage()),
    );
  }

  // =====================================================
  // HÀM XỬ LÝ ĐĂNG NHẬP
  // =====================================================
  /// Hàm xử lý đăng nhập khi người dùng nhấn nút Login
  /// Đăng nhập bằng email và password
  Future<void> _handleLogin(BuildContext context) async {
    setState(() {
      _isLoading = true;
      _loginErrorMessage = null;
    });

    await _loginWithEmail(context);
  }

  /// Đăng nhập bằng email và password
  Future<void> _loginWithEmail(BuildContext context) async {
    final String email = _usernameCtrl.text.trim();
    final String password = _passwordCtrl.text.trim();

    try {
      await _authRepository.loginInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Đăng nhập thành công
      if (context.mounted) {
        // After successful login, show recommendation if this user hasn't seen it yet
        final user = _firebaseAuthService.getCurrentUser();
        if (user != null) {
          try {
            final prefs = await SharedPreferences.getInstance();
            final key = 'recommendation_seen_${user.uid}';
            final seen = prefs.getBool(key) ?? false;
            if (!seen) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      recommendationpageview(userId: user.uid),
                ),
              );
              return;
            }
          } catch (_) {
            // ignore prefs errors and fall back to main page
          }
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Mainpage()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loginErrorMessage = 'Email hoặc mật khẩu không đúng';
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
}
