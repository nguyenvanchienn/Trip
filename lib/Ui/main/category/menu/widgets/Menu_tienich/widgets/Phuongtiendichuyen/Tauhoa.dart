import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TauhoaPage extends StatelessWidget {
  const TauhoaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final trains = [
      {
        'from': 'Hà Nội',
        'to': 'Đà Nẵng',
        'time': '06:00 - 14:30',
        'duration': '8h 30m',
        'price': 450000,
        'operator': 'VNR',
      },
      {
        'from': 'Sài Gòn',
        'to': 'Nha Trang',
        'time': '09:15 - 13:40',
        'duration': '4h 25m',
        'price': 280000,
        'operator': 'VNR',
      },
      {
        'from': 'Hải Phòng',
        'to': 'Hà Nội',
        'time': '07:00 - 09:00',
        'duration': '2h 0m',
        'price': 120000,
        'operator': 'LocalRail',
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Tàu hỏa')),
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
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.train,
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
                          'Tàu hỏa',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Tìm chuyến, kiểm tra giờ và đặt vé tàu thuận tiện',
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
            itemCount: trains.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final t = trains[index];
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
                        Icons.ev_station,
                        size: 30,
                        color: Colors.brown,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${t['from']} → ${t['to']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${t['time']} • ${t['duration']}',
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
                            '${(t['price'] as int).toString().replaceAllMapped(RegExp(r"\B(?=(\d{3})+(?!\d))"), (m) => ".")} ₫',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => TrainBookingPage(train: t),
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
                  Text('- Kiểm tra số toa và giờ làm thủ tục.'),
                  Text('- Giữ vé điện tử hoặc in vé khi cần.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TrainBookingPage extends StatefulWidget {
  const TrainBookingPage({super.key, required this.train});

  final Map<String, dynamic> train;

  @override
  State<TrainBookingPage> createState() => _TrainBookingPageState();
}

class _TrainBookingPageState extends State<TrainBookingPage> {
  String seatClass = 'Ngồi mềm';
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
    final price = widget.train['price'] as int;
    final total =
        price * quantity + (seatClass == 'Giường' ? 50000 * quantity : 0);

    return Scaffold(
      appBar: AppBar(
        title: Text('Đặt vé: ${widget.train['from']} → ${widget.train['to']}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.train['from']} → ${widget.train['to']}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Thời gian: ${widget.train['time']} • Hãng: ${widget.train['operator']}',
            ),
            const SizedBox(height: 16),

            const Text('Hạng ghế'),
            const SizedBox(height: 8),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Ngồi mềm'),
                  selected: seatClass == 'Ngồi mềm',
                  onSelected: (_) => setState(() => seatClass = 'Ngồi mềm'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Giường'),
                  selected: seatClass == 'Giường',
                  onSelected: (_) => setState(() => seatClass = 'Giường'),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Số vé:'),
                const SizedBox(width: 12),
                DropdownButton<int>(
                  value: quantity,
                  items: [1, 2, 3, 4]
                      .map((e) => DropdownMenuItem(value: e, child: Text('$e')))
                      .toList(),
                  onChanged: (v) => setState(() => quantity = v ?? 1),
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
                      'type': 'Tàu hỏa',
                      'route':
                          '${widget.train['from']} → ${widget.train['to']}',
                      'time': widget.train['time'],
                      'operator': widget.train['operator'],
                      'seatClass': seatClass,
                      'quantity': quantity,
                      'total': total,
                      'timestamp': DateTime.now().toIso8601String(),
                    };
                    await _saveBooking(record);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đặt vé tàu thành công (giả lập)'),
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
