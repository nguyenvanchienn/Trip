import 'package:flutter/material.dart';
import 'menu_item.dart';
import 'widgets/timbenhviengannhat_page.dart';

class Timbenhviengannhat extends StatelessWidget {
  const Timbenhviengannhat({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MenuItemTile(
      onTap:
          onTap ??
          () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TimbenhviengannhatPage()),
            );
          },
      icon: const Icon(
        Icons.local_hospital_outlined,
        size: 36,
        color: Colors.redAccent,
      ),
      label: 'Tìm kiếm bệnh viện gần nhất',
    );
  }
}
