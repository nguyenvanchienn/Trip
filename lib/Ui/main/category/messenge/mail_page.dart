// ChatPage import is no longer needed (database widget is used directly)
import 'package:tourn/Ui/main/category/messenge/pages/HomePage.dart';
import 'package:flutter/material.dart';

class mailpage extends StatelessWidget {
  const mailpage({super.key});

  @override
  Widget build(BuildContext context) {
    // no nested MaterialApp; root navigator handles chat route
    return const HomePage();
  }
}
