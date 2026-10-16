import 'package:flutter/material.dart';
import 'package:tourn/data/firebase/firebase_user_service.dart';
import 'package:tourn/models/user_model.dart';

class Taikhoanbichan extends StatefulWidget {
  const Taikhoanbichan({super.key});

  @override
  State<Taikhoanbichan> createState() => _TaikhoanbichanState();
}

class _TaikhoanbichanState extends State<Taikhoanbichan> {
  List<UserModel> users = [];
  String search = "";

  @override
  void initState() {
    super.initState();
    FirebaseUserService().getBlockedUsers().listen((list) {
      if (mounted) setState(() => users = list);
    });
  }

  void _unblock(UserModel user) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Bỏ chặn"),
        content: Text("Bạn muốn bỏ chặn ${user.displayName}?"),
        actions: [
          TextButton(
            child: const Text("Hủy"),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text("Bỏ chặn", style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (ok == true) {
      await FirebaseUserService().unblockUser(user.uid);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã bỏ chặn tài khoản')));
      }
    }
  }

  Widget _userTile(UserModel user) {
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.person)),
      title: Text(user.displayName),
      subtitle: Text('@${user.username ?? user.uid}'),
      trailing: TextButton(
        child: const Text("Bỏ chặn", style: TextStyle(color: Colors.red)),
        onPressed: () => _unblock(user),
      ),
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
      appBar: AppBar(title: const Text("Tài khoản bị chặn"), centerTitle: true),
      body: Column(
        children: [
          // 🔍 Search
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Tìm tài khoản bị chặn...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (v) {
                setState(() => search = v);
              },
            ),
          ),

          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text("Không có tài khoản bị chặn"))
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
