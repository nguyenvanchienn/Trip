import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:tourn/data/post/firestore_post_repository.dart';
import 'package:tourn/domain/user_repository/user_repository.dart';
import 'package:tourn/models/post_model.dart';
import 'package:tourn/Ui/main/category/favorites/pages/Baiviet.dart';
import 'package:tourn/Ui/main/category/home/widgets/share_sheet.dart';
import 'package:tourn/ultils.enums/image_utils.dart';

/// Page hiển thị danh sách ảnh của bài viết (giống Facebook)
/// Mỗi ảnh có thể tap để xem chi tiết full screen
class ImageGalleryPage extends StatefulWidget {
  final List<String> mediaUrls;
  final String authorName;
  final String? authorPhotoUrl;
  final String? content;
  final DateTime? createdAt;
  final int initialIndex;
  final PostModel? post; // Full post model for like/comment/share

  const ImageGalleryPage({
    super.key,
    required this.mediaUrls,
    required this.authorName,
    this.authorPhotoUrl,
    this.content,
    this.createdAt,
    this.initialIndex = 0,
    this.post,
  });

  @override
  State<ImageGalleryPage> createState() => _ImageGalleryPageState();
}

class _ImageGalleryPageState extends State<ImageGalleryPage> {
  late ScrollController _scrollController;
  final FirestorePostRepository _postRepository = FirestorePostRepository();
  final FirestoreUserRepository _userRepository = FirestoreUserRepository();

  late bool _isLiked;
  bool _isLoading = false;
  int _likesCount = 0;
  int _commentsCount = 0;
  int _sharesCount = 0;

