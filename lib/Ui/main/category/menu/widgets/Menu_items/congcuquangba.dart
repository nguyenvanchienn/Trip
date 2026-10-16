import 'package:flutter/material.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_items/widgets/congcuquangba_page.dart';
import 'menu_item.dart';

class CongCuQuangBa extends StatelessWidget {
  const CongCuQuangBa({super.key, this.onTap, this.isBusinessAccount = false});

  final VoidCallback? onTap;
  final bool isBusinessAccount;

  @override
  Widget build(BuildContext context) {
    if (!isBusinessAccount) {
      return const SizedBox.shrink();
    }

    return MenuItemTile(
      onTap:
          onTap ??
          () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CongCuQuangBaPage()),
            );
          },
      icon: const Icon(Icons.campaign_outlined, size: 36, color: Colors.pink),
      label: 'Công cụ quảng bá',
    );
  }
}
