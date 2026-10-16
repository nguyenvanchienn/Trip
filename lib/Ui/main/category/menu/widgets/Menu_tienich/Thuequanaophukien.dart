import 'package:flutter/material.dart';
import 'menu_item.dart';
import 'widgets/Thuequanaophukien_page.dart';

class Thuequanaovaphukien extends StatelessWidget {
  const Thuequanaovaphukien({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MenuItemTile(
      collectionName: 'business_clothes_services',
      onTap:
          onTap ??
          () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ThuequanaophukienPage()),
            );
          },
      icon: const Icon(Icons.checkroom_outlined, size: 36, color: Colors.green),
      label: 'Thuê quần áo & phụ kiện',
    );
  }
}
