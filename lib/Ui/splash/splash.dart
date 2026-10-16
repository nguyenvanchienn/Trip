import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tourn/Ui/main/main_page.dart';
import 'package:tourn/Ui/onboarding/onboarding_page_view.dart';
import 'package:tourn/Ui/welcome/welcome_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAppStatus();
  }

  Future<void> _checkAppStatus() async {
    // wait briefly so splash is visible
    await Future.delayed(const Duration(seconds: 3));

    // if a user is already signed in with Firebase we don't treat them as
    // "logged out" – go straight to the main page regardless of onboarding
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Mainpage()),
      );
      return;
    }

    // no active user, continue with normal onboarding/welcome flow
    final iscomplete = await isonboardingcompleted();
    if (!mounted) return;
    if (iscomplete) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => WelcomePage(isFirsTimeinstallApp: false),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => onboardingpageview()),
      );
    }
  }

  Future<bool> isonboardingcompleted() async {
    // Hàm giả lập khởi tạo ứng dụng
    try {
      // Giả lập việc lấy trạng thái từ bộ nhớ hoặc cơ sở dữ liệu
      final SharedPreferences prefs =
          await SharedPreferences.getInstance(); // Lấy instance của SharedPreferences
      final result = prefs.getBool(
        'konboardingcompleted',
      ); // Lấy trạng thái hoàn thành onboarding
      return result ?? false; // Trả về kết quả
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // trạng thái ứng dụng đã được kiểm tra trong initState
    // Kiểm tra trạng thái ứng dụng khi xây dựng giao diện (không gọi ở đây)
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('asset/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(child: _buildbodypage()),
      ),
    );
  }

  Widget _buildbodypage() {
    return Center(
      child: Container(
        child: Column(
          mainAxisSize: MainAxisSize.min, // Cột chỉ chiếm không gian cần thiết
          children: [
            _buildiconpage(), // Gọi phương thức xây dựng hình ảnh logo
            const SizedBox(height: 10), // Khoảng cách giữa hình ảnh và văn bản
            _buildtextpage(), // Gọi phương thức xây dựng văn bản chào mừng
          ],
        ),
      ),
    );
  }

  Widget _buildiconpage() {
    return Image.asset(
      'asset/icon/logo.png',
      width: 95,
      height: 140,
      fit: BoxFit.cover, // Đảm bảo hình ảnh được bao phủ đúng cách
    );
  }

  Widget _buildtextpage() {
    return Text(
      'TRIP',
      style: TextStyle(
        fontSize: 40,
        color: Color(0xFFFFB620),
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
