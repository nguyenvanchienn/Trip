import 'package:flutter/material.dart';
import 'menu_item.dart';
import 'widgets/khamphadiadiem_page.dart';

class Khamphadiadiem extends StatelessWidget {
  const Khamphadiadiem({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MenuItemTile(
      onTap:
          onTap ??
          () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const KhamPhaDiaDiemPage()),
            );
          },
      icon: const Icon(Icons.place_outlined, size: 36, color: Colors.amber),
      label: 'Khám phá địa điểm',
    );
  }
}
