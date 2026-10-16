// đây là file chứa code của trang trang chủ trong phần home
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tourn/Ui/main/category/home/pages/FirebaseNewfeed.dart';
import 'package:tourn/Ui/main/category/home/pages/liststory.dart';
import 'package:tourn/Ui/main/category/home/widgets/bottom_sheet.dart';
import 'package:tourn/Ui/main/category/home/widgets/profile/Profile.dart';
import 'package:tourn/Ui/main/category/home/widgets/search.dart';
import 'package:tourn/Ui/main/category/home/widgets/community_header.dart';
import 'package:tourn/Ui/main/category/home/widgets/community_search.dart';
import 'package:tourn/Ui/main/category/home/widgets/community_section_title.dart';
import 'package:tourn/Ui/main/category/home/widgets/community_tab_chips.dart';
import 'package:tourn/Ui/main/category/home/widgets/community_destination_cards.dart';
import 'package:tourn/Ui/main/category/home/pages/firebase_hashtag_posts_page.dart';
import 'package:tourn/domain/user_repository/user_repository.dart';
import 'package:tourn/models/user_model.dart';
import 'package:tourn/models/post_model.dart';
import 'package:tourn/data/post/firestore_post_repository.dart';

class Homepage extends StatefulWidget {
  final ValueChanged<bool>? onBottomNavVisibilityChanged;
  final double bottomNavProgress;

  const Homepage({
    super.key,
    this.onBottomNavVisibilityChanged,
    this.bottomNavProgress = 1,
  });

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int _selectedTabIndex = 0;
  UserModel? _currentUser;
  late final UserRepository _userRepository;
  StreamSubscription<UserModel?>? _userSub;
  HomeFeedFilter _feedFilter = HomeFeedFilter.suggested;

  // Cache repository và stream để tránh tạo mới mỗi build
  final FirestorePostRepository _postRepository = FirestorePostRepository();
  Stream<List<PostModel>>? _publicFeedStream;

  final List<String> _tabs = [
    'Trending',
    'Ẩm thực',
    'Biển đảo',
    'Núi rừng',
    'Văn hóa',
    'Khác',
  ];

  // Mapping hashtags to categories
  static const Map<String, List<String>> _categoryKeywords = {
    'Ẩm thực': [
      'amthuc',
      'ẩmthực',
      'food',
      'pho',
      'phở',
      'banhmi',
      'bánhmì',
      'buncha',
      'búnchả',
      'com',
      'cơm',
      'nhahang',
      'nhàhàng',
      'restaurant',
      'cafe',
      'coffee',
      'caphe',
      'càphê',
      'monan',
      'mónan',
      'doan',
      'đồăn',
      'anvat',
      'ănvặt',
      'seafood',
      'haisan',
      'hảisản',
      'bbq',
      'nuong',
      'nướng',
      'lau',
      'lẩu',
      'buffet',
      'dessert',
      'trangmieng',
      'trángmiệng',
    ],
    'Biển đảo': [
      'phuquoc',
      'phúquốc',
      'nhatrang',
      'nhatrang',
      'danang',
      'đànẵng',
      'vungtau',
      'vũngtàu',
      'phanthiet',
      'phanthiết',
      'halong',
      'hạlong',
      'beach',
      'bien',
      'biển',
      'dao',
      'đảo',
      'island',
      'condao',
      'côndảo',
      'quangninh',
      'quảngninh',
      'muine',
      'mũiné',
      'catba',
      'cátbà',
      'phuyen',
      'phúyên',
      'quynhon',
      'quynhơn',
      'hoian',
      'hộian',
      'ocean',
      'sea',
      'diving',
      'lanlặn',
      'snorkeling',
      'resort',
      'langco',
      'lăngcô',
      'samson',
      'sầmsơn',
      'cualo',
      'cửalò',
    ],
    'Núi rừng': [
      'dalat',
      'đàlạt',
      'sapa',
      'sapá',
      'fansipan',
      'nui',
      'núi',
      'mountain',
      'rung',
      'rừng',
      'forest',
      'trekking',
      'hiking',
      'leodeo',
      'leocore',
      'hagiang',
      'hàgiang',
      'mocchau',
      'mộcchâu',
      'bana',
      'bànà',
      'tamđảo',
      'tamdao',
      'bavi',
      'bavì',
      'bavì',
      'maisau',
      'maichâu',
      'puluong',
      'pùluông',
      'batxat',
      'bátxát',
      'yentu',
      'yêntử',
      'langbiang',
      'camping',
      'camprai',
      'phượt',
      'phuot',
      'baclieu',
      'bắcliêu',
    ],
    'Văn hóa': [
      'vanhoa',
      'vănhóa',
      'culture',
      'lehoi',
      'lễhội',
      'festival',
      'temple',
      'chua',
      'chùa',
      'den',
      'đền',
      'pagoda',
      'museum',
      'baotang',
      'bảotàng',
      'ditich',
      'ditích',
      'heritage',
      'history',
      'lichsu',
      'lịchsử',
      'traditional',
      'truyenthong',
      'truyềnthống',
      'hue',
      'huế',
      'hoangcung',
      'hoàngcung',
      'palace',
      'ancient',
      'cổđại',
      'codai',
      'maihong',
      'folklor',
      'danca',
      'dânca',
    ],
  };

