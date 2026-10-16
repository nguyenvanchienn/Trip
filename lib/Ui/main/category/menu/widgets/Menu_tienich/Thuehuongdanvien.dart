import 'package:flutter/material.dart';
import 'menu_item.dart';
import 'widgets/Thuehuongdanvien_page.dart';

class Thuehuongdanvien extends StatelessWidget {
  const Thuehuongdanvien({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MenuItemTile(
      collectionName: 'business_guide_services',
      onTap:
          onTap ??
          () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ThuehuongdanvienPage()),
            );
          },
      icon: const Icon(
        Icons.support_agent_outlined,
        size: 36,
        color: Colors.amber,
      ),
      label: 'Thuê hướng dẫn viên',
    );
  }
}
