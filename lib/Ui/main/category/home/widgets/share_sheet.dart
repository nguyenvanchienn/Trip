import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tourn/data/post/firestore_post_repository.dart';
import 'package:tourn/domain/user_repository/user_repository.dart';
import 'package:tourn/domain/message_repository/message_repository.dart';
import 'package:tourn/models/user_model.dart';
import 'package:tourn/models/post_model.dart';
import 'package:tourn/models/message_model.dart';
import 'package:tourn/ultils.enums/image_utils.dart';
import 'package:url_launcher/url_launcher.dart';

/// Facebook-style share bottom sheet widget.
/// Supports sharing to feed, Messenger friends, copy link, and external apps.
class ShareSheet extends StatefulWidget {
  /// Post data for Map-based posts (Newfeed.dart)
  final Map<String, dynamic>? postMap;

  /// Post data for PostModel-based posts (profile, Firebase)
  final PostModel? postModel;

  /// Current user info
  final UserModel? currentUser;

  /// Repository for share operations
  final FirestorePostRepository postRepository;

  /// Repository for user operations
  final FirestoreUserRepository userRepository;

  /// Callback when share is successful
  final VoidCallback? onShareSuccess;

  const ShareSheet({
    super.key,
    this.postMap,
    this.postModel,
    this.currentUser,
    required this.postRepository,
    required this.userRepository,
    this.onShareSuccess,
  }) : assert(
         postMap != null || postModel != null,
         'Either postMap or postModel must be provided',
       );

