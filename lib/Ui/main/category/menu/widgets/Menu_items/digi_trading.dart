import 'package:flutter/material.dart';
import 'menu_item.dart';

class DigiTrading extends StatelessWidget {
  const DigiTrading({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MenuItemTile(
      onTap: onTap,
      icon: const Icon(Icons.show_chart, size: 36, color: Colors.green),
      label: 'Digi\nTrading',
    );
  }
}
