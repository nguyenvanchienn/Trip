import 'package:flutter/material.dart';
import 'menu_item.dart';
import 'widgets/soskhancap_page.dart';

class SosKhanCap extends StatelessWidget {
  const SosKhanCap({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MenuItemTile(
      onTap:
          onTap ??
          () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SoskhancapPage()));
          },

      icon: const Icon(
        Icons.warning_amber_rounded,
        size: 36,
        color: Colors.redAccent,
      ),

      label: 'SOS khẩn cấp',
    );
  }
}
