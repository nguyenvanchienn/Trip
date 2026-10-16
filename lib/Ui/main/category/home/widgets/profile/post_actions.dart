import 'package:flutter/material.dart';

/// Các widget action cho menu bài viết.
/// Mỗi hành động là một widget riêng (ListTile) để dễ tái sử dụng và test.

typedef VoidAsyncCallback = Future<void> Function();

class ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final bool autoClose;

  const ActionTile({
    super.key,
    required this.icon,
    required this.title,
    this.onTap,
    this.autoClose = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (onTap != null) onTap!();
        if (autoClose) Navigator.of(context).pop();
      },
      child: ListTile(
        leading: Icon(icon, color: Colors.black),
        title: Text(title),
      ),
    );
  }
}

class PostActionsList extends StatelessWidget {
  final VoidCallback? onNotInterested;
  final VoidCallback? onSaveTrip;
  final VoidCallback? onHidePost;
  final VoidCallback? onReportPost;
  final VoidCallback? onBlockUser;
  final VoidCallback? onToggleNotify;
  final VoidCallback? onUnfollow;

  const PostActionsList({
    super.key,
    this.onNotInterested,
    this.onSaveTrip,
    this.onHidePost,
    this.onReportPost,
    this.onBlockUser,
    this.onToggleNotify,
    this.onUnfollow,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ActionTile(
          icon: Icons.thumb_down_alt_outlined,
          title: 'Không quan tâm',
          onTap: onNotInterested,
        ),
        ActionTile(
          icon: Icons.bookmark_border,
          title: 'Lưu hành trình',
          onTap: onSaveTrip,
        ),
        ActionTile(
          icon: Icons.visibility_off_outlined,
          title: 'Ẩn bài viết',
          onTap: onHidePost,
        ),
        ActionTile(
          icon: Icons.report_outlined,
          title: 'Báo cáo bài viết',
          onTap: onReportPost,
        ),
        ActionTile(
          icon: Icons.block_outlined,
          title: 'Chặn trang cá nhân của người đăng',
          onTap: onBlockUser,
        ),
        ActionTile(
          icon: Icons.notifications_active_outlined,
          title: 'Nhận thông báo về bài viết này',
          onTap: onToggleNotify,
        ),
        ActionTile(
          icon: Icons.person_remove_alt_1_outlined,
          title: 'Bỏ theo dõi người đăng',
          onTap: onUnfollow,
        ),
      ],
    );
  }
}
