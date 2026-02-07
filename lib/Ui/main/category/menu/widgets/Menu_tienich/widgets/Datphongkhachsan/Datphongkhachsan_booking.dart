import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HotelBookingPage extends StatefulWidget {
  const HotelBookingPage({super.key, required this.hotel});

  final Map<String, dynamic> hotel;

  @override
  State<HotelBookingPage> createState() => _HotelBookingPageState();
}

class _HotelBookingPageState extends State<HotelBookingPage> {
  DateTimeRange? _range;
  int _rooms = 1;
  int _guests = 1;

  String _fmt(int v) =>
      '${v.toString().replaceAllMapped(RegExp(r"\B(?=(\d{3})+(?!\d))"), (m) => '.')} ₫';

  Future<void> _saveBooking(Map<String, dynamic> record) async {
    final prefs = await SharedPreferences.getInstance();
    const key = 'hotel_booking_history_v1';
    final raw = prefs.getStringList(key) ?? [];
    raw.insert(0, jsonEncode(record));
    await prefs.setStringList(key, raw);
  }

  int get nights {
    if (_range == null) return 1;
    return _range!.end.difference(_range!.start).inDays;
  }

  int get total {
    final price = widget.hotel['price'] as int;
    return price * (nights == 0 ? 1 : nights) * _rooms;
  }

  Future<void> _pickRange() async {
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _range,
    );
    if (r != null) setState(() => _range = r);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đặt phòng')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.hotel['name'],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _range == null
                        ? 'Chọn ngày'
                        : '${_range!.start.toLocal().toString().split(' ').first} → ${_range!.end.toLocal().toString().split(' ').first}',
                  ),
                ),
                ElevatedButton(
                  onPressed: _pickRange,
                  child: const Text('Chọn ngày'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Phòng:'),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _rooms,
                  items: [1, 2, 3, 4]
                      .map((e) => DropdownMenuItem(value: e, child: Text('$e')))
                      .toList(),
                  onChanged: (v) => setState(() => _rooms = v ?? 1),
                ),
                const SizedBox(width: 24),
                const Text('Khách:'),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _guests,
                  items: [1, 2, 3, 4]
                      .map((e) => DropdownMenuItem(value: e, child: Text('$e')))
                      .toList(),
                  onChanged: (v) => setState(() => _guests = v ?? 1),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Tổng: ${_fmt(total)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_range == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vui lòng chọn ngày')),
                      );
                      return;
                    }
                    final record = {
                      'type': 'Khách sạn',
                      'hotelId': widget.hotel['id'],
                      'hotelName': widget.hotel['name'],
                      'range': {
                        'from': _range!.start.toIso8601String(),
                        'to': _range!.end.toIso8601String(),
                      },
                      'rooms': _rooms,
                      'guests': _guests,
                      'total': total,
                      'timestamp': DateTime.now().toIso8601String(),
                    };
                    await _saveBooking(record);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đặt phòng thành công (giả lập)'),
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
