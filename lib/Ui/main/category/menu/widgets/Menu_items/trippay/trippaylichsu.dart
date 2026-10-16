import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Trippaylichsu extends StatelessWidget {
  const Trippaylichsu({super.key});

  @override
  Widget build(BuildContext context) {
    final List<TransactionModel> transactions = [
      TransactionModel(
        title: "Nhận tiền",
        subtitle: "Từ Nguyễn Văn A",
        amount: 500000,
        isIncome: true,
        time: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      TransactionModel(
        title: "Thanh toán",
        subtitle: "Đặt vé máy bay",
        amount: 1200000,
        isIncome: false,
        time: DateTime.now().subtract(const Duration(days: 1)),
      ),
      TransactionModel(
        title: "Chuyển tiền",
        subtitle: "Đến Trần Thị B",
        amount: 300000,
        isIncome: false,
        time: DateTime.now().subtract(const Duration(days: 2)),
      ),
      TransactionModel(
        title: "Nạp tiền",
        subtitle: "Từ ngân hàng",
        amount: 2000000,
        isIncome: true,
        time: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: const Text("Lịch sử giao dịch"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: transactions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final tx = transactions[index];

          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: tx.isIncome
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  child: Icon(
                    tx.isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                    color: tx.isIncome ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tx.subtitle,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat("HH:mm - dd/MM/yyyy").format(tx.time),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  "${tx.isIncome ? "+" : "-"}${NumberFormat("#,###", "vi_VN").format(tx.amount).replaceAll(",", ".")} đ",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: tx.isIncome ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class TransactionModel {
  final String title;
  final String subtitle;
  final double amount;
  final bool isIncome;
  final DateTime time;

  TransactionModel({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isIncome,
    required this.time,
  });
}
