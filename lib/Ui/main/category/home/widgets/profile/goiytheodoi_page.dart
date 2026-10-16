import 'package:flutter/material.dart';
import 'package:tourn/models/user_model.dart';
import 'package:tourn/ultils.enums/image_utils.dart';
import 'package:tourn/Ui/main/category/home/widgets/profile/Profile.dart';

class SuggestionsPage extends StatefulWidget {
  final List<UserModel> suggestions;
  final bool Function(UserModel user) isFollowing;
  final bool Function(UserModel user) isRequested;
  final int Function(UserModel user) mutualCount;
  final Future<void> Function(UserModel user) onFollow;
  final Future<void> Function(UserModel user) onUnfollow;
  final void Function(UserModel user)? onDismiss;

  const SuggestionsPage({
    super.key,
    required this.suggestions,
    required this.isFollowing,
    required this.isRequested,
    required this.mutualCount,
    required this.onFollow,
    required this.onUnfollow,
    this.onDismiss,
  });

  @override
  State<SuggestionsPage> createState() => _SuggestionsPageState();
}

class _SuggestionsPageState extends State<SuggestionsPage> {
  late List<UserModel> _items;

  @override
  void initState() {
    super.initState();
    _items = List<UserModel>.from(widget.suggestions);
  }

  Future<void> _handleFollow(UserModel user) async {
    await widget.onFollow(user);
    if (!mounted) return;
    setState(() {
      _items.removeWhere((u) => u.uid == user.uid);
    });
  }

  Future<void> _handleUnfollow(UserModel user) async {
    await widget.onUnfollow(user);
    if (mounted) setState(() {});
  }

  void _handleDismiss(UserModel user) {
    widget.onDismiss?.call(user);
    setState(() {
      _items.removeWhere((u) => u.uid == user.uid);
    });
  }

  void _openProfile(UserModel user) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) =>
            Profile(userId: user.uid, showBottomNav: true, initialTab: 0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = _items
        .where((u) => !widget.isFollowing(u) && !widget.isRequested(u))
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Gợi ý theo dõi')),
      body: ListView.separated(
        itemCount: visibleItems.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final user = visibleItems[index];
          final isFollowing = widget.isFollowing(user);
          final isRequested = widget.isRequested(user);
          final mutualCount = widget.mutualCount(user);
          final avatarProvider = getImageProvider(user.photoUrl);

          return InkWell(
            onTap: () => _openProfile(user),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundImage: avatarProvider,
                    backgroundColor: Colors.grey.shade300,
                    child: avatarProvider == null
                        ? const Icon(Icons.person, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF113953),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          mutualCount > 0
                              ? 'Ban chung $mutualCount'
                              : '@${user.email.split('@').first}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!isFollowing)
                    SizedBox(
                      height: 34,
                      child: ElevatedButton(
                        onPressed: isRequested
                            ? null
                            : () => _handleFollow(user),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFB620),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(isRequested ? 'Da gui' : 'Theo doi'),
                      ),
                    )
                  else
                    SizedBox(
                      height: 34,
                      child: OutlinedButton(
                        onPressed: () => _handleUnfollow(user),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade400),
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Dang theo doi'),
                      ),
                    ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => _handleDismiss(user),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
