import 'package:flutter/material.dart';

class CommunitySectionTitle extends StatelessWidget {
  final VoidCallback onViewAll;
  final String title;

  const CommunitySectionTitle({
    super.key,
    this.title = 'Kinh nghiệm từ cộng đồng',
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF113953).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.tag,
                  color: Color(0xFF113953),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF113953),
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: onViewAll,
            child: const Text(
              'Xem tất cả',
              style: TextStyle(color: Color(0xFF113953)),
            ),
          ),
        ],
      ),
    );
  }
}
