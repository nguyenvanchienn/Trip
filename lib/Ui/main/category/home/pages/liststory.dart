import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tourn/Ui/main/category/home/widgets/button_add/create_and_edit_content.dart';
import 'package:tourn/Ui/main/category/home/widgets/story/story_viewer.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tourn/data/firebase/firebase_story_service.dart';
import 'package:tourn/models/story_model.dart';
import 'package:tourn/models/user_model.dart';
import 'package:tourn/domain/user_repository/user_repository.dart';
import 'package:tourn/ultils.enums/image_utils.dart';

class Liststory extends StatefulWidget {
  const Liststory({super.key});

  @override
  State<Liststory> createState() => _ListstoryState();
}

class _ListstoryState extends State<Liststory> {
  final ImagePicker _picker = ImagePicker();
  final FirebaseStoryService _storyService = FirebaseStoryService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Controllers for story creation
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  String? _selectedCountry;
  bool _isUploading = false;

  // Current user for avatar sync
  UserModel? _currentUser;
  StreamSubscription<UserModel?>? _userSub;
  late Stream<List<StoryModel>> _storiesStream;

  @override
  void initState() {
    super.initState();
    final userRepo = context.read<UserRepository>();
    _userSub = userRepo.streamCurrentUser().listen((user) {
      if (mounted) setState(() => _currentUser = user);
    });
    // Cleanup expired stories async - không block initState
    Future.microtask(() => _storyService.cleanupExpiredStories());
    _storiesStream = _storyService.getPublicStories(limit: 20);
  }

