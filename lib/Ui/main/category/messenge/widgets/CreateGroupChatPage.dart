import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tourn/domain/message_repository/message_repository.dart';
import 'package:tourn/domain/user_repository/user_repository.dart';
import 'package:tourn/models/user_model.dart';
import 'package:tourn/Ui/main/category/messenge/widgets/FirebaseRecentChats.dart';

/// Page to create a new group chat, similar to Facebook Messenger
class CreateGroupChatPage extends StatefulWidget {
  const CreateGroupChatPage({super.key});

  @override
  State<CreateGroupChatPage> createState() => _CreateGroupChatPageState();
}

class _CreateGroupChatPageState extends State<CreateGroupChatPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _groupNameController = TextEditingController();

  List<UserModel> _followingUsers = [];
  List<UserModel> _filteredUsers = [];
  final Set<String> _selectedUserIds = {};
  final Map<String, UserModel> _selectedUsers = {};

  bool _isLoading = true;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _loadFollowingUsers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _groupNameController.dispose();
    super.dispose();
  }

  void _loadFollowingUsers() {
    final userRepo = context.read<UserRepository>();
    final currentUserId = userRepo.currentUserId;
    if (currentUserId == null) {
      setState(() => _isLoading = false);
      return;
    }

    userRepo.getFollowing(currentUserId).listen((users) {
      if (!mounted) return;
      setState(() {
        _followingUsers = users;
        _filteredUsers = users;
        _isLoading = false;
      });
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filteredUsers = _followingUsers;
      });
    } else {
      setState(() {
        _filteredUsers = _followingUsers.where((user) {
          final name = user.displayName.toLowerCase();
          return name.contains(query);
        }).toList();
      });
    }
  }

  void _toggleUser(UserModel user) {
    setState(() {
      if (_selectedUserIds.contains(user.uid)) {
        _selectedUserIds.remove(user.uid);
        _selectedUsers.remove(user.uid);
      } else {
        _selectedUserIds.add(user.uid);
        _selectedUsers[user.uid] = user;
      }
    });
  }

  Future<void> _createGroup() async {
    if (_selectedUserIds.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất 2 người')),
      );
      return;
    }

    String groupName = _groupNameController.text.trim();
    if (groupName.isEmpty) {
      // Generate default name from selected users
      final names = _selectedUsers.values
          .take(3)
          .map((u) => u.displayName.split(' ').last)
          .toList();
      if (_selectedUsers.length > 3) {
        names.add('+${_selectedUsers.length - 3}');
      }
      groupName = names.join(', ');
    }

    setState(() => _isCreating = true);

    try {
      final msgRepo = context.read<MessageRepository>();
      final userRepo = context.read<UserRepository>();
      final currentUser = await userRepo.getCurrentUser();

      // Build participant names map
      final participantNames = <String, String>{};
      final participantPhotos = <String, String?>{};

      // Add current user
      if (currentUser != null) {
        participantNames[currentUser.uid] = currentUser.displayName;
        participantPhotos[currentUser.uid] = currentUser.photoUrl;
      }

      // Add selected users
      for (final user in _selectedUsers.values) {
        participantNames[user.uid] = user.displayName;
        participantPhotos[user.uid] = user.photoUrl;
      }

      final conversation = await msgRepo.createGroupConversation(
        name: groupName,
        participantIds: _selectedUserIds.toList(),
        participantNames: participantNames,
        participantPhotos: participantPhotos,
      );

      if (conversation != null && mounted) {
        // Navigate to the new group chat
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => FirebaseChatPage(
              conversationId: conversation.id,
              displayName: groupName,
              displayPhoto: null,
              isGroup: true,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi tạo nhóm: $e')));
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo nhóm chat'),
        backgroundColor: const Color(0xFF113953),
        foregroundColor: Colors.white,
        actions: [
          // Create button - only show when 2+ users selected
          if (_selectedUserIds.length >= 2)
            TextButton(
              onPressed: _isCreating ? null : _createGroup,
              child: _isCreating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'TẠO',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Group name input
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: TextField(
              controller: _groupNameController,
              decoration: InputDecoration(
                hintText: 'Tên nhóm (tùy chọn)',
                prefixIcon: const Icon(Icons.group, color: Color(0xFF113953)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),

          // Selected users chips
          if (_selectedUsers.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              width: double.infinity,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedUsers.values.map((user) {
                  return Chip(
                    avatar: CircleAvatar(
                      radius: 14,
                      backgroundImage:
                          user.photoUrl != null && user.photoUrl!.isNotEmpty
                          ? NetworkImage(user.photoUrl!)
                          : const AssetImage('asset/images/OIP.jpg')
                                as ImageProvider,
                    ),
                    label: Text(user.displayName),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () => _toggleUser(user),
                    backgroundColor: const Color(
                      0xFF113953,
                    ).withValues(alpha: 0.1),
                  );
                }).toList(),
              ),
            ),

          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm bạn bè...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
          ),

          // User list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isEmpty
                              ? 'Bạn chưa theo dõi ai'
                              : 'Không tìm thấy bạn bè',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      final isSelected = _selectedUserIds.contains(user.uid);

                      return ListTile(
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundImage:
                                  user.photoUrl != null &&
                                      user.photoUrl!.isNotEmpty
                                  ? NetworkImage(user.photoUrl!)
                                  : const AssetImage('asset/images/OIP.jpg')
                                        as ImageProvider,
                            ),
                            if (isSelected)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF113953),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        title: Text(
                          user.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        trailing: Checkbox(
                          value: isSelected,
                          onChanged: (_) => _toggleUser(user),
                          activeColor: const Color(0xFF113953),
                          shape: const CircleBorder(),
                        ),
                        onTap: () => _toggleUser(user),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
