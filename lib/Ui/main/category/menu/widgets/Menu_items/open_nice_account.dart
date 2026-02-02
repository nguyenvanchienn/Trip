import 'package:flutter/material.dart';
import 'menu_item.dart';

class OpenNiceAccount extends StatelessWidget {
  const OpenNiceAccount({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MenuItemTile(
      onTap: onTap,
      icon: Icon(
        Icons.sentiment_satisfied,
        size: 36,
        color: Colors.orangeAccent,
      ),
      label: 'Mở tài khoản\nsố đẹp',
    );
  }
}
