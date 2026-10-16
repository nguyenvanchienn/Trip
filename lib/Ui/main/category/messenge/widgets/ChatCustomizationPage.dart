import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ChatCustomizationPage extends StatefulWidget {
  final String chatName;
  final Color? currentColor;
  final String? currentEmoji;
  final String? currentBackgroundImage;

  const ChatCustomizationPage({
    super.key,
    required this.chatName,
    this.currentColor,
    this.currentEmoji,
    this.currentBackgroundImage,
  });

  @override
  State<ChatCustomizationPage> createState() => _ChatCustomizationPageState();
}

class _ChatCustomizationPageState extends State<ChatCustomizationPage> {
  late Color _selectedColor;
  late String _selectedEmoji;
  String? _backgroundImagePath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.currentColor ?? Color(0xFF113953);
    _selectedEmoji = widget.currentEmoji ?? '👍';
    _backgroundImagePath = widget.currentBackgroundImage;
  }

  final List<Color> _chatColors = [
    Color(0xFF113953),
    Color(0xFF0084FF),
    Color(0xFF7646FF),
    Color(0xFFFF6B9D),
    Color(0xFFFF5E3A),
    Color(0xFFFFC400),
    Color(0xFF00C896),
    Color(0xFF00B2FF),
    Colors.red,
    Colors.purple,
    Colors.green,
    Colors.orange,
  ];

  final List<String> _popularEmojis = [
    '👍',
    '❤️',
    '😂',
    '😮',
    '😢',
    '😡',
    '🔥',
    '✨',
    '🎉',
    '💯',
    '👏',
    '🙏',
    '😊',
    '😍',
    '😎',
    '🤔',
    '😭',
    '😘',
    '🥰',
    '😇',
    '🤗',
    '🤩',
    '😱',
    '🥺',
    '💪',
    '👌',
    '✌️',
    '🤞',
    '👋',
    '🙌',
    '💕',
    '💖',
    '💗',
    '💓',
    '💝',
    '💘',
    '🌟',
    '⭐',
    '🌈',
    '☀️',
    '🌙',
    '⚡',
    '💥',
    '🎊',
    '🎈',
    '🎁',
    '🍀',
    '🌹',
    '😀',
    '😃',
    '😄',
    '😁',
    '🙂',
    '😉',
    '😌',
    '😋',
    '😜',
    '😝',
    '🤪',
    '🤨',
    '🧐',
    '🤓',
    '😏',
    '😒',
  ];

  void _showEmojiPickerModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: EdgeInsets.only(top: 8, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Chọn emoji',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF113953),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Custom emoji grid (không dùng thư viện để tránh lag)
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _popularEmojis.length,
                itemBuilder: (context, index) {
                  final emoji = _popularEmojis[index];
                  final isSelected = emoji == _selectedEmoji;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedEmoji = emoji;
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _selectedColor.withOpacity(0.2)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? _selectedColor
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(emoji, style: TextStyle(fontSize: 28)),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _pickBackgroundImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _backgroundImagePath = image.path;
      });
    }
  }

  void _removeBackgroundImage() {
    setState(() {
      _backgroundImagePath = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _selectedColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Tùy chỉnh chat', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () {
              // Trả dữ liệu về trang trước
              Navigator.pop(context, {
                'color': _selectedColor,
                'emoji': _selectedEmoji,
                'backgroundImage': _backgroundImagePath,
              });
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Đã lưu tùy chỉnh')));
              Navigator.pop(context);
            },
            child: Text(
              'Lưu',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          // Phần chọn màu
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Màu sắc chat',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF113953),
                  ),
                ),
                SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _chatColors.length,
                  itemBuilder: (context, index) {
                    final color = _chatColors[index];
                    final isSelected = color == _selectedColor;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedColor = color;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? Colors.black
                                : Colors.grey[300]!,
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                        child: isSelected
                            ? Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          Divider(height: 1, thickness: 8, color: Colors.grey[200]),

          // Phần chọn ảnh nền
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ảnh nền chat',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF113953),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    // Nút chọn ảnh
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickBackgroundImage,
                        icon: Icon(Icons.photo_library, color: _selectedColor),
                        label: Text(
                          'Chọn ảnh từ thư viện',
                          style: TextStyle(color: _selectedColor),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: _selectedColor),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    if (_backgroundImagePath != null) ...[
                      SizedBox(width: 8),
                      IconButton(
                        onPressed: _removeBackgroundImage,
                        icon: Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Xóa ảnh nền',
                      ),
                    ],
                  ],
                ),
                if (_backgroundImagePath != null) ...[
                  SizedBox(height: 12),
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                      image: DecorationImage(
                        image: FileImage(File(_backgroundImagePath!)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          Divider(height: 1, thickness: 8, color: Colors.grey[200]),

          // Phần chọn emoji
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Biểu tượng cảm xúc nhanh',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF113953),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Nhấn giữ tin nhắn để thả cảm xúc nhanh',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                SizedBox(height: 16),
                // Emoji hiện tại
                GestureDetector(
                  onTap: _showEmojiPickerModal,
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: _selectedColor),
                      borderRadius: BorderRadius.circular(12),
                      color: _selectedColor.withOpacity(0.1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              _selectedEmoji,
                              style: TextStyle(fontSize: 32),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Emoji đã chọn',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        Icon(Icons.edit, color: _selectedColor),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, thickness: 8, color: Colors.grey[200]),

          // Preview
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xem trước',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF113953),
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                    color: Colors.grey[100],
                    image: _backgroundImagePath != null
                        ? DecorationImage(
                            image: FileImage(File(_backgroundImagePath!)),
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(
                              Colors.white.withOpacity(0.7),
                              BlendMode.lighten,
                            ),
                          )
                        : null,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: _selectedColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Tin nhắn mẫu',
                            style: TextStyle(color: Colors.white, fontSize: 15),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(_selectedEmoji, style: TextStyle(fontSize: 24)),
                      ],
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
}
