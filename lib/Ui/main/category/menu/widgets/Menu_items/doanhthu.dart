import 'package:flutter/material.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_items/widgets/doanhthu_page.dart';
import 'menu_item.dart';

class DoanhThu extends StatelessWidget {
  const DoanhThu({super.key, this.onTap, this.isBusinessAccount = false});

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
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const DoanhThuPage()));
          },
      icon: const Icon(Icons.trending_up, size: 36, color: Colors.green),
      label: 'Doanh thu',
    );
  }
}
