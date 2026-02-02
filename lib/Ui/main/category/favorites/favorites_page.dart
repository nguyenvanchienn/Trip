import 'package:flutter/material.dart';
import 'package:tourn/Ui/main/category/favorites/pages/Baiviet.dart';
import 'package:tourn/Ui/main/category/favorites/pages/Trangthongbao.dart';

class favorites extends StatelessWidget {
  const favorites({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Color(0xFFF5F5F3),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFFF5F5F3),
          foregroundColor: Color(0xFF113953),
        ),
      ),
      routes: {
        "/": (context) => HomePage(),
        "/baiviet": (context) => Baiviet(),
      },
    );
  }
}
