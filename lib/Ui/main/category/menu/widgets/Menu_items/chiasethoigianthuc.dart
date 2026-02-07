import 'package:flutter/material.dart';
import 'menu_item.dart';
import 'widgets/chiasethoigianthuc_page.dart';

class Chiasethoigianthuc extends StatelessWidget {
  const Chiasethoigianthuc({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MenuItemTile(
      onTap:
          onTap ??
          () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ChiaSeThoiGianThucPage()),
            );
          },
      icon: const Icon(
        Icons.wifi_tethering_outlined,
        size: 36,
        color: Colors.blue,
      ),
      label: 'Chia sẻ thời gian thực',
    );
  }
}
