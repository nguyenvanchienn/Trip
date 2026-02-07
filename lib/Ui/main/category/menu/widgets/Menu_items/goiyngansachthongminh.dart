import 'package:flutter/material.dart';
import 'menu_item.dart';
import 'widgets/goiyngansachthongminh_page.dart';

class Goiyngansachthongminh extends StatelessWidget {
  const Goiyngansachthongminh({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MenuItemTile(
      onTap:
          onTap ??
          () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const GoiYNganSachThongMinhPage(),
              ),
            );
          },
      icon: const Icon(
        Icons.lightbulb_outline,
        size: 36,
        color: Colors.orangeAccent,
      ),
      label: 'Gợi ý ngân sách thông minh',
    );
  }
}
