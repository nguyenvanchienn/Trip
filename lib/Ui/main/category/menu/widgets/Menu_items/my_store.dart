import 'package:flutter/material.dart';
import 'menu_item.dart';

class MyStore extends StatelessWidget {
  const MyStore({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MenuItemTile(
      onTap: onTap,
      icon: const Icon(Icons.store, size: 36, color: Colors.blue),
      label: 'Cửa hàng\ncủa tôi',
    );
  }
}
