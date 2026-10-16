import 'dart:async';
// ignore: unused_import
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tourn/Ui/main/category/home/widgets/button_add/create_and_edit_content.dart';
import 'package:tourn/domain/user_repository/user_repository.dart';
import 'package:tourn/domain/message_repository/message_repository.dart';
import 'package:tourn/models/user_model.dart';
import 'package:tourn/Ui/main/category/messenge/widgets/FirebaseRecentChats.dart';
import 'package:tourn/ultils.enums/image_utils.dart';
import 'package:tourn/Ui/main/category/messenge/widgets/MessageBubble.dart';

class ActivateChats extends StatefulWidget {
  const ActivateChats({super.key});

  @override
  State<ActivateChats> createState() => _ActivateChatsState();
}

class _ActivateChatsState extends State<ActivateChats> {
  List<UserModel> _followingUsers = [];
  UserModel? _currentUser;
  bool _loading = true;
  StreamSubscription<UserModel?>? _currentUserSub;
  StreamSubscription<List<UserModel>>? _followingSub;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final userRepo = context.read<UserRepository>();
    final currentUserId = userRepo.currentUserId;
    if (currentUserId == null) {
      setState(() => _loading = false);
      return;
    }

    // Listen to current user changes (for avatar updates)
    _currentUserSub = userRepo.streamUser(currentUserId).listen((user) {
      if (!mounted) return;
      setState(() => _currentUser = user);
    });

    // Load following users
    _followingSub = userRepo.getFollowing(currentUserId).listen((users) {
      if (!mounted) return;
      // Sắp xếp: người đang online trước
      final sorted = List<UserModel>.from(users);
      sorted.sort((a, b) {
        // Online users first - use isUserOnline helper
        final aOnline = isUserOnline(a.isOnline, a.lastSeen);
        final bOnline = isUserOnline(b.isOnline, b.lastSeen);
        if (aOnline && !bOnline) return -1;
        if (!aOnline && bOnline) return 1;
        return 0;
      });
      setState(() {
        _followingUsers = sorted;
        _loading = false;
      });
    });
  }

  @override
  void dispose() {
    _currentUserSub?.cancel();
    _followingSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 25, left: 5),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Current user first (like Messenger)
            if (_currentUser != null) _buildCurrentUserAvatar(),
            // Following users
            ..._followingUsers.map((user) => _buildUserAvatar(user)),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentUserAvatar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: GestureDetector(
        onTap: () {
          // Navigate to create post page
          Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(builder: (_) => const createandeditcontent()),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(35),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(35),
                    child:
                        _currentUser!.photoUrl != null &&
                            _currentUser!.photoUrl!.isNotEmpty
                        ? Image(
                            image: getImageProvider(_currentUser!.photoUrl)!,
                            width: 65,
                            height: 65,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Image.asset(
                              'asset/images/OIP.jpg',
                              width: 65,
                              height: 65,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Image.asset(
                            'asset/images/OIP.jpg',
                            width: 65,
                            height: 65,
                            fit: BoxFit.cover,
                          ),
                  ),
                  // Add post button
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: const Color(0xFF113953),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            const SizedBox(
              width: 65,
              child: Text(
                'Bạn',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserAvatar(UserModel user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: GestureDetector(
        onTap: () async {
          // Tạo hoặc lấy conversation với người này
          final msgRepo = context.read<MessageRepository>();
          final userRepo = context.read<UserRepository>();
          final currentUser = await userRepo.getCurrentUser();

          final conversation = await msgRepo.getOrCreatePrivateConversation(
            otherUserId: user.uid,
            otherUserName: user.displayName,
            otherUserPhoto: user.photoUrl,
            currentUserName: currentUser?.displayName,
            currentUserPhoto: currentUser?.photoUrl,
          );

          if (conversation != null && context.mounted) {
            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(
                builder: (_) => FirebaseChatPage(
                  conversationId: conversation.id,
                  displayName: user.displayName,
                  displayPhoto: user.photoUrl,
                ),
              ),
            );
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(35),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(35),
                    child: user.photoUrl != null && user.photoUrl!.isNotEmpty
                        ? Image(
                            image: getImageProvider(user.photoUrl)!,
                            width: 65,
                            height: 65,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Image.asset(
                              'asset/images/OIP.jpg',
                              width: 65,
                              height: 65,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Image.asset(
                            'asset/images/OIP.jpg',
                            width: 65,
                            height: 65,
                            fit: BoxFit.cover,
                          ),
                  ),
                  if (isUserOnline(user.isOnline, user.lastSeen))
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 65,
              child: Text(
                user.displayName,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
