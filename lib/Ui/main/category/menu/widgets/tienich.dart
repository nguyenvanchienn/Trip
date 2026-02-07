import 'package:flutter/material.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_items/Ghichu.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_tienich/Thuequanaophukien.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_tienich/phuongtiendichuyen.dart';
import 'Menu_tienich/Datphongkhachsan.dart';
import 'Menu_tienich/Thuehuongdanvien.dart';
import 'Menu_tienich/Thuethochupanh.dart';
import 'Menu_tienich/thanhtoanvachiase.dart';
import 'Menu_tienich/khamphadiadiem.dart';
import 'Menu_tienich/goiyhanhtrinh.dart';

class Tienich extends StatelessWidget {
  const Tienich({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2, // độ cao bóng
      margin: const EdgeInsets.all(0), // khoảng cách bên ngoài thẻ
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          8,
          12,
          8,
          8,
        ), // khoảng cách bên trong thẻ
        child: LayoutBuilder(
          builder: (context, constraints) {
            const double spacing = 12; // cách nhau giữa các mục
            const double runSpacing = 12; // cách nhau giữa các hàng
            const int columns = 4; // số cột cố định
            final double totalSpacing =
                spacing * (columns - 1); // tổng khoảng cách giữa các mục
            final double itemWidth =
                (constraints.maxWidth - totalSpacing) / columns;

            return Wrap(
              spacing: spacing,
              runSpacing: runSpacing,
              children: [
                SizedBox(width: itemWidth, child: PhuongTienDiChuyen()),
                SizedBox(width: itemWidth, child: Datphongkhachsan()),
                SizedBox(width: itemWidth, child: Thuehuongdanvien()),
                SizedBox(width: itemWidth, child: Thuethochupanh()),
                SizedBox(width: itemWidth, child: Thuequanaovaphukien()),
                SizedBox(width: itemWidth, child: Thanhtoanvachiase()),
                SizedBox(width: itemWidth, child: Khamphadiadiem()),
                SizedBox(width: itemWidth, child: Goiyhanhtrinh()),
              ],
            );
          },
        ),
      ),
    );
  }
}
