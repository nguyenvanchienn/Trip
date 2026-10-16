// File này chứa phiên bản tích hợp Firebase cho Newfeed
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:tourn/data/post/firestore_post_repository.dart';
import 'package:tourn/domain/user_repository/user_repository.dart';
import 'package:tourn/models/post_model.dart';
import 'package:tourn/Ui/main/category/home/widgets/profile/Profile.dart';
import 'package:tourn/Ui/main/category/favorites/pages/baiviet.dart';
import 'package:tourn/data/firebase/firebase_user_service.dart';
import 'package:tourn/ultils.enums/image_utils.dart';
import 'package:tourn/data/firebase/firebase_menu_service.dart';
import 'package:tourn/data/firebase/firebase_activity_service.dart';
import 'package:tourn/data/firebase/firebase_account_service.dart';
import 'package:tourn/models/menu_models.dart';
import 'package:tourn/models/user_model.dart';
import 'package:intl/intl.dart';
import 'package:tourn/data/firebase/trip_notification_helper.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tourn/domain/notification_repository/notification_repository.dart';
import 'package:tourn/Ui/main/category/home/widgets/share_sheet.dart';
import 'package:tourn/Ui/main/category/home/widgets/image_gallery_page.dart';
import 'package:tourn/Ui/main/category/home/widgets/profile/edit_post_page.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_items/widgets/kholuutru_page.dart';
import 'package:tourn/Ui/main/category/home/widgets/story/story_avatar.dart';

enum HomeFeedFilter { suggested, friends, following, explore }

class FirebaseNewfeed extends StatefulWidget {
  final HomeFeedFilter filter;

  const FirebaseNewfeed({super.key, this.filter = HomeFeedFilter.suggested});

  @override
  State<FirebaseNewfeed> createState() => _FirebaseNewfeedState();
}

class _FirebaseNewfeedState extends State<FirebaseNewfeed> {
  final FirestorePostRepository _postRepository = FirestorePostRepository();
  final FirebaseAccountService _accountService = FirebaseAccountService();
  List<PostModel> _cachedPosts = [];
  Stream<List<PostModel>>? _feedStream;
  late final UserRepository _userRepository;
  final Map<String, bool> _authorPrivateCache = {};
  final Set<String> _privacyLoading = {};

  Map<String, DateTime> _viewedPostTimes = {};

  static const String _viewedTimesKeyPrefix = 'home_viewed_post_times';

  @override
  void initState() {
    super.initState();
    _userRepository = context.read<UserRepository>();
    // Cache stream để tránh tạo mới mỗi build
    _feedStream = _postRepository.getPublicFeed(limit: 50);
    _loadViewedPostState();
  }

  Future<void> _loadViewedPostState() async {
    final uid = _postRepository.currentUserId;
    if (uid == null) return;

    final prefs = await SharedPreferences.getInstance();
    final timesRaw = prefs.getString('${_viewedTimesKeyPrefix}_$uid');

    final Map<String, DateTime> parsedTimes = {};

    if (timesRaw != null && timesRaw.isNotEmpty) {
      final decoded = jsonDecode(timesRaw) as Map<String, dynamic>;
      for (final entry in decoded.entries) {
        final ms = (entry.value as num?)?.toInt();
        if (ms != null) {
          parsedTimes[entry.key] = DateTime.fromMillisecondsSinceEpoch(ms);
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _viewedPostTimes = parsedTimes;
    });
  }

  Future<void> _persistViewedPostState() async {
    final uid = _postRepository.currentUserId;
    if (uid == null) return;

    final prefs = await SharedPreferences.getInstance();
    final times = <String, int>{
      for (final entry in _viewedPostTimes.entries)
        entry.key: entry.value.millisecondsSinceEpoch,
    };
    await prefs.setString('${_viewedTimesKeyPrefix}_$uid', jsonEncode(times));
  }

  Future<void> _markPostAsViewed(PostModel post) async {
    if (post.id.isEmpty) return;

    final now = DateTime.now();
    final updatedTimes = <String, DateTime>{..._viewedPostTimes, post.id: now};

    setState(() {
      _viewedPostTimes = updatedTimes;
    });

    await _persistViewedPostState();
  }

  bool _ensureSignedIn() {
    if (_userRepository.currentUserId != null) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cần đăng nhập để thực hiện thao tác này')),
    );
    return false;
  }

  Future<void> _ensurePrivacyLoaded(String uid) async {
    if (_authorPrivateCache.containsKey(uid) || _privacyLoading.contains(uid)) {
      return;
    }
    _privacyLoading.add(uid);
    try {
      final isPrivate = await FirebaseUserService().isPrivateAccount(uid);
      if (!mounted) return;
      setState(() {
        _authorPrivateCache[uid] = isPrivate;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _authorPrivateCache[uid] = false;
      });
    } finally {
      _privacyLoading.remove(uid);
    }
  }

  bool _shouldHidePost(PostModel post, UserModel? currentUser) {
    final currentId = _userRepository.currentUserId;
    if (currentId != null && post.authorId == currentId) return false;

    final isPrivate = _authorPrivateCache[post.authorId];
    if (isPrivate == null) {
      _ensurePrivacyLoaded(post.authorId);
      return true;
    }

    if (!isPrivate) return false;

    final following = currentUser?.following ?? const <String>[];
    return !following.contains(post.authorId);
  }

  int _priorityForAuthor({
    required String authorId,
    required String currentUid,
    required Set<String> following,
    required Set<String> followers,
  }) {
    if (authorId == currentUid) return 0;
    final isFriend =
        following.contains(authorId) && followers.contains(authorId);
    if (isFriend) return 1;
    if (following.contains(authorId)) return 2;
    return 3;
  }

  double _engagementScore(PostModel post) {
    return (post.likes.length * 2.0) +
        (post.commentCount * 3.0) +
        (post.shareCount * 4.0);
  }

  double _freshnessScore(PostModel post) {
    final ageHours = DateTime.now().difference(post.createdAt).inHours;
    if (ageHours <= 24) {
      // strong boost for first 24h
      return 1200 - (ageHours * 20).toDouble();
    }
    // gradually decay for older posts
    return (300 - ageHours).clamp(0, 300).toDouble();
  }

  double _viewRecencyPenalty(PostModel post) {
    final viewedAt = _viewedPostTimes[post.id];
    if (viewedAt == null) return 0;

    final minutesSinceViewed = DateTime.now().difference(viewedAt).inMinutes;
    if (minutesSinceViewed <= 30) return 900;
    if (minutesSinceViewed <= 180) return 550;
    if (minutesSinceViewed <= 720) return 280;
    if (minutesSinceViewed <= 1440) return 150;
    return 60;
  }

