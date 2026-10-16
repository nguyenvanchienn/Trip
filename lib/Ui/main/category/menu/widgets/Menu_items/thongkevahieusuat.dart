import 'package:flutter/material.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_items/widgets/thongkevahieusuat_page.dart';
import 'menu_item.dart';

class Thongkevahieusuat extends StatelessWidget {
  const Thongkevahieusuat({
    super.key,
    this.onTap,
    this.isBusinessAccount = false,
  });

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
              MaterialPageRoute(builder: (_) => const ThongkevahieusuatPage()),
            );
          },
      icon: const Icon(Icons.insights, size: 36, color: Colors.indigo),
      label: 'Thống kê & hiệu suất',
    );
  }
}