  @override
  State<ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<ShareSheet> {
  final TextEditingController _captionController = TextEditingController();
  final FirestoreMessageRepository _messageRepository =
      FirestoreMessageRepository();
  int _selectedVisibility = 0; // 0: Public, 1: Friends, 2: Only me
  bool _isSharing = false;
  List<UserModel> _friends = [];
  bool _loadingFriends = true;
  bool _loadingUser = true;
  UserModel? _currentUser;

  // Visibility options
  final List<Map<String, dynamic>> _visibilityOptions = [
    {'icon': Icons.public, 'label': 'Công khai', 'value': 0},
    {'icon': Icons.people, 'label': 'Bạn bè', 'value': 1},
    {'icon': Icons.lock, 'label': 'Chỉ mình tôi', 'value': 2},
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadFriends();
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    if (widget.currentUser != null) {
      setState(() {
        _currentUser = widget.currentUser;
        _loadingUser = false;
      });
      return;
    }
    final uid = widget.postRepository.currentUserId;
    if (uid != null) {
      final user = await widget.userRepository.getUserById(uid);
      if (mounted) {
        setState(() {
          _currentUser = user;
          _loadingUser = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _loadingUser = false);
      }
    }
  }

  Future<void> _loadFriends() async {
    try {
      final currentId = widget.postRepository.currentUserId;
      if (currentId == null) {
        setState(() => _loadingFriends = false);
        return;
      }

      final me = await widget.userRepository.getUserById(currentId);
      if (me == null) {
        setState(() => _loadingFriends = false);
        return;
      }

      // Get mutual friends (followers ∩ following)
      final friendIds = me.followers.toSet().intersection(me.following.toSet());
      final List<UserModel> friends = [];

      for (final id in friendIds) {
        final user = await widget.userRepository.getUserById(id);
        if (user != null) friends.add(user);
      }

      if (mounted) {
        setState(() {
          _friends = friends;
          _loadingFriends = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingFriends = false);
      }
    }
  }

  String get _postContent {
    if (widget.postModel != null) {
      return widget.postModel!.content;
    }
    return widget.postMap?['text'] as String? ?? '';
  }

  String get _postId {
    if (widget.postModel != null) {
      return widget.postModel!.id;
    }
    return widget.postMap?['id'] as String? ?? '';
  }

  String get _authorName {
    if (widget.postModel != null) {
      return widget.postModel!.authorName;
    }
    return widget.postMap?['author'] as String? ?? '';
  }

  List<String> get _mediaUrls {
    if (widget.postModel != null) {
      return widget.postModel!.mediaUrls;
    }
    // Extract from postMap - check various possible keys
    if (widget.postMap != null) {
      // Check 'images' key (List)
      final images = widget.postMap!['images'];
      if (images is List && images.isNotEmpty) {
        return List<String>.from(images);
      }
      // Check 'image' key (single String)
      final image = widget.postMap!['image'];
      if (image is String && image.isNotEmpty) {
        return [image];
      }
      // Check 'mediaUrls' key
      final mediaUrls = widget.postMap!['mediaUrls'];
      if (mediaUrls is List && mediaUrls.isNotEmpty) {
        return List<String>.from(mediaUrls);
      }
    }
    return [];
  }

  /// Share to own feed
  Future<void> _shareToFeed() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      // Map visibility selection to PostAudience
      final PostAudience audience;
      switch (_selectedVisibility) {
        case 1:
          audience = PostAudience.friends;
          break;
        case 2:
          audience = PostAudience.onlyMe;
          break;
        default:
          audience = PostAudience.public;
      }

      // Tạo bài viết chia sẻ mới (giống Facebook)
      if (_postId.isNotEmpty && _currentUser != null) {
        final sharedPost = await widget.postRepository.createSharedPost(
          originalPostId: _postId,
          authorName: _currentUser!.displayName,
          authorPhotoUrl: _currentUser!.photoUrl,
          content: _captionController.text.trim(),
          audience: audience,
        );

        if (mounted) {
          Navigator.pop(context);
          widget.onShareSuccess?.call();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                sharedPost != null
                    ? 'Đã chia sẻ lên bảng tin của bạn!'
                    : 'Có lỗi xảy ra khi chia sẻ',
              ),
              backgroundColor: sharedPost != null
                  ? const Color(0xFFFF6600)
                  : Colors.red,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể chia sẻ bài viết này'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi khi chia sẻ: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  /// Show confirmation dialog before sending to friend (Facebook-style)
  Future<bool?> _showSendConfirmDialog(UserModel friend) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildAvatar(photoUrl: friend.photoUrl, radius: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Gửi cho',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        Text(
                          friend.displayName,
                          style: const TextStyle(
                            color: Color(0xFF1a1a1a),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Post preview
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  // Post thumbnail
                  if (_mediaUrls.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: _buildPostThumbnail(_mediaUrls.first),
                      ),
                    )
                  else
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6600),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.article, color: Colors.white),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _authorName,
                          style: const TextStyle(
                            color: Color(0xFF1a1a1a),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        if (_postContent.isNotEmpty)
                          Text(
                            _postContent,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.grey.shade200,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Hủy',
                        style: TextStyle(
                          color: Color(0xFF1a1a1a),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6600),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Gửi',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build thumbnail for post preview
  Widget _buildPostThumbnail(String url) {
    final provider = getImageProvider(url);
    if (provider != null) {
      return Image(
        image: provider,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey[700],
          child: const Icon(Icons.broken_image, color: Colors.white, size: 24),
        ),
      );
    }

    // Handle asset images
    if (url.startsWith('asset/') || url.startsWith('assets/')) {
      return Image.asset(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey[700],
          child: const Icon(Icons.broken_image, color: Colors.white, size: 24),
        ),
      );
    }

    return Container(
      color: Colors.grey[700],
      child: const Icon(Icons.image, color: Colors.white, size: 24),
    );
  }

  /// Share to a specific friend via Messenger-style
  Future<void> _shareToFriend(UserModel friend) async {
    // Show confirmation dialog like Facebook
    final confirmed = await _showSendConfirmDialog(friend);
    if (confirmed != true) return;

    try {
      if (_currentUser == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Không thể gửi tin nhắn')));
        return;
      }

      // Tạo hoặc lấy conversation với bạn bè
      final conversation = await _messageRepository
          .getOrCreatePrivateConversation(
            otherUserId: friend.uid,
            otherUserName: friend.displayName,
            otherUserPhoto: friend.photoUrl,
            currentUserName: _currentUser!.displayName,
            currentUserPhoto: _currentUser!.photoUrl,
          );

      if (conversation == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể tạo cuộc trò chuyện')),
          );
        }
        return;
      }

      // Build shared post metadata
      final Map<String, dynamic> postMetadata = {
        'postId': _postId,
        'authorId':
            widget.postModel?.authorId ?? widget.postMap?['authorId'] ?? '',
        'authorName': _authorName,
        'authorPhotoUrl':
            widget.postModel?.authorPhotoUrl ?? widget.postMap?['avatar'] ?? '',
        'content': _postContent,
        'mediaUrls': _mediaUrls,
        'backgroundColor':
            widget.postModel?.backgroundColor ??
            widget.postMap?['backgroundColor'],
        'createdAt':
            widget.postModel?.createdAt.toIso8601String() ??
            (widget.postMap?['timestamp'] as DateTime?)?.toIso8601String(),
      };

      // Gửi tin nhắn với bài viết được chia sẻ
      await _messageRepository.sendMessage(
        conversationId: conversation.id,
        content: _postContent.isNotEmpty
            ? 'Đã chia sẻ một bài viết'
            : 'Đã chia sẻ một bài viết',
        senderName: _currentUser!.displayName,
        senderPhotoUrl: _currentUser!.photoUrl,
        type: MessageType.sharedPost,
        metadata: postMetadata,
      );

      // Update share count
      if (_postId.isNotEmpty) {
        await widget.postRepository.sharePost(_postId);
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onShareSuccess?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã gửi cho ${friend.displayName}'),
            backgroundColor: const Color(0xFFFF6600),
          ),
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

  /// Copy link to clipboard
  Future<void> _copyLink() async {
    // Generate a shareable link (in a real app, this would be a deep link)
    final link = 'https://trip.app/post/$_postId';
    await Clipboard.setData(ClipboardData(text: link));

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã sao chép liên kết'),
          backgroundColor: Color(0xFFFF6600),
        ),
      );
    }
  }