  double _contentTypeBoost(PostModel post) {
    double score = 0;
    if (post.mediaUrls.isNotEmpty) score += 40;
    if (post.experienceEntries.isNotEmpty) score += 30;
    if (post.tripId != null && post.tripId!.isNotEmpty) score += 20;
    return score;
  }

  double _stableJitter(PostModel post) {
    final bucket = DateTime.now().millisecondsSinceEpoch ~/ (1000 * 60 * 30);
    final seed = post.id.hashCode ^ bucket;
    final normalized = (seed.abs() % 1000) / 1000.0;
    return normalized * 18;
  }

  double _feedScore(PostModel post) {
    return _freshnessScore(post) +
        _engagementScore(post) +
        _contentTypeBoost(post) +
        _stableJitter(post) -
        _viewRecencyPenalty(post);
  }

  List<PostModel> _diversifyByAuthor(List<PostModel> sortedPosts) {
    final Map<String, List<PostModel>> byAuthor = {};
    for (final post in sortedPosts) {
      byAuthor.putIfAbsent(post.authorId, () => []).add(post);
    }

    final authors = byAuthor.keys.toList()
      ..sort((a, b) {
        final topA = byAuthor[a]!.first;
        final topB = byAuthor[b]!.first;
        return _feedScore(topB).compareTo(_feedScore(topA));
      });

    final result = <PostModel>[];
    bool addedInRound = true;
    while (addedInRound) {
      addedInRound = false;
      for (final author in authors) {
        final queue = byAuthor[author]!;
        if (queue.isEmpty) continue;
        result.add(queue.removeAt(0));
        addedInRound = true;
      }
    }

    return result;
  }

  List<PostModel> _sortPosts(List<PostModel> posts, UserModel? user) {
    final uid = _postRepository.currentUserId;
    if (uid == null) {
      final fallback = List<PostModel>.from(posts)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return fallback;
    }

    final following = (user?.following ?? const <String>[]).toSet();
    final followers = (user?.followers ?? const <String>[]).toSet();

    final own = <PostModel>[];
    final friends = <PostModel>[];
    final followingOnly = <PostModel>[];
    final others = <PostModel>[];

    for (final post in posts) {
      final priority = _priorityForAuthor(
        authorId: post.authorId,
        currentUid: uid,
        following: following,
        followers: followers,
      );
      if (priority == 0) {
        own.add(post);
      } else if (priority == 1) {
        friends.add(post);
      } else if (priority == 2) {
        followingOnly.add(post);
      } else {
        others.add(post);
      }
    }

    List<PostModel> rankByViewedThenRecent(List<PostModel> list) {
      final unviewed =
          list.where((p) => !_viewedPostTimes.containsKey(p.id)).toList()
            ..sort((a, b) => _feedScore(b).compareTo(_feedScore(a)));
      final viewed =
          list.where((p) => _viewedPostTimes.containsKey(p.id)).toList()
            ..sort((a, b) => _feedScore(b).compareTo(_feedScore(a)));

      final diversifiedUnviewed = _diversifyByAuthor(unviewed);
      final diversifiedViewed = _diversifyByAuthor(viewed);

      return [...diversifiedUnviewed, ...diversifiedViewed];
    }

    return [
      ...rankByViewedThenRecent(own),
      ...rankByViewedThenRecent(friends),
      ...rankByViewedThenRecent(followingOnly),
      ...rankByViewedThenRecent(others),
    ];
  }

  List<PostModel> _applyFilter(List<PostModel> posts, UserModel? user) {
    final uid = _postRepository.currentUserId;
    if (uid == null) {
      if (widget.filter == HomeFeedFilter.explore) {
        final sorted = List<PostModel>.from(posts)
          ..sort((a, b) => _feedScore(b).compareTo(_feedScore(a)));
        return _diversifyByAuthor(sorted);
      }
      return _sortPosts(posts, user);
    }

    final following = (user?.following ?? const <String>[]).toSet();
    final followers = (user?.followers ?? const <String>[]).toSet();
    final friends = following.intersection(followers);

    switch (widget.filter) {
      case HomeFeedFilter.suggested:
        return _sortPosts(posts, user);
      case HomeFeedFilter.friends:
        return posts
            .where((p) => p.authorId != uid && friends.contains(p.authorId))
            .toList();
      case HomeFeedFilter.following:
        return posts
            .where((p) => p.authorId != uid && following.contains(p.authorId))
            .toList();
      case HomeFeedFilter.explore:
        final sorted = List<PostModel>.from(posts)
          ..sort((a, b) => _feedScore(b).compareTo(_feedScore(a)));
        return _diversifyByAuthor(sorted);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel?>(
      stream: _userRepository.streamCurrentUser(),
      builder: (context, userSnapshot) {
        final currentUser = userSnapshot.data;

        return StreamBuilder<List<PostModel>>(
          stream: _feedStream,
          builder: (context, snapshot) {
            final rawPosts = snapshot.data ?? const <PostModel>[];
            final filteredPosts = rawPosts
                .where((post) => !_shouldHidePost(post, currentUser))
                .toList();

            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              _cachedPosts = _applyFilter(filteredPosts, currentUser);
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              if (_cachedPosts.isNotEmpty) {
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 8,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final post = _cachedPosts[index];
                      return FirebasePostCard(
                        post: post,
                        onViewed: _markPostAsViewed,
                      );
                    }, childCount: _cachedPosts.length),
                  ),
                );
              }
              return const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              return SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Lỗi: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            final posts = _applyFilter(filteredPosts, currentUser);

            if (posts.isEmpty) {
              return const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.article_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Chưa có bài viết nào',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Hãy là người đầu tiên chia sẻ!',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final post = posts[index];
                  return FirebasePostCard(
                    post: post,
                    onViewed: _markPostAsViewed,
                  );
                }, childCount: posts.length),
              ),
            );
          },
        );
      },
    );
  }
}

class FirebasePostCard extends StatefulWidget {
  final PostModel post;
  final ValueChanged<PostModel>? onViewed;

  const FirebasePostCard({super.key, required this.post, this.onViewed});

  @override
  State<FirebasePostCard> createState() => _FirebasePostCardState();
}

class _FirebasePostCardState extends State<FirebasePostCard> {
  final FirestorePostRepository _postRepository = FirestorePostRepository();
  final FirestoreUserRepository _userRepository = FirestoreUserRepository();
  final FirebaseActivityService _activityService = FirebaseActivityService();
  late bool _isLiked;
  bool _isLoading = false;
  bool _isOwnPost = false;

