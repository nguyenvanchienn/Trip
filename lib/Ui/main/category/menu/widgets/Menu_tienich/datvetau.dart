import 'package:flutter/material.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_tienich/menu_item.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_tienich/widgets/datvetau_page.dart';

class Datvetau extends StatelessWidget {
  const Datvetau({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MenuItemTile(
      collectionName: 'business_ship_ticket_services',
      onTap:
          onTap ??
          () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const DatvetauPage()));
          },
      icon: const Icon(
        Icons.directions_boat,
        size: 36,
        color: Colors.blueAccent,
      ),
      label: 'Đặt vé tàu',
    );
  }
}
