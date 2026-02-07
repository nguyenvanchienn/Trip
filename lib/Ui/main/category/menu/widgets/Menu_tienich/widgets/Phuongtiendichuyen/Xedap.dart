import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class XedapPage extends StatelessWidget {
  const XedapPage({super.key});

  @override
  Widget build(BuildContext context) {
    final stations = [
      {
        'name': 'Trạm Bạch Mai',
        'bikes': 6,
        'distance': '300m',
        'pricePerHour': 5000,
      },
      {
        'name': 'Trạm Hoàn Kiếm',
        'bikes': 2,
        'distance': '450m',
        'pricePerHour': 7000,
      },
      {
        'name': 'Trạm Cầu Long Biên',
        'bikes': 10,
        'distance': '1.2km',
        'pricePerHour': 4500,
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Xe đạp')),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: stations.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final s = stations[index];
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.pedal_bike,
                      size: 30,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s['name'] as String,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${s['bikes']} xe sẵn có • ${s['distance']}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${(s['pricePerHour'] as int).toString().replaceAllMapped(RegExp(r"\B(?=(\d{3})+(?!\d))"), (m) => ".")} ₫/giờ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: (s['bikes'] as int) > 0
                            ? () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => BikeBookingPage(station: s),
                                ),
                              )
                            : null,
                        child: const Text('Thuê'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class BikeBookingPage extends StatefulWidget {
  const BikeBookingPage({super.key, required this.station});

  final Map<String, dynamic> station;

  @override
  State<BikeBookingPage> createState() => _BikeBookingPageState();
}

class _BikeBookingPageState extends State<BikeBookingPage> {
  int hours = 1;
  int quantity = 1;

  Future<void> _saveBooking(Map<String, dynamic> record) async {
    final prefs = await SharedPreferences.getInstance();
    const key = 'phuongtiendichuyen_history_v1';
    final raw = prefs.getStringList(key) ?? [];
    raw.insert(0, jsonEncode(record));
    await prefs.setStringList(key, raw);
  }

  @override
  Widget build(BuildContext context) {
    final pricePerHour = widget.station['pricePerHour'] as int;
    final total = pricePerHour * hours * quantity;

    return Scaffold(
      appBar: AppBar(title: Text('Thuê - ${widget.station['name']}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.station['name'] as String,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Xe sẵn có: ${widget.station['bikes']}'),
            const SizedBox(height: 16),

            const Text('Số giờ thuê'),
            const SizedBox(height: 8),
            DropdownButton<int>(
              value: hours,
              items: List.generate(12, (i) => i + 1)
                  .map((e) => DropdownMenuItem(value: e, child: Text('$e')))
                  .toList(),
              onChanged: (v) => setState(() => hours = v ?? 1),
            ),

            const SizedBox(height: 12),
            const Text('Số lượng xe'),
            const SizedBox(height: 8),
            DropdownButton<int>(
              value: quantity,
              items: List.generate(5, (i) => i + 1)
                  .map((e) => DropdownMenuItem(value: e, child: Text('$e')))
                  .toList(),
              onChanged: (v) => setState(() => quantity = v ?? 1),
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
                    // Simple availability check
                    final available = widget.station['bikes'] as int;
                    if (quantity > available) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Không đủ xe trong trạm')),
                      );
                      return;
                    }

                    final record = {
                      'type': 'Xe đạp',
                      'station': widget.station['name'],
                      'hours': hours,
                      'quantity': quantity,
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
