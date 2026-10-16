import 'package:flutter/material.dart';
import 'menu_item.dart';
import 'widgets/chiasethoigianthuc_page.dart';

class Chiasethoigianthuc extends StatelessWidget {
  /// If [sessionId] is supplied the pushed page will act as a viewer.
  const Chiasethoigianthuc({super.key, this.onTap, this.sessionId});

  final VoidCallback? onTap;
  final String? sessionId;

  @override
  Widget build(BuildContext context) {
    return MenuItemTile(
      onTap:
          onTap ??
          () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChiaSeThoiGianThucPage(sessionId: sessionId),
              ),
            );
          },
      icon: const Icon(
        Icons.wifi_tethering_outlined,
        size: 36,
        color: Colors.blue,
      ),
      label: 'Chia sẻ thời gian thực',
    );
  }
}
