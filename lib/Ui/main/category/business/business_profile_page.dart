import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tourn/ultils.enums/image_utils.dart';
import 'package:tourn/Ui/main/category/messenge/pages/ChatPage.dart';

class BusinessProfilePage extends StatelessWidget {
  final String ownerId;

  const BusinessProfilePage({super.key, required this.ownerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin người bán'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'report') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã gửi báo cáo vi phạm.')),
                );
              } else if (value == 'block') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã chặn người dùng này.')),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.report_problem_outlined, color: Colors.red),
                    SizedBox(width: 8),
                    Text(
                      'Báo cáo vi phạm',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(Icons.block, color: Colors.black87),
                    SizedBox(width: 8),
                    Text('Chặn tài khoản'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('user_profiles')
            .doc(ownerId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Không tìm thấy thông tin.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final businessProfile =
              data['businessProfile'] as Map<String, dynamic>? ?? {};
          final ownerProfile = 
              data['ownerProfile'] as Map<String, dynamic>? ?? {};

          String _getValidString(List<String?> values, String defaultValue) {
            for (final v in values) {
              if (v != null && v.trim().isNotEmpty) return v.trim();
            }
            return defaultValue;
          }

          final storeName = _getValidString([
            businessProfile['name'] as String?,
            ownerProfile['name'] as String?,
            data['fullName'] as String?,
          ], 'Người đăng ẩn danh');

          final media = businessProfile['media'] as Map<String, dynamic>? ?? {};
          final avatar = _getValidString([
            media['avatarPath'] as String?,
            media['avatar'] as String?,
            data['avatar'] as String?,
            data['photoURL'] as String?,
            data['photoUrl'] as String?,
          ], '');

          final description = _getValidString([
            businessProfile['description'] as String?,
            businessProfile['category'] as String?,
          ], 'Chưa có mô tả.');

          final phone = _getValidString([
            businessProfile['phone'] as String?,
            ownerProfile['phone'] as String?,
            data['phone'] as String?,
          ], 'Chưa cập nhật');

          final address = _getValidString([
            businessProfile['address'] as String?,
          ], 'Chưa cập nhật');

          final email = _getValidString([
            businessProfile['email'] as String?,
            ownerProfile['email'] as String?,
            data['email'] as String?,
          ], 'Chưa cập nhật');

          String createdDateStr = 'Chưa cập nhật';
          final createdAt = businessProfile['createdAt'];
          if (createdAt is Timestamp) {
            final date = createdAt.toDate();
            createdDateStr = '${date.day}/${date.month}/${date.year}';
          } else if (createdAt is String) {
            try {
              final date = DateTime.parse(createdAt);
              createdDateStr = '${date.day}/${date.month}/${date.year}';
            } catch (_) {}
          }

          final reviewsCount =
              (businessProfile['reviewsCount'] as num?)?.toInt() ?? 0;
          final rating = reviewsCount == 0
              ? 0.0
              : ((businessProfile['rating'] as num?)?.toDouble() ?? 0.0);

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Avatar
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.deepPurple.withOpacity(0.1),
                    backgroundImage: avatar != null && avatar.isNotEmpty
                        ? getImageProvider(avatar)
                        : null,
                    child: (avatar == null || avatar.isEmpty)
                        ? const Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.deepPurple,
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                // Name
                Text(
                  storeName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                // Badges / Stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '${rating.toStringAsFixed(1)} ($reviewsCount đánh giá)',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.check_circle,
                      color: Colors.green[600],
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Đã xác thực',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Nút Nhắn tin
                ElevatedButton.icon(
                  onPressed: () {
                    final chatUser = {
                      'id': ownerId,
                      'name': storeName,
                      'avatar': avatar ?? '',
                      'isOnline': true,
                      'isBusinessChat': true,
                    };
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatPage(user: chatUser),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Nhắn tin'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                // Contact info
                ListTile(
                  leading: const Icon(Icons.phone, color: Colors.deepPurple),
                  title: const Text('Số điện thoại'),
                  subtitle: Text(phone),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.location_on,
                    color: Colors.deepPurple,
                  ),
                  title: const Text('Địa chỉ'),
                  subtitle: Text(address),
                ),
                ListTile(
                  leading: const Icon(Icons.email, color: Colors.deepPurple),
                  title: const Text('Email'),
                  subtitle: Text(email),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.calendar_today,
                    color: Colors.deepPurple,
                  ),
                  title: const Text('Ngày tham gia'),
                  subtitle: Text(createdDateStr),
                ),
                const Divider(),
                // Description
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Giới thiệu',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          description,
                          style: const TextStyle(fontSize: 16, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
