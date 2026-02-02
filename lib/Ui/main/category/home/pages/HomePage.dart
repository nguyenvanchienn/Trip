// đây là file chứa code của trang trang chủ trong phần home
import 'package:flutter/material.dart';
import 'package:tourn/Ui/main/category/home/pages/Newfeed.dart';
import 'package:tourn/Ui/main/category/home/pages/liststory.dart';
import 'package:tourn/Ui/main/category/home/widgets/bottom_sheet.dart';
import 'package:tourn/Ui/main/category/home/widgets/profile.dart';
import 'package:tourn/Ui/main/category/home/widgets/search.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int _selectedTabIndex = 0;
  final List<String> _tabs = [
    'Trending',
    'Ẩm thực',
    'Biển đảo',
    'Núi rừng',
    'Văn hóa',
  ];

  // Dữ liệu bài viết theo hashtag từ người dùng chia sẻ kinh nghiệm
  final Map<int, List<Map<String, dynamic>>> _hashtagPosts = {
    0: [
      // Trending
      {
        'hashtag': '#DaLat',
        'title': 'Đà Lạt mùa hoa',
        'author': 'Minh Anh',
        'avatar': 'asset/images/employee-5.png',
        'image': 'asset/images/anh-mo-ta.jpg',
        'description': 'Check-in thiên đường hoa tại Đà Lạt',
        'likes': 1520,
        'posts': 89,
        'isFavorite': false,
      },
      {
        'hashtag': '#PhuQuoc',
        'title': 'Phú Quốc đảo ngọc',
        'author': 'Thu Hà',
        'avatar': 'asset/images/anh-mo-ta.jpg',
        'image': 'asset/images/anh-mo-ta.jpg',
        'description': 'Khám phá hòn đảo xinh đẹp nhất VN',
        'likes': 2340,
        'posts': 156,
        'isFavorite': true,
      },
      {
        'hashtag': '#HoiAn',
        'title': 'Phố cổ Hội An',
        'author': 'Văn Đức',
        'avatar': 'asset/images/anh-mo-ta.jpg',
        'image': 'asset/images/anh-mo-ta.jpg',
        'description': 'Đêm phố cổ lung linh đèn lồng',
        'likes': 1890,
        'posts': 234,
        'isFavorite': false,
      },
    ],
    1: [
      // Ẩm thực
      {
        'hashtag': '#StreetFood',
        'title': 'Ẩm thực đường phố',
        'author': 'Foodie VN',
        'avatar': 'asset/images/anh-mo-ta.jpg',
        'image': 'asset/images/anh-mo-ta.jpg',
        'description': 'Khám phá món ngon đường phố',
        'likes': 3200,
        'posts': 567,
        'isFavorite': true,
      },
      {
        'hashtag': '#PhoHaNoi',
        'title': 'Phở Hà Nội',
        'author': 'Hà Nội Food',
        'avatar': 'asset/images/anh-mo-ta.jpg',
        'image': 'asset/images/anh-mo-ta.jpg',
        'description': 'Tinh hoa ẩm thực Thủ đô',
        'likes': 2890,
        'posts': 423,
        'isFavorite': false,
      },
    ],
    2: [
      // Biển đảo
      {
        'hashtag': '#NhaTrang',
        'title': 'Biển Nha Trang',
        'author': 'Beach Lover',
        'avatar': 'asset/images/anh-mo-ta.jpg',
        'image': 'asset/images/anh-mo-ta.jpg',
        'description': 'Vịnh biển đẹp nhất Việt Nam',
        'likes': 4560,
        'posts': 789,
        'isFavorite': true,
      },
      {
        'hashtag': '#ConDao',
        'title': 'Côn Đảo hoang sơ',
        'author': 'Island Hunter',
        'avatar': 'asset/images/anh-mo-ta.jpg',
        'image': 'asset/images/anh-mo-ta.jpg',
        'description': 'Thiên đường biển hoang sơ',
        'likes': 2100,
        'posts': 156,
        'isFavorite': false,
      },
    ],
    3: [
      // Núi rừng
      {
        'hashtag': '#Sapa',
        'title': 'Sapa mây phủ',
        'author': 'Trekking VN',
        'avatar': 'asset/images/anh-mo-ta.jpg',
        'image': 'asset/images/anh-mo-ta.jpg',
        'description': 'Chinh phục đỉnh Fansipan',
        'likes': 3890,
        'posts': 456,
        'isFavorite': true,
      },
      {
        'hashtag': '#HaGiang',
        'title': 'Hà Giang loop',
        'author': 'Biker Club',
        'avatar': 'asset/images/anh-mo-ta.jpg',
        'image': 'asset/images/anh-mo-ta.jpg',
        'description': 'Cung đường đẹp nhất Việt Nam',
        'likes': 5670,
        'posts': 890,
        'isFavorite': false,
      },
    ],
    4: [
      // Văn hóa
      {
        'hashtag': '#HueCoDo',
        'title': 'Huế cố đô',
        'author': 'Heritage VN',
        'avatar': 'asset/images/anh-mo-ta.jpg',
        'image': 'asset/images/anh-mo-ta.jpg',
        'description': 'Di sản văn hóa thế giới',
        'likes': 2340,
        'posts': 345,
        'isFavorite': true,
      },
      {
        'hashtag': '#MyTho',
        'title': 'Miền Tây sông nước',
        'author': 'Delta Explorer',
        'avatar': 'asset/images/anh-mo-ta.jpg',
        'image': 'asset/images/anh-mo-ta.jpg',
        'description': 'Văn hóa miệt vườn sông nước',
        'likes': 1890,
        'posts': 234,
        'isFavorite': false,
      },
    ],
  };

  @override
  void dispose() {
    super.dispose();
  }

  void _toggleFavorite(int index) {
    setState(() {
      _hashtagPosts[_selectedTabIndex]![index]['isFavorite'] =
          !(_hashtagPosts[_selectedTabIndex]![index]['isFavorite'] as bool);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header cố định
            SliverToBoxAdapter(child: _buildHeader(context)),
            // Search bar
            SliverToBoxAdapter(child: _buildSearchBar(context)),
            // Section title và tabs
            SliverToBoxAdapter(child: _buildSectionTitle()),
            // Tab chips
            SliverToBoxAdapter(child: _buildTabChips()),
            // Destination cards
            SliverToBoxAdapter(child: _buildDestinationCards()),
            // Phần nội dung gốc (posts, stories)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
            // Liststory horizontal scroll
            SliverToBoxAdapter(child: Liststory()),
            // Newfeed - tích hợp trực tiếp vào CustomScrollView
            const Newfeed(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
                  onPressed: () => bottom(context),
                  padding: EdgeInsets.zero,
                  iconSize: 20,
                  icon: const Icon(Icons.add, color: Colors.black),
                ),
              ),
              const SizedBox(width: 12),
              // Avatar
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const profile()),
                  );
                },
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

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchPage()),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey[400], size: 22),
                    const SizedBox(width: 12),
                    Text(
                      'Tìm kiếm địa điểm...',
                      style: TextStyle(color: Colors.grey[400], fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF113953),
              borderRadius: BorderRadius.circular(16),
            ),
            child: IconButton(
              onPressed: () {
                // Filter options
              },
              icon: const Icon(Icons.tune, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle() {
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
              const Text(
                'Kinh nghiệm từ cộng đồng',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF113953),
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: () {},
            child: const Text(
              'Xem tất cả',
              style: TextStyle(color: Color(0xFF113953)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabChips() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _tabs.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedTabIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTabIndex = index;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF113953) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF113953)
                        : Colors.grey.shade300,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF113953).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    if (index == 0)
                      Icon(
                        Icons.local_fire_department,
                        size: 16,
                        color: isSelected ? Colors.orange : Colors.orange,
                      ),
                    if (index == 1)
                      Icon(
                        Icons.restaurant,
                        size: 16,
                        color: isSelected ? Colors.white : Colors.grey[600],
                      ),
                    if (index == 2)
                      Icon(
                        Icons.beach_access,
                        size: 16,
                        color: isSelected ? Colors.white : Colors.grey[600],
                      ),
                    if (index == 3)
                      Icon(
                        Icons.terrain,
                        size: 16,
                        color: isSelected ? Colors.white : Colors.grey[600],
                      ),
                    if (index == 4)
                      Icon(
                        Icons.account_balance,
                        size: 16,
                        color: isSelected ? Colors.white : Colors.grey[600],
                      ),
                    const SizedBox(width: 6),
                    Text(
                      _tabs[index],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[700],
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDestinationCards() {
    final posts = _hashtagPosts[_selectedTabIndex] ?? [];
    return SizedBox(
      height: 300,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.85),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child: GestureDetector(
              onTap: () {
                // Chuyển đến danh sách bài viết theo hashtag
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background image
                      Image.asset(
                        post['image'] as String,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.image, size: 50),
                        ),
                      ),
                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.8),
                            ],
                            stops: const [0.4, 1.0],
                          ),
                        ),
                      ),
                      // Hashtag badge at top left
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF113953),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            post['hashtag'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      // Favorite button
                      Positioned(
                        top: 16,
                        right: 16,
                        child: GestureDetector(
                          onTap: () => _toggleFavorite(index),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              post['isFavorite'] as bool
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: post['isFavorite'] as bool
                                  ? Colors.red
                                  : Colors.grey[700],
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                      // Content at bottom
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Title
                            Text(
                              post['title'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Description
                            Text(
                              post['description'] as String,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),
                            // Stats row
                            Row(
                              children: [
                                // Author
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      post['avatar'] as String,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.person,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  post['author'] as String,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                const Spacer(),
                                // Likes
                                const Icon(
                                  Icons.favorite,
                                  color: Colors.red,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${post['likes']}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Posts count
                                const Icon(
                                  Icons.article_outlined,
                                  color: Colors.white70,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${post['posts']} bài',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // View more button
                            Row(
                              children: [
                                const Text(
                                  'Xem bài viết',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward,
                                    color: Color(0xFF113953),
                                    size: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
