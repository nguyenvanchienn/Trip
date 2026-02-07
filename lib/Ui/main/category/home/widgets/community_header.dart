import 'package:flutter/material.dart';

class CommunityHeader extends StatelessWidget {
  final VoidCallback onAddTap;
  final VoidCallback onProfileTap;

  const CommunityHeader({
    super.key,
    required this.onAddTap,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Greeting text
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Image.asset("asset/icon/logo.png", height: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Xin chào, ',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF113953),
                    ),
                  ),
                  const Text(
                    'Chiến',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF113953),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Chào mừng đến với TRIP',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
          // Profile avatar and menu
          Row(
            children: [
              // Add button
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 1.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  onPressed: onAddTap,
                  padding: EdgeInsets.zero,
                  iconSize: 20,
                  icon: const Icon(Icons.add, color: Colors.black),
                ),
              ),
              const SizedBox(width: 12),
              // Avatar
              GestureDetector(
                onTap: onProfileTap,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF113953),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'asset/images/employee-5.png',
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
