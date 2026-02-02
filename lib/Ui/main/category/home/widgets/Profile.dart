// đây là file chứa code của trang profile chính trong phần home
import 'package:flutter/material.dart';
import 'package:tourn/Ui/main/main_page.dart';
import 'package:tourn/Ui/main/category/home/widgets/Album_profile.dart';
import 'package:tourn/Ui/main/category/home/widgets/Followers_and_Are_following.dart';
import 'package:tourn/Ui/main/category/home/widgets/Newfeed_profile.dart';
import 'package:tourn/Ui/main/category/home/widgets/check_in.dart';
import 'package:tourn/Ui/main/category/home/widgets/create_and_edit_content.dart';
import 'package:tourn/Ui/main/category/home/widgets/edit_profile.dart';
import 'package:tourn/Ui/main/category/home/widgets/intro_profile.dart';
import 'package:tourn/Ui/main/category/home/widgets/search.dart';
import 'package:image_picker/image_picker.dart';

class profile extends StatefulWidget {
  final String? name;
  final String? avatar;
  final bool isOnline;
  final bool showBottomNav; // Hiển thị bottom nav khi mở từ chat

  const profile({
    super.key,
    this.name,
    this.avatar,
    this.isOnline = false,
    this.showBottomNav = false,
  });

  @override
  State<profile> createState() => _profileState();
}

class _profileState extends State<profile> {
  int _selectedTab = 0; // Biến để theo dõi tab được chọn

  final ImagePicker _picker = ImagePicker(); // Khởi tạo ImagePicker
  String? _avatarPath;

