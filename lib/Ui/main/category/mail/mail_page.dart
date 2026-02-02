import 'package:tourn/Ui/main/category/mail/pages/ChatPage.dart';
import 'package:tourn/Ui/main/category/mail/pages/HomePage.dart';
import 'package:flutter/material.dart';

class mailpage extends StatelessWidget {
  const mailpage({super.key});

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
        "/chatPage": (context) => ChatPage(),
      },
    );
  }
}
