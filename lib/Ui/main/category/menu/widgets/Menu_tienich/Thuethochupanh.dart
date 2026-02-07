import 'package:flutter/material.dart';
import 'menu_item.dart';
import 'widgets/Thuethochupanh_Page.dart';

class Thuethochupanh extends StatelessWidget {
  const Thuethochupanh({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MenuItemTile(
      onTap:
          onTap ??
          () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ThuethochupanhPage()),
            );
          },
      icon: const Icon(
        Icons.photo_camera_outlined,
        size: 36,
        color: Colors.orangeAccent,
      ),
      label: 'Thuê thợ chụp ảnh',
    );
  }
}
