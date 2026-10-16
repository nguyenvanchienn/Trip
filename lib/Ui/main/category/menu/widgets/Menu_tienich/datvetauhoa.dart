import 'package:flutter/material.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_tienich/menu_item.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_tienich/widgets/datvetauhoa_page.dart';

class Datvetauhoa extends StatelessWidget {
  const Datvetauhoa({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MenuItemTile(
      collectionName: 'business_train_ticket_services',
      onTap:
          onTap ??
          () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const TauhoaPage()));
          },
      icon: const Icon(Icons.train, size: 36, color: Colors.blueAccent),
      label: 'Đặt vé tàu hỏa',
    );
  }
}
