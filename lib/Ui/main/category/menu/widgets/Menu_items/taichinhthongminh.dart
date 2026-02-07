import 'package:flutter/material.dart';
import 'menu_item.dart';
import 'widgets/taichinhthongminh_page.dart';

class Taichinhthongminh extends StatelessWidget {
  const Taichinhthongminh({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MenuItemTile(
      onTap:
          onTap ??
          () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TaiChinhThongMinhPage()),
            );
          },
      icon: const Icon(Icons.pie_chart, size: 36, color: Colors.amber),
      label: 'Tài chính thông minh',
    );
  }
}
