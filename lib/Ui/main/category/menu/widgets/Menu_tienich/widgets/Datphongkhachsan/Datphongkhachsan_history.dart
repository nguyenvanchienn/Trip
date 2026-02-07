import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HotelBookingHistoryPage extends StatefulWidget {
  const HotelBookingHistoryPage({super.key});

  @override
  State<HotelBookingHistoryPage> createState() =>
      _HotelBookingHistoryPageState();
}

class _HotelBookingHistoryPageState extends State<HotelBookingHistoryPage> {
  final String _key = 'hotel_booking_history_v1';
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    setState(() {
      _history = raw.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
    });
  }

  Future<void> _removeAt(int i) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    final removed = raw.removeAt(i);
    await prefs.setStringList(_key, raw);
    await _load();

    // show undo
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Đã xóa'),
        action: SnackBarAction(
          label: 'Hoàn tác',
          onPressed: () async {
            final prefs2 = await SharedPreferences.getInstance();
            final raw2 = prefs2.getStringList(_key) ?? [];
            raw2.insert(i, removed);
            await prefs2.setStringList(_key, raw2);
            await _load();
          },
        ),
      ),
    );
  }

  String _fmtNum(num? v) {
    if (v == null) return '';
    return '${v.toStringAsFixed(0).replaceAllMapped(RegExp(r"\B(?=(\d{3})+(?!\d))"), (m) => '.')} ₫';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử đặt phòng')),
      body: _history.isEmpty
          ? const Center(child: Text('Chưa có lịch sử đặt phòng'))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _history.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final r = _history[i];
                final title = r['hotelName'] ?? 'Khách sạn';
                String dateRange = '';
                try {
                  final from = DateTime.parse(
                    r['range']['from'],
                  ).toLocal().toString().split('.').first;
                  final to = DateTime.parse(
                    r['range']['to'],
                  ).toLocal().toString().split('.').first;
                  dateRange = '$from → $to';
                } catch (_) {}
                final total = r['total'];
                return Dismissible(
                  key: ValueKey(r['timestamp'] ?? i),
                  direction: DismissDirection.startToEnd,
                  background: Container(
                    color: Colors.redAccent,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (_) async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (d) => AlertDialog(
                        title: const Text('Xóa'),
                        content: const Text('Xóa mục này?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(d, false),
                            child: const Text('Hủy'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(d, true),
                            child: const Text('Xóa'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) await _removeAt(i);
                    return ok == true;
                  },
                  child: Card(
                    child: ListTile(
                      leading: const Icon(Icons.hotel),
                      title: Text(title),
                      subtitle: Text(dateRange),
                      trailing: total == null ? null : Text(_fmtNum(total)),
                      onTap: () => showDialog<void>(
                        context: context,
                        builder: (d) => AlertDialog(
                          title: Text(title),
                          content: SingleChildScrollView(
                            child: Text(
                              const JsonEncoder.withIndent('  ').convert(r),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(d),
                              child: const Text('Đóng'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
