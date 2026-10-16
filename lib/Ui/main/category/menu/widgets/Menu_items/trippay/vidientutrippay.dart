import 'package:flutter/material.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_items/trippay/trippay_pin_page.dart';
import '../menu_item.dart';

class Vidientutrippay extends StatelessWidget {
  const Vidientutrippay({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MenuItemTile(
      onTap:
          onTap ??
          () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const TripPayPinPage()));
          },

      // ⭐ Icon ví điện tử chuẩn
      icon: const Icon(
        Icons.account_balance_wallet_outlined,
        size: 36,
        color: Colors.deepOrange,
      ),

      label: 'TripPay',
    );
  }
}
