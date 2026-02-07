import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class XemayPage extends StatelessWidget {
  const XemayPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bikes = [
      {'model': 'Dream 125', 'type': 'Số', 'pricePerHour': 15000},
      {'model': 'Vision 110', 'type': 'Tự động', 'pricePerHour': 18000},
      {'model': 'Lead 125', 'type': 'Tự động', 'pricePerHour': 20000},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Xe máy')),
      body: ListView(
        padding: const EdgeInsets.all(12),
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.motorcycle,
                      size: 36,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Xe máy',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Thuê xe máy theo giờ hoặc theo ngày — linh hoạt cho di chuyển trong thành phố',
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

          Text(
            'Loại xe có sẵn',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: bikes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final b = bikes[index];
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
                        Icons.motorcycle,
                        size: 30,
                        color: Colors.indigo,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              b['model'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${b['type']} • ${(b['pricePerHour'] as int).toString().replaceAllMapped(RegExp(r"\B(?=(\d{3})+(?!\d))"), (m) => ".")} ₫/giờ',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BikeRentPage(bike: b),
                          ),
                        ),
                        child: const Text('Thuê'),
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
                    '- Mang theo giấy tờ cần thiết khi thuê (CMND/CCCD, bằng lái).',
                  ),
                  Text(
                    '- Kiểm tra tình trạng xe trước khi nhận và tuân thủ luật giao thông.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BikeRentPage extends StatefulWidget {
  const BikeRentPage({super.key, required this.bike});

  final Map<String, dynamic> bike;

  @override
  State<BikeRentPage> createState() => _BikeRentPageState();
}

class _BikeRentPageState extends State<BikeRentPage> {
  int hours = 1;
  bool helmet = true;

  Future<void> _saveBooking(Map<String, dynamic> record) async {
    final prefs = await SharedPreferences.getInstance();
    const key = 'phuongtiendichuyen_history_v1';
    final raw = prefs.getStringList(key) ?? [];
    raw.insert(0, jsonEncode(record));
    await prefs.setStringList(key, raw);
  }

  @override
  Widget build(BuildContext context) {
    final price = widget.bike['pricePerHour'] as int;
    final total = price * hours + (helmet ? 10000 : 0);

    return Scaffold(
      appBar: AppBar(title: Text('Thuê ${widget.bike['model']}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.bike['model'] as String,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Loại: ${widget.bike['type']}'),
            const SizedBox(height: 16),

            Row(
              children: [
                const Text('Số giờ thuê:'),
                const SizedBox(width: 12),
                DropdownButton<int>(
                  value: hours,
                  items: List.generate(24, (i) => i + 1)
                      .map((e) => DropdownMenuItem(value: e, child: Text('$e')))
                      .toList(),
                  onChanged: (v) => setState(() => hours = v ?? 1),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Row(
              children: [
                Checkbox(
                  value: helmet,
                  onChanged: (v) => setState(() => helmet = v ?? true),
                ),
                const SizedBox(width: 8),
                const Text('Thêm mũ bảo hiểm (+10.000 ₫)'),
              ],
            ),

            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Tổng: ${total.toString().replaceAllMapped(RegExp(r"\B(?=(\d{3})+(?!\d))"), (m) => ".")} ₫',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final record = {
                      'type': 'Xe máy',
                      'model': widget.bike['model'],
                      'hours': hours,
                      'helmet': helmet,
                      'total': total,
                      'timestamp': DateTime.now().toIso8601String(),
                    };
                    await _saveBooking(record);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Thuê thành công (giả lập)'),
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
