import 'package:flutter/material.dart';
import 'menu_item.dart';
import 'widgets/ghichu_page.dart';

class Ghichu extends StatelessWidget {
  const Ghichu({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MenuItemTile(
      onTap:
          onTap ??
          () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const GhiChuPage()));
          },
      icon: const Icon(Icons.edit_note_outlined, size: 36, color: Colors.green),
      label: 'Ghi chú',
    );
  }
}
