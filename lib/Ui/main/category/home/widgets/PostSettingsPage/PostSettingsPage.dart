// đây là file chứa code của trang next page trong phần home
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tourn/Ui/main/category/home/widgets/PostSettingsPage/chiaselentincuaban.dart';
import 'package:tourn/Ui/main/category/home/widgets/PostSettingsPage/congtacvien.dart';
import 'package:tourn/Ui/main/category/home/widgets/PostSettingsPage/doituongbaiviet.dart';
import 'package:tourn/Ui/main/category/home/widgets/PostSettingsPage/luachonlichdang.dart';
import 'package:tourn/data/post/firestore_post_repository.dart';
import 'package:tourn/domain/user_repository/user_repository.dart';
import 'package:tourn/models/post_model.dart';

class PostSettingsPage extends StatefulWidget {
  final String? content;
  final int? backgroundColor;
  final List<Uint8List>? mediaBytes;
  final double? locationLat;
  final double? locationLng;
  final String? locationName;
  final int layoutIndex;
  final List<Map<String, dynamic>>? experienceEntries;

  const PostSettingsPage({
    super.key,
    this.content,
    this.backgroundColor,
    this.mediaBytes,
    this.locationLat,
    this.locationLng,
    this.locationName,
    this.layoutIndex = 0,
    this.experienceEntries,
  });

  @override
  State<PostSettingsPage> createState() => _PostSettingsPageState();
}

class _PostSettingsPageState extends State<PostSettingsPage> {
  bool shareToStory = false;
  final PostAudience _selectedAudience = PostAudience.public;
  bool _isPosting = false;

  Future<void> _createPost() async {
    if (_isPosting) return;

    setState(() {
      _isPosting = true;
    });

    try {
      print('Starting post creation...');
      // Get current user info from UserRepository
      final userRepository = context.read<UserRepository>();
      print('Getting current user...');
      final currentUser = await userRepository.getCurrentUser();
      print('Current user: ${currentUser?.displayName}');

      print('Creating post repository...');
      final postRepository = FirestorePostRepository();
      print('mediaBytes count: ${widget.mediaBytes?.length ?? 0}');

      // Extract hashtags from content
      final content = widget.content ?? '';
      final hashtagPattern = RegExp(
        r'#([a-zA-Z0-9_àáảãạăắằẳẵặâấầẩẫậèéẻẽẹêếềểễệìíỉĩịòóỏõọôốồổỗộơớờởỡợùúủũụưứừửữựỳýỷỹỵđĐ]+)',
      );
      final matches = hashtagPattern.allMatches(content);
      final hashtags = matches.map((m) => m.group(1)!).toList();
      print('Extracted hashtags: $hashtags');

      final post = await postRepository.createPost(
        content: content,
        authorName: currentUser?.displayName ?? 'Người dùng',
        authorPhotoUrl: currentUser?.photoUrl,
        backgroundColor: widget.backgroundColor?.toString(),
        mediaBytes: widget.mediaBytes,
        audience: _selectedAudience,
        location: widget.locationName,
        hashtags: hashtags,
        layoutIndex: widget.layoutIndex,
        experienceEntries: widget.experienceEntries,
      );
      print('Post created: ${post?.id}');

      if (mounted) {
        if (post != null) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã đăng bài viết thành công!'),
              backgroundColor: Colors.green,
            ),
          );
          // Pop 2 times to return to Home (PostSettingsPage -> CreateEditContent -> Home)
          Navigator.of(context).pop(); // Pop PostSettingsPage
          Navigator.of(context).pop(); // Pop CreateEditContent
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể đăng bài viết. Vui lòng đăng nhập.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPosting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Cài đặt bài viết',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton(
              onPressed: _isPosting ? null : _createPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: _isPosting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Đăng',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          _buildSettingItem(
            icon: Icons.public,
            title: 'Đối tượng của bài viết',
            subtitle: 'Công khai',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const Doituongbaiviet(),
                ),
              );
            },
          ),
          _buildSettingItem(
            icon: Icons.access_time,
            title: 'Lựa chọn lịch đăng',
            subtitle: 'Đăng ngay',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const Luachonlichdang(),
                ),
              );
            },
          ),
          _buildToggleItem(
            icon: Icons.collections,
            title: 'Chia sẻ lên tin của bạn',
            value: shareToStory,
            onChanged: (value) {
              setState(() {
                shareToStory = value;
              });
              // Chỉ chuyển đến trang khi bật công tắc
              if (value) {
                Navigator.push<Map<String, dynamic>>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Chiaselentincuaban(),
                  ),
                ).then((result) {
                  if (result != null && result['shareToStory'] != null) {
                    setState(() {
                      shareToStory = result['shareToStory'] as bool;
                    });
                  }
                });
              }
            },
          ),
          _buildSettingItem(
            icon: Icons.person_add,
            title: 'Cộng tác viên',
            subtitle: 'Ghi nhận cộng tác viên đóng góp cho bài viết của bạn.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Congtacvien()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.grey[700], size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      onTap: onTap,
    );
  }

  Widget _buildToggleItem({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.grey[700], size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: Colors.orange,
      ),
    );
  }
}
