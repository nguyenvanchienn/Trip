import 'package:flutter/material.dart';
import 'package:tourn/Ui/main/category/menu/pages/Menu_page.dart';

class Menu extends StatelessWidget {
  final MenuPageController? controller;

  const Menu({super.key, this.controller});

  @override
  Widget build(BuildContext context) {
    // direct page; navigation (if any) via root navigator
    return MenuPage(controller: controller);
  }
}
