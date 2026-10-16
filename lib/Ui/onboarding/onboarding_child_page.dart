// đón vai trò giao diện mà hình
import 'package:flutter/material.dart';
import 'package:tourn/ultils.enums/onboarding_page_position.dart';

class onboardingchildpage extends StatelessWidget {
  final OnboardingPagePosition onboardingpageposition; // Sử dụng kiểu enum đúng

  final VoidCallback nextonpress; // Hàm gọi khi nhấn nút tiếp theo
  final VoidCallback backonpress; // Hàm gọi khi nhấn nút quay lại
  final VoidCallback skiponpress; // Hàm gọi khi nhấn nút bỏ qua

  const onboardingchildpage({
    super.key,
    required this.onboardingpageposition,
    required this.nextonpress,
    required this.backonpress,
    required this.skiponpress,
  }); // Khởi tạo hằng số với tham số bắt buộc

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        // SafeArea để tránh các khu vực không an toàn trên
        child: SingleChildScrollView(
          // Cho phép cuộn nếu nội dung vượt quá màn hình
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.start, // Căn các phần tử từ đầu trục chính
            crossAxisAlignment:
                CrossAxisAlignment.center, // Căn các phần tử từ đầu trục Giữa
            children: [
              _buildskipbuttonpage(),
              _buildonboardingimagepage(),
              _buildonboardingcontrolpage(),
              _buildonboardingtitleandcontentpage(),
              _buildonboardingnextandprevbutton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildskipbuttonpage() {
    return Container(
      alignment: AlignmentDirectional.centerStart, // Căn nút về phía bên trái
      margin: const EdgeInsets.only(top: 14),
      child: TextButton(
        onPressed: () {
          skiponpress();
        },
        child: Text(
          "SKIP",
          style: TextStyle(
            fontSize: 16,
            fontFamily: "lato",
            color: Colors.black.withValues(
              alpha: 0.44,
            ), // Màu trắng với độ mờ 44%
          ),
        ),
      ),
    );
  }

  Widget _buildonboardingimagepage() {
    return Image.asset(
      onboardingpageposition.onboardingpageimage(),
      width: 296,
      height: 291,
      fit: BoxFit.contain,
    );
  }

  Widget _buildonboardingcontrolpage() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 50),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Chấm điều khiển trang 1
          Container(
            margin: EdgeInsets.symmetric(
              horizontal: 8,
            ), // Khoảng cách ngang giữa các chấm
            height: 10,
            width: 10,
            decoration: BoxDecoration(
              color:
                  onboardingpageposition ==
                      OnboardingPagePosition
                          .page1 // Kiểm tra vị trí trang hiện tại
                  ? Colors.black
                  : Colors.black.withValues(alpha: 0.30),
              borderRadius: BorderRadius.circular(56),
            ),
          ),
          // Chấm điều khiển trang 2
          Container(
            margin: EdgeInsets.symmetric(
              horizontal: 8,
            ), // Khoảng cách ngang giữa các chấm
            height: 10,
            width: 10,
            decoration: BoxDecoration(
              color: onboardingpageposition == OnboardingPagePosition.page2
                  ? Colors.black
                  : Colors.black.withValues(alpha: 0.30),
              borderRadius: BorderRadius.circular(56),
            ),
          ),
          // Chấm điều khiển trang 3
          Container(
            margin: EdgeInsets.symmetric(
              horizontal: 8,
            ), // Khoảng cách ngang giữa các chấm
            height: 10,
            width: 10,
            decoration: BoxDecoration(
              color: onboardingpageposition == OnboardingPagePosition.page3
                  ? Colors.black
                  : Colors.black.withValues(alpha: 0.30),
              borderRadius: BorderRadius.circular(56), // Bo góc cho chấm
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildonboardingtitleandcontentpage() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            onboardingpageposition.onboardingpagetitle(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center, // Căn giữa văn bản
          ),
          SizedBox(height: 42), // Khoảng cách giữa tiêu đề và nội dung
          Text(
            onboardingpageposition.onboardingpagecontent(),
            style: TextStyle(
              fontSize: 16,
              color: Colors.black.withValues(alpha: 0.54),
            ), // Màu trắng với độ mờ 54%
            textAlign: TextAlign.center, // Căn giữa văn bản
          ),
        ],
      ),
    );
  }

  Widget _buildonboardingnextandprevbutton() {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: 24,
      ).copyWith(top: 75, bottom: 20), // Khoảng cách từ trên xuống
      child: Row(
        children: [
          TextButton(
            onPressed: () {
              backonpress();
            },
            child: Text(
              "BACK",
              style: TextStyle(
                fontSize: 16,
                fontFamily: "loto",
                color: Colors.black.withValues(
                  alpha: 0.44,
                ), // Màu trắng với độ mờ 44%
              ),
            ),
          ),
          Spacer(), // Khoảng cách linh hoạt giữa hai nút
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 27, 40, 129),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(0),
              ),
            ),
            onPressed: () {
              nextonpress();
            },
            child: Text(
              onboardingpageposition ==
                      OnboardingPagePosition
                          .page3 // Kiểm tra vị trí trang hiện tại
                  ? "GET STARTED" // Nếu là trang cuối cùng, hiển thị "GET STARTED"
                  : "NEXT", // Ngược lại, hiển thị "NEXT"
              style: TextStyle(
                fontSize: 16,
                fontFamily: "loto",
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