  bool _ensureSignedIn() {
    if (_userRepository.currentUserId != null) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cần đăng nhập để thực hiện thao tác này')),
    );
    return false;
  }

  // whether current user has already joined the associated trip
  bool get _hasJoinedTrip {
    if (_associatedTrip == null) return false;
    final uid = _menuService.currentUserId;
    return uid != null && _associatedTrip!.members.contains(uid);
  }

  Future<void> _confirmAndJoin() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Xác nhận tham gia'),
        content: const Text('Bạn có chắc muốn tham gia chuyến đi này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _joinTrip();
    }
  }

  bool _isFollowing = false;
  bool _hasRequestedFollow = false;
  bool _authorPrivate = false;
  bool _isAuthorBlocked = false; // hide card if author is blocked
  final FirebaseMenuService _menuService = FirebaseMenuService();
  TripModel? _associatedTrip;
  StreamSubscription<TripModel?>? _tripSubscription;

  // helper for navigation / sharing
  void _openComments(PostModel post) {
    widget.onViewed?.call(post);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => Baiviet(postId: post.id)),
    );
  }

  Future<void> _openShareSheet(PostModel post) async {
    showFacebookShareSheet(
      context,
      postModel: post,
      postRepository: _postRepository,
      userRepository: _userRepository,
      onShareSuccess: () {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void initState() {
    super.initState();
    // Check locally from post data - no Firebase call needed
    final uid = _postRepository.currentUserId;
    _isLiked = uid != null && widget.post.likes.contains(uid);
    _isOwnPost = uid == widget.post.authorId;
    _checkFollowing();
    _loadAuthorPrivacy();
    _loadFollowRequestStatus();

    // immediately check whether we've blocked this author so we can drop
    // the card as early as possible.
    _checkAuthorBlocked();

    // also start loading this author's posts into repository cache so
    // tapping profile later is instantaneous
    _postRepository
        .getUserPosts(widget.post.authorId)
        .first
        .catchError((_) => <PostModel>[]);

    // if this post is associated with a trip, listen to real-time updates
    if (widget.post.tripId != null) {
      _tripSubscription = _menuService
          .getTripStreamById(widget.post.tripId!)
          .listen((t) {
            if (mounted) {
              setState(() {
                _associatedTrip = t;
              });
            }
          });
    }
  }

  @override
  void dispose() {
    _tripSubscription?.cancel();
    super.dispose();
  }

  Future<void> _navigateToProfile(String authorId) async {
    if (authorId.isEmpty) return;
    final cached = _postRepository.getCachedUserPosts(authorId);
    if (cached == null || cached.isEmpty) {
      try {
        await _postRepository.getUserPosts(authorId).first;
      } catch (_) {}
    }
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (c) => Profile(userId: authorId)),
      );
    }
  }

  Future<void> _checkFollowing() async {
    if (_isOwnPost) return;
    try {
      final following = await _userRepository.isFollowing(widget.post.authorId);
      if (mounted) {
        setState(() {
          _isFollowing = following;
          if (following) {
            _hasRequestedFollow = false;
          }
        });
      }
    } catch (e) {
      // Ignore errors
    }
  }

  Future<void> _loadAuthorPrivacy() async {
    if (_isOwnPost) return;
    try {
      final isPrivate = await FirebaseUserService().isPrivateAccount(
        widget.post.authorId,
      );
      if (!mounted) return;
      setState(() {
        _authorPrivate = isPrivate;
      });
    } catch (_) {
      // Ignore errors
    }
  }

  Future<void> _loadFollowRequestStatus() async {
    if (_isOwnPost) return;
    try {
      final requested = await _userRepository.isFollowRequested(
        widget.post.authorId,
      );
      if (!mounted) return;
      setState(() {
        _hasRequestedFollow = requested;
      });
    } catch (_) {
      // Ignore errors
    }
  }

  Future<void> _checkAuthorBlocked() async {
    if (widget.post.authorId.isEmpty) return;
    final blocked = await FirebaseUserService().isBlocked(widget.post.authorId);
    if (blocked && mounted) {
      setState(() {
        _isAuthorBlocked = true;
      });
    }
  }

  Future<void> _toggleLike() async {
    if (!_ensureSignedIn()) return;
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isLiked) {
        await _postRepository.unlikePost(widget.post.id);
      } else {
        await _postRepository.likePost(widget.post.id);
      }

      if (mounted) {
        setState(() {
          _isLiked = !_isLiked;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  IconData _audienceIcon(PostAudience audience) {
    switch (audience) {
      case PostAudience.public:
        return Icons.public;
      case PostAudience.friends:
        return Icons.people;
      case PostAudience.onlyMe:
        return Icons.lock;
    }
  }

  // Build rich text with clickable hashtags (#) and mentions (@)
  Widget _buildRichContent(
    String content, {
    TextStyle? baseStyle,
    TextAlign? textAlign,
  }) {
    final style =
        baseStyle ??
        const TextStyle(fontSize: 15, color: Color(0xFF1a1a1a), height: 1.4);

    // Regex to match hashtags (#word) and mentions (@Name with Vietnamese support)
    // Hashtag: # followed by word characters
    // Mention: @ followed by Vietnamese name (words starting with uppercase letters)
    final pattern = RegExp(
      r'(#[a-zA-Z0-9_àáảãạăắằẳẵặâấầẩẫậèéẻẽẹêếềểễệìíỉĩịòóỏõọôốồổỗộơớờởỡợùúủũụưứừửữựỳýỷỹỵđĐ]+|@[A-ZĐÀÁẢÃẠĂẮẰẲẴẶÂẤẦẨẪẬÈÉẺẼẸÊẾỀỂỄỆÌÍỈĨỊÒÓỎÕỌÔỐỒỔỖỘƠỚỜỞỠỢÙÚỦŨỤƯỨỪỬỮỰỲÝỶỸỴ][a-zA-ZàáảãạăắằẳẵặâấầẩẫậèéẻẽẹêếềểễệìíỉĩịòóỏõọôốồổỗộơớờởỡợùúủũụưứừửữựỳýỷỹỵđĐ]*(?:\s+[A-ZĐÀÁẢÃẠĂẮẰẲẴẶÂẤẦẨẪẬÈÉẺẼẸÊẾỀỂỄỆÌÍỈĨỊÒÓỎÕỌÔỐỒỔỖỘƠỚỜỞỠỢÙÚỦŨỤƯỨỪỬỮỰỲÝỶỸỴ][a-zA-ZàáảãạăắằẳẵặâấầẩẫậèéẻẽẹêếềểễệìíỉĩịòóỏõọôốồổỗộơớờởỡợùúủũụưứừửữựỳýỷỹỵđĐ]*)*)',
    );
    final matches = pattern.allMatches(content);

    if (matches.isEmpty) {
      return Text(content, style: style, textAlign: textAlign);
    }

    final spans = <InlineSpan>[];
    int lastEnd = 0;

    for (final match in matches) {
      // Add text before the match
      if (match.start > lastEnd) {
        spans.add(
          TextSpan(text: content.substring(lastEnd, match.start), style: style),
        );
      }

      final matchedText = match.group(0)!;
      final isHashtag = matchedText.startsWith('#');

      spans.add(
        TextSpan(
          text: matchedText,
          style: style.copyWith(
            color: Colors.orange,
            fontWeight: FontWeight.w500,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              if (isHashtag) {
                _navigateToHashtagSearch(matchedText.substring(1));
              } else {
                _navigateToMentionProfile(matchedText.substring(1).trim());
              }
            },
        ),
      );

      lastEnd = match.end;
    }

    // Add remaining text after last match
    if (lastEnd < content.length) {
      spans.add(TextSpan(text: content.substring(lastEnd), style: style));
    }

    return RichText(
      text: TextSpan(children: spans),
      textAlign: textAlign ?? TextAlign.start,
    );
  }

  // Navigate to hashtag search page
  void _navigateToHashtagSearch(String hashtag) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (c) => _HashtagSearchPage(hashtag: hashtag)),
    );
  }

  // Navigate to mentioned user profile
  Future<void> _navigateToMentionProfile(String displayName) async {
    try {
      // Search for user by display name
      final users = await _userRepository.searchUsers(displayName);

      if (users.isNotEmpty && mounted) {
        // Try to find exact match first
        final exactMatch = users.firstWhere(
          (u) => u.displayName.toLowerCase() == displayName.toLowerCase(),
          orElse: () => users.first,
        );

        Navigator.push(
          context,
          MaterialPageRoute(builder: (c) => Profile(userId: exactMatch.uid)),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không tìm thấy người dùng "$displayName"')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuthorBlocked) {
      return const SizedBox.shrink();
    }
    final post = widget.post;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Avatar (tap to open profile)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) => Profile(
                              showBottomNav: true,
                              initialTab: 0,
                              userId: post.authorId,
                            ),
                          ),
                        );
                      },
                      child: StoryAvatar(
                        userId: post.authorId,
                        photoUrl: post.authorPhotoUrl,
                        userName: post.authorName,
                        radius: 22,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  Profile(initialTab: 0, userId: post.authorId),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Author & time
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              _navigateToProfile(post.authorId);
                            },
                            child: Text(
                              post.authorName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF1a1a1a),
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                _formatTimeAgo(post.createdAt),
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                _audienceIcon(post.audience),
                                size: 14,
                                color: Colors.grey[500],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Follow button - only show if not own post and not following
                    if (!_isOwnPost && !_isFollowing)
                      GestureDetector(
                        onTap: () async {
                          if (!_ensureSignedIn()) return;
                          try {
                            if (_hasRequestedFollow) {
                              await _userRepository.cancelFollowRequest(
                                widget.post.authorId,
                              );
                              if (mounted) {
                                setState(() {
                                  _hasRequestedFollow = false;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Đã hủy yêu cầu theo dõi'),
                                  ),
                                );
                              }
                              return;
                            }

                            if (_authorPrivate) {
                              await _userRepository.requestFollow(
                                widget.post.authorId,
                              );
                              if (mounted) {
                                setState(() {
                                  _hasRequestedFollow = true;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Đã gửi yêu cầu theo dõi'),
                                  ),
                                );
                              }
                              return;
                            }

                            await _userRepository.followUser(
                              widget.post.authorId,
                            );
                            if (mounted) {
                              setState(() {
                                _isFollowing = true;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Đã theo dõi ${widget.post.authorName}',
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Lỗi: ${e.toString()}')),
                              );
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _hasRequestedFollow
                                ? Colors.grey[300]
                                : const Color(0xFFFFB620),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _hasRequestedFollow ? 'Đã gửi' : 'Theo dõi',
                            style: TextStyle(
                              color: _hasRequestedFollow
                                  ? Colors.black
                                  : Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(width: 4),
                    // Menu button (available for every post)
                    IconButton(
                      icon: Icon(Icons.more_horiz, color: Colors.grey[600]),
                      onPressed: () {
                        if (_isOwnPost) {
                          _showPostOptions(context);
                        } else {
                          _showPostOptions(
                            context,
                          ); // this method already handles other posts via _isOwnPost flag
                        }
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ], // close inner Column children
            ), // close inner Column
          ),

          // Content - hiển thị trên ảnh (như Facebook)
          if (post.content.isNotEmpty &&
              (post.mediaUrls.isNotEmpty || post.backgroundColor == null))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _buildRichContent(post.content),
            ),

          // Hiển thị bài viết gốc được chia sẻ (embedded shared post - Facebook style)
          if (post.isSharedPost && post.sharedPostData != null)
            _buildEmbeddedSharedPost(post.sharedPostData!),

          // Media section (không có text overlay) - chỉ hiển thị khi không phải shared post
          if (post.mediaUrls.isNotEmpty && !post.isSharedPost)
            _buildMediaSection(post.mediaUrls, post.layoutIndex),

          // Background color post (no media)
          if (post.mediaUrls.isEmpty && post.backgroundColor != null)
            Builder(
              builder: (context) {
                final bgColor = _parseBackgroundColor(post.backgroundColor);
                // Calculate text color based on background luminance
                final textColor = bgColor.computeLuminance() > 0.5
                    ? Colors.black
                    : Colors.white;
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 60,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _buildRichContent(
                    post.content,
                    baseStyle: TextStyle(
                      fontSize: 24,
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),

          // Experience entries section
          if (post.experienceEntries.isNotEmpty)
            _buildExperienceSection(post.experienceEntries),

          // show join/details buttons if this post is tied to a trip
          if (post.tripId != null && _associatedTrip != null)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Trip name
                  Text(
                    _associatedTrip!.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Starting location (điểm đi)
                  if (_associatedTrip!.startingLocation.isNotEmpty)
                    _buildTripInfoRow(
                      Icons.trip_origin,
                      'Tập trung: ${_associatedTrip!.startingLocation}',
                    ),
                  // Destination (điểm đến)
                  _buildTripInfoRow(
                    Icons.location_on,
                    'Điểm đến: ${_associatedTrip!.location.isNotEmpty ? _associatedTrip!.location : "Chưa có"}',
                  ),
                  // Date range
                  _buildTripInfoRow(
                    Icons.calendar_today,
                    '${DateFormat('dd/MM/yyyy').format(_associatedTrip!.startDate)} - ${DateFormat('dd/MM/yyyy').format(_associatedTrip!.endDate)}',
                  ),
                  // Cost - tappable if has costBreakdown (smart budget)
                  if (_associatedTrip!.estimatedCost != null)
                    _associatedTrip!.costBreakdown.isNotEmpty
                        ? GestureDetector(
                            onTap: _showCostBreakdown,
                            child: _buildTripInfoRow(
                              Icons.attach_money,
                              'Chi phí: ${_formatCurrency(_associatedTrip!.estimatedCost!)}',
                              isClickable: true,
                            ),
                          )
                        : _buildTripInfoRow(
                            Icons.attach_money,
                            'Chi phí: ${_formatCurrency(_associatedTrip!.estimatedCost!)}',
                          ),
                  // Members - tappable to view member list
                  GestureDetector(
                    onTap: _showMembersList,
                    child: _buildTripInfoRow(
                      Icons.people,
                      '${_associatedTrip!.members.length}/${_associatedTrip!.maxMembers} thành viên',
                      isClickable: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Buttons - hide Join if user is the post author or already a member
                  Row(
                    children: [
                      if (!_isOwnPost && !_hasJoinedTrip)
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _confirmAndJoin,
                            child: const Text('Tham gia'),
                          ),
                        ),
                      if (!_isOwnPost && !_hasJoinedTrip)
                        const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange,
                            side: const BorderSide(color: Colors.orange),
                          ),
                          onPressed: _viewTripDetails,
                          child: const Text('Xem chi tiết'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          // Stats row - only show for non-trip posts
          if (post.tripId == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  // Like
                  GestureDetector(
                    onTap: _toggleLike,
                    child: Row(
                      children: [
                        Icon(
                          _isLiked ? Icons.favorite : Icons.favorite_border,
                          size: 22,
                          color: _isLiked ? Colors.red : Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${post.likes.length}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Comment
                  GestureDetector(
                    onTap: () => _openComments(post),
                    child: Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 20,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${post.commentCount}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Share
                  GestureDetector(
                    onTap: () => _openShareSheet(post),
                    child: Row(
                      children: [
                        Icon(
                          Icons.share_outlined,
                          size: 20,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${post.shareCount}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          // Bottom spacing for trip posts
          if (post.tripId != null) const SizedBox(height: 16),
        ],
      ),
    );
  }

  Color _parseBackgroundColor(String? backgroundColor) {
    if (backgroundColor == null) return Colors.transparent;
    try {
      final colorInt = int.tryParse(backgroundColor);
      if (colorInt != null) {
        return Color(colorInt);
      }
    } catch (e) {
      // Ignore
    }
    return Colors.blue;
  }

  // Helper to build image from URL (supports both network URL and base64 data URL)
  Widget _buildImage(
    String url, {
    BoxFit fit = BoxFit.cover,
    Widget? errorWidget,
  }) {
    if (url.startsWith('data:')) {
      // Base64 data URL
      try {
        final base64String = url.split(',').last;
        final bytes = base64Decode(base64String);
        return Image.memory(
          Uint8List.fromList(bytes),
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return errorWidget ??
                Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 48,
                      color: Colors.grey,
                    ),
                  ),
                );
          },
        );
      } catch (e) {
        return errorWidget ??
            Container(
              color: Colors.grey[300],
              child: const Center(
                child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
              ),
            );
      }
    } else {
      // Network URL
      return Image.network(
        url,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ??
              Container(
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                ),
              );
        },
      );
    }
  }

  Widget _buildMediaSection(List<String> mediaUrls, int layoutIndex) {
    if (mediaUrls.isEmpty) return const SizedBox.shrink();

    final post = widget.post;

    // Wrap toàn bộ media section với GestureDetector
    return GestureDetector(
      onTap: () => _handleMediaTap(mediaUrls, 0),
      child: _buildMediaLayout(mediaUrls, layoutIndex),
    );
  }

  /// Xử lý tap vào ảnh:
  /// - 1 ảnh: mở ImageDetailViewer trực tiếp
  /// - Nhiều ảnh: mở ImageGalleryPage
  void _handleMediaTap(List<String> mediaUrls, int index) {
    final post = widget.post;
    widget.onViewed?.call(post);

    if (mediaUrls.length == 1) {
      // Chỉ có 1 ảnh -> xem chi tiết luôn
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImageDetailViewer(
            mediaUrls: mediaUrls,
            initialIndex: 0,
            authorName: post.authorName,
            post: post,
          ),
        ),
      );
    } else {
      // Nhiều ảnh -> mở gallery page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImageGalleryPage(
            mediaUrls: mediaUrls,
            authorName: post.authorName,
            authorPhotoUrl: post.authorPhotoUrl,
            content: post.content,
            createdAt: post.createdAt,
            initialIndex: index,
            post: post,
          ),
        ),
      );
    }
  }

  Widget _buildMediaLayout(List<String> mediaUrls, int layoutIndex) {
    // Sử dụng layout theo layoutIndex
    // 0: Grid 2 cột, 1: Ảnh đơn, 2: Cuộn ngang, 3: 1 lớn + 2 nhỏ
    switch (layoutIndex) {
      case 1: // Ảnh đơn - hiển thị từng ảnh
        return _buildSingleImageLayout(mediaUrls);
      case 2: // Cuộn ngang
        return _buildHorizontalScrollLayout(mediaUrls);
      case 3: // 1 lớn + 2 nhỏ
        return _buildOneBigTwoSmallLayout(mediaUrls);
      case 0: // Grid 2 cột
      default:
        return _buildGrid2ColumnsLayout(mediaUrls);
    }
  }

  // Layout 0: Grid 2 cột
  Widget _buildGrid2ColumnsLayout(List<String> mediaUrls) {
    if (mediaUrls.length == 1) {
      return AspectRatio(aspectRatio: 1, child: _buildImage(mediaUrls.first));
    }

    return AspectRatio(
      aspectRatio: 1,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: mediaUrls.length > 4 ? 4 : mediaUrls.length,
        itemBuilder: (context, index) {
          final isLast = index == 3 && mediaUrls.length > 4;
          return GestureDetector(
            onTap: () => _handleMediaTap(mediaUrls, index),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildImage(mediaUrls[index]),
                if (isLast)
                  Container(
                    color: Colors.black54,
                    child: Center(
                      child: Text(
                        '+${mediaUrls.length - 3}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
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

  // Layout 1: Ảnh đơn - hiển thị ảnh đầu tiên
  Widget _buildSingleImageLayout(List<String> mediaUrls) {
    return Stack(
      children: [
        AspectRatio(aspectRatio: 1, child: _buildImage(mediaUrls.first)),
        if (mediaUrls.length > 1)
          Positioned(
            right: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '+${mediaUrls.length - 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Layout 2: Cuộn ngang
  Widget _buildHorizontalScrollLayout(List<String> mediaUrls) {
    return SizedBox(
      height: 250,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: mediaUrls.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _handleMediaTap(mediaUrls, index),
            child: Padding(
              padding: EdgeInsets.only(
                left: index == 0 ? 0 : 2,
                right: index == mediaUrls.length - 1 ? 0 : 2,
              ),
              child: AspectRatio(
                aspectRatio: 1,
                child: _buildImage(mediaUrls[index]),
              ),
            ),
          );
        },
      ),
    );
  }

  // Layout 3: 1 lớn + 2 nhỏ (1 trên, 2 dưới)
  Widget _buildOneBigTwoSmallLayout(List<String> mediaUrls) {
    if (mediaUrls.length == 1) {
      return AspectRatio(aspectRatio: 1, child: _buildImage(mediaUrls.first));
    }

    if (mediaUrls.length == 2) {
      return AspectRatio(
        aspectRatio: 1,
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: () => _handleMediaTap(mediaUrls, 0),
                child: _buildImage(mediaUrls[0]),
              ),
            ),
            const SizedBox(height: 2),
            Expanded(
              child: GestureDetector(
                onTap: () => _handleMediaTap(mediaUrls, 1),
                child: _buildImage(mediaUrls[1]),
              ),
            ),
          ],
        ),
      );
    }

    // 3+ ảnh: 1 ảnh lớn trên, 2 ảnh nhỏ dưới
    return AspectRatio(
      aspectRatio: 1,
      child: Column(
        children: [
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () => _handleMediaTap(mediaUrls, 0),
              child: _buildImage(mediaUrls[0]),
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _handleMediaTap(mediaUrls, 1),
                    child: _buildImage(mediaUrls[1]),
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _handleMediaTap(mediaUrls, 2),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildImage(mediaUrls[2]),
                        if (mediaUrls.length > 3)
                          Container(
                            color: Colors.black54,
                            child: Center(
                              child: Text(
                                '+${mediaUrls.length - 3}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- embedded shared post (Facebook-style) ----------
  Widget _buildEmbeddedSharedPost(Map<String, dynamic> sharedData) {
    final originalAuthorName =
        sharedData['authorName'] as String? ?? 'Người dùng';
    final originalAuthorPhotoUrl = sharedData['authorPhotoUrl'] as String?;
    final originalContent = sharedData['content'] as String? ?? '';
    final originalMediaUrls =
        (sharedData['mediaUrls'] as List<dynamic>?)?.cast<String>() ?? [];
    final originalBackgroundColor = sharedData['backgroundColor'] as String?;
    final originalLayoutIndex = sharedData['layoutIndex'] as int? ?? 0;
    final originalCreatedAtStr = sharedData['createdAt'] as String?;
    final originalPostId = sharedData['id'] as String?;

    DateTime? originalCreatedAt;
    if (originalCreatedAtStr != null) {
      try {
        originalCreatedAt = DateTime.parse(originalCreatedAtStr);
      } catch (_) {}
    }

    final hasBackgroundColor =
        originalBackgroundColor != null &&
        originalBackgroundColor != 'none' &&
        originalMediaUrls.isEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () {
          widget.onViewed?.call(widget.post);
          if (originalPostId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Baiviet(postId: originalPostId),
              ),
            );
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header của bài viết gốc
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      final authorId = sharedData['authorId'] as String?;
                      if (authorId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) => Profile(userId: authorId),
                          ),
                        );
                      }
                    },
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.grey[200],
                      backgroundImage:
                          originalAuthorPhotoUrl != null &&
                              originalAuthorPhotoUrl.isNotEmpty
                          ? getImageProvider(originalAuthorPhotoUrl)
                          : const AssetImage('asset/images/OIP.jpg')
                                as ImageProvider,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () {
                            final authorId = sharedData['authorId'] as String?;
                            if (authorId != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (c) => Profile(userId: authorId),
                                ),
                              );
                            }
                          },
                          child: Text(
                            originalAuthorName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (originalCreatedAt != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                _formatTimeAgo(originalCreatedAt),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.public,
                                size: 12,
                                color: Colors.grey[600],
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Nội dung bài viết gốc
            if (hasBackgroundColor)
              Builder(
                builder: (context) {
                  final bgColor = _parseBackgroundColor(
                    originalBackgroundColor,
                  );
                  final textColor = bgColor.computeLuminance() > 0.5
                      ? Colors.black
                      : Colors.white;
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 40,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(color: bgColor),
                    child: _buildRichContent(
                      originalContent,
                      baseStyle: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              )
            else if (originalContent.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: _buildRichContent(
                  originalContent,
                  baseStyle: const TextStyle(fontSize: 14),
                ),
              ),

            // Media của bài viết gốc
            if (originalMediaUrls.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 0),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(11),
                    bottomRight: Radius.circular(11),
                  ),
                  child: _buildMediaSection(
                    originalMediaUrls,
                    originalLayoutIndex,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Build experience entries section (Kinh nghiệm, Lịch trình, Chi tiêu, etc.)
  Widget _buildExperienceSection(List<Map<String, dynamic>> entries) {
    if (entries.isEmpty) return const SizedBox.shrink();

    // Group entries by category
    final Map<String, List<String>> groupedEntries = {};
    for (final entry in entries) {
      final category = entry['category'] as String? ?? 'Khác';
      final content = entry['content'] as String? ?? '';
      final title = entry['title'] as String?;

      final displayCategory =
          category == 'Khác' && title != null && title.isNotEmpty
          ? title
          : category;

      if (!groupedEntries.containsKey(displayCategory)) {
        groupedEntries[displayCategory] = [];
      }
      groupedEntries[displayCategory]!.add(content);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: groupedEntries.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.key,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF1a1a1a),
                  ),
                ),
                const SizedBox(height: 4),
                ...entry.value.map(
                  (content) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      content,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showPostOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: _isOwnPost
            ? _buildOwnPostOptions(context)
            : _buildOtherPostOptions(context),
      ),
    );
  }

  List<Widget> _buildOwnPostOptions(BuildContext context) {
    final post = widget.post;
    // Capture navigator before sheet closes
    final navigator = Navigator.of(context, rootNavigator: true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    return [
      ListTile(
        leading: const Icon(Icons.bookmark_border),
        title: const Text('Lưu bài viết'),
        onTap: () async {
          Navigator.pop(context);
          try {
            await _activityService.savePost(post.id);
            if (mounted) {
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: const Text('Đã lưu bài viết'),
                  action: SnackBarAction(
                    label: 'Xem',
                    onPressed: () {
                      navigator.push(
                        MaterialPageRoute(
                          builder: (_) => const KhoLuuTruPage(),
                        ),
                      );
                    },
                  ),
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              scaffoldMessenger.showSnackBar(
                SnackBar(content: Text('Lỗi khi lưu bài viết: $e')),
              );
            }
          }
        },
      ),
      ListTile(
        leading: const Icon(Icons.edit_outlined),
        title: const Text('Chỉnh sửa bài viết'),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditPostPage(
                post: {
                  'content': post.content,
                  'images': post.mediaUrls,
                  'privacy': post.audience.name,
                  'allowComments': post.allowComments,
                },
                onSave: (updatedPost) async {
                  final postModel = post.copyWith(
                    content: updatedPost['content'] as String? ?? post.content,
                    audience: PostAudience.values.firstWhere(
                      (e) =>
                          e.name ==
                          (updatedPost['privacy'] as String? ??
                              post.audience.name),
                      orElse: () => post.audience,
                    ),
                    allowComments:
                        updatedPost['allowComments'] as bool? ??
                        post.allowComments,
                  );
                  await _postRepository.updatePost(postModel);
                },
              ),
            ),
          );
        },
      ),
      ListTile(
        leading: const Icon(Icons.public),
        title: const Text('Chỉnh sửa quyền riêng tư'),
        subtitle: Text(
          _getAudienceText(post.audience),
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        onTap: () {
          Navigator.pop(context);
          _showPrivacyOptions(context);
        },
      ),
      ListTile(
        leading: const Icon(Icons.chat_bubble_outline),
        title: const Text('Chỉnh sửa quyền bình luận về bài viết'),
        subtitle: Text(
          post.allowComments ? 'Mọi người' : 'Đã tắt',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        onTap: () async {
          Navigator.pop(context);
          final allow = post.allowComments;
          await _postRepository.setAllowComments(post.id, !allow);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(!allow ? 'Đã bật bình luận' : 'Đã tắt bình luận'),
              ),
            );
          }
        },
      ),
      ListTile(
        leading: const Icon(Icons.delete_outline, color: Colors.red),
        title: const Text('Xóa bài viết', style: TextStyle(color: Colors.red)),
        onTap: () {
          Navigator.pop(context);
          _showDeleteConfirmation(context);
        },
      ),
      ListTile(
        leading: const Icon(Icons.photo_album_outlined),
        title: const Text('Thêm vào album'),
        onTap: () async {
          Navigator.pop(context);
          final albumName = await showDialog<String>(
            context: context,
            builder: (c) {
              final controller = TextEditingController();
              return AlertDialog(
                title: const Text('Tên album'),
                content: TextField(
                  controller: controller,
                  decoration: const InputDecoration(hintText: 'Nhập tên album'),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(c),
                    child: const Text('Hủy'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(c, controller.text.trim()),
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
          if (albumName != null && albumName.isNotEmpty) {
            await _postRepository.addPostToAlbum(post.id, albumName);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đã thêm vào album "$albumName"')),
              );
            }
          }
        },
      ),
      const SizedBox(height: 8),
    ];
  }

  List<Widget> _buildOtherPostOptions(BuildContext context) {
    // Capture navigator before sheet closes
    final navigator = Navigator.of(context, rootNavigator: true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    return [
      ListTile(
        leading: const Icon(Icons.bookmark_border),
        title: const Text('Lưu bài viết'),
        onTap: () async {
          Navigator.pop(context);
          try {
            await _activityService.savePost(widget.post.id);
            if (mounted) {
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: const Text('Đã lưu bài viết'),
                  action: SnackBarAction(
                    label: 'Xem',
                    onPressed: () {
                      navigator.push(
                        MaterialPageRoute(
                          builder: (_) => const KhoLuuTruPage(),
                        ),
                      );
                    },
                  ),
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              scaffoldMessenger.showSnackBar(
                SnackBar(content: Text('Lỗi khi lưu bài viết: $e')),
              );
            }
          }
        },
      ),
      ListTile(
        leading: const Icon(Icons.visibility_off),
        title: const Text('Ẩn bài viết'),
        onTap: () {
          Navigator.pop(context);
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Đã ẩn bài viết!')),
          );
        },
      ),
      ListTile(
        leading: const Icon(Icons.flag_outlined),
        title: const Text('Báo cáo bài viết'),
        onTap: () {
          Navigator.pop(context);
          _showReportDialog(context);
        },
      ),
      const SizedBox(height: 8),
    ];
  }

  String _getAudienceText(PostAudience audience) {
    switch (audience) {
      case PostAudience.public:
        return 'Công khai';
      case PostAudience.friends:
        return 'Bạn bè';
      case PostAudience.onlyMe:
        return 'Chỉ mình tôi';
    }
  }

  Future<void> _joinTrip() async {
    if (widget.post.tripId == null) return;
    final tripId = widget.post.tripId!;
    try {
      final (success, isFull, trip) = await _menuService.joinTrip(tripId);
      String message;
      if (!success) {
        if (isFull) {
          message = 'Chuyến đi đã đầy thành viên';
        } else if (trip != null &&
            trip.members.contains(_menuService.currentUserId)) {
          message = 'Bạn đã là thành viên của chuyến đi này';
        } else {
          message =
              'Không thể tham gia chuyến đi (có thể đã bắt đầu hoặc kết thúc)';
        }
      } else {
        message = 'Đã tham gia chuyến đi "${trip?.name}" thành công!';
        // Refresh the associated trip data
        if (trip != null && mounted) {
          setState(() {
            _associatedTrip = trip;
          });
        }

        // send notifications for successful join
        final uid = _menuService.currentUserId;
        if (uid != null && trip != null) {
          await TripNotificationHelper().sendJoinNotifications(
            trip: trip,
            joinerId: uid,
            isFull: trip.isFull,
          );
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _viewTripDetails() async {
    if (widget.post.tripId == null) return;
    final trip = await _menuService.getTripById(widget.post.tripId!);
    if (!mounted || trip == null) return;
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.flight_takeoff, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(child: Text(trip.name)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (trip.description.isNotEmpty) ...[
                Text(trip.description, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 12),
              ],
              _buildTripDetailRow(
                Icons.location_on,
                'Địa điểm',
                trip.location.isNotEmpty ? trip.location : 'Chưa có',
              ),
              _buildTripDetailRow(
                Icons.calendar_today,
                'Thời gian',
                '${DateFormat('dd/MM/yyyy').format(trip.startDate)} - ${DateFormat('dd/MM/yyyy').format(trip.endDate)}',
              ),
              _buildTripDetailRow(
                Icons.people,
                'Thành viên',
                '${trip.members.length}/${trip.maxMembers}',
              ),
              _buildTripDetailRow(
                Icons.info_outline,
                'Trạng thái',
                trip.statusDisplayText,
              ),
              if (trip.estimatedCost != null)
                _buildTripDetailRow(
                  Icons.attach_money,
                  'Chi phí ước tính',
                  _formatCurrency(trip.estimatedCost!),
                ),
              if (trip.startingLocation.isNotEmpty)
                _buildTripDetailRow(
                  Icons.place,
                  'Tập trung',
                  trip.startingLocation,
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(),
            child: const Text('Đóng'),
          ),
          if (!_isOwnPost && !_hasJoinedTrip)
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () async {
                Navigator.of(c).pop();
                await _confirmAndJoin();
              },
              child: const Text('Tham gia ngay'),
            ),
        ],
      ),
    );
  }

  Widget _buildTripDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.orange.shade700),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildTripInfoRow(
    IconData icon,
    String text, {
    bool isClickable = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.orange.shade700),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: isClickable
                    ? Colors.orange.shade700
                    : Colors.grey.shade600,
                decoration: isClickable ? TextDecoration.underline : null,
              ),
            ),
          ),
          if (isClickable)
            Icon(Icons.chevron_right, size: 14, color: Colors.orange.shade700),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(amount.toInt())} VNĐ';
  }

  void _showCostBreakdown() {
    if (_associatedTrip == null || _associatedTrip!.costBreakdown.isEmpty) {
      return;
    }
    final breakdown = _associatedTrip!.costBreakdown;
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.account_balance_wallet, color: Colors.orange),
            SizedBox(width: 8),
            Text('Chi tiết ngân sách'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...breakdown.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key, style: const TextStyle(fontSize: 14)),
                      Text(
                        _formatCurrency(entry.value),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tổng cộng',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _formatCurrency(_associatedTrip!.estimatedCost ?? 0),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showMembersList() async {
    if (_associatedTrip == null) return;
    final members = _associatedTrip!.members;

    // Fetch user info for all members
    final memberInfos = <String, UserModel?>{};
    for (final memberId in members) {
      memberInfos[memberId] = await _userRepository.getUserById(memberId);
    }

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.people, color: Colors.orange),
            const SizedBox(width: 8),
            Text(
              'Thành viên (${members.length}/${_associatedTrip!.maxMembers})',
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: members.isEmpty
              ? const Center(child: Text('Chưa có thành viên'))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final memberId = members[index];
                    final isOwner = memberId == _associatedTrip!.userId;
                    final user = memberInfos[memberId];
                    final displayName = user?.displayName ?? 'Người dùng';
                    final avatarUrl = user?.photoUrl;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isOwner
                            ? Colors.orange
                            : Colors.grey.shade300,
                        backgroundImage:
                            avatarUrl != null && avatarUrl.isNotEmpty
                            ? NetworkImage(avatarUrl)
                            : null,
                        child: (avatarUrl == null || avatarUrl.isEmpty)
                            ? Icon(
                                Icons.person,
                                color: isOwner
                                    ? Colors.white
                                    : Colors.grey.shade600,
                              )
                            : null,
                      ),
                      title: Text(
                        displayName,
                        style: TextStyle(
                          fontWeight: isOwner
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        memberId.length > 20
                            ? '${memberId.substring(0, 20)}...'
                            : memberId,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      trailing: isOwner
                          ? const Text(
                              'Trưởng nhóm',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            )
                          : null,
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Chọn quyền riêng tư',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.public),
            title: const Text('Công khai'),
            subtitle: const Text('Mọi người đều có thể xem'),
            onTap: () => _updatePrivacy(context, PostAudience.public),
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Bạn bè'),
            subtitle: const Text('Chỉ bạn bè mới xem được'),
            onTap: () => _updatePrivacy(context, PostAudience.friends),
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Chỉ mình tôi'),
            subtitle: const Text('Chỉ bạn mới xem được'),
            onTap: () => _updatePrivacy(context, PostAudience.onlyMe),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _updatePrivacy(
    BuildContext context,
    PostAudience audience,
  ) async {
    Navigator.pop(context);
    try {
      await _postRepository.updatePostAudience(widget.post.id, audience);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã cập nhật quyền riêng tư: ${_getAudienceText(audience)}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
      }
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa bài viết?'),
        content: const Text(
          'Bạn có chắc chắn muốn xóa bài viết này? Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _postRepository.deletePost(widget.post.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã xóa bài viết!')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Báo cáo bài viết'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Nội dung không phù hợp'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cảm ơn bạn đã báo cáo!')),
                );
              },
            ),
            ListTile(
              title: const Text('Spam/Quảng cáo'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cảm ơn bạn đã báo cáo!')),
                );
              },
            ),
            ListTile(
              title: const Text('Thông tin sai lệch'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cảm ơn bạn đã báo cáo!')),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );
  }
}

// Private page for hashtag search results
class _HashtagSearchPage extends StatelessWidget {
  final String hashtag;

  const _HashtagSearchPage({required this.hashtag});

  @override
  Widget build(BuildContext context) {
    final postRepo = FirestorePostRepository();

    return Scaffold(
      appBar: AppBar(title: Text('#$hashtag'), elevation: 0),
      body: StreamBuilder<List<PostModel>>(
        stream: postRepo.getPostsByHashtag(hashtag),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Lỗi: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final posts = snapshot.data ?? [];

          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.tag, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Không có bài viết nào với #$hashtag',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              return FirebasePostCard(post: posts[index]);
            },
          );
        },
      ),
    );
  }
}
