import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_player/video_player.dart';

class ProfileVideoModel {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final String mediaUrl;
  final String? caption;
  final String? location;
  final String? country;
  final DateTime createdAt;
  final DateTime archivedAt;
  final int likes;
  final int views;
  final String? thumbnailUrl;

  ProfileVideoModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    required this.mediaUrl,
    this.caption,
    this.location,
    this.country,
    required this.createdAt,
    required this.archivedAt,
    this.likes = 0,
    this.views = 0,
    this.thumbnailUrl,
  });

  factory ProfileVideoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProfileVideoModel(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorPhotoUrl: data['authorPhotoUrl'],
      mediaUrl: data['mediaUrl'] ?? '',
      caption: data['caption'],
      location: data['location'],
      country: data['country'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      archivedAt:
          (data['archivedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likes: data['likes'] ?? 0,
      views: data['views'] ?? 0,
      thumbnailUrl: data['thumbnailUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorPhotoUrl': authorPhotoUrl,
      'mediaUrl': mediaUrl,
      'caption': caption,
      'location': location,
      'country': country,
      'createdAt': Timestamp.fromDate(createdAt),
      'archivedAt': Timestamp.fromDate(archivedAt),
      'likes': likes,
      'views': views,
      'thumbnailUrl': thumbnailUrl,
    };
  }
}

class VideoProfile extends StatefulWidget {
  final String? userId;
  const VideoProfile({super.key, this.userId});

  @override
  State<VideoProfile> createState() => _VideoProfileState();
}

class _VideoProfileState extends State<VideoProfile> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _profileUserId => widget.userId ?? _auth.currentUser?.uid ?? '';

  // Get archived videos from profile_videos collection
  Stream<List<ProfileVideoModel>> _getArchivedVideos() {
    if (_profileUserId.isEmpty) return Stream.value([]);

    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) return Stream.value(<ProfileVideoModel>[]);
      return _firestore
          .collection('profile_videos')
          .where('authorId', isEqualTo: _profileUserId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .handleError((_) {})
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => ProfileVideoModel.fromFirestore(doc))
                .toList();
          });
    });
  }

  // Get current active video stories
  Stream<List<ProfileVideoModel>> _getActiveVideoStories() {
    if (_profileUserId.isEmpty) return Stream.value([]);

    final now = DateTime.now();
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) return Stream.value(<ProfileVideoModel>[]);
      return _firestore
          .collection('stories')
          .where('authorId', isEqualTo: _profileUserId)
          .where('type', isEqualTo: 'video')
          .snapshots()
          .handleError((_) {})
          .map((snapshot) {
            return snapshot.docs
                .where((doc) {
                  final expiresAt = (doc.data()['expiresAt'] as Timestamp?)
                      ?.toDate();
                  return expiresAt != null && expiresAt.isAfter(now);
                })
                .map((doc) {
                  final data = doc.data();
                  return ProfileVideoModel(
                    id: doc.id,
                    authorId: data['authorId'] ?? '',
                    authorName: data['authorName'] ?? '',
                    authorPhotoUrl: data['authorPhotoUrl'],
                    mediaUrl: data['mediaUrl'] ?? '',
                    caption: data['caption'],
                    location: data['location'],
                    country: data['country'],
                    createdAt:
                        (data['createdAt'] as Timestamp?)?.toDate() ?? now,
                    archivedAt: now, // Not archived yet
                    likes: (data['likes'] as List?)?.length ?? 0,
                    views: (data['viewers'] as List?)?.length ?? 0,
                  );
                })
                .toList();
          });
    });
  }

  // Combine both streams
  Stream<List<ProfileVideoModel>> _getAllVideos() {
    return _getActiveVideoStories().asyncMap((activeVideos) async {
      // Get archived videos
      final archivedSnapshot = await _firestore
          .collection('profile_videos')
          .where('authorId', isEqualTo: _profileUserId)
          .orderBy('createdAt', descending: true)
          .get();

      final archivedVideos = archivedSnapshot.docs
          .map((doc) => ProfileVideoModel.fromFirestore(doc))
          .toList();

      // Combine and sort by createdAt
      final allVideos = [...activeVideos, ...archivedVideos];
      allVideos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return allVideos;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ProfileVideoModel>>(
      stream: _getAllVideos(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Không thể tải video',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        final videos = snapshot.data ?? [];

        if (videos.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.video_library_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Chưa có video nào',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Đăng video Story để hiển thị ở đây',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(2),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
            childAspectRatio: 9 / 16,
          ),
          itemCount: videos.length,
          itemBuilder: (context, index) {
            return _buildVideoThumbnail(videos[index]);
          },
        );
      },
    );
  }

  Widget _buildVideoThumbnail(ProfileVideoModel video) {
    return GestureDetector(
      onTap: () => _openVideoPlayer(video),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Thumbnail or placeholder
          Container(
            color: Colors.grey[900],
            child: video.thumbnailUrl != null && video.thumbnailUrl!.isNotEmpty
                ? Image.network(
                    video.thumbnailUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildVideoPlaceholder(),
                  )
                : _buildVideoPlaceholder(),
          ),
          // Play icon overlay
          Center(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
          // Views count
          Positioned(
            left: 8,
            bottom: 8,
            child: Row(
              children: [
                const Icon(Icons.play_arrow, color: Colors.white, size: 14),
                const SizedBox(width: 2),
                Text(
                  _formatViews(video.views),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 1),
                        blurRadius: 2,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Location if available
          if (video.location != null && video.location!.isNotEmpty)
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 10,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      video.location!.length > 10
                          ? '${video.location!.substring(0, 10)}...'
                          : video.location!,
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoPlaceholder() {
    return Container(
      color: Colors.grey[800],
      child: const Center(
        child: Icon(Icons.videocam, color: Colors.white54, size: 40),
      ),
    );
  }

  String _formatViews(int views) {
    if (views >= 1000000) {
      return '${(views / 1000000).toStringAsFixed(1)}M';
    } else if (views >= 1000) {
      return '${(views / 1000).toStringAsFixed(1)}K';
    }
    return views.toString();
  }

  void _openVideoPlayer(ProfileVideoModel video) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => VideoPlayerPage(video: video)));
  }
}

class VideoPlayerPage extends StatefulWidget {
  final ProfileVideoModel video;
  const VideoPlayerPage({super.key, required this.video});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _incrementViews();
  }

  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.video.mediaUrl),
    );

    try {
      await _controller.initialize();
      setState(() {
        _isInitialized = true;
      });
      _controller.play();
      setState(() {
        _isPlaying = true;
      });
    } catch (e) {
      print('Error initializing video: $e');
    }

    _controller.addListener(() {
      if (mounted) {
        setState(() {
          _isPlaying = _controller.value.isPlaying;
        });
      }
    });
  }

  Future<void> _incrementViews() async {
    try {
      await FirebaseFirestore.instance
          .collection('profile_videos')
          .doc(widget.video.id)
          .update({'views': FieldValue.increment(1)});
    } catch (e) {
      print('Error incrementing views: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.video.authorName,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: GestureDetector(
        onTap: () {
          setState(() {
            _showControls = !_showControls;
          });
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video player
            Center(
              child: _isInitialized
                  ? AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    )
                  : const CircularProgressIndicator(color: Colors.white),
            ),
            // Controls overlay
            if (_showControls)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        iconSize: 64,
                        icon: Icon(
                          _isPlaying ? Icons.pause_circle : Icons.play_circle,
                          color: Colors.white,
                        ),
                        onPressed: _togglePlayPause,
                      ),
                    ],
                  ),
                ),
              ),
            // Video info at bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.video.caption != null &&
                        widget.video.caption!.isNotEmpty)
                      Text(
                        widget.video.caption!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    if (widget.video.location != null &&
                        widget.video.location!.isNotEmpty)
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.white70,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.video.location!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.remove_red_eye,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.video.views} lượt xem',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.favorite,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.video.likes}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    // Video progress bar
                    if (_isInitialized)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: VideoProgressIndicator(
                          _controller,
                          allowScrubbing: true,
                          colors: const VideoProgressColors(
                            playedColor: Colors.orange,
                            bufferedColor: Colors.white38,
                            backgroundColor: Colors.white24,
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
    );
  }
}
