import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TaxiPage extends StatelessWidget {
  const TaxiPage({super.key});

  @override
  Widget build(BuildContext context) {
    final drivers = [
      {'name': 'Taxi A', 'eta': '3-5 phút', 'price': 35000},
      {'name': 'Taxi B', 'eta': '5-8 phút', 'price': 29000},
      {'name': 'Taxi C', 'eta': '2-4 phút', 'price': 42000},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Taxi')),
      body: ListView(
        padding: const EdgeInsets.all(12.0),
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.yellow.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.local_taxi,
                      size: 36,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Taxi',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Gọi taxi nhanh chóng, theo dõi ETA và giá ước tính',
                          style: TextStyle(color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          Text('Xe sẵn sàng', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: drivers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final d = drivers[index];
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person,
                        size: 30,
                        color: Colors.blueGrey,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              d['name'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ETA: ${d['eta']}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${(d['price'] as int).toString().replaceAllMapped(RegExp(r"\B(?=(\d{3})+(?!\d))"), (m) => ".")} ₫',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => TaxiBookingPage(driver: d),
                              ),
                            ),
                            child: const Text('Gọi'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 20),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
            color: Colors.grey[50],
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Lưu ý', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text(
                    '- Kiểm tra lộ trình và giá ước tính trước khi xác nhận.',
                  ),
                  Text('- Liên lạc với tài xế để trao đổi điểm đón nếu cần.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TaxiBookingPage extends StatefulWidget {
  const TaxiBookingPage({super.key, required this.driver});

  final Map<String, dynamic> driver;

  @override
  State<TaxiBookingPage> createState() => _TaxiBookingPageState();
}

class _TaxiBookingPageState extends State<TaxiBookingPage> {
  final TextEditingController pickupController = TextEditingController();
  final TextEditingController dropoffController = TextEditingController();

  @override
  void dispose() {
    pickupController.dispose();
    dropoffController.dispose();
    super.dispose();
  }

  Future<void> _saveBooking(Map<String, dynamic> record) async {
    final prefs = await SharedPreferences.getInstance();
    const key = 'phuongtiendichuyen_history_v1';
    final raw = prefs.getStringList(key) ?? [];
    raw.insert(0, jsonEncode(record));
    await prefs.setStringList(key, raw);
  }

  @override
  Widget build(BuildContext context) {
    final price = widget.driver['price'] as int;

    return Scaffold(
      appBar: AppBar(title: Text('Gọi ${widget.driver['name']}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ETA: ${widget.driver['eta']}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pickupController,
              decoration: const InputDecoration(
                labelText: 'Điểm đón',
                hintText: 'Nhập địa chỉ điểm đón',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: dropoffController,
              decoration: const InputDecoration(
                labelText: 'Điểm đến',
                hintText: 'Nhập địa chỉ điểm đến',
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Giá ước tính: ${price.toString().replaceAllMapped(RegExp(r"\B(?=(\d{3})+(?!\d))"), (m) => ".")} ₫',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (pickupController.text.trim().isEmpty ||
                        dropoffController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Vui lòng nhập điểm đón và điểm đến'),
                        ),
                      );
                      return;
                    }
                    final record = {
                      'type': 'Taxi',
                      'driver': widget.driver['name'],
                      'pickup': pickupController.text.trim(),
                      'dropoff': dropoffController.text.trim(),
                      'eta': widget.driver['eta'],
                      'price': widget.driver['price'],
                      'timestamp': DateTime.now().toIso8601String(),
                    };
                    await _saveBooking(record);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cuốc xe đã được đặt (giả lập)'),
                      ),
                    );
                    Navigator.of(context).pop();
                  },
                  child: const Text('Xác nhận'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
