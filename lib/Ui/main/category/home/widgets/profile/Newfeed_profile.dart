// đây là file chứa code của phần trang chủ profile trong trang profile
// Đã tích hợp Firebase để hiển thị bài viết của người dùng hiện tại
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tourn/data/firebase/trip_notification_helper.dart';
import 'package:provider/provider.dart';
import 'package:tourn/Ui/main/category/favorites/pages/Baiviet.dart';
import 'package:tourn/Ui/main/category/home/widgets/profile/edit_post_page.dart';
import 'package:tourn/Ui/main/category/home/widgets/share_sheet.dart';
import 'package:tourn/Ui/main/category/home/widgets/image_gallery_page.dart';
import 'package:tourn/data/post/firestore_post_repository.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tourn/domain/notification_repository/notification_repository.dart';
import 'package:tourn/models/user_model.dart';
import 'package:tourn/data/firebase/firebase_menu_service.dart';
import 'package:tourn/data/firebase/firebase_activity_service.dart';
import 'package:tourn/domain/user_repository/user_repository.dart';
import 'package:tourn/models/post_model.dart';
import 'package:tourn/models/menu_models.dart';
import 'package:tourn/Ui/main/category/home/widgets/profile/Profile.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_items/widgets/kholuutru_page.dart';
import 'package:tourn/ultils.enums/image_utils.dart';

class Newfeedprofile extends StatefulWidget {
  final String? userId; // optional id of profile to display posts for

  const Newfeedprofile({super.key, this.userId});

  @override
  State<Newfeedprofile> createState() => _NewfeedprofileState();
}

class _NewfeedprofileState extends State<Newfeedprofile>
    with AutomaticKeepAliveClientMixin {
  final FirestorePostRepository postRepository = FirestorePostRepository();
  List<PostModel> _cachedPosts = [];

  bool _ensureSignedIn() {
    if (postRepository.currentUserId != null) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cần đăng nhập để thực hiện thao tác này')),
    );
    return false;
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final currentUserId = widget.userId ?? postRepository.currentUserId;

    if (currentUserId == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.login, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Vui lòng đăng nhập',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<List<PostModel>>(
      stream: postRepository.getUserPosts(currentUserId),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _cachedPosts = snapshot.data!;
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          // while waiting for data, display cache if available, otherwise show
          // simple grey placeholders so user sees something immediately
          if (_cachedPosts.isNotEmpty) {
            return _buildPostList(_cachedPosts);
          } else {
            return _buildLoadingPlaceholders();
          }
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
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
            ),
          );
        }

        final posts = snapshot.data ?? [];
        if (posts.isEmpty) {
          final viewerId = postRepository.currentUserId;
          final isOwnProfile =
              widget.userId == null || widget.userId == viewerId;
          return LayoutBuilder(
            builder: (context, constraints) {
              final minHeight = constraints.maxHeight - 80;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(40),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: minHeight > 0 ? minHeight : 0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      const Icon(
                        Icons.article_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Chưa có bài viết nào',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      if (isOwnProfile) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Hãy chia sẻ khoảnh khắc đầu tiên của bạn!',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        }

        return _buildPostList(posts);
      },
    );
  }

  Widget _buildPostList(List<PostModel> posts) {
    return ListView.builder(
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final p = posts[index];
        return ProfilePostCard(post: p, onUpdate: _handleUpdatedPost);
      },
    );
  }

  // show a few grey cards while the real data loads -- improves perceived speed
  Widget _buildLoadingPlaceholders() {
    return ListView.builder(
      itemCount: 3,
      itemBuilder: (context, _) => _PlaceholderCard(),
    );
  }

  void _handleUpdatedPost(PostModel updated) {
    // update cached list to reflect pin change
    final idx = _cachedPosts.indexWhere((p) => p.id == updated.id);
    if (idx == -1) return;
    setState(() {
      _cachedPosts.removeAt(idx);
      if (updated.isPinned) {
        _cachedPosts.insert(0, updated);
      } else {
        // insert based on createdAt ordering
        var insertPos = _cachedPosts.indexWhere(
          (p) => p.createdAt.isBefore(updated.createdAt),
        );
        if (insertPos == -1) {
          _cachedPosts.add(updated);
        } else {
          _cachedPosts.insert(insertPos, updated);
        }
      }
    });
  }
}

