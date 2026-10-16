import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tourn/data/firebase/firebase_menu_service.dart';
import 'package:tourn/models/menu_models.dart';

class HotelBookingHistoryPage extends StatefulWidget {
  const HotelBookingHistoryPage({super.key});

  @override
  State<HotelBookingHistoryPage> createState() =>
      _HotelBookingHistoryPageState();
}

class _HotelBookingHistoryPageState extends State<HotelBookingHistoryPage> {
  final FirebaseMenuService _menuService = FirebaseMenuService();
  List<BookingModel> _history = [];
  StreamSubscription<List<BookingModel>>? _subscription;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _load() {
    _subscription = _menuService.getBookingsStream(type: 'hotel').listen((
      bookings,
    ) {
      _history = bookings;
      if (mounted) setState(() => _loading = false);
    });
  }

  Future<void> _removeAt(BookingModel booking) async {
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

    if (ok == true) {
      await _menuService.deleteBooking(booking.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã xóa')));
    }
  }

  String _fmtNum(num? v) {
    if (v == null) return '';
    return '${v.toStringAsFixed(0).replaceAllMapped(RegExp(r"\B(?=(\d{3})+(?!\d))"), (m) => '.')} ₫';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử đặt phòng')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
          ? const Center(child: Text('Chưa có lịch sử đặt phòng'))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _history.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final booking = _history[i];
                final dateRange =
                    '${_formatDate(booking.startDate)} → ${_formatDate(booking.endDate)}';

                return Dismissible(
                  key: ValueKey(booking.id),
                  direction: DismissDirection.startToEnd,
                  background: Container(
                    color: Colors.redAccent,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (_) async {
                    await _removeAt(booking);
                    return false; // Firebase handles the removal
                  },
                  child: Card(
                    child: ListTile(
                      leading: const Icon(Icons.hotel),
                      title: Text(booking.serviceName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(dateRange),
                          Text(
                            'Trạng thái: ${booking.status == 'upcoming'
                                ? 'Sắp tới'
                                : booking.status == 'completed'
                                ? 'Đã hoàn thành'
                                : booking.status}',
                            style: TextStyle(
                              color: booking.status == 'upcoming'
                                  ? Colors.blue
                                  : Colors.green,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      trailing: Text(_fmtNum(booking.totalPrice)),
                      onLongPress: () => _removeAt(booking),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
