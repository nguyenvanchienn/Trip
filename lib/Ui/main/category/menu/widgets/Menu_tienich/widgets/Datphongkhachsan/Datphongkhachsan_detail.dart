import 'package:flutter/material.dart';

import 'Datphongkhachsan_booking.dart';

class HotelDetailPage extends StatelessWidget {
  const HotelDetailPage({super.key, required this.hotel});

  final Map<String, dynamic> hotel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(hotel['name'])),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Image carousel
          SizedBox(
            height: 200,
            child: PageView.builder(
              itemCount: (hotel['images'] as List).length,
              itemBuilder: (context, idx) {
                final url = (hotel['images'] as List)[idx] as String;
                return ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    url,
                    fit: BoxFit.cover,
                    loadingBuilder: (c, w, progress) => progress == null
                        ? w
                        : Center(child: CircularProgressIndicator()),
                    errorBuilder: (c, e, s) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image, size: 40),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  hotel['name'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${hotel['rating']}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${hotel['location']}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(hotel['desc']),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: const [
              Chip(label: Text('Miễn phí hủy')),
              Chip(label: Text('Bữa sáng')),
              Chip(label: Text('Wifi')),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Giá từ: ${(hotel['price'] as int).toString().replaceAllMapped(RegExp(r"\\B(?=(\\d{3})+(?!\\d))"), (m) => '.')} ₫',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => HotelBookingPage(hotel: hotel),
                  ),
                ),
                child: const Text('Đặt phòng'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
