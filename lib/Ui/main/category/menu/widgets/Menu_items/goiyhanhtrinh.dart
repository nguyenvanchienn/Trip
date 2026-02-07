import 'package:flutter/material.dart';
import 'menu_item.dart';
import 'widgets/goiyhanhtrinh_page.dart';

class Goiyhanhtrinh extends StatelessWidget {
  const Goiyhanhtrinh({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MenuItemTile(
      onTap:
          onTap ??
          () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const GoiYHanhTrinhPage()),
            );
          },
      icon: const Icon(
        Icons.route_outlined,
        size: 36,
        color: Colors.orangeAccent,
      ),
      label: 'Gợi ý hành trình',
    );
  }
}
