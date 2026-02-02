import 'package:flutter/material.dart';
import 'menu_item.dart';

class QrReceive extends StatelessWidget {
  const QrReceive({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MenuItemTile(
      onTap: onTap,
      icon: const Icon(Icons.qr_code, size: 36, color: Colors.brown),
      label: 'QR\nnhận tiền',
    );
  }
}