  @override
  void dispose() {
    _userSub?.cancel();
    _captionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  int _priorityForAuthor(String authorId, String currentUid) {
    if (authorId == currentUid) return 0;
    final following = (_currentUser?.following ?? const <String>[]).toSet();
    final followers = (_currentUser?.followers ?? const <String>[]).toSet();
    final isFriend =
        following.contains(authorId) && followers.contains(authorId);
    if (isFriend) return 1;
    if (following.contains(authorId)) return 2;
    return 3;
  }

  bool _hasUnviewedStories(List<StoryModel> stories, String? currentUid) {
    if (currentUid == null) return true;
    return stories.any((story) => !story.viewers.contains(currentUid));
  }

  DateTime _latestStoryTime(List<StoryModel> stories) {
    if (stories.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);
    return stories
        .map((s) => s.createdAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);
  }

  bool _hasLiveStory(List<StoryModel> stories) {
    return stories.any((s) => s.isLive);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF113953).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.explore,
                      color: Color(0xFF113953),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Bạn bè đang khám phá',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF113953),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Stories list with Firebase StreamBuilder
        SizedBox(
          height: 140,
          child: StreamBuilder<List<StoryModel>>(
            stream: _storiesStream,
            builder: (context, snapshot) {
              // Handle loading state
              if (snapshot.connectionState == ConnectionState.waiting) {
                return ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _buildAddStoryItem(),
                    ..._buildLoadingPlaceholders(),
                  ],
                );
              }

              // Handle error state - just show add story button
              if (snapshot.hasError) {
                print('Story stream error: ${snapshot.error}');
                return ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [_buildAddStoryItem()],
                );
              }

              final stories = snapshot.data ?? [];
              print('Got ${stories.length} stories from Firebase');

              // If no stories, show add button with a helpful hint
              if (stories.isEmpty) {
                return ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _buildAddStoryItem(),
                    const SizedBox(width: 12),
                    _buildEmptyStoryHint(),
                  ],
                );
              }

              // Group stories by author
              final Map<String, List<StoryModel>> storiesByAuthor = {};
              for (final story in stories) {
                if (!storiesByAuthor.containsKey(story.authorId)) {
                  storiesByAuthor[story.authorId] = [];
                }
                storiesByAuthor[story.authorId]!.add(story);
              }

              // Sort author IDs - put current user first (like Facebook)
              final currentUid = _auth.currentUser?.uid;
              final authorIds = storiesByAuthor.keys.toList()
                ..sort((a, b) {
                  if (currentUid == null) {
                    final latestA = _latestStoryTime(storiesByAuthor[a]!);
                    final latestB = _latestStoryTime(storiesByAuthor[b]!);
                    return latestB.compareTo(latestA);
                  }

                  final pa = _priorityForAuthor(a, currentUid);
                  final pb = _priorityForAuthor(b, currentUid);
                  if (pa != pb) return pa.compareTo(pb);

                  final aHasUnviewed = _hasUnviewedStories(
                    storiesByAuthor[a]!,
                    currentUid,
                  );
                  final bHasUnviewed = _hasUnviewedStories(
                    storiesByAuthor[b]!,
                    currentUid,
                  );
                  if (aHasUnviewed != bHasUnviewed) {
                    return aHasUnviewed ? -1 : 1;
                  }

                  final aHasLive = _hasLiveStory(storiesByAuthor[a]!);
                  final bHasLive = _hasLiveStory(storiesByAuthor[b]!);
                  if (aHasLive != bHasLive) {
                    return aHasLive ? -1 : 1;
                  }

                  final latestA = _latestStoryTime(storiesByAuthor[a]!);
                  final latestB = _latestStoryTime(storiesByAuthor[b]!);
                  return latestB.compareTo(latestA);
                });

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: authorIds.length + 1, // +1 for "Add Story"
                itemBuilder: (context, index) {
                  // First item is "Add your story"
                  if (index == 0) {
                    // If current user has stories, show their story with indicator
                    if (currentUid != null &&
                        storiesByAuthor.containsKey(currentUid)) {
                      return _buildMyStoryItem(storiesByAuthor[currentUid]!);
                    }
                    return _buildAddStoryItem();
                  }
                  final authorId = authorIds[index - 1];
                  // Skip current user if already shown as first item
                  if (authorId == currentUid) {
                    return const SizedBox.shrink();
                  }
                  final authorStories = storiesByAuthor[authorId]!;
                  final latestStory = authorStories.first;
                  return _buildFriendStoryItem(latestStory, authorStories);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  List<Widget> _buildLoadingPlaceholders() {
    return List.generate(
      4,
      (index) => Container(
        width: 85,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[300],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 50,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStoryHint() {
    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                'Chưa có tin nào',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Hãy là người đầu tiên chia sẻ chuyến đi!',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildMyStoryItem(List<StoryModel> myStories) {
    return GestureDetector(
      onTap: () {
        _showStoryViewer(myStories);
      },
      onLongPress: () {
        _showMediaOptions();
      },
      child: Container(
        width: 85,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          children: [
            Stack(
              children: [
                // Avatar with gradient border (has story)
                Container(
                  width: 70,
                  height: 70,
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF113953), Color(0xFF2196F3)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    padding: const EdgeInsets.all(2),
                    child: ClipOval(
                      child:
                          _currentUser?.photoUrl != null &&
                              _currentUser!.photoUrl!.isNotEmpty &&
                              getImageProvider(_currentUser!.photoUrl!) != null
                          ? Image(
                              image: getImageProvider(_currentUser!.photoUrl!)!,
                              fit: BoxFit.cover,
                              width: 60,
                              height: 60,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.person,
                                size: 30,
                                color: Colors.grey[400],
                              ),
                            )
                          : Image.asset(
                              'asset/images/OIP.jpg',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.person,
                                size: 30,
                                color: Colors.grey[400],
                              ),
                            ),
                    ),
                  ),
                ),
                // Add button overlay
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _showMediaOptions,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFF113953),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Tin của bạn',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddStoryItem() {
    return GestureDetector(
      onTap: () {
        _showMediaOptions();
      },
      child: Container(
        width: 85,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[200],
                    border: Border.all(color: Colors.grey[300]!, width: 2),
                  ),
                  child: ClipOval(
                    child:
                        _currentUser?.photoUrl != null &&
                            _currentUser!.photoUrl!.isNotEmpty &&
                            getImageProvider(_currentUser!.photoUrl!) != null
                        ? Image(
                            image: getImageProvider(_currentUser!.photoUrl!)!,
                            fit: BoxFit.cover,
                            width: 70,
                            height: 70,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.person,
                              size: 35,
                              color: Colors.grey[400],
                            ),
                          )
                        : Image.asset(
                            'asset/images/OIP.jpg',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.person,
                              size: 35,
                              color: Colors.grey[400],
                            ),
                          ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF113953),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Chuyến đi\ncủa bạn',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMediaOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Chia sẻ chuyến đi của bạn',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF113953),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Chọn ảnh hoặc video để chia sẻ',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 20),
                // Camera options
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildMediaOptionButton(
                      icon: Icons.camera_alt,
                      label: 'Chụp ảnh',
                      color: Colors.blue,
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera);
                      },
                    ),
                    _buildMediaOptionButton(
                      icon: Icons.videocam,
                      label: 'Quay video',
                      color: Colors.red,
                      onTap: () {
                        Navigator.pop(context);
                        _pickVideo(ImageSource.camera);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                // Gallery options
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildMediaOptionButton(
                      icon: Icons.photo_library,
                      label: 'Thư viện ảnh',
                      color: Colors.green,
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                    _buildMediaOptionButton(
                      icon: Icons.video_library,
                      label: 'Thư viện video',
                      color: Colors.orange,
                      onTap: () {
                        Navigator.pop(context);
                        _pickVideo(ImageSource.gallery);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                // Create post option
                ListTile(
                  leading: Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: const Color(0xFF113953).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.edit_note,
                      color: Color(0xFF113953),
                    ),
                  ),
                  title: const Text(
                    'Tạo bài viết chi tiết',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Viết bài kèm ảnh và video',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(
                        builder: (_) => const createandeditcontent(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaOptionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1080,
        imageQuality: 85,
      );
      if (picked != null) {
        // Chuyển đến màn hình tạo story với ảnh
        _showStoryPreview(picked.path, isVideo: false);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Không thể chọn ảnh')));
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(seconds: 60),
      );
      if (picked != null) {
        // Chuyển đến màn hình tạo story với video
        _showStoryPreview(picked.path, isVideo: true);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Không thể chọn video')));
    }
  }

  void _showStoryPreview(String filePath, {required bool isVideo}) {
    _captionController.clear();
    _locationController.clear();
    _selectedCountry = 'Việt Nam';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Stack(
            children: [
              // Preview
              Center(
                child: isVideo
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.play_circle_outline,
                            color: Colors.white,
                            size: 80,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Video đã chọn',
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            filePath.split('/').last,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(filePath),
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.image,
                            color: Colors.white54,
                            size: 100,
                          ),
                        ),
                      ),
              ),
              // Header
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                        Row(
                          children: [
                            if (isVideo)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.videocam,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Video',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.photo,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Ảnh',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Bottom actions
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Caption input
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(color: Colors.white30),
                          ),
                          child: TextField(
                            controller: _captionController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Viết caption...',
                              hintStyle: TextStyle(color: Colors.white60),
                              border: InputBorder.none,
                              prefixIcon: Icon(
                                Icons.edit,
                                color: Colors.white60,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Location tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(color: Colors.white30),
                          ),
                          child: TextField(
                            controller: _locationController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Thêm vị trí (VD: Đà Lạt, Hạ Long...)',
                              hintStyle: TextStyle(color: Colors.white60),
                              border: InputBorder.none,
                              prefixIcon: Icon(
                                Icons.location_on,
                                color: Colors.white60,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Country dropdown
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(color: Colors.white30),
                          ),
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedCountry,
                            dropdownColor: Colors.grey[900],
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              prefixIcon: Icon(
                                Icons.flag,
                                color: Colors.white60,
                              ),
                            ),
                            hint: const Text(
                              'Chọn quốc gia',
                              style: TextStyle(color: Colors.white60),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'Việt Nam',
                                child: Text('Việt Nam'),
                              ),
                              DropdownMenuItem(
                                value: 'Thái Lan',
                                child: Text('Thái Lan'),
                              ),
                              DropdownMenuItem(
                                value: 'Nhật Bản',
                                child: Text('Nhật Bản'),
                              ),
                              DropdownMenuItem(
                                value: 'Hàn Quốc',
                                child: Text('Hàn Quốc'),
                              ),
                              DropdownMenuItem(
                                value: 'Indonesia',
                                child: Text('Indonesia'),
                              ),
                              DropdownMenuItem(
                                value: 'Singapore',
                                child: Text('Singapore'),
                              ),
                              DropdownMenuItem(
                                value: 'Khác',
                                child: Text('Khác'),
                              ),
                            ],
                            onChanged: (value) {
                              setModalState(() {
                                _selectedCountry = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Share button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isUploading
                                ? null
                                : () async {
                                    setModalState(() {
                                      _isUploading = true;
                                    });

                                    await _uploadStory(
                                      filePath: filePath,
                                      isVideo: isVideo,
                                    );

                                    setModalState(() {
                                      _isUploading = false;
                                    });

                                    if (mounted) {
                                      Navigator.pop(context);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF113953),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: _isUploading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Chia sẻ ngay',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _uploadStory({
    required String filePath,
    required bool isVideo,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng đăng nhập để chia sẻ story'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      // Get photoUrl from Firestore instead of FirebaseAuth
      final userRepo = context.read<UserRepository>();
      final userData = await userRepo.getCurrentUser();
      final story = await _storyService.createStory(
        filePath: filePath,
        type: isVideo ? StoryType.video : StoryType.image,
        authorName: user.displayName ?? 'Người dùng',
        authorPhotoUrl: userData?.photoUrl,
        caption: _captionController.text.trim().isNotEmpty
            ? _captionController.text.trim()
            : null,
        location: _locationController.text.trim().isNotEmpty
            ? _locationController.text.trim()
            : null,
        country: _selectedCountry,
      );

      if (story != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã chia sẻ chuyến đi của bạn!'),
            backgroundColor: Color(0xFF113953),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể chia sẻ story. Vui lòng thử lại.'),
            backgroundColor: Colors.red,
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

  Widget _buildFriendStoryItem(
    StoryModel latestStory,
    List<StoryModel> authorStories,
  ) {
    final userRepo = context.read<UserRepository>();
    final currentUid = _auth.currentUser?.uid;

    // Check if current user has viewed ALL stories from this author
    final hasUnviewedStory = authorStories.any(
      (story) => currentUid != null && !story.viewers.contains(currentUid),
    );

    return GestureDetector(
      onTap: () {
        // View friend's story
        _showStoryViewer(authorStories);
      },
      child: Container(
        width: 85,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          children: [
            Stack(
              children: [
                // Avatar with gradient border (blue if unviewed, grey if viewed)
                Container(
                  width: 70,
                  height: 70,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: hasUnviewedStory
                        ? const LinearGradient(
                            colors: [Color(0xFF113953), Color(0xFF2196F3)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: hasUnviewedStory ? null : Colors.grey[300],
                  ),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    padding: const EdgeInsets.all(2),
                    child: ClipOval(
                      child: StreamBuilder<UserModel?>(
                        stream: userRepo.streamUser(latestStory.authorId),
                        builder: (context, snapshot) {
                          final user = snapshot.data;
                          final photoUrl =
                              user?.photoUrl ?? latestStory.authorPhotoUrl;
                          if (photoUrl != null &&
                              photoUrl.isNotEmpty &&
                              getImageProvider(photoUrl) != null) {
                            return Image(
                              image: getImageProvider(photoUrl)!,
                              fit: BoxFit.cover,
                              width: 60,
                              height: 60,
                              errorBuilder: (_, __, ___) => Image.asset(
                                'asset/images/OIP.jpg',
                                fit: BoxFit.cover,
                              ),
                            );
                          }
                          return Image.asset(
                            'asset/images/OIP.jpg',
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                    ),
                  ),
                ),
                // Live indicator
                if (latestStory.isLive)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              latestStory.authorName,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            if (latestStory.location != null &&
                latestStory.location!.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 10,
                    color: Color(0xFF113953),
                  ),
                  const SizedBox(width: 2),
                  Flexible(
                    child: Text(
                      latestStory.location!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _showStoryViewer(List<StoryModel> stories) {
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        opaque: true,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) {
          return StoryViewerFirebase(
            stories: stories,
            initialIndex: 0,
            storyService: _storyService,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOut),
                ),
            child: child,
          );
        },
      ),
    );
  }
}
