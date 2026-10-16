import 'package:flutter/material.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_tienich/widgets/amthucvungmien_page.dart';
import 'menu_item.dart';

class Amthucvungmien extends StatelessWidget {
  const Amthucvungmien({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MenuItemTile(
      collectionName: 'business_food_services',
      onTap:
          onTap ??
          () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AmthucvungmienPage()),
            );
          },

      // Icon phù hợp cho ẩm thực
      icon: const Icon(
        Icons.restaurant_menu_rounded,
        size: 36,
        color: Colors.orange,
      ),

      label: 'Ẩm thực vùng miền',
    );
  }
}
