// đây là file chứa code của trang tạo và chỉnh sửa bài viết trong phần home
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

// Local widgets (relative imports help avoid package-name mismatches)
import '../PostSettingsPage/PostSettingsPage.dart';
import '../PostSettingsPage/congtacvien.dart';
import '../check_in.dart';
import 'live_stream.dart';
import 'edit_photo_page.dart';
import 'layout_selector_dialog.dart';

// Domain and model classes
import '../../../../../../domain/user_repository/user_repository.dart';
import '../../../../../../models/user_model.dart';

// Utilities
import '../../../../../../ultils.enums/image_utils.dart';

// model for experience entries
class ExperienceEntry {
  final String category;
  final String? title;
  final String content;

  ExperienceEntry({required this.category, this.title, required this.content});
}

class createandeditcontent extends StatefulWidget {
  const createandeditcontent({super.key});

  @override
  State<createandeditcontent> createState() => _createandeditcontentState();
}

class _createandeditcontentState extends State<createandeditcontent> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final GlobalKey _textFieldKey = GlobalKey();
  final DraggableScrollableController _draggableController =
      DraggableScrollableController();
  bool _sheetAttached = false;

  // header pills state
  String _visibility = 'Công khai';
  bool _isExperienceSharing = false;
  bool _showExperienceInput = false;
  String? _experienceCategory; // Chi phí / Ăn uống / Lộ trình / Khác
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _experienceTitleController =
      TextEditingController();

  // multiple entries
  final List<ExperienceEntry> _experienceEntries = [];
  final FocusNode _experienceFocus = FocusNode();

  bool isTyping = false;
  final ValueNotifier<Color> _bgColor = ValueNotifier<Color>(Colors.black);
  final int _minLinesCount = 7;
  static const double _typingPanelHeight =
      70; // chiều cao của panel khi đang nhập nội dung (cảm xúc, gắn thẻ, check in)

  // List to store selected media files
  final List<XFile> _selectedMedia = [];

  // Selected layout index (0: 2 columns, 1: single, 2: horizontal, 3: 1big+2small)
  int _selectedLayout = 0;

  // Captions for each image
  final Map<int, String> _imageCaptions = {};

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    // Rebuild to update "Tiếp" button state
    if (mounted) setState(() {});
  }

  void _onFocusChange() {
    final hasFocus = _focusNode.hasFocus;
    if (mounted) {
      setState(() {
        isTyping = hasFocus;
      });
    }
    if (hasFocus) {
      // when typing, the sheet is not attached
      _sheetAttached = false;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    _experienceController.dispose();
    _experienceTitleController.dispose();
    _experienceFocus.dispose();
    _draggableController.dispose();
    _bgColor.dispose();
    super.dispose();
  }

  // helper to inject text at current cursor position
  void _insertText(String text) {
    final value = _controller.value;
    final selection = value.selection;
    final newText = value.text.replaceRange(
      selection.start,
      selection.end,
      text,
    );
    final newOffset = selection.start + text.length;
    _controller.value = value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newOffset),
    );
    FocusScope.of(context).requestFocus(_focusNode);
  }

  // Insert hashtag with location suggestions
  void _showHashtagPicker() {
    final searchController = TextEditingController();
    final suggestions = ValueNotifier<List<String>>([]);
    final customHashtag = ValueNotifier<String>('');

    // Popular travel locations in Vietnam
    final popularLocations = [
      'HàNội',
      'SàiGòn',
      'ĐàNẵng',
      'HộiAn',
      'HạLong',
      'SaPa',
      'ĐàLạt',
      'NhaTrang',
      'PhúQuốc',
      'Huế',
      'QuảngBình',
      'MũiNé',
      'VũngTàu',
      'CầnThơ',
      'CônĐảo',
      'QuyNhơn',
      'FansiPan',
      'TamĐảo',
      'MộcChâu',
      'Biển',
      'Núi',
      'ẨmThực',
      'VănHóa',
      'DuLịch',
      'KhámPhá',
      'CheckIn',
      'Travel',
      'Vietnam',
      'Food',
      'Beach',
      'Mountain',
      'Culture',
    ];

    suggestions.value = popularLocations;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF2A2A2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.5,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Thêm hashtag',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Search field
                TextField(
                  controller: searchController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Nhập hashtag hoặc tìm kiếm...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: const Icon(Icons.tag, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (query) {
                    final trimmed = query.trim();
                    customHashtag.value = trimmed;
                    if (trimmed.isEmpty) {
                      suggestions.value = popularLocations;
                    } else {
                      suggestions.value = popularLocations
                          .where(
                            (loc) => loc.toLowerCase().contains(
                              trimmed.toLowerCase(),
                            ),
                          )
                          .toList();
                    }
                  },
                  onSubmitted: (value) {
                    // Allow user to submit custom hashtag by pressing enter
                    final trimmed = value.trim();
                    if (trimmed.isNotEmpty) {
                      // Remove leading # if user typed it
                      final cleanTag = trimmed.startsWith('#')
                          ? trimmed.substring(1)
                          : trimmed;
                      if (cleanTag.isNotEmpty) {
                        _insertText('#$cleanTag ');
                        Navigator.pop(context);
                      }
                    }
                  },
                ),
                const SizedBox(height: 12),
                // Custom hashtag option (show when user types something not in list)
                ValueListenableBuilder<String>(
                  valueListenable: customHashtag,
                  builder: (context, tag, _) {
                    if (tag.isEmpty) return const SizedBox.shrink();
                    // Remove leading # if typed
                    final cleanTag = tag.startsWith('#')
                        ? tag.substring(1)
                        : tag;
                    // Check if it exactly matches any suggestion
                    final exactMatch = popularLocations.any(
                      (loc) => loc.toLowerCase() == cleanTag.toLowerCase(),
                    );
                    if (exactMatch) return const SizedBox.shrink();

                    return ListTile(
                      leading: const Icon(
                        Icons.add_circle_outline,
                        color: Colors.green,
                      ),
                      title: Text(
                        'Tạo hashtag mới: #$cleanTag',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () {
                        _insertText('#$cleanTag ');
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
                const Text(
                  'Đề xuất',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 8),
                // Suggestions list
                Expanded(
                  child: ValueListenableBuilder<List<String>>(
                    valueListenable: suggestions,
                    builder: (context, locs, _) {
                      if (locs.isEmpty) {
                        return Center(
                          child: Text(
                            'Không tìm thấy. Nhấn Enter hoặc\nchọn "Tạo hashtag mới" ở trên.',
                            style: TextStyle(color: Colors.grey[400]),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return ListView.builder(
                        itemCount: locs.length,
                        itemBuilder: (context, index) {
                          final loc = locs[index];
                          return ListTile(
                            leading: const Icon(
                              Icons.location_on,
                              color: Colors.blue,
                            ),
                            title: Text(
                              '#$loc',
                              style: const TextStyle(color: Colors.white),
                            ),
                            onTap: () {
                              _insertText('#$loc ');
                              Navigator.pop(context);
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Insert mention with friend suggestions
  void _showMentionPicker() {
    final searchController = TextEditingController();
    final suggestions = ValueNotifier<List<UserModel>>([]);
    final isLoading = ValueNotifier<bool>(true);

    // Load following users
    _loadFollowingUsers(suggestions, isLoading);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF2A2A2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.5,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Gắn thẻ bạn bè',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Search field
                TextField(
                  controller: searchController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm bạn bè...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (query) {
                    _searchUsers(query, suggestions, isLoading);
                  },
                ),
                const SizedBox(height: 12),
                const Text(
                  'Bạn bè',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 8),
                // Suggestions list
                Expanded(
                  child: ValueListenableBuilder<bool>(
                    valueListenable: isLoading,
                    builder: (context, loading, _) {
                      if (loading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return ValueListenableBuilder<List<UserModel>>(
                        valueListenable: suggestions,
                        builder: (context, users, _) {
                          if (users.isEmpty) {
                            return const Center(
                              child: Text(
                                'Không tìm thấy bạn bè',
                                style: TextStyle(color: Colors.grey),
                              ),
                            );
                          }
                          return ListView.builder(
                            itemCount: users.length,
                            itemBuilder: (context, index) {
                              final user = users[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: user.photoUrl != null
                                      ? getImageProvider(user.photoUrl!)
                                      : null,
                                  child: user.photoUrl == null
                                      ? const Icon(Icons.person)
                                      : null,
                                ),
                                title: Text(
                                  user.displayName,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                subtitle: Text(
                                  '@${user.displayName.replaceAll(' ', '')}',
                                  style: TextStyle(color: Colors.grey[400]),
                                ),
                                onTap: () {
                                  _insertText('@${user.displayName} ');
                                  Navigator.pop(context);
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Load following users for mention suggestions
  Future<void> _loadFollowingUsers(
    ValueNotifier<List<UserModel>> suggestions,
    ValueNotifier<bool> isLoading,
  ) async {
    try {
      final userRepository = context.read<UserRepository>();
      final currentUser = await userRepository.getCurrentUser();
      if (currentUser != null) {
        userRepository.getFollowing(currentUser.uid).listen((users) {
          suggestions.value = users;
          isLoading.value = false;
        });
      } else {
        isLoading.value = false;
      }
    } catch (e) {
      isLoading.value = false;
    }
  }

  // Search users by query
  Future<void> _searchUsers(
    String query,
    ValueNotifier<List<UserModel>> suggestions,
    ValueNotifier<bool> isLoading,
  ) async {
    if (query.isEmpty) {
      _loadFollowingUsers(suggestions, isLoading);
      return;
    }

    try {
      isLoading.value = true;
      final userRepository = context.read<UserRepository>();
      final users = await userRepository.searchUsers(query);
      suggestions.value = users;
      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
    }
  }

  // Pick image or video from gallery
  Future<void> _pickMedia() async {
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      showDragHandle: false,
      backgroundColor: const Color(0xFF2A2A2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.green),
                title: const Text(
                  'Chọn ảnh từ thư viện',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final List<XFile> images = await picker.pickMultiImage();
                  if (images.isNotEmpty) {
                    setState(() {
                      _selectedMedia.addAll(images);
                      _sheetAttached = false;
                    });
                    _showMediaSelectedSnackbar('Đã chọn ${images.length} ảnh');
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_library, color: Colors.blue),
                title: const Text(
                  'Chọn video từ thư viện',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? video = await picker.pickVideo(
                    source: ImageSource.gallery,
                  );
                  if (video != null) {
                    setState(() {
                      _selectedMedia.add(video);
                      _sheetAttached = false;
                    });
                    _showMediaSelectedSnackbar('Đã chọn video');
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.orange),
                title: const Text(
                  'Chụp ảnh',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? photo = await picker.pickImage(
                    source: ImageSource.camera,
                  );
                  if (photo != null) {
                    setState(() {
                      _selectedMedia.add(photo);
                      _sheetAttached = false;
                    });
                    _showMediaSelectedSnackbar('Đã chụp ảnh');
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam, color: Colors.red),
                title: const Text(
                  'Quay video',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? video = await picker.pickVideo(
                    source: ImageSource.camera,
                  );
                  if (video != null) {
                    setState(() {
                      _selectedMedia.add(video);
                      _sheetAttached = false;
                    });
                    _showMediaSelectedSnackbar('Đã quay video');
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showMediaSelectedSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // Show emotion/activity picker
  void _showEmotionPicker() {
    final emotions = [
      {'emoji': '😊', 'label': 'Vui vẻ'},
      {'emoji': '😍', 'label': 'Yêu thích'},
      {'emoji': '😢', 'label': 'Buồn'},
      {'emoji': '😠', 'label': 'Tức giận'},
      {'emoji': '😮', 'label': 'Ngạc nhiên'},
      {'emoji': '😴', 'label': 'Mệt mỏi'},
      {'emoji': '🤔', 'label': 'Đang nghĩ'},
      {'emoji': '🥳', 'label': 'Ăn mừng'},
      {'emoji': '😎', 'label': 'Tự tin'},
      {'emoji': '🤗', 'label': 'Hạnh phúc'},
      {'emoji': '😋', 'label': 'Đang ăn'},
      {'emoji': '🏃', 'label': 'Đang chạy'},
    ];

    final activities = [
      {
        'icon': Icons.local_cafe,
        'label': 'Đang uống cà phê',
        'color': Colors.brown,
      },
      {'icon': Icons.restaurant, 'label': 'Đang ăn', 'color': Colors.orange},
      {'icon': Icons.movie, 'label': 'Đang xem phim', 'color': Colors.red},
      {
        'icon': Icons.music_note,
        'label': 'Đang nghe nhạc',
        'color': Colors.purple,
      },
      {'icon': Icons.flight, 'label': 'Đang du lịch', 'color': Colors.blue},
      {
        'icon': Icons.sports_soccer,
        'label': 'Đang chơi thể thao',
        'color': Colors.green,
      },
      {
        'icon': Icons.shopping_bag,
        'label': 'Đang mua sắm',
        'color': Colors.pink,
      },
      {'icon': Icons.book, 'label': 'Đang đọc sách', 'color': Colors.teal},
    ];

    showModalBottomSheet(
      context: context,
      showDragHandle: false,
      backgroundColor: const Color(0xFF2A2A2A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Cảm xúc/Hoạt động',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Text(
                            'CẢM XÚC',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                childAspectRatio: 0.9,
                              ),
                          itemCount: emotions.length,
                          itemBuilder: (context, index) {
                            return InkWell(
                              onTap: () {
                                Navigator.pop(context);
                                _showMediaSelectedSnackbar(
                                  'Đã chọn: ${emotions[index]['label']}',
                                );
                              },
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    emotions[index]['emoji']!,
                                    style: const TextStyle(fontSize: 32),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    emotions[index]['label']!,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Text(
                            'HOẠT ĐỘNG',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        ...activities.map((activity) {
                          return ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: (activity['color'] as Color).withOpacity(
                                  0.2,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                activity['icon'] as IconData,
                                color: activity['color'] as Color,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              activity['label'] as String,
                              style: const TextStyle(color: Colors.white),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              _showMediaSelectedSnackbar(
                                'Đã chọn: ${activity['label']}',
                              );
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Show color picker dialog
  void _showColorPickerDialog() {
    final colors = [
      {'color': Colors.black, 'name': 'Đen'},
      {'color': Colors.white, 'name': 'Trắng'},
      {'color': Colors.blue, 'name': 'Xanh dương'},
      {'color': Colors.cyan, 'name': 'Xanh ngọc'},
      {'color': Colors.purple, 'name': 'Tím'},
      {'color': Colors.red, 'name': 'Đỏ'},
      {'color': Colors.orange, 'name': 'Cam'},
      {'color': Colors.green, 'name': 'Xanh lá'},
      {'color': Colors.pink, 'name': 'Hồng'},
      {'color': Colors.yellow, 'name': 'Vàng'},
      {'color': Colors.indigo, 'name': 'Chàm'},
      {'color': Colors.teal, 'name': 'Xanh mòng két'},
    ];

    showModalBottomSheet(
      context: context,
      showDragHandle: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Chọn màu nền',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemCount: colors.length,
                itemBuilder: (context, index) {
                  final colorData = colors[index];
                  final color = colorData['color'] as Color;
                  return GestureDetector(
                    onTap: () {
                      _bgColor.value = color;
                      Navigator.pop(context);
                    },
                    child: ValueListenableBuilder<Color>(
                      valueListenable: _bgColor,
                      builder: (context, currentColor, _) {
                        final isSelected = currentColor == color;
                        return Container(
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFFFB620)
                                  : Colors.grey,
                              width: isSelected ? 3 : 1,
                            ),
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check,
                                  color:
                                      color == Colors.white ||
                                          color == Colors.yellow
                                      ? Colors.black
                                      : Colors.white,
                                  size: 20,
                                )
                              : null,
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _safeAnimateTo(
    double target, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOut,
  }) {
    // Only animate if sheet is attached and images are not selected
    if (!_sheetAttached || _selectedMedia.isNotEmpty) return;
    try {
      _draggableController.animateTo(target, duration: duration, curve: curve);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () {
            // Close without animating the sheet to avoid UI hangs when
            // popping the route during an ongoing sheet animation.
            FocusScope.of(context).unfocus();
            Navigator.of(context).maybePop();
          },
          child: const Icon(Icons.close, color: Colors.black87),
        ),
        centerTitle: true,
        title: GestureDetector(
          onTap: () {
            _safeAnimateTo(0.35);
          },
          child: const Text(
            'Tạo bài viết',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontSize: 20,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: (_controller.text.trim().isEmpty && _selectedMedia.isEmpty)
                  ? null
                  : () async {
                      _safeAnimateTo(0.35);
                      // Convert XFile to bytes for web compatibility
                      List<Uint8List>? mediaBytes;
                      if (_selectedMedia.isNotEmpty) {
                        mediaBytes = [];
                        for (final media in _selectedMedia) {
                          final bytes = await media.readAsBytes();
                          mediaBytes.add(bytes);
                        }
                      }
                      // Convert experience entries to Map format
                      List<Map<String, dynamic>>? experienceEntriesMap;
                      if (_experienceEntries.isNotEmpty) {
                        experienceEntriesMap = _experienceEntries
                            .map(
                              (e) => {
                                'category': e.category,
                                'title': e.title,
                                'content': e.content,
                              },
                            )
                            .toList();
                      }
                      if (!context.mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PostSettingsPage(
                            content: _controller.text,
                            backgroundColor: _bgColor.value.value,
                            mediaBytes: mediaBytes,
                            layoutIndex: _selectedLayout,
                            experienceEntries: experienceEntriesMap,
                          ),
                        ),
                      );
                    },
              child: Text(
                'Tiếp',
                style: TextStyle(
                  color:
                      (_controller.text.trim().isEmpty &&
                          _selectedMedia.isEmpty)
                      ? Colors.grey
                      : Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              if (_focusNode.hasFocus) {
                FocusScope.of(context).unfocus();
                setState(() {
                  isTyping = false;
                });
                // Only animate sheet if it's attached (no images selected)
                if (_selectedMedia.isEmpty && _sheetAttached) {
                  try {
                    final double size = _draggableController.size;
                    const double initial = 0.35;
                    if (size > initial + 0.01) {
                      _safeAnimateTo(initial);
                    }
                  } catch (_) {}
                }
              }
            },
            child: Column(
              children: [
                _buildHeader(),
                if (_selectedMedia.isNotEmpty)
                  _buildMediaWithTextOverlay()
                else
                  Expanded(
                    child: Column(
                      children: [Flexible(child: _buildTextField())],
                    ),
                  ),
              ],
            ),
          ),
          if (isTyping || _showExperienceInput) // mở panel khi đang nhập
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.of(context).viewInsets.bottom,
              height: _typingPanelHeight,
              child: Container(
                color: const Color(0xFFF5F5F5),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: _typingOptions(),
              ),
            )
          else // Hiển thị DraggableScrollableSheet khi không nhập
            DraggableScrollableSheet(
              controller: _draggableController,
              initialChildSize: _selectedMedia.isNotEmpty ? 0.12 : 0.35,
              minChildSize: 0.12,
              maxChildSize: 0.9,
              builder: (context, scrollController) {
                // keep track when sheet is attached so we can safely animate it
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _sheetAttached = true;
                });

                return ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Container(
                    color: const Color(0xFFF5F5F5),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Compact icons row (always visible)
                        // Detailed list (visible when expanded)
                        Expanded(
                          child: NotificationListener<ScrollNotification>(
                            // any scroll in the sheet should hide the keyboard
                            onNotification: (notif) {
                              if (_focusNode.hasFocus) {
                                FocusScope.of(context).unfocus();
                                setState(() {
                                  isTyping = false;
                                });
                              }
                              return false;
                            },
                            child: ListView(
                              controller: scrollController,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              children: [
                                _OptionTile(
                                  Icons.image,
                                  Colors.green,
                                  'Ảnh/video',
                                  onTap: () => _pickMedia(),
                                ),
                                _OptionTile(
                                  Icons.person_add,
                                  Colors.blue,
                                  'Gắn thẻ người khác',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const Congtacvien(),
                                      ),
                                    );
                                  },
                                ),
                                _OptionTile(
                                  Icons.emoji_emotions,
                                  Colors.orange,
                                  'Cảm xúc/hoạt động',
                                  onTap: () => _showEmotionPicker(),
                                ),
                                _OptionTile(
                                  Icons.location_on,
                                  Colors.red,
                                  'Check in',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const CheckIn(),
                                      ),
                                    );
                                  },
                                ),
                                _OptionTile(
                                  Icons.videocam,
                                  Colors.pink,
                                  'Video trực tiếp',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const LiveStreamPage(),
                                      ),
                                    );
                                  },
                                ),
                                // Only show color picker option when no images selected
                                if (_selectedMedia.isEmpty)
                                  _OptionTile(
                                    Icons.text_fields,
                                    Colors.cyan,
                                    'Màu nền',
                                    onTap: () => _showColorPickerDialog(),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final userRepo = context.read<UserRepository>();

    return StreamBuilder<UserModel?>(
      stream: userRepo.streamCurrentUser(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final displayName = user?.displayName ?? 'Người dùng';
        final photoUrl = user?.photoUrl;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                    ? getImageProvider(photoUrl)
                    : const AssetImage('asset/images/OIP.jpg') as ImageProvider,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _pill(_visibility, onTap: _changeVisibility),
                        _pill('+ Album', onTap: _selectAlbum),
                        _pill(
                          _isExperienceSharing
                              ? '+ Chia sẻ kinh nghiệm đang bật'
                              : '+ Chia sẻ kinh nghiệm đang tắt',
                          onTap: () {
                            setState(() {
                              _isExperienceSharing = !_isExperienceSharing;
                              if (!_isExperienceSharing) {
                                _showExperienceInput = false;
                                _experienceCategory = null;
                                _experienceController.clear();
                                _experienceEntries.clear();
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _changeVisibility() async {
    // simple bottom sheet to pick visibility
    final options = ['Công khai', 'Bạn bè', 'Chỉ mình tôi'];
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (c) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: options
                .map(
                  (o) => ListTile(
                    title: Text(o),
                    onTap: () => Navigator.pop(c, o),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
    if (choice != null) {
      setState(() {
        _visibility = choice;
      });
    }
  }

  void _selectAlbum() {
    // placeholder; could push album picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tính năng album chưa hỗ trợ')),
    );
  }

  Widget _buildMediaPreview() {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedMedia.length,
        itemBuilder: (context, index) {
          final media = _selectedMedia[index];
          final isVideo =
              media.path.toLowerCase().endsWith('.mp4') ||
              media.path.toLowerCase().endsWith('.mov') ||
              media.path.toLowerCase().endsWith('.avi');

          return Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: isVideo ? Colors.grey[800] : null,
                ),
                clipBehavior: Clip.antiAlias,
                child: isVideo
                    ? const Center(
                        child: Icon(
                          Icons.play_circle_outline,
                          color: Colors.white,
                          size: 40,
                        ),
                      )
                    : FutureBuilder<Uint8List>(
                        future: media.readAsBytes(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Image.memory(
                              snapshot.data!,
                              fit: BoxFit.cover,
                              width: 100,
                              height: 100,
                            );
                          }
                          return const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          );
                        },
                      ),
              ),
              Positioned(
                top: 4,
                right: 12,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedMedia.removeAt(index);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Current image index for display
  final int _currentImageIndex = 0;

  Widget _buildMediaWithTextOverlay() {
    return Expanded(
      child: Column(
        children: [
          // scrolling region contains text input and grid
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Text input field at top
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: const Color(0xFF1A1A1A),
                    child: Column(
                      children: [
                        TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          maxLines: 2,
                          minLines: 1,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Hãy nói gì đó về nội dung này...',
                            hintStyle: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 16,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        if (_experienceEntries.isNotEmpty)
                          _buildExperienceList(),
                        if (_isExperienceSharing)
                          GestureDetector(
                            onTap: _startExperienceEntry,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                children: const [
                                  Icon(Icons.add, color: Colors.grey, size: 20),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Thêm chia sẻ kinh nghiệm',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (_showExperienceInput) _buildExperienceInput(),
                      ],
                    ),
                  ),

                  // Image grid - Facebook style (square aspect ratio)
                  if (_selectedMedia.isNotEmpty)
                    AspectRatio(
                      aspectRatio: 1.0, // Square grid
                      child: Container(
                        color: Colors.white,
                        child: _buildFacebookStyleGrid(),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Bottom toolbar - only layout selector
          Container(
            color: const Color(0xFF1A1A1A),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Center(
              child: GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    showDragHandle: false,
                    backgroundColor: Colors.transparent,
                    builder: (_) => LayoutSelectorDialog(
                      images: _selectedMedia,
                      currentLayout: _selectedLayout,
                      onLayoutSelected: (layout) {
                        setState(() {
                          _selectedLayout = layout;
                        });
                      },
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.grid_view,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          // Space for DraggableScrollableSheet (12% of screen when media selected)
          SizedBox(height: MediaQuery.of(context).size.height * 0.12),
        ],
      ),
    );
  }

  Widget _buildToolbarIcon(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: color, size: 22),
    );
  }

  Widget _buildFacebookStyleGrid() {
    if (_selectedMedia.isEmpty) return const SizedBox.shrink();

    final int totalImages = _selectedMedia.length;

    // Switch based on selected layout
    switch (_selectedLayout) {
      case 1: // Ảnh đơn - Single image (carousel style)
        return _buildLayoutSingle();
      case 2: // Cuộn ngang - Horizontal scroll
        return _buildLayoutHorizontal();
      case 3: // 1 lớn + 2 nhỏ
        return _buildLayout1Big2Small();
      case 0: // Lưới 2 cột - Default grid
      default:
        return _buildLayoutGrid2Columns();
    }
  }

  // Layout 0: Grid 2 columns (default) - 2x2 grid với 4 ô bằng nhau
  Widget _buildLayoutGrid2Columns() {
    final int totalImages = _selectedMedia.length;

    if (totalImages == 1) {
      return _buildMediaItem(0, showRemove: true, showEdit: true);
    }

    if (totalImages == 2) {
      // 2 ảnh - hiển thị 2 cột, 1 hàng
      return Row(
        children: [
          Expanded(child: _buildMediaItem(0, showRemove: true, showEdit: true)),
          const SizedBox(width: 2),
          Expanded(child: _buildMediaItem(1, showRemove: true)),
        ],
      );
    }

    // 3+ images - Grid 2x2
    return Column(
      children: [
        // Hàng 1
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _buildMediaItem(0, showRemove: true, showEdit: true),
              ),
              const SizedBox(width: 2),
              Expanded(child: _buildMediaItem(1, showRemove: false)),
            ],
          ),
        ),
        const SizedBox(height: 2),
        // Hàng 2
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: totalImages > 2
                    ? _buildMediaItem(2, showRemove: false)
                    : const SizedBox(),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: totalImages > 3
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          _buildMediaItem(3, showRemove: false),
                          if (totalImages > 4)
                            GestureDetector(
                              onTap: () => _showImageSelectionSheet(),
                              child: Container(
                                color: Colors.black54,
                                child: Center(
                                  child: Text(
                                    '+${totalImages - 3}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      )
                    : const SizedBox(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Layout 1: Single image (show one at a time with navigation)
  Widget _buildLayoutSingle() {
    return PageView.builder(
      itemCount: _selectedMedia.length,
      itemBuilder: (context, index) {
        return _buildMediaItem(
          index,
          showRemove: index == 0,
          showEdit: index == 0,
        );
      },
    );
  }

  // Layout 2: Horizontal scroll
  Widget _buildLayoutHorizontal() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: _selectedMedia.length,
      itemBuilder: (context, index) {
        return Container(
          width: MediaQuery.of(context).size.width * 0.7,
          margin: EdgeInsets.only(
            left: index == 0 ? 0 : 4,
            right: index == _selectedMedia.length - 1 ? 0 : 4,
          ),
          child: _buildMediaItem(
            index,
            showRemove: index == 0,
            showEdit: index == 0,
          ),
        );
      },
    );
  }

  // Layout 3: 1 big + 2 small
  Widget _buildLayout1Big2Small() {
    final int totalImages = _selectedMedia.length;

    if (totalImages == 1) {
      return _buildMediaItem(0, showRemove: true, showEdit: true);
    }

    if (totalImages == 2) {
      return Column(
        children: [
          Expanded(
            flex: 2,
            child: _buildMediaItem(0, showRemove: true, showEdit: true),
          ),
          const SizedBox(height: 2),
          Expanded(child: _buildMediaItem(1, showRemove: false)),
        ],
      );
    }

    // 3+ images
    return Column(
      children: [
        Expanded(
          flex: 2,
          child: _buildMediaItem(0, showRemove: true, showEdit: true),
        ),
        const SizedBox(height: 2),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildMediaItem(1, showRemove: false)),
              const SizedBox(width: 2),
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildMediaItem(2, showRemove: false),
                    if (totalImages > 3)
                      GestureDetector(
                        onTap: () => _showImageSelectionSheet(),
                        child: Container(
                          color: Colors.black54,
                          child: Center(
                            child: Text(
                              '+${totalImages - 3}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
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
      ],
    );
  }

  Widget _buildMediaItem(
    int index, {
    bool showRemove = false,
    bool showEdit = false,
  }) {
    if (index >= _selectedMedia.length) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        // If single image, go to edit. If multiple, show selection sheet
        if (_selectedMedia.length == 1) {
          _navigateToEditPhoto(index);
        } else {
          _showImageSelectionSheet();
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          FutureBuilder<Uint8List>(
            future: _selectedMedia[index].readAsBytes(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Image.memory(snapshot.data!, fit: BoxFit.cover);
              }
              return Container(
                color: Colors.grey[300],
                child: const Center(child: CircularProgressIndicator()),
              );
            },
          ),
          // Top buttons row (edit + remove) - only on first image
          if (showEdit || showRemove)
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Edit button - only show on first image
                  if (showEdit)
                    GestureDetector(
                      onTap: () {
                        if (_selectedMedia.length == 1) {
                          _navigateToEditPhoto(0);
                        } else {
                          _showImageSelectionSheet();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Aa Chỉnh sửa',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  // Remove button
                  if (showRemove)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedMedia.removeAt(index);
                          _imageCaptions.remove(index);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 18,
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

  void _navigateToEditPhoto(int index) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditPhotoPage(
          imageFile: _selectedMedia[index],
          index: index,
          onSave: (idx, caption) {
            setState(() {
              if (caption != null) {
                _imageCaptions[idx] = caption;
              }
            });
          },
          onDelete: (idx) {
            setState(() {
              _selectedMedia.removeAt(idx);
              _imageCaptions.remove(idx);
            });
          },
        ),
      ),
    );
  }

  void _showImageOptionsMenu(BuildContext parentContext, int index) {
    showModalBottomSheet(
      context: parentContext,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Options container
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    // Remove photo option
                    _buildOptionItem('Gỡ ảnh ${index + 1}', Colors.red, () {
                      Navigator.pop(context);
                      Navigator.pop(parentContext);
                      setState(() {
                        _selectedMedia.removeAt(index);
                        _imageCaptions.remove(index);
                      });
                      if (_selectedMedia.isNotEmpty) {
                        _showImageSelectionSheet();
                      }
                    }),
                    const Divider(height: 1),
                    // Edit photo option
                    _buildOptionItem(
                      'Chỉnh sửa ảnh ${index + 1}',
                      Colors.blue,
                      () {
                        Navigator.pop(context);
                        Navigator.pop(parentContext);
                        _navigateToEditPhoto(index);
                      },
                    ),
                    const Divider(height: 1),
                    // Alt text option
                    _buildOptionItem(
                      'Chỉnh sửa văn bản thay thế',
                      Colors.blue,
                      () {
                        Navigator.pop(context);
                        _showAltTextDialog(index);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Cancel button
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: _buildOptionItem(
                  'Hủy',
                  Colors.blue,
                  () => Navigator.pop(context),
                  isBold: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionItem(
    String title,
    Color color,
    VoidCallback onTap, {
    bool isBold = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _showAltTextDialog(int index) {
    final TextEditingController altTextController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Văn bản thay thế',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: altTextController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Mô tả ảnh cho người khiếm thị...',
            hintStyle: TextStyle(color: Colors.grey[500]),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[600]!),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blue),
            ),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _showImageSelectionSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF2A2A2A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Chỉnh sửa ảnh',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Image list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _selectedMedia.length,
                  itemBuilder: (context, index) {
                    return _buildImageSelectionItem(index);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSelectionItem(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with controls
          Stack(
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: FutureBuilder<Uint8List>(
                  future: _selectedMedia[index].readAsBytes(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Image.memory(
                        snapshot.data!,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      );
                    }
                    return Container(
                      width: double.infinity,
                      height: 200,
                      color: Colors.grey[800],
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                ),
              ),
              // Top controls
              Positioned(
                top: 8,
                left: 8,
                right: 8,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Edit button
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToEditPhoto(index);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Aa Chỉnh sửa',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    // More + Delete buttons
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            _showImageOptionsMenu(context, index);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.more_horiz,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedMedia.removeAt(index);
                              _imageCaptions.remove(index);
                            });
                            if (_selectedMedia.isEmpty) {
                              Navigator.pop(context);
                            } else {
                              // Rebuild the sheet
                              Navigator.pop(context);
                              _showImageSelectionSheet();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Caption input
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Thêm chú thích...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (value) {
                _imageCaptions[index] = value;
              },
              controller: TextEditingController(
                text: _imageCaptions[index] ?? '',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String text, {VoidCallback? onTap}) {
    Widget child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade600,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        softWrap: true,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
    if (onTap != null) {
      child = GestureDetector(onTap: onTap, child: child);
    }
    return child;
  }

  Widget _buildTextField() {
    final double fontSize = 20;
    final double lineHeightPx = fontSize * 1.2;
    final double verticalPadding = 16;
    final double fixedHeight =
        (lineHeightPx * _minLinesCount) + verticalPadding;

    return ValueListenableBuilder<Color>(
      valueListenable: _bgColor,
      builder: (context, bg, _) {
        final textColor = bg.computeLuminance() > 0.5
            ? Colors.black
            : Colors.white;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              key: _textFieldKey,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: bg,
              child: SizedBox(
                height: fixedHeight,
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  minLines: _minLinesCount,
                  maxLines: _minLinesCount,
                  style: TextStyle(fontSize: fontSize, color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Bạn đang nghĩ gì?',
                    hintStyle: TextStyle(color: textColor.withOpacity(0.6)),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  keyboardType: TextInputType.multiline,
                ),
              ),
            ),
            if (_experienceEntries.isNotEmpty) _buildExperienceList(),
            if (_isExperienceSharing)
              GestureDetector(
                onTap: _startExperienceEntry,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
                  child: Row(
                    children: const [
                      Icon(Icons.add, color: Colors.grey, size: 20),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Thêm chia sẻ',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_showExperienceInput) _buildExperienceInput(),
          ],
        );
      },
    );
  }

  void _startExperienceEntry() async {
    // choose category first
    final options = ['Lộ trình', 'Chi phí', 'Ăn uống', 'Khác'];
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: options
              .map(
                (opt) => ListTile(
                  title: Text(opt),
                  onTap: () => Navigator.pop(c, opt),
                ),
              )
              .toList(),
        ),
      ),
    );
    if (choice != null) {
      setState(() {
        _experienceCategory = choice;
        _showExperienceInput = true;
        // clear previous content/title
        _experienceController.clear();
        _experienceTitleController.clear();
      });
      Future.delayed(const Duration(milliseconds: 100), () {
        _experienceFocus.requestFocus();
      });
    }
  }

  void _addExperienceEntry() {
    if (_experienceCategory == null) return;
    final content = _experienceController.text.trim();
    if (content.isEmpty) return; // nothing to save
    final entry = ExperienceEntry(
      category: _experienceCategory!,
      title: _experienceCategory == 'Khác'
          ? _experienceTitleController.text.trim()
          : null,
      content: content,
    );
    setState(() {
      _experienceEntries.add(entry);
      _showExperienceInput = false;
      _experienceCategory = null;
      _experienceController.clear();
      _experienceTitleController.clear();
    });
  }

  Widget _buildExperienceList() {
    return Column(
      children: _experienceEntries
          .asMap()
          .entries
          .map(
            (e) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      e.value.category == 'Khác'
                          ? '${e.value.title ?? ''}: ${e.value.content}'
                          : '${e.value.category}: ${e.value.content}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _experienceEntries.removeAt(e.key);
                      });
                    },
                    child: const Icon(
                      Icons.close,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildExperienceInput() {
    final bool isOther = _experienceCategory == 'Khác';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isOther)
          Container(
            margin: const EdgeInsets.only(top: 8, left: 16, right: 16),
            child: TextField(
              controller: _experienceTitleController,
              decoration: const InputDecoration(
                hintText: 'Tiêu đề chia sẻ',
                hintStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        Container(
          margin: EdgeInsets.only(top: isOther ? 8 : 8, left: 16, right: 16),
          child: TextField(
            controller: _experienceController,
            focusNode: _experienceFocus,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: isOther
                  ? 'Nội dung chia sẻ'
                  : 'Nhập ${_experienceCategory?.toLowerCase()} của bạn...',
              hintStyle: const TextStyle(color: Colors.grey),
              border: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.deepPurple),
              ),
              prefix: isOther
                  ? null
                  : Text(
                      '${_experienceCategory!}: ',
                      style: const TextStyle(color: Colors.grey),
                    ),
            ),
            // Màu chữ đen khi không có ảnh (nền sáng), trắng khi có ảnh (nền tối)
            style: TextStyle(
              color: _selectedMedia.isEmpty ? Colors.black : Colors.white,
            ),
          ),
        ),
        // Save/cancel buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _addExperienceEntry,
                  child: const Text('Lưu'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _showExperienceInput = false;
                    });
                  },
                  child: const Text('Hủy'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _typingOptions() {
    final iconActions = [
      {
        'icon': Icons.image,
        'color': Colors.green,
        'action': () => _pickMedia(),
        'showAlways': true,
      },
      {
        'icon': Icons.person_add,
        'color': Colors.blue,
        'action': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const Congtacvien()),
          );
        },
        'showAlways': true,
      },
      {
        'icon': Icons.emoji_emotions,
        'color': Colors.orange,
        'action': () => _showEmotionPicker(),
        'showAlways': true,
      },
      {
        'icon': Icons.location_on,
        'color': Colors.red,
        'action': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CheckIn()),
          );
        },
        'showAlways': true,
      },
      {
        'icon': Icons.videocam,
        'color': Colors.pink,
        'action': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LiveStreamPage()),
          );
        },
        'showAlways': true,
      },
      {
        'icon': Icons.text_fields,
        'color': Colors.cyan,
        'action': () => _showColorPickerDialog(),
        'showAlways': false, // Only show when no images
      },
    ];

    // Filter based on whether images are selected
    final filteredActions = iconActions.where((item) {
      if (item['showAlways'] == true) return true;
      return _selectedMedia.isEmpty;
    }).toList();

    return Row(
      children: [
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: filteredActions
                .map(
                  (item) => _OptionIcon(
                    item['icon'] as IconData,
                    item['color'] as Color,
                    onTap: item['action'] as VoidCallback,
                  ),
                )
                .toList(),
          ),
        ),
        // # and @ buttons on the right
        GestureDetector(
          onTap: _showHashtagPicker,
          child: Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                '#',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: _showMentionPicker,
          child: Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                '@',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorPicker() {
    final colors = [
      Colors.white,
      Colors.blue,
      Colors.cyan,
      Colors.purple,
      Colors.red,
      Colors.orange,
      Colors.black,
    ];

    return SizedBox(
      height: 48,
      child: ValueListenableBuilder<Color>(
        valueListenable: _bgColor,
        builder: (context, bg, _) {
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            itemBuilder: (_, i) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                _bgColor.value = colors[i];
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors[i],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: bg == colors[i]
                        ? const Color(0xFFFFB620)
                        : Colors.white24,
                    width: bg == colors[i] ? 3 : 1,
                  ),
                ),
                child: bg == colors[i]
                    ? Icon(
                        Icons.check,
                        size: 20,
                        color: colors[i].computeLuminance() > 0.5
                            ? Colors.black
                            : Colors.white,
                      )
                    : null,
              ),
            ),
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemCount: colors.length,
          );
        },
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final VoidCallback? onTap;

  const _OptionTile(this.icon, this.color, this.title, {this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: const TextStyle(color: Colors.black87, fontSize: 16),
      ),
      onTap: onTap,
    );
  }
}

class _OptionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _OptionIcon(this.icon, this.color, {this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }
}
