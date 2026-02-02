import 'package:flutter/material.dart';
import 'menu_item.dart';

class Explore extends StatelessWidget {
  const Explore({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MenuItemTile(
      onTap: onTap,
      icon: Icon(Icons.explore, size: 36, color: Colors.brown),
      label: 'Khám\nphá',
    );
  }
}
