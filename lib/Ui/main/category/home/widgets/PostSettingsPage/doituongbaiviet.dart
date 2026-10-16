import 'package:flutter/material.dart';

class Doituongbaiviet extends StatefulWidget {
  const Doituongbaiviet({super.key});

  @override
  State<Doituongbaiviet> createState() => _DoituongbaivietState();
}

class _DoituongbaivietState extends State<Doituongbaiviet> {
  String _selectedAudience =
      'public'; // public, friends, closeFriends, specific, onlyMe

  final List<Map<String, dynamic>> _audienceOptions = [
    {
      'id': 'public',
      'icon': Icons.public,
      'title': 'Công khai',
      'subtitle': 'Bất kỳ ai trên Trip',
      'color': Colors.blue,
    },
    {
      'id': 'friends',
      'icon': Icons.people,
      'title': 'Bạn bè',
      'subtitle': 'Bạn bè của bạn trên Trip',
      'color': Colors.green,
    },
    {
      'id': 'followers',
      'icon': Icons.people,
      'title': 'Người theo dõi',
      'subtitle': 'Danh sách những người đang theo dõi bạn',
      'color': Colors.orange,
    },
    {
      'id': 'specific',
      'icon': Icons.person_search,
      'title': 'Bạn bè cụ thể',
      'subtitle': 'Chỉ hiện với một số bạn bè nhất định',
      'color': Colors.purple,
    },
    {
      'id': 'onlyMe',
      'icon': Icons.lock,
      'title': 'Chỉ mình tôi',
      'subtitle': 'Chỉ bạn mới có thể xem',
      'color': Colors.grey,
    },
  ];

  // Danh sách người bị ẩn
  final List<Map<String, dynamic>> _hiddenFromList = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Đối tượng bài viết',
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
              onPressed: _saveAudience,
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
            // Mô tả
            _buildDescription(),

            const Divider(height: 1),

            // Tiêu đề phần chọn đối tượng
            _buildSectionHeader('AI CÓ THỂ XEM BÀI VIẾT CỦA BẠN?'),

            // Danh sách lựa chọn
            _buildAudienceList(),

            const Divider(height: 1),

            // Phần ẩn với người cụ thể
            _buildSectionHeader('ẨN VỚI'),

            _buildHideFromOption(),

            if (_hiddenFromList.isNotEmpty) _buildHiddenList(),

            const SizedBox(height: 24),

            // Thông tin bổ sung
            _buildInfoSection(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDescription() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFFB620).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.visibility,
              color: Color(0xFFFFB620),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quyền riêng tư bài viết',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Chọn ai có thể xem bài viết này. Cài đặt này sẽ được ghi nhớ cho các bài viết sau.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildAudienceList() {
    return Column(
      children: _audienceOptions.map((option) {
        final isSelected = _selectedAudience == option['id'];
        return _buildAudienceTile(
          id: option['id'],
          icon: option['icon'],
          title: option['title'],
          subtitle: option['subtitle'],
          color: option['color'],
          isSelected: isSelected,
        );
      }).toList(),
    );
  }

  Widget _buildAudienceTile({
    required String id,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedAudience = id;
        });
        if (id == 'specific') {
          _showSpecificFriendsPicker();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.15) : Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? color : Colors.grey[600],
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.black : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? const Color(0xFFFFB620)
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFFFB620)
                      : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHideFromOption() {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.person_off, color: Colors.red, size: 22),
      ),
      title: const Text(
        'Ẩn với người cụ thể',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        _hiddenFromList.isEmpty
            ? 'Ẩn bài viết với một số người nhất định'
            : '${_hiddenFromList.length} người',
        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: _showHideFromPicker,
    );
  }

  Widget _buildHiddenList() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _hiddenFromList.map((user) {
          return Chip(
            avatar: CircleAvatar(
              backgroundImage: AssetImage(user['avatar']),
              onBackgroundImageError: (_, __) {},
              child: Icon(Icons.person, size: 16, color: Colors.grey[600]),
            ),
            label: Text(
              user['name'].split(' ').last,
              style: const TextStyle(fontSize: 13),
            ),
            deleteIcon: const Icon(Icons.close, size: 18),
            onDeleted: () {
              setState(() {
                _hiddenFromList.remove(user);
              });
            },
            backgroundColor: Colors.grey[100],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lưu ý về quyền riêng tư',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Người được gắn thẻ trong bài viết có thể nhìn thấy bài viết, bạn bè của họ cũng có thể thấy nếu được chia sẻ.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSpecificFriendsPicker() {
    // Hiển thị dialog chọn bạn bè cụ thể
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Tính năng chọn bạn bè cụ thể sẽ sớm ra mắt!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showHideFromPicker() {
    // Danh sách bạn bè mẫu để ẩn
    final friends = [
      {
        'id': '1',
        'name': 'Nguyễn Văn An',
        'avatar': 'asset/images/employee-5.png',
      },
      {
        'id': '2',
        'name': 'Trần Thị Bình',
        'avatar': 'asset/images/employee-5.png',
      },
      {
        'id': '3',
        'name': 'Lê Hoàng Cường',
        'avatar': 'asset/images/employee-5.png',
      },
      {
        'id': '4',
        'name': 'Phạm Minh Đức',
        'avatar': 'asset/images/employee-5.png',
      },
      {
        'id': '5',
        'name': 'Hoàng Thị Em',
        'avatar': 'asset/images/employee-5.png',
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
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
                    'Ẩn với người cụ thể',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Những người này sẽ không thấy bài viết của bạn',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: friends.length,
                      itemBuilder: (context, index) {
                        final friend = friends[index];
                        final isHidden = _hiddenFromList.any(
                          (h) => h['id'] == friend['id'],
                        );

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: AssetImage(friend['avatar']!),
                            onBackgroundImageError: (_, __) {},
                            child: Icon(Icons.person, color: Colors.grey[600]),
                          ),
                          title: Text(friend['name']!),
                          trailing: Checkbox(
                            value: isHidden,
                            activeColor: const Color(0xFFFFB620),
                            onChanged: (value) {
                              setModalState(() {
                                if (value == true) {
                                  if (!_hiddenFromList.any(
                                    (h) => h['id'] == friend['id'],
                                  )) {
                                    _hiddenFromList.add(friend);
                                  }
                                } else {
                                  _hiddenFromList.removeWhere(
                                    (h) => h['id'] == friend['id'],
                                  );
                                }
                              });
                              setState(() {});
                            },
                          ),
                          onTap: () {
                            setModalState(() {
                              if (isHidden) {
                                _hiddenFromList.removeWhere(
                                  (h) => h['id'] == friend['id'],
                                );
                              } else {
                                _hiddenFromList.add(friend);
                              }
                            });
                            setState(() {});
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFB620),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Xong',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
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

  void _saveAudience() {
    // Trả về cài đặt đối tượng đã chọn
    final audienceName = _audienceOptions.firstWhere(
      (o) => o['id'] == _selectedAudience,
    )['title'];

    Navigator.pop(context, {
      'audience': _selectedAudience,
      'audienceName': audienceName,
      'hiddenFrom': _hiddenFromList,
    });
  }
}
