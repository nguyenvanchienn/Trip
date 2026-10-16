import 'package:flutter/material.dart';
import 'menu_item.dart';
import 'widgets/timkiematmgannhat_page.dart';

class Timkiematmgannhat extends StatelessWidget {
  const Timkiematmgannhat({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MenuItemTile(
      onTap:
          onTap ??
          () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TimkiematmgannhatPage()),
            );
          },
      icon: const Icon(
        Icons.account_balance_outlined,
        size: 36,
        color: Colors.green,
      ),
      label: 'Tìm kiếm ATM gần nhất',
    );
  }
}
