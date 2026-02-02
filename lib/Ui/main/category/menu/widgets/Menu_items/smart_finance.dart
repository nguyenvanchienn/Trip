import 'package:flutter/material.dart';
import 'menu_item.dart';

class SmartFinance extends StatelessWidget {
  const SmartFinance({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MenuItemTile(
      onTap: onTap,
      icon: Icon(Icons.pie_chart, size: 36, color: Colors.amber),
      label: 'Tài chính\nthông minh',
    );
  }
}
