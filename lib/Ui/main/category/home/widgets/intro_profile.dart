// Profile intro widget used on the user's profile page.
import 'package:flutter/material.dart';

class Introprofile extends StatelessWidget {
  const Introprofile({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryText = Colors.black;
    final secondaryText = Colors.black54;
    final cardBg = Colors.white;
    final cardBorder = Colors.black12;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar + name
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 46,
                  backgroundColor: Colors.grey.shade200,
                  child: ClipOval(
                    child: Image.asset(
                      'asset/images/anh-con-cho-26.jpg',
                      width: 86,
                      height: 86,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        color: Colors.grey.shade300,
                        width: 86,
                        height: 86,
                        child: const Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Nguyễn Chiến',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: primaryText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Đã khám phá 14/64 tỉnh thành tại Việt Nam',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: secondaryText,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Quick stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatItem(value: '14', label: 'Tỉnh/TP'),
              _StatItem(value: '28', label: 'Điểm đến'),
              _StatItem(value: '1.2k', label: 'Người theo dõi'),
            ],
          ),

          const SizedBox(height: 18),

          // Bio card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Giới thiệu',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: primaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Mình là travel-lover, thích khám phá các vùng miền Việt Nam. Thích leo núi, phượt và thử các món ăn địa phương.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: secondaryText,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Sửa hồ sơ'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF8A00),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryText,
                      ),
                      child: const Text('Chia sẻ'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Optional map preview card
          Container(
            height: 300,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cardBorder),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'asset/images/Group 151.png',
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) =>
                        Container(color: const Color(0xFF06314A)),
                  ),
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.map),
                      label: const Text('Xem bản đồ'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF8A00),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}

/// Full page wrapper you can push to show the intro profile as a screen.
class IntroProfilePage extends StatelessWidget {
  static const routeName = '/intro-profile';
  const IntroProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('Giới thiệu', style: TextStyle(color: Colors.black)),
      ),
      body: const Introprofile(),
    );
  }
}
