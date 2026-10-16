import 'package:flutter/material.dart';
import 'package:tourn/Ui/main/category/favorites/pages/Trangthongbao.dart';

class favorites extends StatelessWidget {
  const favorites({super.key, required this.isActive});

  final bool isActive;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // routes are now defined globally, just show home page
    return HomePage(isActive: isActive);
  }
}
