import 'package:flutter/material.dart';
import 'package:tourn/data/firebase/firebase_menu_service.dart';
import 'package:tourn/models/menu_models.dart';

class BusinessReviewsPage extends StatelessWidget {
  const BusinessReviewsPage({super.key});

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Widget _buildStars(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < rating ? Icons.star : Icons.star_border,
          size: 14,
          color: Colors.amber,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đánh giá')),
      body: StreamBuilder<List<BookingModel>>(
        stream: FirebaseMenuService().getBookingsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snapshot.data ?? [];
          final reviews = all
              .where((b) => (b.review ?? '').isNotEmpty || (b.rating ?? 0) > 0)
              .toList();
          if (reviews.isEmpty) {
            return const Center(child: Text('Chưa có đánh giá'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: reviews.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = reviews[index];
              final rating = item.rating ?? 0;
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0x14000000)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item.serviceName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          _buildStars(rating),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.review ?? 'Không có nội dung',
                        style: const TextStyle(color: Colors.black87),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatDate(item.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
