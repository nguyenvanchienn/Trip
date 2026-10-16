import 'package:flutter/material.dart';

class CommunityPostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final VoidCallback? onTap;

  const CommunityPostCard({super.key, required this.post, this.onTap});

  @override
  Widget build(BuildContext context) {
    final content =
        post['content'] as String? ?? post['description'] as String? ?? '';
    final experience = post['experience'] as String?;
    final itinerary = post['itinerary'] as String?;
    final expenses = post['expenses'] as String?;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      post['avatar'] as String? ?? 'asset/images/anh-mo-ta.jpg',
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: Colors.grey[300]),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post['author'] as String? ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      backgroundColor: const Color(0xFFFFB620),
                    ),
                    child: const Text('Theo dõi'),
                  ),
                ],
              ),
            ),
            if ((post['image'] as String?) != null)
              ClipRRect(
                child: Image.asset(
                  post['image'] as String,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 200,
                  errorBuilder: (_, __, ___) =>
                      Container(height: 200, color: Colors.grey[300]),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.favorite, color: Colors.red, size: 16),
                      const SizedBox(width: 6),
                      Text('${post['likes'] ?? 0}'),
                      const SizedBox(width: 16),
                      const Icon(Icons.comment, color: Colors.grey, size: 16),
                      const SizedBox(width: 6),
                      Text('${post['comments'] ?? 0}'),
                      const SizedBox(width: 16),
                      const Icon(Icons.share, color: Colors.grey, size: 16),
                      const SizedBox(width: 6),
                      Text('${post['shares'] ?? 0}'),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF113953).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(post['hashtag'] as String? ?? ''),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (experience != null) ...[
                    const Text(
                      'Kinh nghiệm',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(experience),
                    const SizedBox(height: 8),
                  ],
                  if (itinerary != null) ...[
                    const Text(
                      'Lịch trình',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(itinerary),
                    const SizedBox(height: 8),
                  ],
                  if (expenses != null) ...[
                    const Text(
                      'Chi tiêu',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(expenses),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
