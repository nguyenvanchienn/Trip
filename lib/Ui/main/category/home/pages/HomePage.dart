// đây là file chứa code của trang trang chủ trong phần home
import 'package:flutter/material.dart';
import 'package:tourn/Ui/main/category/home/pages/Newfeed.dart';
import 'package:tourn/Ui/main/category/home/pages/liststory.dart';
import 'package:tourn/Ui/main/category/home/widgets/bottom_sheet.dart';
import 'package:tourn/Ui/main/category/home/widgets/profile.dart';
import 'package:tourn/Ui/main/category/home/widgets/search.dart';
import 'package:tourn/Ui/main/category/home/widgets/community_header.dart';
import 'package:tourn/Ui/main/category/home/widgets/community_search.dart';
import 'package:tourn/Ui/main/category/home/widgets/community_section_title.dart';
import 'package:tourn/Ui/main/category/home/widgets/community_tab_chips.dart';
import 'package:tourn/Ui/main/category/home/widgets/community_destination_cards.dart';
import 'package:tourn/Ui/main/category/home/pages/community_all_posts.dart';
import 'package:tourn/Ui/main/category/home/pages/hashtag_posts_page.dart';

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
        'image': 'asset/images/anhdemo.jpeg',
        'description': 'Check-in thiên đường hoa tại Đà Lạt',
        'likes': 1520,
        'posts': 89,
        'isFavorite': false,
        'experience':
            'Kinh nghiệm chụp cảnh và tìm góc đẹp sau 3 lần đi Đà Lạt, mẹo tránh sương mù sớm.',
        'itinerary':
            'Sáng: Hồ Xuân Hương → Dinh Bảo Đại. Chiều: Vườn hoa thành phố → Chợ đêm.',
        'expenses':
            'Khoảng 800k - 1.2M cho 2 ngày (không tính lưu trú cao cấp).',
      },
      {
        'hashtag': '#PhuQuoc',
        'title': 'Phú Quốc đảo ngọc',
        'author': 'Thu Hà',
        'avatar': 'asset/images/OIP.jpg',
        'image': 'asset/images/anhdemo2.jpg',
        'description': 'Khám phá hòn đảo xinh đẹp nhất VN',
        'likes': 2340,
        'posts': 156,
        'isFavorite': true,
        'experience':
            'Mẹo mua hải sản ngon, chọn khu tắm biển sạch, và tiết kiệm khi đi mùa thấp điểm.',
        'itinerary': 'Ngày 1: Bãi Dài - Hòn Thơm; Ngày 2: Nam Đảo - Làng chài.',
        'expenses': 'Dự trù 2-3 triệu cho 2 ngày: ăn + vé cáp + thuê xe.',
      },
      {
        'hashtag': '#HoiAn',
        'title': 'Phố cổ Hội An',
        'author': 'Văn Đức',
        'avatar': 'asset/images/OIP.jpg',
        'image': 'asset/images/anhdemo3.webp',
        'description': 'Đêm phố cổ lung linh đèn lồng',
        'likes': 1890,
        'posts': 234,
        'isFavorite': false,
        'experience':
            'Thời điểm tốt nhất là buổi tối, nhớ thử cao lầu và bánh mì Phượng.',
        'itinerary': 'Tản bộ phố cổ → Tham quan hội quán → Ăn đêm.',
        'expenses': 'Khoảng 300k - 600k cho ăn uống và quà lưu niệm.',
      },
    ],
    1: [
      // Ẩm thực
      {
        'hashtag': '#StreetFood',
        'title': 'Ẩm thực đường phố',
        'author': 'Foodie VN',
        'avatar': 'asset/images/OIP.jpg',
        'image': 'asset/images/anhdemo.jpeg',
        'description': 'Khám phá món ngon đường phố',
        'likes': 3200,
        'posts': 567,
        'isFavorite': true,
        'experience': 'Nên thử món địa phương lúc tối, mang theo tiền lẻ.',
        'itinerary': 'Đi bộ khám phá các quầy ở khu phố cổ và chợ đêm.',
        'expenses': 'Tầm 200k - 400k cho một bữa đi ăn đường phố.',
      },
      {
        'hashtag': '#PhoHaNoi',
        'title': 'Phở Hà Nội',
        'author': 'Hà Nội Food',
        'avatar': 'asset/images/OIP.jpg',
        'image': 'asset/images/anhdemo2.jpg',
        'description': 'Tinh hoa ẩm thực Thủ đô',
        'likes': 2890,
        'posts': 423,
        'isFavorite': false,
        'experience':
            'Chọn quán có nước dùng trong, ít mỡ; ăn kèm chanh ớt theo khẩu vị.',
        'itinerary': 'Sáng ăn phở + tham quan Văn Miếu.',
        'expenses': 'Khoảng 30k - 80k cho một tô phở.',
      },
    ],
    2: [
      // Biển đảo
      {
        'hashtag': '#NhaTrang',
        'title': 'Biển Nha Trang',
        'author': 'Beach Lover',
        'avatar': 'asset/images/OIP.jpg',
        'image': 'asset/images/anhdemo3.webp',
        'description': 'Vịnh biển đẹp nhất Việt Nam',
        'likes': 4560,
        'posts': 789,
        'isFavorite': true,
        'experience':
            'Nên lặn ngắm san hô ở buổi sáng, và hỏi trước giá dịch vụ.',
        'itinerary': 'Đảo Hòn Mun → Vinpearl → Bãi Trũ.',
        'expenses': 'Khoảng 1.5 - 2 triệu cho vé tàu, lặn và ăn uống.',
      },
      {
        'hashtag': '#ConDao',
        'title': 'Côn Đảo hoang sơ',
        'author': 'Island Hunter',
        'avatar': 'asset/images/OIP.jpg',
        'image': 'asset/images/anhdemo.jpeg',
        'description': 'Thiên đường biển hoang sơ',
        'likes': 2100,
        'posts': 156,
        'isFavorite': false,
        'experience':
            'Chuẩn bị trước giấy tờ, hỏi lịch trình tàu và tour tham quan.',
        'itinerary': 'Tham quan di tích → Bãi biển → Ngắm rùa.',
        'expenses': 'Dự trù 2-3 triệu tùy mùa.',
      },
    ],
    3: [
      // Núi rừng
      {
        'hashtag': '#Sapa',
        'title': 'Sapa mây phủ',
        'author': 'Trekking VN',
        'avatar': 'asset/images/OIP.jpg',
        'image': 'asset/images/anhdemo3.webp',
        'description': 'Chinh phục đỉnh Fansipan',
        'likes': 3890,
        'posts': 456,
        'isFavorite': true,
        'experience':
            'Chuẩn bị quần áo ấm, giày trekking, và tham khảo thời tiết 1 tuần trước khi đi.',
        'itinerary':
            'Ngày 1: Trekking bản Cát Cát; Ngày 2: Lên Fansipan bằng cáp treo.',
        'expenses':
            'Ước tính 1.5 - 2 triệu cho 2 ngày (bao gồm vé cáp và guide).',
      },
      {
        'hashtag': '#HaGiang',
        'title': 'Hà Giang loop',
        'author': 'Biker Club',
        'avatar': 'asset/images/OIP.jpg',
        'image': 'asset/images/anhdemo2.jpg',
        'description': 'Cung đường đẹp nhất Việt Nam',
        'likes': 5670,
        'posts': 890,
        'isFavorite': false,
        'experience': 'Chuẩn bị xe kỹ, check lốp, và mang theo đồ ấm cho đêm.',
        'itinerary': 'Hành trình 3 ngày: Quản Bạ → Yên Minh → Đồng Văn.',
        'expenses':
            'Tùy xe và số ngày, 2 - 3 triệu cho chi phí nhiên liệu và ăn uống.',
      },
    ],
    4: [
      // Văn hóa
      {
        'hashtag': '#HueCoDo',
        'title': 'Huế cố đô',
        'author': 'Heritage VN',
        'avatar': 'asset/images/OIP.jpg',
        'image': 'asset/images/anhdemo.jpeg',
        'description': 'Di sản văn hóa thế giới',
        'likes': 2340,
        'posts': 345,
        'isFavorite': true,
        'experience':
            'Thời điểm tham quan tốt là sáng sớm để tránh nắng; thử đặc sản bún bò Huế.',
        'itinerary': 'Thăm Đại Nội → Lăng Tự Đức → Sông Hương.',
        'expenses': 'Khoảng 300k - 700k cho 1-2 ngày tham quan.',
      },
      {
        'hashtag': '#MyTho',
        'title': 'Miền Tây sông nước',
        'author': 'Delta Explorer',
        'avatar': 'asset/images/OIP.jpg',
        'image': 'asset/images/anhdemo.jpeg',
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
            SliverToBoxAdapter(
              child: CommunityHeader(
                onAddTap: () => bottom(context),
                onProfileTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const profile()),
                ),
              ),
            ),
            // Search bar
            SliverToBoxAdapter(
              child: CommunitySearch(
                onSearchTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchPage()),
                ),
                onFilterTap: () {},
              ),
            ),
            // Section title và tabs
            SliverToBoxAdapter(
              child: CommunitySectionTitle(
                onViewAll: () {
                  final allPosts = _hashtagPosts.values
                      .expand((x) => x)
                      .toList();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CommunityAllPostsPage(posts: allPosts),
                    ),
                  );
                },
              ),
            ),
            // Tab chips
            SliverToBoxAdapter(
              child: CommunityTabChips(
                tabs: _tabs,
                selectedIndex: _selectedTabIndex,
                onSelected: (i) => setState(() => _selectedTabIndex = i),
              ),
            ),
            // Destination cards
            SliverToBoxAdapter(
              child: CommunityDestinationCards(
                posts: _hashtagPosts[_selectedTabIndex] ?? [],
                onToggleFavorite: (i) => _toggleFavorite(i),
                onCardTap: (i) {
                  final postsForTab = _hashtagPosts[_selectedTabIndex] ?? [];
                  final post = postsForTab[i];
                  // Lọc chỉ những bài có cùng hashtag với thẻ được chọn
                  final related = postsForTab
                      .where((p) => p['hashtag'] == post['hashtag'])
                      .toList();
                  // Đưa bài vừa chạm lên đầu, các bài còn lại sắp xếp theo lượt like giảm dần
                  related.removeWhere((p) => p['title'] == post['title']);
                  related.sort(
                    (a, b) => (b['likes'] as int? ?? 0).compareTo(
                      a['likes'] as int? ?? 0,
                    ),
                  );
                  final ordered = [post, ...related];

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HashtagPostsPage(
                        hashtag: post['hashtag'] as String,
                        posts: ordered,
                      ),
                    ),
                  );
                },
              ),
            ),
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

  // Header moved to `CommunityHeader` widget

  // Search bar moved to `CommunitySearch` widget

  // Section title moved to `CommunitySectionTitle` widget

  // Tab chips moved to `CommunityTabChips` widget

  // Destination cards moved to `CommunityDestinationCards` widget
}
