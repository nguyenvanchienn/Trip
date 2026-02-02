import 'package:flutter/material.dart';
import 'package:tourn/Ui/main/category/menu/pages/Menu_drawer.dart';
import 'package:tourn/Ui/main/category/menu/pages/Menu_page.dart';

class Menu extends StatelessWidget {
  const Menu({super.key});

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
        "/": (context) => MenuPage(),
        "/menudrawer": (context) => MenuDrawer(),
      },
    );
  }
}
