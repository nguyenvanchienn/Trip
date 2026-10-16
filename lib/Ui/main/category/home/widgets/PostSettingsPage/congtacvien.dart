import 'package:flutter/material.dart';

class Congtacvien extends StatefulWidget {
  const Congtacvien({super.key});

  @override
  State<Congtacvien> createState() => _CongtacvienState();
}

class _CongtacvienState extends State<Congtacvien> {
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _selectedCollaborators = [];
  String _searchQuery = '';

  // Danh sách người dùng mẫu (trong thực tế sẽ lấy từ API)
  final List<Map<String, dynamic>> _suggestedUsers = [
    {
      'id': '1',
      'name': 'Nguyễn Văn An',
      'username': '@nguyenvanan',
      'avatar': 'asset/images/employee-5.png',
      'isFollowing': true,
    },
    {
      'id': '2',
      'name': 'Trần Thị Bình',
      'username': '@tranthbinh',
      'avatar': 'asset/images/employee-5.png',
      'isFollowing': true,
    },
    {
      'id': '3',
      'name': 'Lê Hoàng Cường',
      'username': '@lehoangcuong',
      'avatar': 'asset/images/employee-5.png',
      'isFollowing': false,
    },
    {
      'id': '4',
      'name': 'Phạm Minh Đức',
      'username': '@phamminhduc',
      'avatar': 'asset/images/employee-5.png',
      'isFollowing': true,
    },
    {
      'id': '5',
      'name': 'Hoàng Thị Em',
      'username': '@hoangthiem',
      'avatar': 'asset/images/employee-5.png',
      'isFollowing': false,
    },
    {
      'id': '6',
      'name': 'Võ Văn Phúc',
      'username': '@vovanphuc',
      'avatar': 'asset/images/employee-5.png',
      'isFollowing': true,
    },
  ];

  List<Map<String, dynamic>> get _filteredUsers {
    if (_searchQuery.isEmpty) {
      return _suggestedUsers;
    }
    return _suggestedUsers.where((user) {
      final name = user['name'].toString().toLowerCase();
      final username = user['username'].toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || username.contains(query);
    }).toList();
  }

  bool _isSelected(String id) {
    return _selectedCollaborators.any((c) => c['id'] == id);
  }

  void _toggleSelection(Map<String, dynamic> user) {
    setState(() {
      if (_isSelected(user['id'])) {
        _selectedCollaborators.removeWhere((c) => c['id'] == user['id']);
      } else {
        _selectedCollaborators.add(user);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
          'Cộng tác viên',
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
              onPressed: _selectedCollaborators.isNotEmpty
                  ? _saveCollaborators
                  : null,
              child: Text(
                'Xong',
                style: TextStyle(
                  color: _selectedCollaborators.isNotEmpty
                      ? Colors.blue
                      : Colors.grey,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mô tả
          _buildDescription(),

          // Thanh tìm kiếm
          _buildSearchBar(),

          // Danh sách đã chọn
          if (_selectedCollaborators.isNotEmpty) _buildSelectedList(),

          // Tiêu đề gợi ý
          _buildSectionTitle(),

          // Danh sách người dùng
          Expanded(child: _buildUserList()),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB620).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.people_alt,
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
                      'Ghi nhận cộng tác viên',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cộng tác viên sẽ được hiển thị trên bài viết và có thể chia sẻ bài viết lên trang cá nhân của họ.',
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
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Tìm kiếm người dùng...',
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[500]),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedList() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Đã chọn (${_selectedCollaborators.length})',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _selectedCollaborators.length,
              itemBuilder: (context, index) {
                final user = _selectedCollaborators[index];
                return _buildSelectedChip(user);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedChip(Map<String, dynamic> user) {
    return Container(
      width: 70,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFB620), width: 2),
                ),
                child: ClipOval(
                  child: Image.asset(
                    user['avatar'],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.person,
                          color: Colors.grey[600],
                          size: 28,
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: GestureDetector(
                  onTap: () => _toggleSelection(user),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            user['name'].split(' ').last,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        _searchQuery.isEmpty ? 'GỢI Ý CHO BẠN' : 'KẾT QUẢ TÌM KIẾM',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildUserList() {
    if (_filteredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy người dùng',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) {
        final user = _filteredUsers[index];
        return _buildUserTile(user);
      },
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user) {
    final isSelected = _isSelected(user['id']);

    return ListTile(
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? const Color(0xFFFFB620) : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: ClipOval(
          child: Image.asset(
            user['avatar'],
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[300],
                child: Icon(Icons.person, color: Colors.grey[600], size: 24),
              );
            },
          ),
        ),
      ),
      title: Row(
        children: [
          Text(
            user['name'],
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          if (user['isFollowing'] == true) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Đang theo dõi',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        user['username'],
        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
      ),
      trailing: GestureDetector(
        onTap: () => _toggleSelection(user),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFB620) : Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: Icon(
            isSelected ? Icons.check : Icons.add,
            color: isSelected ? Colors.white : Colors.grey[700],
            size: 20,
          ),
        ),
      ),
      onTap: () => _toggleSelection(user),
    );
  }

  void _saveCollaborators() {
    // Trả về danh sách cộng tác viên đã chọn
    Navigator.pop(context, _selectedCollaborators);
  }
}
