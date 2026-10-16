import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditPostPage extends StatefulWidget {
  final Map<String, dynamic> post;
  final Function(Map<String, dynamic>)? onSave;

  const EditPostPage({required this.post, this.onSave, super.key});

  @override
  State<EditPostPage> createState() => _EditPostPageState();
}

class _EditPostPageState extends State<EditPostPage> {
  late TextEditingController _contentController;
  late String _privacy;
  late bool _allowComments;
  List<String> _images = [];
  final List<String> _newImages = [];
  bool _isLoading = false;

  final List<Map<String, dynamic>> _privacyOptions = [
    {'value': 'public', 'label': 'Công khai', 'icon': Icons.public},
    {'value': 'friends', 'label': 'Bạn bè', 'icon': Icons.people},
    {'value': 'private', 'label': 'Chỉ mình tôi', 'icon': Icons.lock},
  ];

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(
      text: widget.post['content'] as String? ?? '',
    );
    _privacy = widget.post['privacy'] as String? ?? 'public';
    _allowComments = widget.post['allowComments'] as bool? ?? true;

    // Load existing images
    final postImages = widget.post['images'];
    if (postImages is List) {
      _images = postImages.map((e) => e.toString()).toList();
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles.isNotEmpty) {
      setState(() {
        _newImages.addAll(pickedFiles.map((e) => e.path));
      });
    }
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _newImages.add(pickedFile.path);
      });
    }
  }

  void _removeImage(int index, bool isNew) {
    setState(() {
      if (isNew) {
        _newImages.removeAt(index);
      } else {
        _images.removeAt(index);
      }
    });
  }

  void _showPrivacyDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chọn quyền riêng tư',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._privacyOptions.map(
              (option) => ListTile(
                leading: Icon(
                  option['icon'] as IconData,
                  color: _privacy == option['value']
                      ? const Color(0xFF113953)
                      : Colors.grey,
                ),
                title: Text(option['label'] as String),
                trailing: _privacy == option['value']
                    ? const Icon(Icons.check, color: Color(0xFF113953))
                    : null,
                onTap: () {
                  setState(() {
                    _privacy = option['value'] as String;
                  });
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePost() async {
    if (_contentController.text.trim().isEmpty &&
        _images.isEmpty &&
        _newImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập nội dung hoặc thêm ảnh'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate saving
    await Future.delayed(const Duration(milliseconds: 800));

    final updatedPost = Map<String, dynamic>.from(widget.post);
    updatedPost['content'] = _contentController.text.trim();
    updatedPost['privacy'] = _privacy;
    updatedPost['allowComments'] = _allowComments;
    updatedPost['images'] = [..._images, ..._newImages];
    updatedPost['editedAt'] = DateTime.now().toIso8601String();

    widget.onSave?.call(updatedPost);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã cập nhật bài viết'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, updatedPost);
    }
  }

  IconData _getPrivacyIcon() {
    switch (_privacy) {
      case 'friends':
        return Icons.people;
      case 'private':
        return Icons.lock;
      default:
        return Icons.public;
    }
  }

  String _getPrivacyLabel() {
    switch (_privacy) {
      case 'friends':
        return 'Bạn bè';
      case 'private':
        return 'Chỉ mình tôi';
      default:
        return 'Công khai';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF113953),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Chỉnh sửa bài viết',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _savePost,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Lưu',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // User info and privacy
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: widget.post['avatar'] != null
                        ? NetworkImage(widget.post['avatar'] as String)
                        : null,
                    child: widget.post['avatar'] == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.post['name'] as String? ?? 'Người dùng',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: _showPrivacyDialog,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getPrivacyIcon(),
                                  size: 16,
                                  color: Colors.grey[700],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _getPrivacyLabel(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_drop_down,
                                  size: 16,
                                  color: Colors.grey[700],
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
            ),

            // Content editor
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _contentController,
                maxLines: null,
                minLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Bạn đang nghĩ gì?',
                  border: InputBorder.none,
                  hintStyle: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                style: const TextStyle(fontSize: 18),
              ),
            ),

            // Existing images
            if (_images.isNotEmpty) ...[
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ảnh hiện tại',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _images.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    _images[index],
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 120,
                                      height: 120,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.image),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index, false),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // New images
            if (_newImages.isNotEmpty) ...[
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ảnh mới thêm',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _newImages.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(_newImages[index]),
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index, true),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const Divider(),

            // Comment settings
            SwitchListTile(
              title: const Text('Cho phép bình luận'),
              subtitle: Text(
                _allowComments
                    ? 'Mọi người có thể bình luận bài viết này'
                    : 'Không ai có thể bình luận bài viết này',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              value: _allowComments,
              activeThumbColor: const Color(0xFF113953),
              onChanged: (value) {
                setState(() {
                  _allowComments = value;
                });
              },
            ),

            const Divider(),

            // Add media buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickImages,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Thêm ảnh'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF113953),
                        side: const BorderSide(color: Color(0xFF113953)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _takePhoto,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Chụp ảnh'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF113953),
                        side: const BorderSide(color: Color(0xFF113953)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
