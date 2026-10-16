import 'package:flutter/material.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_tienich/widgets/Datphongkhachsan/Datphongkhachsan_list.dart';
import 'menu_item.dart';

class Datphongkhachsan extends StatelessWidget {
  const Datphongkhachsan({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MenuItemTile(
      collectionName: 'business_hotel_services',
      onTap:
          onTap ??
          () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const HotelListPage()));
          },
      icon: const Icon(Icons.home_work_outlined, size: 36, color: Colors.blue),
      label: 'Đặt phòng khách sạn',
    );
  }
}
