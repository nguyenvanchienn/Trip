import 'package:flutter/material.dart';

class Chiaselentincuaban extends StatefulWidget {
  const Chiaselentincuaban({super.key});

  @override
  State<Chiaselentincuaban> createState() => _ChiaselentincuabanState();
}

class _ChiaselentincuabanState extends State<Chiaselentincuaban> {
  // Cài đặt chia sẻ
  bool _shareToStory = true;
  bool _allowReplies = true;
  bool _allowSharing = true;
  bool _showOnProfile = true;
  int _storyDuration = 24; // giờ
  String _selectedPrivacy = 'Bạn bè';

  final List<String> _privacyOptions = [
    'Công khai',
    'Bạn bè',
    'Bạn bè thân',
    'Chỉ mình tôi',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context, {
            'shareToStory': _shareToStory,
          }),
        ),
        title: const Text(
          'Chia sẻ lên tin của bạn',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _saveSettings,
              child: const Text(
                'Xong',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview tin
            _buildStoryPreview(),

            const SizedBox(height: 16),

            // Toggle chia sẻ lên tin
            _buildMainToggle(),

            if (_shareToStory) ...[
              const Divider(height: 1),

              // Quyền riêng tư
              _buildSectionHeader('Quyền riêng tư'),
              _buildPrivacyOption(),

              const Divider(height: 1),

              // Thời gian hiển thị
              _buildSectionHeader('Thời gian hiển thị'),
              _buildDurationSelector(),

              const Divider(height: 1),

              // Tương tác
              _buildSectionHeader('Tương tác'),
              _buildToggleItem(
                icon: Icons.reply,
                iconColor: Colors.blue,
                title: 'Cho phép trả lời',
                subtitle: 'Mọi người có thể trả lời tin của bạn',
                value: _allowReplies,
                onChanged: (value) {
                  setState(() => _allowReplies = value);
                },
              ),
              _buildToggleItem(
                icon: Icons.share,
                iconColor: Colors.green,
                title: 'Cho phép chia sẻ',
                subtitle: 'Mọi người có thể chia sẻ tin của bạn',
                value: _allowSharing,
                onChanged: (value) {
                  setState(() => _allowSharing = value);
                },
              ),
              _buildToggleItem(
                icon: Icons.person,
                iconColor: Colors.orange,
                title: 'Hiển thị trên trang cá nhân',
                subtitle: 'Tin sẽ xuất hiện trong mục tin nổi bật',
                value: _showOnProfile,
                onChanged: (value) {
                  setState(() => _showOnProfile = value);
                },
              ),

              const Divider(height: 1),

              // Tùy chỉnh tin
              _buildSectionHeader('Tùy chỉnh tin'),
              _buildCustomizeOptions(),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryPreview() {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Nội dung bài viết preview
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            image: const DecorationImage(
                              image: AssetImage('asset/images/employee-5.png'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tin của bạn',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Vừa xong',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Nội dung
                    const Text(
                      'Bài viết của bạn sẽ được chia sẻ lên tin...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Progress bar
                    Container(
                      height: 2,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(1),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: 0.3,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(1),
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
    );
  }

  Widget _buildMainToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _shareToStory
                  ? const Color(0xFFFFB620).withOpacity(0.15)
                  : Colors.grey.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.collections,
              color: _shareToStory ? const Color(0xFFFFB620) : Colors.grey,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chia sẻ bài viết lên tin',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                Text(
                  _shareToStory
                      ? 'Bài viết sẽ xuất hiện trong tin của bạn'
                      : 'Bài viết sẽ không xuất hiện trong tin',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _shareToStory,
            activeThumbColor: const Color(0xFFFFB620),
            onChanged: (value) {
              setState(() => _shareToStory = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildPrivacyOption() {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _getPrivacyIcon(_selectedPrivacy),
          color: Colors.blue,
          size: 20,
        ),
      ),
      title: const Text(
        'Ai có thể xem tin của bạn?',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        _selectedPrivacy,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: _showPrivacyPicker,
    );
  }

  IconData _getPrivacyIcon(String privacy) {
    switch (privacy) {
      case 'Công khai':
        return Icons.public;
      case 'Bạn bè':
        return Icons.people;
      case 'Bạn bè thân':
        return Icons.favorite;
      case 'Chỉ mình tôi':
        return Icons.lock;
      default:
        return Icons.people;
    }
  }

  void _showPrivacyPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                'Ai có thể xem tin của bạn?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ...List.generate(_privacyOptions.length, (index) {
                final option = _privacyOptions[index];
                final isSelected = option == _selectedPrivacy;
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.blue.withOpacity(0.12)
                          : Colors.grey.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getPrivacyIcon(option),
                      color: isSelected ? Colors.blue : Colors.grey[700],
                      size: 20,
                    ),
                  ),
                  title: Text(
                    option,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: Colors.blue)
                      : null,
                  onTap: () {
                    setState(() => _selectedPrivacy = option);
                    Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDurationSelector() {
    final durations = [
      {'hours': 6, 'label': '6 giờ'},
      {'hours': 12, 'label': '12 giờ'},
      {'hours': 24, 'label': '24 giờ'},
      {'hours': 48, 'label': '48 giờ'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tin của bạn sẽ hiển thị trong $_storyDuration giờ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: durations.map((duration) {
              final hours = duration['hours'] as int;
              final label = duration['label'] as String;
              final isSelected = hours == _storyDuration;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _storyDuration = hours);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFFFB620)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey[600],
        ),
      ),
      trailing: Switch(
        value: value,
        activeThumbColor: const Color(0xFFFFB620),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildCustomizeOptions() {
    final options = [
      {
        'icon': Icons.text_fields,
        'color': Colors.purple,
        'title': 'Thêm văn bản',
        'subtitle': 'Thêm chữ vào tin',
      },
      {
        'icon': Icons.emoji_emotions,
        'color': Colors.orange,
        'title': 'Thêm nhãn dán',
        'subtitle': 'Thêm sticker vào tin',
      },
      {
        'icon': Icons.music_note,
        'color': Colors.pink,
        'title': 'Thêm nhạc',
        'subtitle': 'Thêm nhạc nền vào tin',
      },
      {
        'icon': Icons.draw,
        'color': Colors.green,
        'title': 'Vẽ',
        'subtitle': 'Vẽ lên tin của bạn',
      },
      {
        'icon': Icons.filter,
        'color': Colors.blue,
        'title': 'Bộ lọc',
        'subtitle': 'Thêm hiệu ứng cho tin',
      },
    ];

    return Column(
      children: options.map((option) {
        return ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (option['color'] as Color).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              option['icon'] as IconData,
              color: option['color'] as Color,
              size: 20,
            ),
          ),
          title: Text(
            option['title'] as String,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            option['subtitle'] as String,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: () {
            _showFeatureSnackbar(option['title'] as String);
          },
        );
      }).toList(),
    );
  }

  void _showFeatureSnackbar(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tính năng "$feature" sẽ sớm ra mắt!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _saveSettings() {
    // Lưu cài đặt và quay về
    Navigator.pop(context, {
      'shareToStory': _shareToStory,
      'privacy': _selectedPrivacy,
      'duration': _storyDuration,
      'allowReplies': _allowReplies,
      'allowSharing': _allowSharing,
      'showOnProfile': _showOnProfile,
    });
  }
}
