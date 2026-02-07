import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MaybayPage extends StatelessWidget {
  const MaybayPage({super.key});

  @override
  Widget build(BuildContext context) {
    final flights = [
      {
        'from': 'Hà Nội',
        'to': 'TP. HCM',
        'time': '08:30 - 10:35',
        'duration': '2h 5m',
        'price': 1200000,
        'carrier': 'VietAir',
      },
      {
        'from': 'Đà Nẵng',
        'to': 'Hà Nội',
        'time': '11:00 - 12:45',
        'duration': '1h 45m',
        'price': 900000,
        'carrier': 'SkyJet',
      },
      {
        'from': 'Huế',
        'to': 'TP. HCM',
        'time': '14:20 - 15:45',
        'duration': '1h 25m',
        'price': 750000,
        'carrier': 'FastAir',
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Máy bay')),
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
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.flight,
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
                          'Máy bay',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Tìm chuyến bay, so sánh giá và đặt vé nhanh chóng',
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
            'Chuyến nổi bật',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: flights.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final f = flights[index];
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
                        Icons.airplanemode_active,
                        size: 30,
                        color: Colors.indigo,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${f['from']} → ${f['to']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${f['time']} • ${f['duration']}',
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
                            '${(f['price'] as int).toString().replaceAllMapped(RegExp(r"\B(?=(\d{3})+(?!\d))"), (m) => ".")} ₫',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => BookingPage(flight: f),
                              ),
                            ),
                            child: const Text('Đặt vé'),
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
                    '- Kiểm tra giờ làm thủ tục và hành lý trước khi ra sân bay.',
                  ),
                  Text('- So sánh giá nhiều hãng để tìm lựa chọn phù hợp.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BookingPage extends StatelessWidget {
  const BookingPage({super.key, required this.flight});

  final Map<String, dynamic> flight;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đặt vé')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${flight['from']} → ${flight['to']}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Thời gian: ${flight['time']}'),
            const SizedBox(height: 8),
            Text('Hãng: ${flight['carrier']}'),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Tổng: ${(flight['price'] as int).toString().replaceAllMapped(RegExp(r"\B(?=(\d{3})+(?!\d))"), (m) => ".")} ₫',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final record = {
                      'type': 'Máy bay',
                      'route': '${flight['from']} → ${flight['to']}',
                      'time': flight['time'],
                      'carrier': flight['carrier'],
                      'total': flight['price'],
                      'timestamp': DateTime.now().toIso8601String(),
                    };
                    final prefs = await SharedPreferences.getInstance();
                    const key = 'phuongtiendichuyen_history_v1';
                    final raw = prefs.getStringList(key) ?? [];
                    raw.insert(0, jsonEncode(record));
                    await prefs.setStringList(key, raw);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đặt vé thành công (giả lập)'),
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
