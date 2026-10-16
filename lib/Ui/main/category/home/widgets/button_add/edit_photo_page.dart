import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditPhotoPage extends StatefulWidget {
  final XFile imageFile;
  final int index;
  final Function(int index, String? caption) onSave;
  final Function(int index) onDelete;

  const EditPhotoPage({
    super.key,
    required this.imageFile,
    required this.index,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<EditPhotoPage> createState() => _EditPhotoPageState();
}

class _EditPhotoPageState extends State<EditPhotoPage> {
  final TextEditingController _captionController = TextEditingController();
  Uint8List? _imageBytes;
  bool _isLoading = true;
  int _selectedTab = 0; // 0: Hiệu ứng, 1: Ánh sáng, 2: Cài đặt

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final bytes = await widget.imageFile.readAsBytes();
    if (mounted) {
      setState(() {
        _imageBytes = bytes;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    _buildOptionItem(
                      'Gỡ ảnh ${widget.index + 1}',
                      Colors.red,
                      () {
                        Navigator.pop(context);
                        widget.onDelete(widget.index);
                        Navigator.pop(context);
                      },
                    ),
                    const Divider(height: 1),
                    _buildOptionItem(
                      'Chỉnh sửa ảnh ${widget.index + 1}',
                      Colors.blue,
                      () => Navigator.pop(context),
                    ),
                    const Divider(height: 1),
                    _buildOptionItem(
                      'Chỉnh sửa văn bản thay thế',
                      Colors.blue,
                      () {
                        Navigator.pop(context);
                        _showAltTextDialog();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
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

  void _showAltTextDialog() {
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top toolbar
            Container(
              color: const Color(0xFF1A1A1A),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  // Close button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Editing icons
                  _buildToolIcon(Icons.music_note, () {}),
                  _buildToolIcon(Icons.alternate_email, () {}),
                  _buildToolIcon(Icons.crop, () {}),
                  _buildToolIcon(Icons.emoji_emotions_outlined, () {}),
                  _buildToolIcon(Icons.text_fields, () {}),
                  _buildToolIcon(Icons.link, () {}),
                ],
              ),
            ),

            // Image section
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Main image
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Image.memory(_imageBytes!, fit: BoxFit.contain),

                  // Top overlay buttons on image
                  Positioned(
                    top: 8,
                    left: 8,
                    right: 8,
                    child: Row(
                      children: [
                        // Edit text button
                        GestureDetector(
                          onTap: () {
                            // TODO: Add text overlay editor
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
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.crop_rotate,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'Chỉnh sửa',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        // More options button
                        GestureDetector(
                          onTap: _showMoreOptions,
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
                        // Delete button
                        GestureDetector(
                          onTap: () {
                            widget.onDelete(widget.index);
                            Navigator.pop(context);
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
                  ),
                ],
              ),
            ),

            // Caption input section
            Container(
              color: const Color(0xFF2A2A2A),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: TextField(
                controller: _captionController,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Thêm chú thích...',
                  hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),

            // Bottom edit bar with Aa Chỉnh sửa, more, and delete
            Container(
              color: const Color(0xFF2A2A2A),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      // Text overlay editor
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Aa',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Chỉnh sửa',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _showMoreOptions,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.more_horiz,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      widget.onDelete(widget.index);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom toolbar with tabs
            Container(
              color: const Color(0xFF1A1A1A),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Tabs
                  _buildTabItem(Icons.auto_awesome, 'Hiệu ứng', 0),
                  const SizedBox(width: 24),
                  _buildTabItem(Icons.wb_sunny_outlined, 'Ánh sáng', 1),
                  const SizedBox(width: 24),
                  _buildTabItem(Icons.settings_outlined, 'Cài đặt', 2),
                  const Spacer(),
                  // Next button
                  GestureDetector(
                    onTap: () {
                      widget.onSave(
                        widget.index,
                        _captionController.text.isNotEmpty
                            ? _captionController.text
                            : null,
                      );
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Tiếp',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
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

  Widget _buildToolIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildTabItem(IconData icon, String label, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.white : Colors.grey[500],
            size: 22,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[500],
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
