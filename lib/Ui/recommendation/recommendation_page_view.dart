// Widget cha quản lý các page con recommendation, chỉ hiện khi user đăng nhập lần đầu
import 'package:flutter/material.dart';
import 'package:tourn/Ui/main/main_page.dart';
import 'package:tourn/Ui/recommendation/recommendation_child_page.dart';
import 'package:tourn/ultils.enums/recommendation_page_position.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tourn/Ui/splash/splash.dart';

/// Widget quản lý luồng hiển thị recommendation cho từng tài khoản
/// Chỉ hiện khi user đăng nhập lần đầu (dựa vào userId)
class recommendationpageview extends StatefulWidget {
  /// id tài khoản hiện tại (unique cho mỗi user)
  final String userId;

  /// Khởi tạo, bắt buộc truyền userId
  const recommendationpageview({super.key, required this.userId});

  @override
  State<recommendationpageview> createState() => _recommendationpageviewState();
}

/// State quản lý logic kiểm tra và hiển thị recommendation
class _recommendationpageviewState extends State<recommendationpageview> {
  /// Controller điều khiển chuyển trang PageView
  final PageController _pagecontroller = PageController();

  /// Biến xác định có hiển thị recommendation không
  bool _shouldShowRecommendation = false;

  @override
  void initState() {
    super.initState();
    _checkFirstLogin(); // Kiểm tra trạng thái đã xem recommendation của user
  }

  /// Kiểm tra user đã xem recommendation chưa (dựa vào userId)
  Future<void> _checkFirstLogin() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final key =
        'recommendation_seen_${widget.userId}'; // Key riêng cho từng user
    final seen = prefs.getBool(key) ?? false;
    setState(() {
      _shouldShowRecommendation = !seen; // Nếu chưa xem thì hiển thị
    });
  }

  @override
  Widget build(BuildContext context) {
    // Nếu user đã xem recommendation, chuyển thẳng vào app chính
    if (!_shouldShowRecommendation) {
      Future.microtask(_gotowelcomepage); // Đảm bảo không build lại nhiều lần
      return const SizedBox.shrink();
    }
    // Nếu chưa xem, hiển thị PageView các trang recommendation
    return Scaffold(
      body: PageView(
        controller: _pagecontroller,
        physics: const NeverScrollableScrollPhysics(), // Không cho vuốt tay
        children: [
          // Trang 1
          recommendationchildpage(
            recommendationpageposition: RecommendationPagePosition.page1,
            nextonpress: () {
              makeonboardingcompleted();
              _pagecontroller.jumpToPage(1); // Chuyển sang trang 2
            },
            backonpress: () {}, // Trang đầu không có back
            skiponpress: () {
              makeonboardingcompleted();
              _gotowelcomepage(); // Bỏ qua, vào app
            },
          ),
          // Trang 2
          recommendationchildpage(
            recommendationpageposition: RecommendationPagePosition.page2,
            nextonpress: () {
              makeonboardingcompleted();
              _pagecontroller.jumpToPage(2); // Chuyển sang trang 3
            },
            backonpress: () {
              _pagecontroller.jumpToPage(0); // Quay lại trang 1
            },
            skiponpress: () {
              makeonboardingcompleted();
              _gotowelcomepage();
            },
          ),
          // Trang 3
          recommendationchildpage(
            recommendationpageposition: RecommendationPagePosition.page3,
            nextonpress: () {
              makeonboardingcompleted();
              _gotowelcomepage(); // Hoàn thành, vào app
            },
            backonpress: () {
              _pagecontroller.jumpToPage(1); // Quay lại trang 2
            },
            skiponpress: () {
              makeonboardingcompleted();
              _gotowelcomepage();
            },
          ),
        ],
      ),
    );
  }

  /// Chuyển sang trang chính của app (homepage)
  void _gotowelcomepage() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const SplashScreen()),
      (route) => false,
    );
  }

  /// Đánh dấu user đã xem recommendation (lưu vào SharedPreferences)
  Future<void> makeonboardingcompleted() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final key = 'recommendation_seen_${widget.userId}';
      await prefs.setBool(key, true);
    } catch (e) {
      // Có thể log lỗi nếu cần
      return;
    }
  }
}
