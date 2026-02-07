import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class XekhachPage extends StatelessWidget {
  const XekhachPage({super.key});

  @override
  Widget build(BuildContext context) {
    final routes = [
      {
        'from': 'Hà Nội',
        'to': 'Ninh Bình',
        'time': '06:00 - 08:30',
        'duration': '2h30m',
        'price': 90000,
        'company': 'VIPBus',
      },
      {
        'from': 'Hà Nội',
        'to': 'Hội An',
        'time': '07:30 - 12:00',
        'duration': '4h30m',
        'price': 180000,
        'company': 'ComfortLines',
      },
      {
        'from': 'TP. HCM',
        'to': 'Vũng Tàu',
        'time': '09:00 - 11:00',
        'duration': '2h0m',
        'price': 85000,
        'company': 'SeaBus',
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Xe khách')),
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
                      color: Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.chair,
                      size: 36,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Xe khách',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Xe giường nằm, xe ghế ngồi liên tỉnh — đặt vé nhanh chóng và an toàn',
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
                        color: Colors.deepPurple,
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
                              '${r['time']} • ${r['duration']}',
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
                                builder: (_) =>
                                    BusPassengerBookingPage(route: r),
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
                  Text('- Đến trước giờ xe khởi hành ít nhất 20 phút.'),
                  Text('- Kiểm tra loại ghế (ngồi/giường) khi đặt vé.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BusPassengerBookingPage extends StatefulWidget {
  const BusPassengerBookingPage({super.key, required this.route});

  final Map<String, dynamic> route;

  @override
  State<BusPassengerBookingPage> createState() =>
      _BusPassengerBookingPageState();
}

class _BusPassengerBookingPageState extends State<BusPassengerBookingPage> {
  String vehicleType = 'Ghế ngồi';
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
    final vehicleModifier = vehicleType == 'Giường'
        ? 25000
        : (vehicleType == 'Limousine' ? 80000 : 0);
    final total = (price + vehicleModifier) * passengers;

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

            const Text('Loại xe'),
            const SizedBox(height: 8),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Ghế ngồi'),
                  selected: vehicleType == 'Ghế ngồi',
                  onSelected: (_) => setState(() => vehicleType = 'Ghế ngồi'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Giường'),
                  selected: vehicleType == 'Giường',
                  onSelected: (_) => setState(() => vehicleType = 'Giường'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Limousine'),
                  selected: vehicleType == 'Limousine',
                  onSelected: (_) => setState(() => vehicleType = 'Limousine'),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Số hành khách:'),
                const SizedBox(width: 12),
                DropdownButton<int>(
                  value: passengers,
                  items: [1, 2, 3, 4]
                      .map((e) => DropdownMenuItem(value: e, child: Text('$e')))
                      .toList(),
                  onChanged: (v) => setState(() => passengers = v ?? 1),
                ),
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
                      'type': 'Xe khách',
                      'route':
                          '${widget.route['from']} → ${widget.route['to']}',
                      'time': widget.route['time'],
                      'company': widget.route['company'],
                      'vehicleType': vehicleType,
                      'passengers': passengers,
                      'total': total,
                      'timestamp': DateTime.now().toIso8601String(),
                    };
                    await _saveBooking(record);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đặt vé xe khách thành công (giả lập)'),
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
