import 'package:flutter/material.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_tienich/menu_item.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_tienich/widgets/datvexekhach_page.dart';

class Datvexekhach extends StatelessWidget {
  const Datvexekhach({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MenuItemTile(
      collectionName: 'business_bus_ticket_services',
      onTap:
          onTap ??
          () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const XekhachPage()));
          },
      icon: const Icon(
        Icons.directions_bus,
        size: 36,
        color: Colors.blueAccent,
      ),
      label: 'Đặt vé xe khách',
    );
  }
}
