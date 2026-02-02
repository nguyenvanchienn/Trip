import 'package:flutter/material.dart';
import 'package:tourn/Ui/main/category/favorites/favorites_page.dart';
import 'package:tourn/Ui/main/category/home/home.dart';
import 'package:tourn/Ui/main/category/mail/mail_page.dart';
import 'package:tourn/Ui/main/category/map/map_page.dart';
import 'package:tourn/Ui/main/category/menu/Menu.dart';
import 'package:easy_localization/easy_localization.dart';

class Mainpage extends StatefulWidget {
  final int initialTab; // Tab khởi đầu

  const Mainpage({super.key, this.initialTab = 0});

  @override
  State<Mainpage> createState() => _MainpageState();
}

class _MainpageState extends State<Mainpage> {
  List<Widget> pages = [];
  // Danh sách các trang để hiển thị khi chọn từ thanh điều hướng dưới cùng
  late int _currentPage; // Sử dụng late để khởi tạo trong initState

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _currentPage = widget.initialTab; // Sử dụng initialTab

    pages = [
      Home(isFirsTimeinstallApp: true), // Trang Home
      mailpage(), // Trang Mail
      mappage(), // Trang Map
      favorites(), // Trang Favorites
      Menu(), // Trang Profile
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Lấy locale hiện tại để trigger rebuild khi thay đổi ngôn ngữ
    final currentLocale = context.locale;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: pages.elementAt(_currentPage), // Hiển thị trang hiện tại
      bottomNavigationBar: BottomNavigationBar(
        // Thêm thanh điều hướng dưới cùng
        key: ValueKey(
          currentLocale.languageCode,
        ), // Force rebuild khi locale thay đổi
        backgroundColor: const Color(0xFF121212),
        currentIndex: _currentPage, // Hiển thị tab hiện tại
        onTap: (index) {
          // Xử lý khi người dùng nhấn vào tab
          setState(() {
            _currentPage = index; // Cập nhật tab hiện tại
          });
        },
        type: BottomNavigationBarType.fixed, // Đặt kiểu thanh điều hướng
        unselectedItemColor: Colors.white, // Màu của mục chưa chọn
        selectedItemColor: Colors.blue, // Màu của mục đã chọn
        items: <BottomNavigationBarItem>[
          // Thêm các mục vào thanh điều hướng dưới cùng
          BottomNavigationBarItem(
            icon: Image.asset(
              // Sử dụng hình ảnh tùy chỉnh cho biểu tượng
              'asset/icon/home-2.png',
              width: 24,
              height: 24,
              fit: BoxFit.cover,
            ),
            activeIcon: Image.asset(
              'asset/icon/home-2.png',
              width: 24,
              height: 24,
              fit: BoxFit.cover,
              color: Colors.blue, // Màu khi mục được chọn
            ),
            label: "home".tr(),
            backgroundColor: Color.fromARGB(255, 1, 8, 14),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mail),
            label: "mail".tr(),
            backgroundColor: Color.fromARGB(255, 1, 8, 14),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: "map".tr(),
            backgroundColor: Color.fromARGB(255, 1, 8, 14),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: "favorite".tr(),
            backgroundColor: Color.fromARGB(255, 1, 8, 14),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu),
            label: "menu".tr(),
            backgroundColor: Color.fromARGB(255, 1, 8, 14),
          ),
        ],
      ),
    );
  }
}