  void _showLoginRequired() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cần đăng nhập để thực hiện thao tác này')),
    );
  }

  // Remove Vietnamese diacritics for comparison
  static String _removeDiacritics(String input) {
    const diacritics =
        'àáảãạăắằẳẵặâấầẩẫậèéẻẽẹêếềểễệìíỉĩịòóỏõọôốồổỗộơớờởỡợùúủũụưứừửữựỳýỷỹỵđ';
    const replacements =
        'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';

    var result = input.toLowerCase();
    for (int i = 0; i < diacritics.length; i++) {
      result = result.replaceAll(diacritics[i], replacements[i]);
    }
    return result;
  }

  // Get category for a hashtag
  String _getCategoryForHashtag(String hashtag) {
    // Normalize: lowercase and remove special chars
    final normalizedWithDiacritics = hashtag.toLowerCase().replaceAll(
      RegExp(
        r'[^a-zA-Z0-9àáảãạăắằẳẵặâấầẩẫậèéẻẽẹêếềểễệìíỉĩịòóỏõọôốồổỗộơớờởỡợùúủũụưứừửữựỳýỷỹỵđ]',
      ),
      '',
    );
    // Also remove diacritics for comparison
    final normalizedNoDiacritics = _removeDiacritics(normalizedWithDiacritics);

    // First pass: check for exact match (prioritize specific locations)
    for (final entry in _categoryKeywords.entries) {
      for (final keyword in entry.value) {
        final keywordNoDiacritics = _removeDiacritics(keyword);
        // Exact match takes priority
        if (normalizedNoDiacritics == keywordNoDiacritics ||
            normalizedWithDiacritics == keyword) {
          return entry.key;
        }
      }
    }

    // Second pass: check for partial containment (longer keywords first)
    // Sort entries by keyword length (descending) to match longer/specific keywords first
    final sortedEntries = _categoryKeywords.entries.toList();
    for (final entry in sortedEntries) {
      // Sort keywords by length (longest first) to prioritize specific matches
      final sortedKeywords = List<String>.from(entry.value)
        ..sort((a, b) => b.length.compareTo(a.length));
      for (final keyword in sortedKeywords) {
        final keywordNoDiacritics = _removeDiacritics(keyword);
        // Skip short generic keywords like 'dao', 'nui' if hashtag is longer
        if (keyword.length <= 3 && normalizedWithDiacritics.length > 5) {
          continue;
        }
        if (normalizedNoDiacritics.contains(keywordNoDiacritics) ||
            normalizedWithDiacritics.contains(keyword)) {
          return entry.key;
        }
      }
    }
    return 'Khác';
  }

  // Check if a post belongs to a category
  bool _postBelongsToCategory(PostModel post, String category) {
    if (post.hashtags.isEmpty) return false;
    return post.hashtags.any((h) => _getCategoryForHashtag(h) == category);
  }

  @override
  void initState() {
    super.initState();
    _userRepository = context.read<UserRepository>();
    // Use stream to keep avatar in sync when changed
    _userSub = _userRepository.streamCurrentUser().listen((user) {
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    });
    // Cache stream để tránh tạo mới mỗi build
    _publicFeedStream = _postRepository.getPublicFeed(limit: 50);
  }

  // temporary map removed – feed will come from Firebase

  @override
  void dispose() {
    _userSub?.cancel();
    super.dispose();
  }

  Map<String, dynamic> _postToMap(PostModel p) {
    // Use appropriate label based on hashtags and experience entries
    String hashtagLabel;
    if (p.hashtags.isNotEmpty) {
      // Get category for the first hashtag
      hashtagLabel = _getCategoryForHashtag(p.hashtags.first);
      // If category is "Khác", show original hashtag with # prefix for display
      if (hashtagLabel == 'Khác') {
        hashtagLabel = '#${p.hashtags.first}';
      }
    } else if (p.experienceEntries.isNotEmpty) {
      hashtagLabel = 'Kinh nghiệm';
    } else {
      hashtagLabel = 'Khác';
    }

    // Check if current user has liked the post
    final isLiked = _currentUser != null && p.likes.contains(_currentUser!.uid);

    return {
      'hashtag': hashtagLabel,
      'title': p.content.length > 20
          ? '${p.content.substring(0, 20)}...'
          : p.content,
      'author': p.authorName,
      'avatar': p.authorPhotoUrl ?? '',
      'image': p.mediaUrls.isNotEmpty ? p.mediaUrls.first : '',
      'backgroundColor': p.backgroundColor,
      'description': p.content,
      'likes': p.likes.length,
      'posts': p.commentCount,
      'isFavorite': isLiked,
    };
  }

  @override
  Widget build(BuildContext context) {
    final headerProgress = widget.bottomNavProgress.clamp(0.0, 1.0);
    final isHomeHeaderVisible = headerProgress > 0.05;
    final headerOffsetY = -72 * (1 - headerProgress);
    final headerSpace = 92.0 * headerProgress;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: SizedBox(height: headerSpace)),
                SliverToBoxAdapter(
                  child: CommunitySearch(
                    onSearchTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SearchPage(),
                      ),
                    ),
                    onFilterTap: _showFeedFilterSheet,
                  ),
                ),
                // Section title và tabs
                SliverToBoxAdapter(
                  child: CommunitySectionTitle(
                    onViewAll: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (c) => const _AllCommunityPostsPage(),
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
                // Destination cards backed by Firebase feed (only posts with hashtags)
                SliverToBoxAdapter(
                  child: StreamBuilder<List<PostModel>>(
                    stream: _publicFeedStream,
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final all = snap.data ?? [];

                      // Filter based on selected tab
                      List<PostModel> posts;
                      if (_selectedTabIndex == 5) {
                        // "Khác" tab: show posts with hashtags that don't match any category
                        // OR posts without hashtags but with experience sharing
                        posts = all.where((p) {
                          if (p.hashtags.isEmpty) {
                            return p.experienceEntries.isNotEmpty;
                          }
                          // Posts with hashtags that don't belong to any defined category
                          return !p.hashtags.any(
                            (h) => _getCategoryForHashtag(h) != 'Khác',
                          );
                        }).toList();
                      } else if (_selectedTabIndex == 0) {
                        // "Trending" tab: only show posts with experience sharing enabled
                        // Sort by engagement (likes + comments) - highest first
                        posts = all
                            .where((p) => p.experienceEntries.isNotEmpty)
                            .toList();
                        // Sort by engagement - highest first
                        posts.sort((a, b) {
                          final engagementA = a.likes.length + a.commentCount;
                          final engagementB = b.likes.length + b.commentCount;
                          // If same engagement, sort by most recent
                          if (engagementA == engagementB) {
                            return b.createdAt.compareTo(a.createdAt);
                          }
                          return engagementB.compareTo(engagementA);
                        });
                      } else {
                        // Category tabs: filter by hashtag category mapping
                        final category = _tabs[_selectedTabIndex];
                        posts = all
                            .where((p) => _postBelongsToCategory(p, category))
                            .toList();
                      }
                      if (posts.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return CommunityDestinationCards(
                        posts: posts.map(_postToMap).toList(),
                        onToggleFavorite: (i) async {
                          if (_currentUser == null) {
                            _showLoginRequired();
                            return;
                          }
                          final post = posts[i];
                          final postRepo = FirestorePostRepository();
                          final isLiked = post.likes.contains(
                            _currentUser!.uid,
                          );
                          if (isLiked) {
                            await postRepo.unlikePost(post.id);
                          } else {
                            await postRepo.likePost(post.id);
                          }
                        },

                        onHashtagTap: (i, hashtag) {
                          final selected = posts[i];
                          // If hashtag starts with #, extract the actual hashtag
                          final cleanHashtag = hashtag.startsWith('#')
                              ? hashtag.substring(1)
                              : hashtag;
                          // Navigate to hashtag posts page
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (c) => FirebaseHashtagPostsPage(
                                hashtag: cleanHashtag,
                                selectedPost: selected,
                              ),
                            ),
                          );
                        },
                        onCardTap: (i) {
                          // Navigate to category posts page with all posts from current tab
                          final category = _tabs[_selectedTabIndex];
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (c) => _CategoryPostsPage(
                                category: category,
                                posts: posts,
                                selectedPostIndex: i,
                              ),
                            ),
                          );
                        },
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
                // Newfeed - tích hợp Firebase để hiển thị bài viết từ database
                FirebaseNewfeed(filter: _feedFilter),
              ],
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                ignoring: true,
                child: Transform.translate(
                  offset: Offset(0, headerOffsetY),
                  child: Opacity(
                    opacity: headerProgress,
                    child: Container(height: 92, color: Colors.white),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                ignoring: !isHomeHeaderVisible,
                child: Transform.translate(
                  offset: Offset(0, headerOffsetY),
                  child: Opacity(
                    opacity: headerProgress,
                    child: CommunityHeader(
                      onAddTap: () => bottom(context),
                      onProfileTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const Profile(showBottomNav: true, initialTab: 0),
                        ),
                      ),
                      userName: _currentUser?.displayName,
                      userPhotoUrl: _currentUser?.photoUrl,
                    ),
                  ),
                ),
              ),
            ),
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

  void _showFeedFilterSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  'Lựa chọn nội dung',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              _filterOptionTile(
                title: 'Đề xuất',
                value: HomeFeedFilter.suggested,
                subtitle:
                    'Nội dung phù hợp với sở thích và những điều bạn quan tâm',
              ),
              _filterOptionTile(
                title: 'Bạn bè',
                value: HomeFeedFilter.friends,
                subtitle:
                    'Theo dõi mọi khoảnh khắc và bài viết từ bạn bè của bạn',
              ),
              _filterOptionTile(
                title: 'Đã theo dõi',
                value: HomeFeedFilter.following,
                subtitle:
                    'Chỉ hiển thị nội dung từ những người bạn chọn theo dõi',
              ),
              _filterOptionTile(
                title: 'Khám phá',
                value: HomeFeedFilter.explore,
                subtitle:
                    'Khám phá xu hướng mới và nội dung đa dạng không giới hạn',
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _filterOptionTile({
    required String title,
    required HomeFeedFilter value,
    String? subtitle,
  }) {
    final isSelected = _feedFilter == value;
    return ListTile(
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: isSelected ? const Color(0xFF113953) : Colors.grey,
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: subtitle == null ? null : Text(subtitle),
      onTap: () {
        setState(() {
          _feedFilter = value;
        });
        Navigator.pop(context);
      },
    );
  }
}

