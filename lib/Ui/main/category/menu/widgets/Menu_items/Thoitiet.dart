import 'package:flutter/material.dart';
import 'menu_item.dart';
import 'widgets/thoitiet_page.dart';

class Thoitiet extends StatelessWidget {
  const Thoitiet({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MenuItemTile(
      onTap:
          onTap ??
          () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ThoiTietPage()));
          },
      icon: const Icon(Icons.wb_sunny_outlined, size: 36, color: Colors.brown),
      label: 'Thời tiết',
    );
  }
}
