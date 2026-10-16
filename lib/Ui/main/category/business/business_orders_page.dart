import 'package:flutter/material.dart';
import 'package:tourn/data/firebase/firebase_menu_service.dart';
import 'package:tourn/models/menu_models.dart';

class BusinessOrdersPage extends StatelessWidget {
  const BusinessOrdersPage({super.key});

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String _formatCurrency(double value) {
    final s = value.toStringAsFixed(0);
    final reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
    return '${s.replaceAll(reg, '.')} đ';
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'completed':
        return 'Hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return 'Sắp diễn ra';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return const Color(0xFF2E7D32);
      case 'cancelled':
        return const Color(0xFFC62828);
      default:
        return const Color(0xFF1565C0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đơn hàng')),
      body: StreamBuilder<List<BookingModel>>(
        stream: FirebaseMenuService().getBookingsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('Chưa có đơn hàng'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = items[index];
              final statusColor = _statusColor(item.status);
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0x14000000)),
                ),
                child: ListTile(
                  title: Text(item.serviceName),
                  subtitle: Text(
                    '${_formatDate(item.startDate)} - ${_formatDate(item.endDate)} • ${item.type}',
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatCurrency(item.totalPrice),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _statusLabel(item.status),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
