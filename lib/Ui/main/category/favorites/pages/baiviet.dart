import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:tourn/domain/post_repository/post_repository.dart';
import 'package:tourn/data/post/firestore_post_repository.dart';
import 'package:tourn/models/post_model.dart';
import 'package:tourn/models/comment_model.dart';
import 'package:tourn/ultils.enums/image_utils.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'dart:async';

class Baiviet extends StatefulWidget {
  final Map<String, dynamic>? post;
  final String? postId;
  final List<Map<String, dynamic>>? relatedPosts;

  const Baiviet({super.key, this.post, this.postId, this.relatedPosts});

  @override
  State<Baiviet> createState() => _BaivietState();
}

class _BaivietState extends State<Baiviet> {
  PostModel? _postModel;
  bool _loading = true;
  bool _liked = false;
  final TextEditingController _commentController = TextEditingController();
  StreamSubscription<List<CommentModel>>? _commentsSub;
  List<CommentModel> _comments = [];

  bool _ensureSignedIn() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cần đăng nhập để thực hiện thao tác này')),
    );
    return false;
  }

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  Future<void> _loadPost() async {
    await Future.delayed(Duration.zero); // ensure context is available
    if (!mounted) return;
    final repo = Provider.of<PostRepository>(context, listen: false);

    PostModel? model;
    try {
      if (widget.postId != null) {
        model = await repo.getPostById(widget.postId!);
      } else if (widget.post != null && widget.post!['id'] != null) {
        model = await repo.getPostById(widget.post!['id'] as String);
      }
    } on FirebaseException catch (e) {
      if (!mounted) return;
      // Permission issues should not crash the view; use cached data instead.
      if (widget.post != null) {
        _applyFallbackPost(widget.post!);
        return;
      }
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể mở bài viết: ${e.code}')),
      );
      return;
    } catch (e) {
      if (!mounted) return;
      if (widget.post != null) {
        _applyFallbackPost(widget.post!);
        return;
      }
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể mở bài viết: $e')));
      return;
    }

    if (model != null && mounted) {
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      setState(() {
        _postModel = model;
        _liked = currentUid != null && model!.likes.contains(currentUid);
        _loading = false;
      });
      _subscribeComments(model.id);
    } else if (widget.post != null && mounted) {
      _applyFallbackPost(widget.post!);
    } else if (mounted) {
      setState(() => _loading = false);
    }
  }

  void _applyFallbackPost(Map<String, dynamic> postData) {
    // Fallback: Create PostModel from the cached post map data
    final fallbackModel = PostModel(
      id: postData['postId'] as String? ?? postData['id'] as String? ?? '',
      authorId: postData['authorId'] as String? ?? '',
      authorName: postData['authorName'] as String? ?? 'Người dùng',
      authorPhotoUrl: postData['authorPhotoUrl'] as String?,
      content: postData['content'] as String? ?? '',
      mediaUrls:
          (postData['mediaUrls'] as List<dynamic>?)?.cast<String>() ?? [],
      backgroundColor: postData['backgroundColor'] as String?,
      createdAt: postData['createdAt'] != null
          ? (postData['createdAt'] is String
                ? DateTime.tryParse(postData['createdAt'] as String) ??
                      DateTime.now()
                : postData['createdAt'] as DateTime)
          : DateTime.now(),
      likes: [],
      commentCount: 0,
      shareCount: 0,
    );
    setState(() {
      _postModel = fallbackModel;
      _loading = false;
    });
  }

  void _subscribeComments(String postId) {
    final repo = Provider.of<PostRepository>(context, listen: false);
    if (repo is FirestorePostRepository) {
      _commentsSub = repo
          .getComments(postId)
          .handleError((_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Không thể tải bình luận')),
            );
          })
          .listen((list) {
            if (mounted) setState(() => _comments = list);
          });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentsSub?.cancel();
    super.dispose();
  }

  void _toggleLike() async {
    final post = _postModel;
    if (post == null) return;
    if (!_ensureSignedIn()) return;
    final repo = Provider.of<PostRepository>(context, listen: false);
    if (repo is FirestorePostRepository) {
      setState(() => _liked = !_liked);
      try {
        if (_liked) {
          await repo.likePost(post.id);
        } else {
          await repo.unlikePost(post.id);
        }
        final updated = await repo.getPostById(post.id);
        if (updated != null && mounted) {
          setState(() => _postModel = updated);
        }
      } catch (_) {
        if (mounted) setState(() => _liked = !_liked);
      }
    }
  }

  Future<void> _addComment(String text) async {
    if (text.trim().isEmpty || _postModel == null) return;
    if (!_ensureSignedIn()) return;
    final repo = Provider.of<PostRepository>(context, listen: false);
    if (repo is FirestorePostRepository) {
      final user = FirebaseAuth.instance.currentUser;
      await repo.addComment(
        postId: _postModel!.id,
        content: text.trim(),
        authorName: user?.displayName ?? 'Bạn',
        authorPhotoUrl: user?.photoURL,
      );
      _commentController.clear();
      // refresh post to get updated comment count
      final updated = await repo.getPostById(_postModel!.id);
      if (updated != null && mounted) {
        setState(() => _postModel = updated);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final post = _postModel;
    if (post == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Không tìm thấy bài viết')),
      );
    }

    final likes = post.likes.length;
    final commentsCount = post.commentCount;
    final shares = post.shareCount;
    final avatarProvider = getImageProvider(post.authorPhotoUrl ?? '');

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: avatarProvider,
              child: avatarProvider == null
                  ? const Icon(Icons.person, size: 18)
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.authorName,
                    style: const TextStyle(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Text(
                        _formatTimestamp(post.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        _visibilityIcon(post.audience),
                        size: 12,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Chọn: $v')));
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Báo cáo', child: Text('Báo cáo')),
              const PopupMenuItem(value: 'Chia sẻ', child: Text('Chia sẻ')),
              const PopupMenuItem(
                value: 'Sao chép link',
                child: Text('Sao chép link'),
              ),
            ],
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Background-color post (text-only with colour)
                  if (post.mediaUrls.isEmpty &&
                      post.backgroundColor != null) ...[
                    Builder(
                      builder: (_) {
                        final bgColor = _parseBackgroundColor(
                          post.backgroundColor,
                        );
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
                  ] else if (post.content.isNotEmpty) ...[
                    _buildRichContent(post.content),
                  ],
                  const SizedBox(height: 12),
                  // Show embedded shared post if this is a shared post
                  if (post.isSharedPost && post.sharedPostData != null)
                    _buildEmbeddedSharedPost(post.sharedPostData!),
                  // show media images from Firebase (only if not a shared post)
                  if (post.mediaUrls.isNotEmpty && !post.isSharedPost)
                    ...post.mediaUrls.map(
                      (url) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => Scaffold(
                                  appBar: AppBar(),
                                  body: Center(
                                    child: InteractiveViewer(
                                      child: _buildFullScreenImage(url),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _buildMediaImage(url),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: _toggleLike,
                        child: Row(
                          children: [
                            Icon(
                              _liked ? Icons.favorite : Icons.favorite_border,
                              color: _liked ? Colors.red : Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text('$likes'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Row(
                        children: [
                          const Icon(
                            Icons.mode_comment_outlined,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text('$commentsCount'),
                        ],
                      ),
                      const SizedBox(width: 24),
                      Row(
                        children: [
                          const Icon(Icons.share_outlined, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text('$shares'),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // experience entries
                  if (post.experienceEntries.isNotEmpty) ...[
                    const Text(
                      'Chia sẻ kinh nghiệm',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...post.experienceEntries.map((entry) {
                      final title = entry['title'] as String? ?? '';
                      final desc = entry['description'] as String? ?? '';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (title.isNotEmpty)
                              Text(
                                title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            if (desc.isNotEmpty) Text(desc),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                  ],
                  // location
                  if (post.location != null && post.location!.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            post.location!,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  // hashtags
                  if (post.hashtags.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      children: post.hashtags
                          .map(
                            (h) => Chip(
                              label: Text(
                                '#$h',
                                style: const TextStyle(fontSize: 12),
                              ),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'Bình luận',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_comments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'Chưa có bình luận nào',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  ..._comments.map((c) => _buildCommentTile(c)),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          // input bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.photo),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Chức năng tải ảnh chưa được bật'),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.gif),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Chèn GIF chưa được bật'),
                          ),
                        );
                      },
                    ),
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: const InputDecoration(
                          hintText: 'Viết bình luận...',
                          border: InputBorder.none,
                        ),
                        onSubmitted: _addComment,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.blue),
                      onPressed: () => _addComment(_commentController.text),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentTile(CommentModel c) {
    final avatarProvider = getImageProvider(c.authorPhotoUrl ?? '');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: avatarProvider,
            child: avatarProvider == null
                ? const Icon(Icons.person, size: 18)
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      c.authorName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _formatTimestamp(c.createdAt),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(c.content),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _visibilityIcon(PostAudience audience) {
    switch (audience) {
      case PostAudience.public:
        return Icons.public;
      case PostAudience.onlyMe:
        return Icons.lock;
      case PostAudience.friends:
        return Icons.people;
    }
  }

  String _formatTimestamp(dynamic t) {
    if (t == null || t is! DateTime) return '';
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} Phút';
    if (diff.inHours < 24) return '${diff.inHours} Giờ';
    return '${diff.inDays} Ngày';
  }

  // ---- Background color helper (matches newsfeed) ----
  Color _parseBackgroundColor(String? backgroundColor) {
    if (backgroundColor == null) return Colors.transparent;
    try {
      final colorInt = int.tryParse(backgroundColor);
      if (colorInt != null) return Color(colorInt);
    } catch (_) {}
    return Colors.blue;
  }

  // ---- Media image builder (handles network URLs and base64 data URLs) ----
  Widget _buildMediaImage(String url) {
    final errorWidget = Container(
      height: 200,
      color: Colors.grey[300],
      child: const Icon(Icons.broken_image, size: 40),
    );

    // Check if it's a local asset path
    if (url.startsWith('asset/') || url.startsWith('assets/')) {
      return Image.asset(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, __, ___) => errorWidget,
      );
    }

    // Check if it's a base64 data URL
    if (url.startsWith('data:')) {
      try {
        final base64Data = url.split(',').last;
        final bytes = base64Decode(base64Data);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (_, __, ___) => errorWidget,
        );
      } catch (e) {
        return errorWidget;
      }
    }

    // Otherwise treat as network URL
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        );
      },
      errorBuilder: (_, __, ___) => errorWidget,
    );
  }

  // ---- Full screen image for InteractiveViewer ----
  Widget _buildFullScreenImage(String url) {
    // Check if it's a local asset path
    if (url.startsWith('asset/') || url.startsWith('assets/')) {
      return Image.asset(url);
    }

    // Check if it's a base64 data URL
    if (url.startsWith('data:')) {
      try {
        final base64Data = url.split(',').last;
        final bytes = base64Decode(base64Data);
        return Image.memory(bytes);
      } catch (e) {
        return const Icon(Icons.broken_image, size: 40);
      }
    }

    // Otherwise treat as network URL
    return Image.network(url);
  }

  // ---- Rich-content renderer (hashtags & mentions) ----
  Widget _buildRichContent(
    String content, {
    TextStyle? baseStyle,
    TextAlign? textAlign,
  }) {
    final style =
        baseStyle ??
        const TextStyle(fontSize: 16, color: Color(0xFF1a1a1a), height: 1.4);

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
      if (match.start > lastEnd) {
        spans.add(
          TextSpan(text: content.substring(lastEnd, match.start), style: style),
        );
      }
      final matchedText = match.group(0)!;
      spans.add(
        TextSpan(
          text: matchedText,
          style: style.copyWith(
            color: Colors.orange,
            fontWeight: FontWeight.w500,
          ),
          recognizer: TapGestureRecognizer()..onTap = () {},
        ),
      );
      lastEnd = match.end;
    }
    if (lastEnd < content.length) {
      spans.add(TextSpan(text: content.substring(lastEnd), style: style));
    }
    return RichText(
      text: TextSpan(children: spans),
      textAlign: textAlign ?? TextAlign.start,
    );
  }

  // ---- Embedded shared post (Facebook-style) ----
  Widget _buildEmbeddedSharedPost(Map<String, dynamic> sharedData) {
    final originalAuthorName =
        sharedData['authorName'] as String? ?? 'Người dùng';
    final originalAuthorPhotoUrl = sharedData['authorPhotoUrl'] as String?;
    final originalContent = sharedData['content'] as String? ?? '';
    final originalMediaUrls =
        (sharedData['mediaUrls'] as List<dynamic>?)?.cast<String>() ?? [];
    final originalBackgroundColor = sharedData['backgroundColor'] as String?;
    final originalCreatedAtStr = sharedData['createdAt'] as String?;

    DateTime? originalCreatedAt;
    if (originalCreatedAtStr != null) {
      originalCreatedAt = DateTime.tryParse(originalCreatedAtStr);
    }

    final hasBackgroundColor =
        originalBackgroundColor != null &&
        originalBackgroundColor != 'none' &&
        originalMediaUrls.isEmpty;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Original post author header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage:
                      originalAuthorPhotoUrl != null &&
                          originalAuthorPhotoUrl.isNotEmpty
                      ? getImageProvider(originalAuthorPhotoUrl)
                      : null,
                  backgroundColor: Colors.grey[400],
                  child:
                      (originalAuthorPhotoUrl == null ||
                          originalAuthorPhotoUrl.isEmpty)
                      ? const Icon(Icons.person, size: 18, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        originalAuthorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF1a1a1a),
                        ),
                      ),
                      if (originalCreatedAt != null)
                        Text(
                          _formatTimestamp(originalCreatedAt),
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
          ),

          // Original post content
          if (hasBackgroundColor)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
              decoration: BoxDecoration(
                gradient: _getGradient(originalBackgroundColor),
                color: _getGradient(originalBackgroundColor) == null
                    ? _parseBackgroundColor(originalBackgroundColor)
                    : null,
              ),
              child: _buildRichContent(
                originalContent,
                baseStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else ...[
            if (originalContent.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: _buildRichContent(originalContent),
              ),
            if (originalMediaUrls.isNotEmpty)
              ...originalMediaUrls.map(
                (url) => GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          appBar: AppBar(),
                          body: Center(
                            child: InteractiveViewer(
                              child: _buildFullScreenImage(url),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  child: _buildMediaImage(url),
                ),
              ),
          ],
        ],
      ),
    );
  }

  // ---- Get gradient for background color ----
  LinearGradient? _getGradient(String? colorName) {
    switch (colorName) {
      case 'gradient_sunset':
        return const LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFFFE66D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'gradient_ocean':
        return const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'gradient_forest':
        return const LinearGradient(
          colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'gradient_night':
        return const LinearGradient(
          colors: [Color(0xFF232526), Color(0xFF414345)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return null;
    }
  }
}
