import 'package:flutter/material.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_tienich/menu_item.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_tienich/widgets/datvemaybay_page.dart';

class Datvemaybay extends StatelessWidget {
  const Datvemaybay({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MenuItemTile(
      collectionName: 'business_flight_ticket_services',
      onTap:
          onTap ??
          () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const MaybayPage()));
          },
      icon: const Icon(
        Icons.flight_takeoff,
        size: 36,
        color: Colors.blueAccent,
      ),
      label: 'Đặt vé máy bay',
    );
  }
}
