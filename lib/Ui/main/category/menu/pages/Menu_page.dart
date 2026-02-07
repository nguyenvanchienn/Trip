import 'package:flutter/material.dart';
import 'package:tourn/Ui/main/category/menu/widgets/tienich.dart';
import 'Menu_drawer.dart';
import '../widgets/quick_access_grid.dart';
import 'package:easy_localization/easy_localization.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    // cái này để load trước hình ảnh, tránh bị giật khi mở drawer
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        precacheImage(
          ResizeImage(
            const AssetImage('asset/images/employee-5.png'),
            width: 112,
          ),
          context,
        );
        precacheImage(
          ResizeImage(const AssetImage('asset/icon/vietnam.webp'), width: 44),
          context,
        );
        precacheImage(
          ResizeImage(const AssetImage('asset/icon/english.png'), width: 44),
          context,
        );
      } catch (_) {}
    });

    return Scaffold(
      endDrawer: const MenuDrawer(), // Drawer bên phải

      appBar: AppBar(
        automaticallyImplyLeading: false, // Ẩn nút quay lại mặc định
        title: Text(
          "menu".tr(),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),

        actions: [
          Builder(
            builder: (context) {
              return IconButton(
                onPressed: () {
                  Scaffold.of(context).openEndDrawer(); //MỞ DRAWER PHẢI
                },
                icon: const Icon(Icons.menu, color: Colors.black),
              );
            },
          ),
        ],
      ),

      body: ListView(
        // Sử dụng ListView để nội dung có thể cuộn
        padding: EdgeInsets.only(
          bottom:
              MediaQuery.of(context).padding.bottom +
              kBottomNavigationBarHeight,
          left: 8,
          right: 8,
          top: 8,
        ),
        children: [
          _buildtrucapnhanh(),
          const SizedBox(height: 12),
          _buildtienich(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

Widget _buildtrucapnhanh() {
  return Padding(
    padding: const EdgeInsets.all(8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [const SizedBox(height: 12), const QuickAccessGrid()],
    ),
  );
}

Widget _buildtienich() {
  return Padding(
    padding: const EdgeInsets.all(8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tiện ích',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Tienich(),
      ],
    ),
  );
}
