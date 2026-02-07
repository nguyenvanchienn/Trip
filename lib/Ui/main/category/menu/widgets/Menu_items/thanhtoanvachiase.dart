import 'package:flutter/material.dart';
import 'menu_item.dart';
import 'widgets/thanhtoanvachiase_page.dart';

class Thanhtoanvachiase extends StatelessWidget {
  const Thanhtoanvachiase({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MenuItemTile(
      onTap:
          onTap ??
          () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ThanhToanVaChiaSePage()),
            );
          },
      icon: const Icon(Icons.payments_outlined, size: 36, color: Colors.brown),
      label: 'Thanh toán và chia tiền',
    );
  }
}
