import 'package:flutter/material.dart';
import 'package:tourn/Ui/domain/domain_data_sources/firebase_auth_sevice.dart';
import 'package:tourn/Ui/domain/domain_authentication_repository/authentication_repository.dart';

class Forgetpassword extends StatefulWidget {
  const Forgetpassword({super.key});

  @override
  State<Forgetpassword> createState() => _ForgetpasswordState();
}

class _ForgetpasswordState extends State<Forgetpassword> {
  final TextEditingController _emailCtrl = TextEditingController();
  final FirebaseAuthService _firebaseAuthService = FirebaseAuthService();
  late final AuthenticationRepository _authRepository;

  bool _isLoading = false;
  String? _emailError;

  @override
  void initState() {
    super.initState();
    _authRepository = AuthenticationRepositoryImpl(
      firebaseAuthService: _firebaseAuthService,
    );
    _emailCtrl.addListener(_validate);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  void _validate() {
    final email = _emailCtrl.text.trim();
    String? err;
    if (email.isNotEmpty) {
      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
      if (!emailRegex.hasMatch(email)) err = 'Email không hợp lệ';
    }
    setState(() => _emailError = err);
  }

  Future<void> _sendReset() async {
    _validate();
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || _emailError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập email hợp lệ')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authRepository.sendPasswordResetEmail(email: email);
      if (mounted) {
        setState(() => _isLoading = false);
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Hoàn tất'),
            content: const Text(
              'Chúng tôi đã gửi email chứa đường dẫn đặt lại mật khẩu. Vui lòng kiểm tra hộp thư để đặt lại mật khẩu của bạn.',
            ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.max,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // đóng dialog
                    },
                    child: const Text(
                      'Đóng',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // đóng dialog
                      Navigator.pop(context); // quay về trang trước (đăng nhập)
                    },
                    child: const Text(
                      'Đăng nhập',
                      style: TextStyle(color: Color(0xFFFF9800)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xảy ra lỗi khi gửi email đặt lại mật khẩu: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool enabled = !_isLoading;
    return Scaffold(
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
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Nhập email đã đăng ký để nhận đường dẫn đặt lại mật khẩu',
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'you@gmail.com',
                  errorText: _emailError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: enabled ? _sendReset : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9800),
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
                      : const Text(
                          'Gửi liên kết đặt lại',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: enabled ? () => Navigator.pop(context) : null,
                  child: Text(
                    'Quay lại',
                    style: TextStyle(color: const Color(0xFFFF9800)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
