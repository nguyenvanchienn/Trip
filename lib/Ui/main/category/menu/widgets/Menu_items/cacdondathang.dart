import 'package:flutter/material.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_items/widgets/cacdondathang_page.dart';
import 'menu_item.dart';

class CacDonDatHang extends StatelessWidget {
  const CacDonDatHang({super.key, this.onTap, this.isBusinessAccount = false});

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
              MaterialPageRoute(builder: (_) => const CacDonDatHangPage()),
            );
          },
      icon: const Icon(Icons.receipt_long, size: 36, color: Colors.teal),
      label: 'Các đơn đặt hàng',
    );
  }
}
