import 'package:flutter/material.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_items/widgets/taochuyendi_page.dart';
import 'menu_item.dart';

class TaoChuyenDi extends StatelessWidget {
  const TaoChuyenDi({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MenuItemTile(
      onTap:
          onTap ??
          () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const TaochuyendiPage()));
          },

      // ⭐ Icon cam đậm → hiện rõ trên nền trắng
      icon: const Icon(
        Icons.alt_route_outlined,
        size: 36,
        color: Colors.deepOrange,
      ),

      label: 'Tạo chuyến đi',
    );
  }
}
