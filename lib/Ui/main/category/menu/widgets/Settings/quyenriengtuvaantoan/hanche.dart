import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tourn/data/firebase/firebase_user_service.dart';
import 'package:tourn/models/user_model.dart';
import 'package:tourn/domain/message_repository/message_repository.dart';
import 'package:tourn/domain/user_repository/user_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tourn/Ui/main/category/messenge/widgets/FirebaseRecentChats.dart';
import 'package:tourn/ultils.enums/image_utils.dart';

class HanChePage extends StatefulWidget {
  const HanChePage({super.key});

  @override
  State<HanChePage> createState() => _HanChePageState();
}

class _HanChePageState extends State<HanChePage> {
  List<UserModel> users = [];
  String search = "";

  @override
  void initState() {
    super.initState();
    FirebaseUserService().getRestrictedUsers().listen((list) {
      if (mounted) setState(() => users = list);
    });
  }

  void _removeRestrict(UserModel user) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Bỏ hạn chế"),
        content: Text("Bạn muốn bỏ hạn chế ${user.displayName}?"),
        actions: [
          TextButton(
            child: const Text("Hủy"),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text(
              "Bỏ hạn chế",
              style: TextStyle(color: Colors.blue),
            ),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (ok == true) {
      await FirebaseUserService().unrestrictUser(user.uid);
      // List will refresh by stream
    }
  }

  Future<void> _openChat(UserModel user) async {
    // replicate Profile._messageUser logic so tapping a restricted account
    // immediately opens the conversation where the "restricted" warning
    // is displayed.
    final repo = context.read<MessageRepository>();
    final curId = repo.currentUserId;
    final targetId = user.uid;

    if (curId == null || targetId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở cuộc trò chuyện')),
      );
      return;
    }

    try {
      final authUser = FirebaseAuth.instance.currentUser;
      // Get current user's photoUrl from Firestore (base64)
      final userRepo = context.read<UserRepository>();
      final currentUserData = await userRepo.getCurrentUser();
      final conv = await repo.getOrCreatePrivateConversation(
        otherUserId: targetId,
        otherUserName: user.displayName,
        otherUserPhoto: user.photoUrl,
        currentUserName: authUser?.displayName,
        currentUserPhoto: currentUserData?.photoUrl,
      );
      if (conv != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FirebaseChatPage(
              conversationId: conv.id,
              displayName: user.displayName,
              displayPhoto: user.photoUrl,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('openChat error: $e');
    }
  }

  Widget _userTile(UserModel user) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: user.photoUrl != null
            ? getImageProvider(user.photoUrl!)
            : null,
        child: user.photoUrl == null ? const Icon(Icons.person) : null,
      ),
      title: Text(
        user.displayName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text('@${user.username ?? user.uid}'),
      onTap: () => _openChat(user),
      onLongPress: () => _removeRestrict(user),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = users
        .where(
          (u) => u.displayName.toLowerCase().contains(search.toLowerCase()),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Danh sách hạn chế"), centerTitle: true),
      body: Column(
        children: [
          /// 🔹 Facebook Description Box
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              "Người bạn hạn chế vẫn là bạn bè nhưng sẽ không thấy bài viết của bạn. "
              "Họ cũng không biết bạn đã hạn chế họ.",
              style: TextStyle(fontSize: 14),
            ),
          ),

          /// 🔍 Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Tìm người bị hạn chế",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (v) => setState(() => search = v),
            ),
          ),

          const SizedBox(height: 10),

          /// 👥 List
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text("Không có người bị hạn chế"))
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _userTile(filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }
}
