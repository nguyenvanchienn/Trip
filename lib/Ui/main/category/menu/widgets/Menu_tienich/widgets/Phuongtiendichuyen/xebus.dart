import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class XebusPage extends StatelessWidget {
  const XebusPage({super.key});

  @override
  Widget build(BuildContext context) {
    final routes = [
      {
        'from': 'Hà Nội',
        'to': 'Hải Phòng',
        'time': '07:00 - 09:30',
        'price': 80000,
        'company': 'BusExpress',
      },
      {
        'from': 'Hà Nội',
        'to': 'Sơn Tây',
        'time': '08:30 - 09:30',
        'price': 20000,
        'company': 'CityBus',
      },
      {
        'from': 'Hà Nội',
        'to': 'Ninh Bình',
        'time': '10:00 - 12:40',
        'price': 120000,
        'company': 'SafeRide',
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Xe buýt')),
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
                      color: Colors.blueGrey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.directions_bus,
                      size: 36,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Xe buýt',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Tìm tuyến, xem giờ khởi hành và đặt vé theo tuyến',
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

          Text('Tuyến nổi bật', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: routes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final r = routes[index];
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
                        Icons.directions_bus_filled,
                        size: 30,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${r['from']} → ${r['to']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${r['time']} • ${r['company']}',
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
                            '${(r['price'] as int).toString().replaceAllMapped(RegExp(r"\B(?=(\d{3})+(?!\d))"), (m) => ".")} ₫',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => BusBookingPage(route: r),
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
                  Text('- Đến trước giờ xe khởi hành ít nhất 15 phút.'),
                  Text('- Giữ vé điện tử hoặc ảnh chụp khi lên xe.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BusBookingPage extends StatefulWidget {
  const BusBookingPage({super.key, required this.route});

  final Map<String, dynamic> route;

  @override
  State<BusBookingPage> createState() => _BusBookingPageState();
}

class _BusBookingPageState extends State<BusBookingPage> {
  int passengers = 1;

  Future<void> _saveBooking(Map<String, dynamic> record) async {
    final prefs = await SharedPreferences.getInstance();
    const key = 'phuongtiendichuyen_history_v1';
    final raw = prefs.getStringList(key) ?? [];
    raw.insert(0, jsonEncode(record));
    await prefs.setStringList(key, raw);
  }

  @override
  Widget build(BuildContext context) {
    final price = widget.route['price'] as int;
    final total = price * passengers;

    return Scaffold(
      appBar: AppBar(
        title: Text('Đặt vé: ${widget.route['from']} → ${widget.route['to']}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.route['from']} → ${widget.route['to']}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Thời gian: ${widget.route['time']} • Hãng: ${widget.route['company']}',
            ),
            const SizedBox(height: 16),

            const Text('Số hành khách'),
            const SizedBox(height: 8),
            DropdownButton<int>(
              value: passengers,
              items: [1, 2, 3, 4, 5]
                  .map((e) => DropdownMenuItem(value: e, child: Text('$e')))
                  .toList(),
              onChanged: (v) => setState(() => passengers = v ?? 1),
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
                      'type': 'Xe buýt',
                      'route':
                          '${widget.route['from']} → ${widget.route['to']}',
                      'time': widget.route['time'],
                      'company': widget.route['company'],
                      'passengers': passengers,
                      'total': total,
                      'timestamp': DateTime.now().toIso8601String(),
                    };
                    await _saveBooking(record);
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
