import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tourn/domain/user_repository/user_repository.dart';
import 'package:tourn/models/user_model.dart';

/// Widget hiển thị phần "Giới thiệu" trong trang cá nhân.
///
/// Nội dung được lấy trực tiếp từ `UserRepository.streamCurrentUser()` nên sẽ
/// cập nhật tự động khi thông tin người dùng thay đổi.
class Introprofile extends StatefulWidget {
  /// Optional uid of the profile being shown. When null, uses current user.
  final String? userId;

  const Introprofile({super.key, this.userId});

  @override
  State<Introprofile> createState() => _IntroprofileState();
}

class _IntroprofileState extends State<Introprofile> {
  // Tên hiển thị cho các trường đã ghim (không bao gồm bio)
  static const Map<String, Map<String, dynamic>> _fieldInfo = {
    'category': {'label': 'Hạng mục', 'icon': Icons.category},
    'work': {'label': 'Công việc', 'icon': Icons.work},
    'education': {'label': 'Học vấn', 'icon': Icons.school},
    'address': {'label': 'Địa chỉ', 'icon': Icons.location_on},
    'hobbies': {'label': 'Sở thích', 'icon': Icons.favorite},
    'travelPlace': {'label': 'Địa điểm yêu thích', 'icon': Icons.place},
    'socialLink': {'label': 'Liên kết', 'icon': Icons.link},
    'email': {'label': 'Email', 'icon': Icons.email},
  };

  // Mở URL trong trình duyệt
  Future<void> _launchUrl(String url) async {
    // Thêm https:// nếu chưa có
    String finalUrl = url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      finalUrl = 'https://$url';
    }

    final uri = Uri.parse(finalUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không thể mở liên kết: $url')));
      }
    }
  }

  void _showBioBottomSheet(BuildContext context, UserModel user, bool isOwner) {
    final bioCtrl = TextEditingController(text: user.bio ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (c) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(c).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tiểu sử',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(c),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (isOwner) ...[
              TextField(
                controller: bioCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Viết tiểu sử của bạn...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: user.bio != null && user.bio!.isNotEmpty
                          ? () async {
                              final repo = context.read<UserRepository>();
                              await repo.updateBio('');
                              if (mounted) Navigator.pop(c);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Đã xóa tiểu sử'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          : null,
                      child: const Text('Xóa tiểu sử'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final newBio = bioCtrl.text.trim();
                        if (newBio.isNotEmpty) {
                          final repo = context.read<UserRepository>();
                          await repo.updateBio(newBio);
                          if (mounted) Navigator.pop(c);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã cập nhật tiểu sử'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      child: const Text('Lưu'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Xem tiểu sử của người khác
              Text(
                user.bio ?? 'Chưa có tiểu sử',
                style: const TextStyle(fontSize: 16),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroContent(
    UserModel user,
    List<String> pinnedFields,
    Map<String, dynamic>? profileData,
  ) {
    List<Widget> rows = [];

    Widget row(
      IconData icon,
      String label,
      String value, {
      VoidCallback? onTap,
    }) => InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$label: $value',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );

    // Chỉ hiển thị các trường đã ghim
    for (final field in pinnedFields) {
      // Bỏ qua bio vì đã hiển thị ở trên
      if (field == 'bio') continue;

      final info = _fieldInfo[field];
      String? value;

      // Lấy giá trị từ user model hoặc profile data
      switch (field) {
        case 'address':
          value = user.address;
          break;
        case 'email':
          value = user.email;
          break;
        default:
          value = profileData?[field] as String?;
      }

      if (value != null && value.isNotEmpty && info != null) {
        // Nếu là socialLink thì cho phép tap để mở URL
        if (field == 'socialLink') {
          rows.add(
            InkWell(
              onTap: () => _launchUrl(value!),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      info['icon'] as IconData,
                      size: 20,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${info['label']}: $value',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        } else {
          rows.add(
            row(info['icon'] as IconData, info['label'] as String, value),
          );
        }
      }
    }

    // số lượng bạn bè = giao của followers và following
    final friendCount = user.followers
        .toSet()
        .intersection(user.following.toSet())
        .length;
    rows.add(row(Icons.group, 'Bạn bè', friendCount.toString()));

    // ngày tham gia
    rows.add(
      row(
        Icons.calendar_today,
        'Ngày tham gia',
        DateFormat('dd/MM/yyyy').format(user.createdAt),
      ),
    );

    // convert to column inside scrollable so height works in parent
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: rows,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<UserRepository>();
    final uid = widget.userId ?? repo.currentUserId;
    final isOwner = uid == repo.currentUserId;

    return StreamBuilder<UserModel?>(
      stream: uid != null ? repo.streamUser(uid) : Stream.value(null),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (userSnapshot.hasError) {
          return const Center(
            child: Text('Không thể tải thông tin người dùng'),
          );
        }
        final user = userSnapshot.data;
        if (user == null) {
          return const Center(child: Text('Không có thông tin người dùng'));
        }

        // When viewing someone else, avoid reading user_profiles to prevent
        // permission-denied errors. Fall back to core fields only.
        if (!isOwner) {
          return _buildIntroContent(user, const [], null);
        }

        // Stream để lấy thông tin mở rộng (pinned fields)
        return StreamBuilder<DocumentSnapshot?>(
          stream: FirebaseAuth.instance.authStateChanges().asyncExpand((user) {
            if (user == null || uid == null) return Stream.value(null);
            return FirebaseFirestore.instance
                .collection('user_profiles')
                .doc(uid)
                .snapshots()
                .handleError((_) {});
          }),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.hasError) {
              return _buildIntroContent(user, const [], null);
            }
            final profileData =
                profileSnapshot.data?.data() as Map<String, dynamic>?;
            final pinnedFields =
                (profileData?['pinnedFields'] as List<dynamic>?)
                    ?.cast<String>() ??
                [];
            return _buildIntroContent(user, pinnedFields, profileData);
          },
        );
      },
    );
  }
}
