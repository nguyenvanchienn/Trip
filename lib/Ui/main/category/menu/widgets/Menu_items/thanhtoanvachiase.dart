import 'package:flutter/material.dart';
import 'menu_item.dart';
import 'widgets/thanhtoanvachiase_page.dart';

class Thanhtoanvachiase extends StatelessWidget {
  const Thanhtoanvachiase({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MenuItemTile(
      onTap:
          onTap ??
          () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ThanhtoanvachiasePage()),
            );
          },
      icon: const Icon(Icons.group, size: 36, color: Colors.green),
      label: 'Thanh toán và chia sẻ',
    );
  }
}
