import 'package:flutter/material.dart';
import 'package:tourn/Ui/main/category/menu/widgets/tienich.dart';
import 'package:tourn/Ui/main/category/menu/widgets/weather_indicator.dart';
import 'Menu_drawer.dart';
import '../widgets/quick_access_grid.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tourn/domain/user_repository/user_repository.dart';

class MenuPageController {
  VoidCallback? _scrollToTop;

  void scrollToTop() {
    _scrollToTop?.call();
  }
}

class MenuPage extends StatefulWidget {
  final MenuPageController? controller;

  const MenuPage({super.key, this.controller});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    widget.controller?._scrollToTop = _handleScrollToTop;
  }

  @override
  void dispose() {
    widget.controller?._scrollToTop = null;
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScrollToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userRepo = context.read<UserRepository>();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Ẩn nút quay lại mặc định
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "menu".tr(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 6),
            const WeatherIndicator(),
          ],
        ),

        actions: [
          Builder(
            builder: (context) {
              return IconButton(
                onPressed: () {
                  context.findRootAncestorStateOfType<ScaffoldState>()?.openEndDrawer(); // MỞ DRAWER CỦA ROOT SCAFFOLD
                },
                icon: const Icon(Icons.menu, color: Colors.black),
              );
            },
          ),
        ],
      ),

      body: ListView(
        controller: _scrollController,
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
          _buildtrucapnhanh(userRepo),
          const SizedBox(height: 12),
          _buildtienich(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

Widget _buildtrucapnhanh(UserRepository userRepo) {
  return Padding(
    padding: const EdgeInsets.all(8),
    child: StreamBuilder(
      stream: userRepo.streamCurrentUser(),
      builder: (context, snapshot) {
        final isBusinessAccount = snapshot.data?.isBusinessAccount ?? false;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            QuickAccessGrid(isBusinessAccount: isBusinessAccount),
          ],
        );
      },
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
        const SizedBox(height: 30),
      ],
    ),
  );
}