  bool _ensureSignedIn() {
    if (_postRepository.currentUserId != null) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cần đăng nhập để thực hiện thao tác này')),
    );
    return false;
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Initialize like state from post
    final uid = _postRepository.currentUserId;
    if (widget.post != null) {
      _isLiked = uid != null && widget.post!.likes.contains(uid);
      _likesCount = widget.post!.likes.length;
      _commentsCount = widget.post!.commentCount;
      _sharesCount = widget.post!.shareCount;
    } else {
      _isLiked = false;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _toggleLike() async {
    if (_isLoading || widget.post == null) return;
    if (!_ensureSignedIn()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isLiked) {
        await _postRepository.unlikePost(widget.post!.id);
        if (mounted) {
          setState(() {
            _isLiked = false;
            _likesCount = _likesCount > 0 ? _likesCount - 1 : 0;
          });
        }
      } else {
        await _postRepository.likePost(widget.post!.id);
        if (mounted) {
          setState(() {
            _isLiked = true;
            _likesCount++;
          });
        }
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

  void _openComments() {
    if (widget.post == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => Baiviet(postId: widget.post!.id)),
    );
  }

  void _openShareSheet() {
    if (widget.post == null) return;
    showFacebookShareSheet(
      context,
      postModel: widget.post,
      postRepository: _postRepository,
      userRepository: _userRepository,
      onShareSuccess: () {
        if (mounted) {
          setState(() {
            _sharesCount++;
          });
        }
      },
    );
  }

  Widget _buildImage(String url, {BoxFit fit = BoxFit.cover}) {
    if (url.startsWith('data:')) {
      try {
        final base64String = url.split(',').last;
        final bytes = base64Decode(base64String);
        return Image.memory(
          Uint8List.fromList(bytes),
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[200],
              child: const Center(
                child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
              ),
            );
          },
        );
      } catch (e) {
        return Container(
          color: Colors.grey[200],
          child: const Center(
            child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
          ),
        );
      }
    } else {
      return Image.network(
        url,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[100],
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: const Center(
              child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
            ),
          );
        },
      );
    }
  }

  void _openImageDetail(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageDetailViewer(
          mediaUrls: widget.mediaUrls,
          initialIndex: index,
          authorName: widget.authorName,
          post: widget.post,
        ),
      ),
    );
  }

  Widget _buildActionRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
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
                  '$_likesCount',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Comment
          GestureDetector(
            onTap: _openComments,
            child: Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 20,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 6),
                Text(
                  '$_commentsCount',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Share
          GestureDetector(
            onTap: _openShareSheet,
            child: Row(
              children: [
                Icon(Icons.share_outlined, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  '$_sharesCount',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build rich text with clickable hashtags (#) and mentions (@)
  Widget _buildRichContent(String content) {
    final style = const TextStyle(
      color: Colors.black87,
      fontSize: 15,
      height: 1.4,
    );

    // Regex to match hashtags (#word) and mentions (@Name with Vietnamese support)
    final pattern = RegExp(
      r'(#[\w\u00C0-\u024F\u1E00-\u1EFF]+)|(@[\w\u00C0-\u024F\u1E00-\u1EFF\s]+?)(?=\s|$|[.,!?])',
    );
    final matches = pattern.allMatches(content);

    if (matches.isEmpty) {
      return Text(content, style: style);
    }

    final spans = <InlineSpan>[];
    int lastEnd = 0;

    for (final match in matches) {
      // Add text before match
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
            color: isHashtag ? Colors.orange : Colors.blue,
            fontWeight: FontWeight.w600,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              if (isHashtag) {
                // Navigate to hashtag search - could implement later
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Tìm kiếm $matchedText')),
                );
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

    return RichText(text: TextSpan(children: spans));
  }

  // Build avatar with proper image loading (supports base64 and network urls)
  Widget _buildAvatar(String? photoUrl, {double radius = 20}) {
    final provider = getImageProvider(photoUrl);

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[300],
      backgroundImage: provider,
      child: provider == null
          ? Icon(Icons.person, color: Colors.grey[600], size: radius)
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        title: Text(
          'Bài viết của ${widget.authorName}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        controller: _scrollController,
        itemCount: widget.mediaUrls.length,
        itemBuilder: (context, index) {
          final url = widget.mediaUrls[index];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hiển thị header cho item đầu tiên với content
              if (index == 0 &&
                  widget.content != null &&
                  widget.content!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildAvatar(widget.authorPhotoUrl),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.authorName,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                if (widget.createdAt != null)
                                  Text(
                                    _formatTimeAgo(widget.createdAt!),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildRichContent(widget.content!),
                    ],
                  ),
                ),

              // Ảnh với tap để xem chi tiết
              GestureDetector(
                onTap: () => _openImageDetail(index),
                child: Container(
                  width: double.infinity,
                  color: Colors.grey[100],
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: _buildImage(url, fit: BoxFit.contain),
                  ),
                ),
              ),

              // Action row cho mỗi ảnh
              _buildActionRow(),

              // Divider giữa các ảnh
              if (index < widget.mediaUrls.length - 1)
                Container(height: 8, color: Colors.grey[100]),
            ],
          );
        },
      ),
    );
  }
}

/// Widget xem chi tiết ảnh full screen với zoom
class ImageDetailViewer extends StatefulWidget {
  final List<String> mediaUrls;
  final int initialIndex;
  final String? authorName;
  final PostModel? post;

  const ImageDetailViewer({
    super.key,
    required this.mediaUrls,
    this.initialIndex = 0,
    this.authorName,
    this.post,
  });

  @override
  State<ImageDetailViewer> createState() => _ImageDetailViewerState();
}

class _ImageDetailViewerState extends State<ImageDetailViewer> {
  late PageController _pageController;
  late int _currentIndex;
  final FirestorePostRepository _postRepository = FirestorePostRepository();
  final FirestoreUserRepository _userRepository = FirestoreUserRepository();

  late bool _isLiked;
  bool _isLoading = false;
  int _likesCount = 0;
  int _commentsCount = 0;
  int _sharesCount = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);

    // Initialize like state from post
    final uid = _postRepository.currentUserId;
    if (widget.post != null) {
      _isLiked = uid != null && widget.post!.likes.contains(uid);
      _likesCount = widget.post!.likes.length;
      _commentsCount = widget.post!.commentCount;
      _sharesCount = widget.post!.shareCount;
    } else {
      _isLiked = false;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    if (_isLoading || widget.post == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isLiked) {
        await _postRepository.unlikePost(widget.post!.id);
        if (mounted) {
          setState(() {
            _isLiked = false;
            _likesCount = _likesCount > 0 ? _likesCount - 1 : 0;
          });
        }
      } else {
        await _postRepository.likePost(widget.post!.id);
        if (mounted) {
          setState(() {
            _isLiked = true;
            _likesCount++;
          });
        }
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

  void _openComments() {
    if (widget.post == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => Baiviet(postId: widget.post!.id)),
    );
  }

  void _openShareSheet() {
    if (widget.post == null) return;
    showFacebookShareSheet(
      context,
      postModel: widget.post,
      postRepository: _postRepository,
      userRepository: _userRepository,
      onShareSuccess: () {
        if (mounted) {
          setState(() {
            _sharesCount++;
          });
        }
      },
    );
  }

  ImageProvider _getImageProvider(String url) {
    if (url.startsWith('data:')) {
      try {
        final base64String = url.split(',').last;
        final bytes = base64Decode(base64String);
        return MemoryImage(Uint8List.fromList(bytes));
      } catch (e) {
        return const AssetImage('asset/images/OIP.jpg');
      }
    } else {
      return NetworkImage(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        title: widget.mediaUrls.length > 1
            ? Text(
                '${_currentIndex + 1}/${widget.mediaUrls.length}',
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              )
            : null,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _showOptionsMenu();
            },
          ),
        ],
      ),
      body: PhotoViewGallery.builder(
        scrollPhysics: const BouncingScrollPhysics(),
        builder: (BuildContext context, int index) {
          return PhotoViewGalleryPageOptions(
            imageProvider: _getImageProvider(widget.mediaUrls[index]),
            initialScale: PhotoViewComputedScale.contained,
            minScale: PhotoViewComputedScale.contained * 0.8,
            maxScale: PhotoViewComputedScale.covered * 3,
            heroAttributes: PhotoViewHeroAttributes(tag: 'image_$index'),
          );
        },
        itemCount: widget.mediaUrls.length,
        loadingBuilder: (context, event) => Center(
          child: CircularProgressIndicator(
            value: event == null
                ? null
                : event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? 1),
            color: Colors.orange,
          ),
        ),
        backgroundDecoration: const BoxDecoration(color: Colors.white),
        pageController: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(context).padding.bottom + 12,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
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
                    '$_likesCount',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 32),
            // Comment
            GestureDetector(
              onTap: _openComments,
              child: Row(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 20,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$_commentsCount',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 32),
            // Share
            GestureDetector(
              onTap: _openShareSheet,
              child: Row(
                children: [
                  Icon(Icons.share_outlined, size: 20, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    '$_sharesCount',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.download, color: Colors.grey[700]),
              title: const Text('Lưu ảnh'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Đã lưu ảnh')));
              },
            ),
            ListTile(
              leading: Icon(Icons.share, color: Colors.grey[700]),
              title: const Text('Chia sẻ ảnh'),
              onTap: () {
                Navigator.pop(context);
                _openShareSheet();
              },
            ),
            ListTile(
              leading: Icon(Icons.report_outlined, color: Colors.grey[700]),
              title: const Text('Báo cáo ảnh'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
