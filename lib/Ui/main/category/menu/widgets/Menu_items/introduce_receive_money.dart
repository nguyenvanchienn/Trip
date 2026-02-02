import 'package:flutter/material.dart';
import 'menu_item.dart';

class IntroduceReceiveMoney extends StatelessWidget {
  const IntroduceReceiveMoney({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MenuItemTile(
      onTap: onTap,
      icon: const Icon(Icons.card_giftcard, size: 36, color: Colors.deepPurple),
      label: 'Giới thiệu\nnhận tiền',
    );
  }
}