// small widget representing a fake post (light grey boxes)
class _PlaceholderCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 40, color: Colors.grey[300]),
            const SizedBox(height: 8),
            Container(width: 100, height: 16, color: Colors.grey[300]),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 60,
              color: Colors.grey[200],
            ),
          ],
        ),
      ),
    );
  }
}

// Card hiển thị bài viết trong profile (sử dụng Firebase)
class ProfilePostCard extends StatefulWidget {
  final PostModel post;
  final ValueChanged<PostModel>? onUpdate;

  const ProfilePostCard({super.key, required this.post, this.onUpdate});

  @override
  State<ProfilePostCard> createState() => _ProfilePostCardState();
}

class _ProfilePostCardState extends State<ProfilePostCard> {
  final FirestorePostRepository _postRepository = FirestorePostRepository();
  final FirestoreUserRepository _userRepository = FirestoreUserRepository();
  final FirebaseMenuService _menuService = FirebaseMenuService();
  final FirebaseActivityService _activityService = FirebaseActivityService();

  bool _ensureSignedIn() {
    if (_postRepository.currentUserId != null) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cần đăng nhập để thực hiện thao tác này')),
    );
    return false;
  }

  Future<void> _openShareSheet(PostModel post) async {
    final currentId = _postRepository.currentUserId;
    if (currentId == null) return;
    final me = await _userRepository.getUserById(currentId);
    if (me == null) return;

    final ids = me.followers.toSet().intersection(me.following.toSet());
    final List<UserModel> friends = [];
    for (final id in ids) {
      final u = await _userRepository.getUserById(id);
      if (u != null) friends.add(u);
    }
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: friends.map((f) {
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: f.photoUrl != null && f.photoUrl!.isNotEmpty
                    ? NetworkImage(f.photoUrl!)
                    : null,
                child: f.photoUrl == null || f.photoUrl!.isEmpty
                    ? const Icon(Icons.person)
                    : null,
              ),
              title: Text(f.displayName),
              trailing: TextButton(
                child: const Text('Chia sẻ'),
                onPressed: () async {
                  await _postRepository.sharePost(post.id);
                  try {
                    final repo = context.read<NotificationRepository>();
                    final uid = repo.currentUserId;
                    if (uid != null) {
                      await repo.sendSystemNotification(
                        recipientId: f.uid,
                        senderName: 'Trip',
                        message: 'Một người bạn đã chia sẻ bài viết với bạn.',
                      );
                    }
                  } catch (_) {}
                  if (mounted) {
                    setState(() {
                      // shareCount is final on PostModel, replace object instead
                      _post = _post.copyWith(shareCount: _post.shareCount + 1);
                    });
                    widget.onUpdate?.call(_post);
                  }
                  Navigator.pop(c);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã chia sẻ bài viết!')),
                  );
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _shareExternal(PostModel post) {
    final text = '${post.authorName} vừa đăng: ${post.content ?? ''}';
    Share.share(text);
    setState(() {
      _post = _post.copyWith(shareCount: _post.shareCount + 1);
    });
    widget.onUpdate?.call(_post);
  }

  /// Opens Facebook share dialog in browser/app using a sharer URL.
  Future<void> _shareToFacebook(PostModel post) async {
    // first-media-url as a potential link, but only if it's publicly reachable.
    String? shareUrl;
    if (post.mediaUrls.isNotEmpty) {
      final candidate = post.mediaUrls.first;
      if (candidate.startsWith('http://') || candidate.startsWith('https://')) {
        shareUrl = candidate;
      }
    }
    final quote = post.content;

    // first try to open the native Facebook app share dialog using deep link
    // the fb://facewebmodal route wraps the standard web sharer inside the app
    // and produces the familiar UI (see screenshot provided by the user).
    final webParams = <String, String>{
      if (shareUrl != null) 'u': shareUrl,
      if (quote.isNotEmpty) 'quote': quote,
    };
    final webSharer = Uri.https(
      'www.facebook.com',
      '/sharer/sharer.php',
      webParams,
    );

    // construct fb:// scheme pointing at the same page
    final fbUri = Uri.parse(
      'fb://facewebmodal/f?href=${Uri.encodeComponent(webSharer.toString())}',
    );

    if (await canLaunchUrl(fbUri)) {
      // on web this will open in same tab unless we specify window name
      await launchUrl(
        fbUri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
      return;
    }

    // fallback to web browser if app is not available
    if (await canLaunchUrl(webSharer)) {
      await launchUrl(
        webSharer,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Không thể mở Facebook')));
    }
  }

  void _showShareOptions(PostModel post) {
    showFacebookShareSheet(
      context,
      postModel: post,
      postRepository: _postRepository,
      userRepository: _userRepository,
      onShareSuccess: () {
        setState(() {
          _post = _post.copyWith(shareCount: _post.shareCount + 1);
        });
        widget.onUpdate?.call(_post);
      },
    );
  }

  // keep a mutable copy of the post so we can update it locally
  late PostModel _post = widget.post;
  late bool _isLiked;
  bool _isLoading = false;
  TripModel? _associatedTrip;
  StreamSubscription<TripModel?>? _tripSubscription;
  bool _isOwnPost = false;
  // helper to know if the current user already joined the trip
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

  // used to suppress card tap when avatar/name are pressed
  bool _suppressCardTap = false;

  @override
  void initState() {
    super.initState();
    // _post already initialized above; only need to compute _isLiked
    final uid = _postRepository.currentUserId;
    _isLiked = uid != null && _post.likes.contains(uid);
    _isOwnPost = uid != null && _post.authorId == uid;
    _loadTrip();
  }

  @override
  void dispose() {
    _tripSubscription?.cancel();
    super.dispose();
  }

  void _loadTrip() {
    if (_post.tripId == null) return;
    _tripSubscription = _menuService.getTripStreamById(_post.tripId!).listen((
      trip,
    ) {
      if (mounted && trip != null) {
        setState(() {
          _associatedTrip = trip;
        });
      }
    });
  }

  @override
  void didUpdateWidget(ProfilePostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.post != oldWidget.post) {
      _post = widget.post;
      final uid = _postRepository.currentUserId;
      _isLiked = uid != null && _post.likes.contains(uid);
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
      final users = await _userRepository.searchUsers(displayName);
      if (users.isNotEmpty && mounted) {
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
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deletePost() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc muốn xóa bài viết này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _postRepository.deletePost(widget.post.id);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Đã xóa bài viết')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Lỗi khi xóa: $e')));
        }
      }
    }
  }

  void _showPostOptions() {
    // capture the scaffold/context above the bottom sheet so snackbars
    // can still be shown after the sheet closes.
    final parentContext = context;
    final navigator = Navigator.of(context, rootNavigator: true);

    showModalBottomSheet(
      context: parentContext,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                _post.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
              ),
              title: Text(
                _post.isPinned ? 'Bỏ ghim bài viết' : 'Ghim bài viết',
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                final isPinned = _post.isPinned;
                // optimistically update UI first
                if (mounted) {
                  setState(() {
                    _post = _post.copyWith(isPinned: !isPinned);
                  });
                  widget.onUpdate?.call(_post);
                }
                // perform network call without awaiting to keep UI smooth
                _postRepository.pinPost(_post.id, pinned: !isPinned).catchError(
                  (e) {
                    // if it fails, revert state and show error
                    if (mounted) {
                      setState(() {
                        _post = _post.copyWith(isPinned: isPinned);
                      });
                      widget.onUpdate?.call(_post);
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        SnackBar(content: Text('Lỗi khi ghim: $e')),
                      );
                    }
                  },
                );
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      isPinned ? 'Đã gỡ ghim bài viết' : 'Đã ghim bài viết',
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_border),
              title: const Text('Lưu bài viết'),
              onTap: () async {
                Navigator.pop(sheetContext);
                try {
                  await _activityService.savePost(_post.id);
                  if (mounted) {
                    ScaffoldMessenger.of(parentContext).showSnackBar(
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
                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      SnackBar(content: Text('Lỗi khi lưu bài viết: $e')),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Chỉnh sửa bài viết'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditPostPage(
                      post: {
                        'content': widget.post.content,
                        'images': widget.post.mediaUrls,
                        'privacy': widget.post.audience.name,
                        'allowComments': widget.post.allowComments,
                      },
                      onSave: (updatedPost) async {
                        // apply updates to Firestore
                        final postModel = widget.post.copyWith(
                          content:
                              updatedPost['content'] as String? ??
                              widget.post.content,
                          audience: PostAudience.values.firstWhere(
                            (e) =>
                                e.name ==
                                (updatedPost['privacy'] as String? ??
                                    widget.post.audience.name),
                            orElse: () => widget.post.audience,
                          ),
                          allowComments:
                              updatedPost['allowComments'] as bool? ??
                              widget.post.allowComments,
                          // TODO: update mediaUrls etc if necessary
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
              onTap: () async {
                Navigator.pop(context);
                final choice = await showDialog<PostAudience>(
                  context: context,
                  builder: (c) => SimpleDialog(
                    title: const Text('Quyền riêng tư'),
                    children: PostAudience.values.map((aud) {
                      return SimpleDialogOption(
                        onPressed: () => Navigator.pop(c, aud),
                        child: Text(aud.name),
                      );
                    }).toList(),
                  ),
                );
                if (choice != null) {
                  await _postRepository.updatePostAudience(_post.id, choice);
                  if (mounted) {
                    setState(() {
                      _post = _post.copyWith(audience: choice);
                    });
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đã chuyển sang ${choice.name}')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.comment),
              title: const Text('Chỉnh sửa quyền bình luận về bài viết'),
              onTap: () async {
                Navigator.pop(context);
                final allow = _post.allowComments;
                await _postRepository.setAllowComments(_post.id, !allow);
                if (mounted) {
                  setState(() {
                    _post = _post.copyWith(allowComments: !allow);
                  });
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      !allow ? 'Đã bật bình luận' : 'Đã tắt bình luận',
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_album),
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
                        decoration: const InputDecoration(
                          hintText: 'Nhập tên album',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(c),
                          child: const Text('Hủy'),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(c, controller.text.trim()),
                          child: const Text('OK'),
                        ),
                      ],
                    );
                  },
                );
                if (albumName != null && albumName.isNotEmpty) {
                  await _postRepository.addPostToAlbum(_post.id, albumName);
                  if (mounted) {
                    setState(() {
                      final existing = List<String>.from(_post.albumIds);
                      if (!existing.contains(albumName)) {
                        existing.add(albumName);
                      }
                      _post = _post.copyWith(albumIds: existing);
                    });
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đã thêm vào album "$albumName"')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'Xóa bài viết',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _deletePost();
              },
            ),
          ],
        ),
      ),
    );
  }

  // options shown when viewing someone else’s post
  void _showOtherPostOptions() {
    final parentContext = context;
    final navigator = Navigator.of(context, rootNavigator: true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showModalBottomSheet(
      context: parentContext,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.bookmark_border),
              title: const Text('Lưu bài viết'),
              onTap: () async {
                Navigator.pop(sheetContext);
                try {
                  await _activityService.savePost(_post.id);
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
              leading: const Icon(Icons.flag),
              title: const Text('Báo cáo bài viết'),
              subtitle: Text(
                'Chúng tôi sẽ không cho ${widget.post.authorName.isNotEmpty ? widget.post.authorName : 'người này'} biết ai đã báo cáo.',
                style: const TextStyle(fontSize: 12),
              ),
              onTap: () async {
                Navigator.pop(sheetContext);
                final reason = await showDialog<String>(
                  context: parentContext,
                  builder: (ctx) => SimpleDialog(
                    title: const Text('Báo cáo bài viết'),
                    children: [
                      SimpleDialogOption(
                        onPressed: () =>
                            Navigator.pop(ctx, 'Nội dung không phù hợp'),
                        child: const Text('Nội dung không phù hợp'),
                      ),
                      SimpleDialogOption(
                        onPressed: () => Navigator.pop(ctx, 'Spam/Quảng cáo'),
                        child: const Text('Spam/Quảng cáo'),
                      ),
                      SimpleDialogOption(
                        onPressed: () =>
                            Navigator.pop(ctx, 'Bạo lực hoặc nguy hiểm'),
                        child: const Text('Bạo lực hoặc nguy hiểm'),
                      ),
                      SimpleDialogOption(
                        onPressed: () =>
                            Navigator.pop(ctx, 'Thông tin sai lệch'),
                        child: const Text('Thông tin sai lệch'),
                      ),
                      SimpleDialogOption(
                        onPressed: () => Navigator.pop(ctx, 'Khác'),
                        child: const Text('Khác'),
                      ),
                    ],
                  ),
                );
                if (reason != null && mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('Đã báo cáo: $reason')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_none),
              title: const Text('Nhận thông báo về bài viết này'),
              onTap: () {
                Navigator.pop(sheetContext);
                // Toggle notification subscription
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Đã bật thông báo cho bài viết này'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) {
      return 'Vừa xong';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} phút trước';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} giờ trước';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ngày trước';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = _post;
    final hasBackgroundColor =
        post.backgroundColor != null &&
        post.backgroundColor != 'none' &&
        post.mediaUrls.isEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () {
          if (_suppressCardTap) return;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Baiviet(postId: _post.id)),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header với avatar và tên
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      _suppressCardTap = true;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (c) => Profile(userId: widget.post.authorId),
                        ),
                      ).then((_) {
                        // reset after navigation
                        Future.delayed(const Duration(milliseconds: 100), () {
                          _suppressCardTap = false;
                        });
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: widget.post.authorPhotoUrl != null
                            ? getImageProvider(widget.post.authorPhotoUrl!)
                            : const AssetImage('asset/images/OIP.jpg')
                                  as ImageProvider,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  _suppressCardTap = true;
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (c) =>
                                          Profile(userId: widget.post.authorId),
                                    ),
                                  ).then((_) {
                                    Future.delayed(
                                      const Duration(milliseconds: 100),
                                      () {
                                        _suppressCardTap = false;
                                      },
                                    );
                                  });
                                },
                                child: Text(
                                  widget.post.authorName.isNotEmpty
                                      ? widget.post.authorName
                                      : 'Đang tải...',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            if (widget.post.isPinned)
                              const Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Icon(Icons.push_pin, size: 16),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              _formatTimestamp(post.createdAt),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.public,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      if (_post.authorId == _postRepository.currentUserId) {
                        _showPostOptions();
                      } else {
                        _showOtherPostOptions();
                      }
                    },
                    icon: const Icon(Icons.more_horiz),
                  ),
                ],
              ),
            ),

            // Nội dung bài viết
            if (hasBackgroundColor)
              // Hiển thị với background màu hoặc gradient (match newsfeed padding/text)
              Builder(
                builder: (context) {
                  final gradient = _getGradient(post.backgroundColor);
                  final bgColor = gradient == null
                      ? _parseBackgroundColor(post.backgroundColor)
                      : Colors
                            .black; // Gradient always dark enough for white text
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
                      gradient: gradient,
                      color: gradient == null ? bgColor : null,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _buildRichContent(
                      post.content,
                      baseStyle: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              )
            else if (post.content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: _buildRichContent(
                  post.content,
                  baseStyle: const TextStyle(fontSize: 15),
                ),
              ),

            // Hiển thị bài viết gốc được chia sẻ (embedded shared post)
            if (post.isSharedPost && post.sharedPostData != null)
              _buildEmbeddedSharedPost(post.sharedPostData!),

            // Hiển thị media theo layout được chọn (chỉ khi không phải shared post)
            if (post.mediaUrls.isNotEmpty && !post.isSharedPost)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildMediaSection(post.mediaUrls, post.layoutIndex),
                ),
              ),

            // Experience entries section
            if (post.experienceEntries.isNotEmpty)
              _buildExperienceSection(post.experienceEntries),

            // Trip info section
            if (_post.tripId != null && _associatedTrip != null)
              _buildTripCard(),

            // Hide like/comment/share for trip posts, show trip actions instead
            if (_post.tripId == null || _associatedTrip == null) ...[
              const Divider(height: 1, color: Colors.grey),

              // Footer với các nút like, comment, share
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Like
                    InkWell(
                      onTap: _toggleLike,
                      child: Row(
                        children: [
                          Icon(
                            _isLiked ? Icons.favorite : Icons.favorite_border,
                            size: 18,
                            color: _isLiked ? Colors.red : Colors.blue[700],
                          ),
                          const SizedBox(width: 6),
                          Text('${post.likes.length}'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),

                    // Comments
                    Row(
                      children: [
                        Icon(
                          post.allowComments
                              ? Icons.mode_comment_outlined
                              : Icons.block,
                          size: 16,
                          color: post.allowComments
                              ? Colors.grey[700]
                              : Colors.red,
                        ),
                        const SizedBox(width: 6),
                        Text('${post.commentCount}'),
                      ],
                    ),
                    const SizedBox(width: 24),

                    // Shares
                    InkWell(
                      onTap: () => _showShareOptions(_post),
                      child: Row(
                        children: [
                          Icon(
                            Icons.share_outlined,
                            size: 16,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(width: 6),
                          Text('${post.shareCount}'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ], // close the if block for non-trip posts
          ],
        ),
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
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () {
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
                                _formatTimestamp(originalCreatedAt),
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
                  final gradient = _getGradient(originalBackgroundColor);
                  final bgColor = gradient == null
                      ? _parseBackgroundColor(originalBackgroundColor)
                      : Colors.black;
                  final textColor = bgColor.computeLuminance() > 0.5
                      ? Colors.black
                      : Colors.white;
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 40,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: gradient,
                      color: gradient == null ? bgColor : null,
                    ),
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

  // ---------- experience entries ----------
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

  // ---------- trip card helper ----------
  Widget _buildTripCard() {
    if (_associatedTrip == null) return const SizedBox.shrink();
    final trip = _associatedTrip!;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
            trip.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 8),
          // Starting location
          if (trip.startingLocation.isNotEmpty)
            _buildTripInfoRow(
              Icons.trip_origin,
              'Tập trung: ${trip.startingLocation}',
            ),
          // Destination
          _buildTripInfoRow(
            Icons.location_on,
            'Điểm đến: ${trip.location.isNotEmpty ? trip.location : "Chưa có"}',
          ),
          // Date range
          _buildTripInfoRow(
            Icons.calendar_today,
            '${DateFormat('dd/MM/yyyy').format(trip.startDate)} - ${DateFormat('dd/MM/yyyy').format(trip.endDate)}',
          ),
          // Cost
          if (trip.estimatedCost != null)
            GestureDetector(
              onTap: trip.costBreakdown.isNotEmpty ? _showCostBreakdown : null,
              child: _buildTripInfoRow(
                Icons.attach_money,
                'Chi phí: ${_formatCurrency(trip.estimatedCost!)}',
                isClickable: trip.costBreakdown.isNotEmpty,
              ),
            ),
          // Members
          GestureDetector(
            onTap: _showMembersList,
            child: _buildTripInfoRow(
              Icons.people,
              '${trip.members.length}/${trip.maxMembers} thành viên',
              isClickable: true,
            ),
          ),
          const SizedBox(height: 12),
          // Buttons - hide Join if user is the post author or already joined
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
              if (!_isOwnPost && !_hasJoinedTrip) const SizedBox(width: 8),
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

  Future<void> _joinTrip() async {
    if (_post.tripId == null) return;
    try {
      final (success, isFull, trip) = await _menuService.joinTrip(
        _post.tripId!,
      );
      String message;
      if (!success) {
        if (isFull) {
          message = 'Chuyến đi đã đầy thành viên';
        } else if (trip != null &&
            trip.members.contains(_menuService.currentUserId)) {
          message = 'Bạn đã là thành viên của chuyến đi này';
        } else {
          message = 'Không thể tham gia chuyến đi';
        }
      } else {
        message = 'Đã tham gia chuyến đi "${trip?.name}" thành công!';
        if (trip != null && mounted) {
          setState(() {
            _associatedTrip = trip;
          });
        }

        // also create in-app notifications for feed join
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

  void _viewTripDetails() {
    if (_associatedTrip == null) return;
    final trip = _associatedTrip!;
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
                        child: avatarUrl == null || avatarUrl.isEmpty
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

  // ---------- media layout helpers ----------
  Widget _buildMediaSection(List<String> mediaUrls, int layoutIndex) {
    if (mediaUrls.isEmpty) return const SizedBox.shrink();

    // Wrap với GestureDetector để xử lý tap
    return GestureDetector(
      onTap: () => _handleMediaTap(mediaUrls, 0),
      child: _buildMediaLayout(mediaUrls, layoutIndex),
    );
  }

  /// Xử lý tap vào ảnh:
  /// - 1 ảnh: mở ImageDetailViewer trực tiếp
  /// - Nhiều ảnh: mở ImageGalleryPage
  void _handleMediaTap(List<String> mediaUrls, int index) {
    if (mediaUrls.length == 1) {
      // Chỉ có 1 ảnh -> xem chi tiết luôn
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImageDetailViewer(
            mediaUrls: mediaUrls,
            initialIndex: 0,
            authorName: _post.authorName,
            post: _post,
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
            authorName: _post.authorName,
            authorPhotoUrl: _post.authorPhotoUrl,
            content: _post.content,
            createdAt: _post.createdAt,
            initialIndex: index,
            post: _post,
          ),
        ),
      );
    }
  }

  Widget _buildMediaLayout(List<String> mediaUrls, int layoutIndex) {
    switch (layoutIndex) {
      case 1:
        return _buildSingleImageLayout(mediaUrls);
      case 2:
        return _buildHorizontalScrollLayout(mediaUrls);
      case 3:
        return _buildOneBigTwoSmallLayout(mediaUrls);
      case 0:
      default:
        return _buildGrid2ColumnsLayout(mediaUrls);
    }
  }

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

  Widget _buildImage(
    String url, {
    BoxFit fit = BoxFit.cover,
    Widget? errorWidget,
  }) {
    if (url.startsWith('data:')) {
      // handle base64 data URL
      try {
        final base64String = url.split(',').last;
        final bytes = base64Decode(base64String);
        return Image.memory(
          Uint8List.fromList(bytes),
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return errorWidget ??
                Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(Icons.broken_image, color: Colors.grey),
                  ),
                );
          },
        );
      } catch (e) {
        return errorWidget ??
            Container(
              color: Colors.grey[200],
              child: const Center(
                child: Icon(Icons.broken_image, color: Colors.grey),
              ),
            );
      }
    }

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
              color: Colors.grey[200],
              child: const Center(
                child: Icon(Icons.broken_image, color: Colors.grey),
              ),
            );
      },
    );
  }

  LinearGradient? _getGradient(String? colorName) {
    switch (colorName) {
      case 'blue':
        return const LinearGradient(
          colors: [Color(0xFF4A90D9), Color(0xFF67B8DE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'green':
        return const LinearGradient(
          colors: [Color(0xFF56AB2F), Color(0xFFA8E063)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'orange':
        return const LinearGradient(
          colors: [Color(0xFFFF8008), Color(0xFFFFC837)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'purple':
        return const LinearGradient(
          colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'red':
        return const LinearGradient(
          colors: [Color(0xFFED213A), Color(0xFF93291E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return null;
    }
  }

  // similar to FirebaseNewfeed._parseBackgroundColor
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
              return ProfilePostCard(post: posts[index]);
            },
          );
        },
      ),
    );
  }
}