  /// Share externally using system share
  Future<void> _shareExternal() async {
    final text = '$_authorName vừa đăng: $_postContent';
    await Share.share(text);

    // Update share count
    if (_postId.isNotEmpty) {
      await widget.postRepository.sharePost(_postId);
    }

    if (mounted) {
      Navigator.pop(context);
      widget.onShareSuccess?.call();
    }
  }

  /// Share to Facebook
  Future<void> _shareToFacebook() async {
    String? shareUrl;
    if (_mediaUrls.isNotEmpty) {
      final candidate = _mediaUrls.first;
      if (candidate.startsWith('http://') || candidate.startsWith('https://')) {
        shareUrl = candidate;
      }
    }

    final webParams = <String, String>{
      if (shareUrl != null) 'u': shareUrl,
      if (_postContent.isNotEmpty) 'quote': _postContent,
    };

    final webSharer = Uri.https(
      'www.trip.com',
      '/sharer/sharer.php',
      webParams,
    );

    final fbUri = Uri.parse(
      'fb://facewebmodal/f?href=${Uri.encodeComponent(webSharer.toString())}',
    );

    if (await canLaunchUrl(fbUri)) {
      await launchUrl(fbUri, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(webSharer)) {
      await launchUrl(webSharer, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Không thể mở Facebook')));
        return;
      }
    }

    // Update share count
    if (_postId.isNotEmpty) {
      await widget.postRepository.sharePost(_postId);
    }

    if (mounted) {
      Navigator.pop(context);
      widget.onShareSuccess?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.85;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Main share to feed section
            _buildShareToFeedSection(),

            Divider(color: Colors.grey[300], height: 1),

            // Send via Messenger section
            _buildMessengerSection(),

            Divider(color: Colors.grey[300], height: 1),

            // Share options row
            _buildShareOptionsRow(),

            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  /// Build avatar widget with proper image loading
  Widget _buildAvatar({String? photoUrl, double radius = 24}) {
    final imageProvider = getImageProvider(photoUrl);

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[400],
      backgroundImage: imageProvider,
      child: imageProvider == null
          ? Icon(Icons.person, color: Colors.white, size: radius)
          : null,
    );
  }

  /// Main section for sharing to feed with caption
  Widget _buildShareToFeedSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info row
          Row(
            children: [
              // Avatar with proper loading
              _loadingUser
                  ? CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.grey[600],
                      child: const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : _buildAvatar(photoUrl: _currentUser?.photoUrl),
              const SizedBox(width: 12),

              // Name and privacy selector
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _loadingUser
                        ? Container(
                            height: 16,
                            width: 100,
                            decoration: BoxDecoration(
                              color: Colors.grey[600],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          )
                        : Text(
                            _currentUser?.displayName ?? 'Người dùng',
                            style: const TextStyle(
                              color: Color(0xFF1a1a1a),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // Feed dropdown
                          _buildDropdownChip(
                            icon: Icons.dynamic_feed,
                            label: 'Bảng feed',
                            onTap: () {},
                          ),
                          const SizedBox(width: 8),
                          // Privacy dropdown
                          _buildDropdownChip(
                            icon:
                                _visibilityOptions[_selectedVisibility]['icon']
                                    as IconData,
                            label:
                                _visibilityOptions[_selectedVisibility]['label']
                                    as String,
                            onTap: _showVisibilityPicker,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Caption input
          TextField(
            controller: _captionController,
            style: const TextStyle(color: Color(0xFF1a1a1a), fontSize: 15),
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Hãy nói gì đó về nội dung này...',
              hintStyle: TextStyle(color: Colors.grey[500]),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),

          const SizedBox(height: 12),

          // Action row (emoji, tag, share button)
          Row(
            children: [
              // Emoji button
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.emoji_emotions_outlined,
                  color: Colors.grey,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 16),
              // Tag people button
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.person_add_outlined, color: Colors.grey),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),

              const Spacer(),

              // Share button
              ElevatedButton(
                onPressed: (_isSharing || _loadingUser || _currentUser == null)
                    ? null
                    : _shareToFeed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6600),
                  disabledBackgroundColor: Colors.grey[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                child: _isSharing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Chia sẻ ngay',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Dropdown chip widget
  Widget _buildDropdownChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: const Color(0xFF1a1a1a)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(color: Color(0xFF1a1a1a), fontSize: 13),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: Color(0xFF1a1a1a),
            ),
          ],
        ),
      ),
    );
  }

  /// Show visibility picker dialog
  void _showVisibilityPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Chọn đối tượng',
                style: TextStyle(
                  color: Color(0xFF1a1a1a),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ..._visibilityOptions.map(
              (option) => ListTile(
                leading: Icon(
                  option['icon'] as IconData,
                  color: const Color(0xFF1a1a1a),
                ),
                title: Text(
                  option['label'] as String,
                  style: const TextStyle(color: Color(0xFF1a1a1a)),
                ),
                trailing: _selectedVisibility == option['value']
                    ? const Icon(Icons.check, color: Color(0xFFFF6600))
                    : null,
                onTap: () {
                  setState(() => _selectedVisibility = option['value'] as int);
                  Navigator.pop(c);
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Messenger-style friend sharing section
  Widget _buildMessengerSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gửi bằng Messenger',
            style: TextStyle(
              color: Color(0xFF1a1a1a),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (_loadingFriends)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFFF6600),
                  ),
                ),
              ),
            )
          else if (_friends.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Chưa có bạn bè',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
            )
          else
            SizedBox(
              height: 88, // Fixed height for friend list
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _friends.length,
                itemBuilder: (context, index) {
                  final friend = _friends[index];
                  return _buildFriendItem(friend);
                },
              ),
            ),
        ],
      ),
    );
  }

  /// Friend item for Messenger section
  Widget _buildFriendItem(UserModel friend) {
    return GestureDetector(
      onTap: () => _shareToFriend(friend),
      child: Container(
        width: 72,
        height: 88,
        padding: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Avatar với border như Facebook
            Container(
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[300]!, width: 1),
              ),
              child: _buildAvatar(photoUrl: friend.photoUrl, radius: 20),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                friend.displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF1a1a1a),
                  fontSize: 11,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Share options row (Story, Messenger, Copy Link, etc.)
  Widget _buildShareOptionsRow() {
    final options = [
      {
        'icon': Icons.auto_stories,
        'label': 'Tin của bạn',
        'color': const Color(0xFFFF6600),
        'onTap': () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã chia sẻ lên tin của bạn')),
          );
        },
      },
      {
        'icon': Icons.message,
        'label': 'Messenger',
        'color': const Color(0xFFFF6600),
        'onTap': _shareExternal,
      },
      {
        'icon': Icons.link,
        'label': 'Sao chép\nliên kết',
        'color': Colors.white,
        'iconColor': Colors.grey[700],
        'onTap': _copyLink,
      },
      {
        'icon': Icons.group,
        'label': 'Nhóm',
        'color': const Color(0xFFFF6600),
        'onTap': () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tính năng nhóm đang phát triển')),
          );
        },
      },
      {
        'icon': Icons.sms,
        'label': 'Tin nhắn',
        'color': const Color(0xFF25D366),
        'onTap': _shareExternal,
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chia sẻ lên',
            style: TextStyle(
              color: Color(0xFF1a1a1a),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: options.map((option) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _buildShareOption(
                    icon: option['icon'] as IconData,
                    label: option['label'] as String,
                    color: option['color'] as Color?,
                    iconColor: option['iconColor'] as Color?,
                    onTap: option['onTap'] as VoidCallback,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// Single share option button
  Widget _buildShareOption({
    required IconData icon,
    required String label,
    Color? color,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color ?? Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor ?? Colors.white, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF1a1a1a), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper function to show the Facebook share sheet
void showFacebookShareSheet(
  BuildContext context, {
  Map<String, dynamic>? postMap,
  PostModel? postModel,
  UserModel? currentUser,
  required FirestorePostRepository postRepository,
  required FirestoreUserRepository userRepository,
  VoidCallback? onShareSuccess,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    enableDrag: true,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (context) => ShareSheet(
      postMap: postMap,
      postModel: postModel,
      currentUser: currentUser,
      postRepository: postRepository,
      userRepository: userRepository,
      onShareSuccess: onShareSuccess,
    ),
  );
}
