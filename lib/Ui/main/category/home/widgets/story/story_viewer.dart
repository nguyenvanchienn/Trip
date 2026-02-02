import 'package:flutter/material.dart';
import 'story_comments.dart';
import 'story_share.dart';
import 'story_more_options.dart';

class StoryViewer extends StatefulWidget {
  final List<Map<String, dynamic>> friends;
  final int initialIndex;

  const StoryViewer({
    super.key,
    required this.friends,
    required this.initialIndex,
  });

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer> {
  late PageController _pageController;

  // State cho mỗi story
  late List<bool> _isLikedList;
  late List<int> _likeCounts;
  late List<bool> _isFollowingList;
  late List<bool> _isSavedList;

  // Controller cho message input
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _pageController = PageController(initialPage: widget.initialIndex);

    // Khởi tạo state cho mỗi story
    _isLikedList = List.generate(widget.friends.length, (_) => false);
    _likeCounts = List.generate(widget.friends.length, (i) => (i + 1) * 234);
    _isFollowingList = List.generate(widget.friends.length, (_) => false);
    _isSavedList = List.generate(widget.friends.length, (_) => false);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _toggleLike(int index) {
    setState(() {
      _isLikedList[index] = !_isLikedList[index];
      if (_isLikedList[index]) {
        _likeCounts[index]++;
      } else {
        _likeCounts[index]--;
      }
    });
  }

  void _toggleFollow(int index) {
    setState(() {
      _isFollowingList[index] = !_isFollowingList[index];
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isFollowingList[index]
              ? 'Đã theo dõi ${widget.friends[index]['name']}'
              : 'Đã hủy theo dõi ${widget.friends[index]['name']}',
        ),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _toggleSave(int index) {
    setState(() {
      _isSavedList[index] = !_isSavedList[index];
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isSavedList[index] ? 'Đã lưu story' : 'Đã bỏ lưu story'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final message = _messageController.text;
    _messageController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã gửi tin nhắn: "$message"'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            onPageChanged: (index) {
              setState(() {});
            },
            itemCount: widget.friends.length,
            itemBuilder: (context, index) {
              final friend = widget.friends[index];
              return _buildStoryPage(friend, index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStoryPage(Map<String, dynamic> friend, int index) {
    final isLiked = _isLikedList[index];
    final likeCount = _likeCounts[index];
    final isFollowing = _isFollowingList[index];

    return GestureDetector(
      onDoubleTap: () => _toggleLike(index),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset(
            friend['image'] as String,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.grey[900],
              child: const Center(
                child: Icon(Icons.image, color: Colors.white54, size: 100),
              ),
            ),
          ),

          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.4),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
                stops: const [0.0, 0.15, 0.6, 1.0],
              ),
            ),
          ),

          // Header - User info
          _buildHeader(friend, index, isFollowing),

          // Right side actions
          _buildRightActions(index, isLiked, likeCount),

          // Bottom content
          _buildBottomContent(friend),

          // Swipe hint
          if (index == widget.initialIndex && index < widget.friends.length - 1)
            _buildSwipeHint(),
        ],
      ),
    );
  }

  Widget _buildHeader(
    Map<String, dynamic> friend,
    int index,
    bool isFollowing,
  ) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: friend['isLive'] as bool ? Colors.red : Colors.white,
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: Image.asset(
                    friend['avatar'] as String,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.person, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Name and location
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          friend['name'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (friend['isLive'] as bool) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'LIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.white70,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${friend['location']}, ${friend['country']}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Follow button
              GestureDetector(
                onTap: () => _toggleFollow(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isFollowing ? Colors.white : Colors.transparent,
                    border: Border.all(color: Colors.white),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isFollowing ? 'Đang theo dõi' : 'Theo dõi',
                    style: TextStyle(
                      color: isFollowing ? Colors.black : Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Close button
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRightActions(int index, bool isLiked, int likeCount) {
    return Positioned(
      right: 16,
      bottom: 120,
      child: Column(
        children: [
          // Like
          _buildActionButton(
            icon: isLiked ? Icons.favorite : Icons.favorite_border,
            label: _formatNumber(likeCount),
            color: isLiked ? Colors.red : Colors.white,
            onTap: () => _toggleLike(index),
          ),
          const SizedBox(height: 20),
          // Comment
          _buildActionButton(
            icon: Icons.chat_bubble_outline,
            label: '${(index + 1) * 45}',
            onTap: () => showStoryComments(
              context: context,
              friendName: widget.friends[index]['name'] as String,
            ),
          ),
          const SizedBox(height: 20),
          // Share
          _buildActionButton(
            icon: Icons.share,
            label: 'Chia sẻ',
            onTap: () => showStoryShare(
              context: context,
              friendName: widget.friends[index]['name'] as String,
            ),
          ),
          const SizedBox(height: 20),
          // More
          _buildActionButton(
            icon: Icons.more_horiz,
            label: '',
            onTap: () => showStoryMoreOptions(
              context: context,
              friendName: widget.friends[index]['name'] as String,
              isSaved: _isSavedList[index],
              onToggleSave: () => _toggleSave(index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomContent(Map<String, dynamic> friend) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 20,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Caption
            Padding(
              padding: const EdgeInsets.only(right: 70),
              child: const Text(
                'Chuyến đi tuyệt vời! 🌴✨\nKhung cảnh đẹp quá trời luôn 😍',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Hashtags
            Padding(
              padding: const EdgeInsets.only(right: 70),
              child: Wrap(
                spacing: 8,
                children: [
                  _buildHashtag('#${friend['location']}'),
                  _buildHashtag('#Travel'),
                  _buildHashtag('#${friend['country']}'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Input message
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 45,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Gửi tin nhắn...',
                        hintStyle: TextStyle(color: Colors.white60),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Icon(
                      Icons.send,
                      color: Colors.white.withOpacity(0.7),
                      size: 22,
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

  Widget _buildSwipeHint() {
    return Positioned(
      bottom: 150,
      left: 0,
      right: 0,
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.keyboard_arrow_up,
              color: Colors.white.withOpacity(0.5),
              size: 30,
            ),
            Text(
              'Lướt lên để xem tiếp',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    Color color = Colors.white,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHashtag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        tag,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
