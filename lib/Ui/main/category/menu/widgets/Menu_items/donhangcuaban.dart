import 'package:flutter/material.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_items/widgets/donhangcuaban_page.dart';
import 'menu_item.dart';

class DonHangCuaBan extends StatelessWidget {
  const DonHangCuaBan({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MenuItemTile(
      onTap:
          onTap ??
          () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DonHangCuaBanPage()),
            );
          },
      icon: const Icon(
        Icons.shopping_bag_outlined,
        size: 36,
        color: Colors.blue,
      ),
      label: 'Đơn hàng của bạn',
    );
  }
}
