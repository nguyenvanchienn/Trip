import 'package:tourn/Ui/main/category/favorites/pages/baiviet.dart';
import 'package:tourn/Ui/main/category/home/pages/homepage.dart';
import 'package:flutter/material.dart';
import 'package:tourn/Ui/main/category/home/widgets/profile.dart';

class Home extends StatelessWidget {
  final bool isFirsTimeinstallApp; // Biến để kiểm tra lần đầu cài đặt ứng dụng

  const Home({super.key, required this.isFirsTimeinstallApp});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Color(0xFFF5F5F3),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFFF5F5F3),
          foregroundColor: Color(0xFF113953), // Màu chữ trên AppBar
        ),
      ),
      routes: {
        "/": (context) => Homepage(),
        "/profile": (context) => profile(),
        "/baiviet": (context) => Baiviet(),
      },
    );
  }
}
