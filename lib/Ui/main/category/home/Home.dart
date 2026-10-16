import 'package:tourn/Ui/main/category/home/pages/HomePage.dart';
import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  final bool isFirsTimeinstallApp; // Biến để kiểm tra lần đầu cài đặt ứng dụng
  final ValueChanged<bool>? onBottomNavVisibilityChanged;
  final double bottomNavProgress;

  const Home({
    super.key,
    required this.isFirsTimeinstallApp,
    this.onBottomNavVisibilityChanged,
    this.bottomNavProgress = 1,
  });

  @override
  Widget build(BuildContext context) {
    // routing is now performed by the root MaterialApp in main.dart
    return Homepage(
      onBottomNavVisibilityChanged: onBottomNavVisibilityChanged,
      bottomNavProgress: bottomNavProgress,
    );
  }
}
