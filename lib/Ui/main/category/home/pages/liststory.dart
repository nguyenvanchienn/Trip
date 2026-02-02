import 'package:flutter/material.dart';
import 'package:tourn/Ui/main/category/home/widgets/create_and_edit_content.dart';
import 'package:tourn/Ui/main/category/home/widgets/story/story_viewer.dart';
import 'package:image_picker/image_picker.dart';

class Liststory extends StatefulWidget {
  const Liststory({super.key});

  @override
  State<Liststory> createState() => _ListstoryState();
}

class _ListstoryState extends State<Liststory> {
  final ImagePicker _picker = ImagePicker();

  final List<Map<String, dynamic>> _friendsExploring = [
    {
      'name': 'Minh Anh',
      'avatar': 'asset/images/employee-5.png',
      'location': 'Đà Lạt',
      'country': 'Việt Nam',
      'image': 'asset/images/anh-mo-ta.jpg',
      'isLive': true,
      'hasStory': true,
    },
    {
      'name': 'Hoàng Nam',
      'avatar': 'asset/images/anh-mo-ta.jpg',
      'location': 'Bali',
      'country': 'Indonesia',
      'image': 'asset/images/anh-mo-ta.jpg',
      'isLive': false,
      'hasStory': true,
    },
    {
      'name': 'Thu Hà',
      'avatar': 'asset/images/anh-mo-ta.jpg',
      'location': 'Tokyo',
      'country': 'Nhật Bản',
      'image': 'asset/images/anh-mo-ta.jpg',
      'isLive': false,
      'hasStory': true,
    },
    {
      'name': 'Văn Đức',
      'avatar': 'asset/images/anh-mo-ta.jpg',
      'location': 'Phú Quốc',
      'country': 'Việt Nam',
      'image': 'asset/images/anh-mo-ta.jpg',
      'isLive': true,
      'hasStory': true,
    },
    {
      'name': 'Ngọc Lan',
      'avatar': 'asset/images/anh-mo-ta.jpg',
      'location': 'Paris',
      'country': 'Pháp',
      'image': 'asset/images/anh-mo-ta.jpg',
      'isLive': false,
      'hasStory': true,
    },
    {
      'name': 'Quốc Bảo',
      'avatar': 'asset/images/anh-mo-ta.jpg',
      'location': 'Hạ Long',
      'country': 'Việt Nam',
      'image': 'asset/images/anh-mo-ta.jpg',
      'isLive': false,
      'hasStory': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      Icons.explore,
                      color: Color(0xFF113953),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Bạn bè đang khám phá',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF113953),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Stories list
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _friendsExploring.length + 1, // +1 for "Add Story"
            itemBuilder: (context, index) {
              // First item is "Add your story"
              if (index == 0) {
                return _buildAddStoryItem();
              }
              return _buildFriendStoryItem(_friendsExploring[index - 1]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAddStoryItem() {
    return GestureDetector(
      onTap: () {
        _showMediaOptions();
      },
      child: Container(
        width: 85,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[200],
                    border: Border.all(color: Colors.grey[300]!, width: 2),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'asset/images/employee-5.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Icon(Icons.person, size: 35, color: Colors.grey[400]),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF113953),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Chuyến đi\ncủa bạn',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMediaOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Chia sẻ chuyến đi của bạn',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF113953),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Chọn ảnh hoặc video để chia sẻ',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),
              // Camera options
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMediaOptionButton(
                    icon: Icons.camera_alt,
                    label: 'Chụp ảnh',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  _buildMediaOptionButton(
                    icon: Icons.videocam,
                    label: 'Quay video',
                    color: Colors.red,
                    onTap: () {
                      Navigator.pop(context);
                      _pickVideo(ImageSource.camera);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              // Gallery options
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMediaOptionButton(
                    icon: Icons.photo_library,
                    label: 'Thư viện ảnh',
                    color: Colors.green,
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                  _buildMediaOptionButton(
                    icon: Icons.video_library,
                    label: 'Thư viện video',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.pop(context);
                      _pickVideo(ImageSource.gallery);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              // Create post option
              ListTile(
                leading: Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: const Color(0xFF113953).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.edit_note, color: Color(0xFF113953)),
                ),
                title: const Text(
                  'Tạo bài viết chi tiết',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Viết bài kèm ảnh và video',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const createandeditcontent(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaOptionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1080,
        imageQuality: 85,
      );
      if (picked != null) {
        // Chuyển đến màn hình tạo story với ảnh
        _showStoryPreview(picked.path, isVideo: false);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Không thể chọn ảnh')));
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(seconds: 60),
      );
      if (picked != null) {
        // Chuyển đến màn hình tạo story với video
        _showStoryPreview(picked.path, isVideo: true);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Không thể chọn video')));
    }
  }

  void _showStoryPreview(String filePath, {required bool isVideo}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Stack(
          children: [
            // Preview
            Center(
              child: isVideo
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.play_circle_outline,
                          color: Colors.white,
                          size: 80,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Video đã chọn',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          filePath.split('/').last,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'asset/images/anh-mo-ta.jpg', // Placeholder
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.image,
                          color: Colors.white54,
                          size: 100,
                        ),
                      ),
                    ),
            ),
            // Header
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                      Row(
                        children: [
                          if (isVideo)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.videocam,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Video',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.photo,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Ảnh',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Bottom actions
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Caption input
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.white30),
                        ),
                        child: const TextField(
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Viết caption...',
                            hintStyle: TextStyle(color: Colors.white60),
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.edit, color: Colors.white60),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Location tag
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.white30),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Colors.white60,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Thêm vị trí',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Share button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã chia sẻ chuyến đi của bạn!'),
                                backgroundColor: Color(0xFF113953),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF113953),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Text(
                            'Chia sẻ ngay',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendStoryItem(Map<String, dynamic> friend) {
    return GestureDetector(
      onTap: () {
        // Xem story của bạn bè
        _showStoryViewer(friend);
      },
      child: Container(
        width: 85,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          children: [
            Stack(
              children: [
                // Avatar với viền gradient
                Container(
                  width: 70,
                  height: 70,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: friend['hasStory'] as bool
                        ? const LinearGradient(
                            colors: [Color(0xFF113953), Color(0xFF2196F3)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    border: !(friend['hasStory'] as bool)
                        ? Border.all(color: Colors.grey[300]!, width: 2)
                        : null,
                  ),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    padding: const EdgeInsets.all(2),
                    child: ClipOval(
                      child: Image.asset(
                        friend['avatar'] as String,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.person,
                          size: 30,
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
                  ),
                ),
                // Live indicator
                if (friend['isLive'] as bool)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              friend['name'] as String,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.location_on,
                  size: 10,
                  color: Color(0xFF113953),
                ),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    friend['location'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showStoryViewer(Map<String, dynamic> friend) {
    // Tìm index của người đang xem
    final int initialIndex = _friendsExploring.indexOf(friend);

    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        opaque: true,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) {
          return StoryViewer(
            friends: _friendsExploring,
            initialIndex: initialIndex >= 0 ? initialIndex : 0,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOut),
                ),
            child: child,
          );
        },
      ),
    );
  }
}
