import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:tourn/data/post/firestore_post_repository.dart';
import 'package:tourn/models/post_model.dart';

/// Simple helper that checks if a url points to a video file based on extension.
bool _isVideoUrl(String url) {
  final lower = url.toLowerCase();
  return lower.endsWith('.mp4') ||
      lower.endsWith('.mov') ||
      lower.endsWith('.webm') ||
      lower.endsWith('.avi') ||
      lower.endsWith('.mkv');
}

class Video extends StatefulWidget {
  const Video({super.key});

  @override
  State<Video> createState() => _VideoState();
}

class _VideoState extends State<Video> with AutomaticKeepAliveClientMixin {
  final FirestorePostRepository _postRepo = FirestorePostRepository();
  List<PostModel> _cachedVideos = [];

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final uid = _postRepo.currentUserId;
    if (uid == null) {
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
      stream: _postRepo.getUserVideoPosts(uid),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _cachedVideos = snapshot.data!;
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            _cachedVideos.isNotEmpty) {
          return _buildVideoList(_cachedVideos);
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          );
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

        final videos = (snapshot.data ?? [])
            .where((p) => p.mediaUrls.any(_isVideoUrl))
            .toList();
        if (videos.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.video_library, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Chưa có video nào',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        }

        return _buildVideoList(videos);
      },
    );
  }

  Widget _buildVideoList(List<PostModel> videos) {
    // show as column so parent scrolling can handle gestures
    return Column(
      children: videos
          .map((p) => _VideoPostCard(post: p))
          .toList(growable: false),
    );
  }
}

class _VideoPostCard extends StatefulWidget {
  final PostModel post;
  const _VideoPostCard({required this.post});

  @override
  State<_VideoPostCard> createState() => _VideoPostCardState();
}

class _VideoPostCardState extends State<_VideoPostCard> {
  VideoPlayerController? _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    final url = widget.post.mediaUrls.firstWhere(_isVideoUrl, orElse: () => '');
    if (url.isNotEmpty) {
      _controller = VideoPlayerController.network(url)
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              _initialized = true;
            });
          }
        });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized || _controller == null) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return GestureDetector(
      onTap: () {
        if (_controller!.value.isPlaying) {
          _controller!.pause();
        } else {
          _controller!.play();
        }
        setState(() {});
      },
      child: AspectRatio(
        aspectRatio: _controller!.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(_controller!),
            if (!_controller!.value.isPlaying)
              const Icon(Icons.play_arrow, size: 64, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}
