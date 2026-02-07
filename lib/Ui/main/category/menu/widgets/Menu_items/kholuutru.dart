import 'package:flutter/material.dart';
import 'menu_item.dart';
import 'widgets/kholuutru_page.dart';

class Kholuutru extends StatelessWidget {
  const Kholuutru({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MenuItemTile(
      onTap:
          onTap ??
          () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const KhoLuuTruPage()));
          },
      icon: const Icon(
        Icons.bookmark_outline,
        size: 36,
        color: Colors.deepPurple,
      ),
      label: 'Kho lưu trữ',
    );
  }
}
