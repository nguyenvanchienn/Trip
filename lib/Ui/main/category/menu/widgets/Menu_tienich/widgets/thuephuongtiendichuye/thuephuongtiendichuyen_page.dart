import 'package:flutter/material.dart';

class ThuephuongtiendichuyenHistoryPage extends StatelessWidget {
  const ThuephuongtiendichuyenHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color pageBg = Color(0xFFF6F2FA);
    const Color accent = Color(0xFF6B5FB5);
    final history = [
      {
        'service': 'Xe ô tô tự lái',
        'date': '24/04/2026',
        'time': '09:00',
        'price': '850.000 đ/ngày',
        'code': 'CAR-4821',
        'status': 'Đã đặt',
      },
      {
        'service': 'Xe máy tự lái',
        'date': '12/04/2026',
        'time': '08:30',
        'price': '160.000 đ/ngày',
        'code': 'MOTO-190',
        'status': 'Hoàn thành',
      },
      {
        'service': 'Xe đạp địa hình',
        'date': '02/04/2026',
        'time': '07:15',
        'price': '150.000 đ/ngày',
        'code': 'BIKE-055',
        'status': 'Hoàn thành',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử thuê phương tiện'),
        centerTitle: true,
      ),
      backgroundColor: pageBg,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
        children: [
          const _HeaderCard(
            icon: Icons.history,
            title: 'Lịch sử đã đặt',
            subtitle: 'Xem lại các đơn thuê của bạn',
          ),
          const SizedBox(height: 12),
          if (history.isEmpty) const _EmptyState(message: 'Chưa có lịch sử'),
          ...history.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _HistoryCard(
                service: item['service'] as String,
                date: item['date'] as String,
                time: item['time'] as String,
                code: item['code'] as String,
                price: item['price'] as String,
                status: item['status'] as String,
                accent: accent,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF1ECFF), Color(0xFFE8F1FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF6B5FB5), size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.service,
    required this.date,
    required this.time,
    required this.code,
    required this.price,
    required this.status,
    required this.accent,
  });

  final String service;
  final String date;
  final String time;
  final String code;
  final String price;
  final String status;
  final Color accent;

  Color _statusColor() {
    switch (status) {
      case 'Hoàn thành':
        return const Color(0xFF2E7D32);
      case 'Đã đặt':
        return const Color(0xFF1565C0);
      default:
        return const Color(0xFF6B5FB5);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0x1F6B5FB5)),
      ),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: [
            Icon(Icons.commute_outlined, size: 20, color: accent),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$date • $time • $code',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor().withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 11,
                      color: _statusColor(),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Text(message, style: const TextStyle(color: Colors.black54)),
      ),
    );
  }
}
