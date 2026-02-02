import 'package:flutter/material.dart';
import 'Menu_items/introduce_receive_money.dart';
import 'Menu_items/my_store.dart';
import 'Menu_items/qr_receive.dart';
import 'Menu_items/open_nice_account.dart';
import 'Menu_items/digi_trading.dart';
import 'Menu_items/explore.dart';
import 'Menu_items/smart_finance.dart';
import 'Menu_items/installment.dart';

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
                SizedBox(width: itemWidth, child: IntroduceReceiveMoney()),
                SizedBox(width: itemWidth, child: MyStore()),
                SizedBox(width: itemWidth, child: QrReceive()),
                SizedBox(width: itemWidth, child: OpenNiceAccount()),
                SizedBox(width: itemWidth, child: DigiTrading()),
                SizedBox(width: itemWidth, child: Explore()),
                SizedBox(width: itemWidth, child: SmartFinance()),
                SizedBox(width: itemWidth, child: Installment()),
              ],
            );
          },
        ),
      ),
    );
  }
}