// Page to show all community posts from all categories
class _AllCommunityPostsPage extends StatefulWidget {
  const _AllCommunityPostsPage();

  @override
  State<_AllCommunityPostsPage> createState() => _AllCommunityPostsPageState();
}

class _AllCommunityPostsPageState extends State<_AllCommunityPostsPage> {
  late final Stream<List<PostModel>> _feedStream;

  @override
  void initState() {
    super.initState();
    _feedStream = FirestorePostRepository().getPublicFeed(limit: 100);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kinh nghiệm từ cộng đồng'),
        elevation: 0,
      ),
      body: StreamBuilder<List<PostModel>>(
        stream: _feedStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final posts = snapshot.data ?? [];
          // Filter posts with hashtags or experience entries
          final filtered = posts
              .where(
                (p) => p.hashtags.isNotEmpty || p.experienceEntries.isNotEmpty,
              )
              .toList();

          if (filtered.isEmpty) {
            return const Center(child: Text('Chưa có bài viết nào'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              return FirebasePostCard(post: filtered[index]);
            },
          );
        },
      ),
    );
  }
}

// Page to show posts from a specific category with scrolling
class _CategoryPostsPage extends StatefulWidget {
  final String category;
  final List<PostModel> posts;
  final int selectedPostIndex;

  const _CategoryPostsPage({
    required this.category,
    required this.posts,
    required this.selectedPostIndex,
  });

  @override
  State<_CategoryPostsPage> createState() => _CategoryPostsPageState();
}

class _CategoryPostsPageState extends State<_CategoryPostsPage> {
  late ScrollController _scrollController;
  final Map<int, GlobalKey> _itemKeys = {};

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // Create keys for all items
    for (int i = 0; i < widget.posts.length; i++) {
      _itemKeys[i] = GlobalKey();
    }
    // Scroll to selected post after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedPost();
    });
  }

  void _scrollToSelectedPost() {
    if (widget.selectedPostIndex > 0 &&
        widget.selectedPostIndex < widget.posts.length) {
      // Estimate position based on average card height
      final estimatedHeight = 400.0; // Average post card height
      final offset = widget.selectedPostIndex * estimatedHeight;
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.category), elevation: 0),
      body: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(8),
        itemCount: widget.posts.length,
        itemBuilder: (context, index) {
          return Padding(
            key: _itemKeys[index],
            padding: const EdgeInsets.only(bottom: 8),
            child: FirebasePostCard(post: widget.posts[index]),
          );
        },
      ),
    );
  }
}
