import 'package:flutter/material.dart';
import 'Menu_items/kholuutru.dart';
import 'Menu_items/chiasethoigianthuc.dart';
import 'Menu_items/taichinhthongminh.dart';
import 'Menu_items/goiyngansachthongminh.dart';
import 'Menu_items/Ghichu.dart';
import 'Menu_items/thanhtoanvachiase.dart';
import 'Menu_items/khamphadiadiem.dart';
import 'Menu_items/goiyhanhtrinh.dart';
import 'Menu_items/Thoitiet.dart';

class QuickAccessGrid extends StatelessWidget {
  const QuickAccessGrid({super.key});

  @override
  Widget build(BuildContext context) {
    // FIX: Đã thay `GridView` bằng `Wrap` để đảm bảo KHÔNG có scrollbar/cuộn trong vùng này.
    // Lý do: GridView (có hoặc không có shrinkWrap) khi kết hợp với layout flex hoặc khi cố gắng scroll
    // có thể dẫn đến xung đột kích thước và gây hiện tượng "BOTTOM OVERFLOWED" hoặc hiển thị thanh cuộn.
    // Ngoài ra đã giảm `runSpacing` và `padding` đáy để tránh khoảng cách lớn phía dưới thẻ.
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
                SizedBox(width: itemWidth, child: Kholuutru()),
                SizedBox(width: itemWidth, child: Chiasethoigianthuc()),
                SizedBox(width: itemWidth, child: Taichinhthongminh()),
                SizedBox(width: itemWidth, child: Goiyngansachthongminh()),
                SizedBox(width: itemWidth, child: Ghichu()),
                SizedBox(width: itemWidth, child: Thanhtoanvachiase()),
                SizedBox(width: itemWidth, child: Khamphadiadiem()),
                SizedBox(width: itemWidth, child: Goiyhanhtrinh()),
                SizedBox(width: itemWidth, child: Thoitiet()),
              ],
            );
          },
        ),
      ),
    );
  }
}
