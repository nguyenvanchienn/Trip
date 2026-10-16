import 'package:flutter/material.dart';
import 'package:tourn/data/firebase/firebase_menu_service.dart';
import 'package:tourn/models/menu_models.dart';

class ThongkevahieusuatPage extends StatelessWidget {
  const ThongkevahieusuatPage({super.key});

  String _formatCurrency(double value) {
    final s = value.toStringAsFixed(0);
    final reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
    return '${s.replaceAll(reg, '.')} đ';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hiệu suất bán hàng')),
      body: StreamBuilder<List<BookingModel>>(
        stream: FirebaseMenuService().getBusinessBookingsStream(),
        initialData: const <BookingModel>[],
        builder: (context, snapshot) {
          final bookings = snapshot.data ?? const <BookingModel>[];
          if (snapshot.connectionState == ConnectionState.waiting &&
              bookings.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError && bookings.isEmpty) {
            return const Center(child: Text('Chưa có dữ liệu hiệu suất'));
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text('Không tải được dữ liệu hiệu suất'),
            );
          }
          if (bookings.isEmpty) {
            return const Center(child: Text('Chưa có dữ liệu hiệu suất'));
          }

          final total = bookings.length;
          final completed = bookings.where((b) => b.status == 'completed');
          final completedCount = completed.length;
          final cancelledCount = bookings
              .where((b) => b.status == 'cancelled')
              .length;
          final completionRate = total == 0
              ? 0
              : (completedCount / total * 100);
          final cancelRate = total == 0 ? 0 : (cancelledCount / total * 100);
          final avgOrder = completedCount == 0
              ? 0.0
              : completed.fold<double>(0, (sum, b) => sum + b.totalPrice) /
                    completedCount;

          final Map<String, int> customerCounts = {};
          for (final b in bookings) {
            customerCounts[b.userId] = (customerCounts[b.userId] ?? 0) + 1;
          }
          final repeatCustomers = customerCounts.values
              .where((c) => c >= 2)
              .length;
          final repeatRate = customerCounts.isEmpty
              ? 0
              : (repeatCustomers / customerCounts.length * 100);

          final topCustomers = customerCounts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          final kpis = [
            {
              'label': 'Tỉ lệ hoàn thành',
              'value': '${completionRate.toStringAsFixed(1)}%',
            },
            {
              'label': 'Tỉ lệ hủy',
              'value': '${cancelRate.toStringAsFixed(1)}%',
            },
            {'label': 'Đơn trung bình', 'value': _formatCurrency(avgOrder)},
            {
              'label': 'Khách quay lại',
              'value': '${repeatRate.toStringAsFixed(1)}%',
            },
          ];

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Text(
                'Chỉ số KPI',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kpis
                    .map(
                      (k) => _MetricChip(
                        label: k['label'] as String,
                        value: k['value'] as String,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              Text(
                'Khách hàng nổi bật',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...topCustomers
                  .take(3)
                  .map(
                    (entry) => ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(entry.key),
                      subtitle: const Text('Số lần đặt dịch vụ'),
                      trailing: Text('${entry.value} đơn'),
                    ),
                  ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Gợi ý',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Theo dõi đơn bị hủy và chăm sóc nhóm khách quay lại để tăng doanh thu.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
