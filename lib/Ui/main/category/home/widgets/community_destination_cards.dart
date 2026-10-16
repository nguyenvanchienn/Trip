import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class CommunityDestinationCards extends StatefulWidget {
  final List<Map<String, dynamic>> posts;
  final ValueChanged<int> onToggleFavorite;
  final ValueChanged<int> onCardTap;
  final void Function(int index, String hashtag)? onHashtagTap;

  const CommunityDestinationCards({
    super.key,
    required this.posts,
    required this.onToggleFavorite,
    required this.onCardTap,
    this.onHashtagTap,
  });

  @override
  _CommunityDestinationCardsState createState() =>
      _CommunityDestinationCardsState();
}

class _CommunityDestinationCardsState extends State<CommunityDestinationCards> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Check if URL is a video
  bool _isVideoUrl(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.webm') ||
        lower.contains('video');
  }

  // Parse background color from string
  Color _parseBackgroundColor(String? backgroundColor) {
    if (backgroundColor == null || backgroundColor.isEmpty) {
      return const Color(0xFF667788); // Default gradient color
    }
    try {
      final colorInt = int.tryParse(backgroundColor);
      if (colorInt != null) {
        return Color(colorInt);
      }
    } catch (e) {
      // Ignore
    }
    return const Color(0xFF667788);
  }

  // Build media background (image, video thumbnail, or solid color)
  Widget _buildMediaBackground(Map<String, dynamic> post) {
    final imageUrl = post['image'] as String? ?? '';
    final backgroundColor = post['backgroundColor'] as String?;

    // No image - show background color
    if (imageUrl.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _parseBackgroundColor(backgroundColor),
              _parseBackgroundColor(backgroundColor).withOpacity(0.7),
            ],
          ),
        ),
      );
    }

    // Base64 data URL
    if (imageUrl.startsWith('data:')) {
      try {
        final base64Data = imageUrl.split(',').last;
        final bytes = base64Decode(base64Data);
        return Image.memory(
          Uint8List.fromList(bytes),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildColorBackground(backgroundColor),
        );
      } catch (e) {
        return _buildColorBackground(backgroundColor);
      }
    }

    // Video URL - show thumbnail with play icon
    if (_isVideoUrl(imageUrl)) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _parseBackgroundColor(backgroundColor),
                  Colors.black87,
                ],
              ),
            ),
          ),
          const Center(
            child: Icon(
              Icons.play_circle_filled,
              size: 64,
              color: Colors.white70,
            ),
          ),
        ],
      );
    }

    // Network image URL
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: _parseBackgroundColor(backgroundColor),
          child: const Center(child: CircularProgressIndicator()),
        );
      },
      errorBuilder: (_, __, ___) => _buildColorBackground(backgroundColor),
    );
  }

  // Build solid color background
  Widget _buildColorBackground(String? backgroundColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _parseBackgroundColor(backgroundColor),
            _parseBackgroundColor(backgroundColor).withOpacity(0.7),
          ],
        ),
      ),
      child: const Center(
        child: Icon(Icons.image, size: 50, color: Colors.white30),
      ),
    );
  }

  // Build avatar widget
  Widget _buildAvatar(String avatarUrl) {
    if (avatarUrl.isEmpty) {
      return const Icon(Icons.person, size: 14, color: Colors.white);
    }

    // Base64 data URL
    if (avatarUrl.startsWith('data:')) {
      try {
        final base64Data = avatarUrl.split(',').last;
        final bytes = base64Decode(base64Data);
        return ClipOval(
          child: Image.memory(
            Uint8List.fromList(bytes),
            fit: BoxFit.cover,
            width: 24,
            height: 24,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.person, size: 14, color: Colors.white),
          ),
        );
      } catch (e) {
        return const Icon(Icons.person, size: 14, color: Colors.white);
      }
    }

    // Network URL
    return ClipOval(
      child: Image.network(
        avatarUrl,
        fit: BoxFit.cover,
        width: 24,
        height: 24,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.person, size: 14, color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final posts = widget.posts;
    return SizedBox(
      height: 300,
      child: PageView.builder(
        controller: _pageController,
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child: GestureDetector(
              onTap: () => widget.onCardTap(index),
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
                      // Background image/video or color
                      _buildMediaBackground(post),
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
                        child: GestureDetector(
                          onTap: () {
                            final hashtag = post['hashtag'] as String;
                            if (widget.onHashtagTap != null) {
                              widget.onHashtagTap!(index, hashtag);
                            }
                          },
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
                      ),
                      // Favorite button
                      Positioned(
                        top: 16,
                        right: 16,
                        child: GestureDetector(
                          onTap: () {
                            widget.onToggleFavorite(index);
                          },
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
                                  child: _buildAvatar(post['avatar'] as String),
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
                            // View more button (explicit tap handler)
                            GestureDetector(
                              onTap: () => widget.onCardTap(index),
                              child: Row(
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