  @override
  void dispose() {
    // Giải phóng bộ nhớ cho các controller khi widget bị hủy
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (picked != null) setState(() => _avatarPath = picked.path);
    } catch (_) {
      // ignore errors for now
    }
  }

  void _viewAvatar() {
    // Hiển thị ảnh đại diện phóng to với nền mờ
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8), // Nền đen mờ
      builder: (context) => GestureDetector(
        onTap: () => Navigator.pop(context), // Đóng khi nhấp ra ngoài
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: GestureDetector(
            onTap: () {}, // Ngăn sự kiện tap lan ra ngoài khi nhấp vào ảnh
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Nút đóng ở trên
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 20, bottom: 10),
                    ),
                  ),
                  // Ảnh đại diện hình tròn với zoom
                  InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 3.0,
                    child: ClipOval(
                      child: Image.asset(
                        'asset/images/anh-mo-ta.jpg',
                        width: 300,
                        height: 300,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Nút thay đổi ảnh đại diện
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showImageOptions(context);
                    },
                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                    label: const Text(
                      'Thay đổi ảnh đại diện',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFB620),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showImageOptions(BuildContext context) {
    // Hiển thị tùy chọn chọn ảnh
    showModalBottomSheet(
      context: context,
      builder: (c) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.remove_red_eye),
              title: const Text('Xem ảnh đại diện'),
              onTap: () {
                Navigator.pop(c);
                _viewAvatar(); // Mở ảnh để xem
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Chụp ảnh'),
              onTap: () {
                Navigator.pop(c);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Chọn từ thư viện'),
              onTap: () {
                Navigator.pop(c);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_avatarPath != null) // chỉ hiển thị nếu đã thay đổi ảnh
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Xóa ảnh đại diện',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(c);
                  setState(() => _avatarPath = null); // Khôi phục ảnh mặc định
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          // Nút next ở góc phải
          TextButton(
            onPressed: () {
              // Xử lý khi nhấn nút edit
              _gotoeditpage(context);
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Icon(Icons.edit, color: Colors.black, size: 20),
          ),
          TextButton(
            onPressed: () {
              // Xử lý khi nhấn nút search
              _gotosearchpage(context);
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Icon(Icons.search, color: Colors.black, size: 25),
          ),
        ],
      ),
      body: SingleChildScrollView(child: _buildbodypagescreen(context)),
      // Hiển thị bottom navigation bar khi mở từ chat
      bottomNavigationBar: widget.showBottomNav
          ? BottomNavigationBar(
              backgroundColor: const Color(0xFF121212),
              type: BottomNavigationBarType.fixed,
              unselectedItemColor: Colors.white,
              selectedItemColor: Colors.blue,
              currentIndex: 0,
              onTap: (index) {
                // Điều hướng về MainPage với tab được chọn
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => Mainpage(initialTab: index),
                  ),
                  (route) => false, // Xóa tất cả các route cũ
                );
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Trang chủ',
                ),
                BottomNavigationBarItem(icon: Icon(Icons.mail), label: 'Thư'),
                BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Bản đồ'),
                BottomNavigationBarItem(
                  icon: Icon(Icons.favorite),
                  label: 'Yêu thích',
                ),
                BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Menu'),
              ],
            )
          : null,
    );
  }

  Widget _buildbodypagescreen(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment
            .start, // Căn chỉnh theo trục chính từ trên xuống dưới
        crossAxisAlignment: CrossAxisAlignment
            .start, // Căn chỉnh theo trục ngang từ trái sang phải
        children: [
          _buildcategoryNamefield(),
          _buildcategorychooseIconfield(context),
          _buildnewfeedprofile(),
        ],
      ),
    );
  }

  Widget _buildcategoryNamefield() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => _showImageOptions(context),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: AssetImage('asset/images/anh-mo-ta.jpg'),
                    ),
                    Positioned(
                      right: -6,
                      bottom: -6,
                      child: Container(
                        height: 34,
                        width: 34,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Các cột số liệu chiếm không gian còn lại và co dãn tránh tràn
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text("34", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      "Điểm đến",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () {
                    // Xử lý khi nhấn vào số liệu Người theo dõi
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FollowersAndAreFollowing(
                          initialTabIndex: 0,
                        ), // Chuyển đến tab Người theo dõi
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "334",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Người theo dõi",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () {
                    // Xử lý khi nhấn vào số liệu Đang theo dõi
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FollowersAndAreFollowing(
                          initialTabIndex: 1,
                        ), // Chuyển đến tab Đang theo dõi
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "134",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Đang theo dõi",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          child: Text(
            "Nguyễn Hữu Hiển",
            style: TextStyle(
              color: Color(0xFF113953),
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          child: Text(
            "Ghét du lịch thích 🦫🍶",
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildcategorychooseIconfield(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Colors.grey.shade300),
              bottom: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() => _selectedTab = 0);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 6),
                      Text(
                        'Trang chủ',
                        style: TextStyle(
                          color: _selectedTab == 0
                              ? const Color(0xFFFFB620)
                              : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() => _selectedTab = 1);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 6),
                      Text(
                        'Giới thiệu',
                        style: TextStyle(
                          color: _selectedTab == 1
                              ? Colors.orange
                              : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() => _selectedTab = 2);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 6),
                      Text(
                        'Album',
                        style: TextStyle(
                          color: _selectedTab == 2
                              ? Colors.orange
                              : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() => _selectedTab = 3);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 6),
                      Text(
                        'Video',
                        style: TextStyle(
                          color: _selectedTab == 3
                              ? Colors.orange
                              : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        Container(
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Colors.grey.shade300),
              bottom: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: Row(
            children: [
              // Viết bài
              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const createandeditcontent(),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.edit, size: 20, color: Colors.grey),
                      SizedBox(width: 6),
                      Text('Viết bài', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),

              // Vạch ngăn giữa
              Container(width: 1, height: 45, color: Colors.grey.shade300),

              // Check-in
              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CheckIn()),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.camera_alt_outlined,
                        size: 20,
                        color: Colors.grey,
                      ),
                      SizedBox(width: 6),
                      Text('Check-in', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildnewfeedprofile() {
    Widget content; // Biến để chứa nội dung của tab được chọn
    switch (_selectedTab) {
      case 0:
        content = const Newfeedprofile();
        break;
      case 1:
        content = const Introprofile();
        break;
      case 2:
        content = const AlbumProfile();
        break;
      default:
        content = Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: const Center(child: Text('Tùy chọn chưa có nội dung')),
        );
    }
    return content;
  }

  void _gotoeditpage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditProfilePage()),
    );
  }

  void _gotosearchpage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SearchPage()),
    );
  }
}
