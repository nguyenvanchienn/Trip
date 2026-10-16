import 'package:flutter/material.dart';
import 'package:tourn/data/firebase/firebase_user_service.dart';

// ignore: unused_import

// Bottom-sheet dialog shown when user selects "Hạn chế" or "Chặn".
Future<dynamic> _showLimitSheet(
  BuildContext context,
  String? userName,
  String? userId,
  bool initiallyRestricted, {
  bool isBlock = false,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.black54,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (c) {
      return StatefulBuilder(
        builder: (context, setState) {
          bool restricted = initiallyRestricted;
          return Container(
            padding: const EdgeInsets.only(
              top: 12,
              left: 16,
              right: 16,
              bottom: 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
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
                CircleAvatar(
                  radius: 48,
                  backgroundImage: const AssetImage(
                    'asset/images/anh-mo-ta.jpg',
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isBlock
                      ? 'Chặn ${userName ?? 'người này'}?'
                      : (restricted
                            ? 'Bạn có muốn bỏ hạn chế ${userName ?? 'người này'}?'
                            : 'Bạn muốn hạn chế ${userName ?? 'người này'} ư?'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                if (isBlock) ...[
                  const Text(
                    'Mọi tài khoản khác mà họ có thể sở hữu hoặc tạo trong tương lai đều sẽ bị chặn. Bạn có thể bỏ chặn họ bất cứ lúc nào.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '• Họ sẽ không thể nhắn tin cho bạn hay tìm được trang cá nhân/nội dung của bạn trên hệ thống.',
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Họ sẽ không được thông báo là bạn đã chặn hoặc báo cáo họ.',
                  ),
                ] else if (!restricted) ...[
                  const Text(
                    'Giới hạn hoạt động tương tác từ người mà bạn quen nhưng không cho họ biết.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '• Họ sẽ không biết khi bạn online hay đọc tin nhắn của họ. '
                    'Hệ thống sẽ chuyển tin nhắn mà họ gửi cho bạn đến phần Tin nhắn đang chờ.',
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Chỉ bạn và họ mới có thể nhìn thấy bình luận mới của họ về bài viết của bạn trừ khi bạn phê duyệt cho họ.',
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Khi cố gắng gắn thẻ hoặc nhắc đến bạn, họ sẽ thấy thông báo là bạn không cho phép mọi người làm như vậy.',
                  ),
                ] else ...[
                  const Text(
                    'Người dùng này sẽ trở lại bình thường và có thể thấy bài viết cũng như tương tác với bạn nếu bạn là bạn bè.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Sau khi bỏ hạn chế, họ sẽ biết khi bạn online hoặc đọc tin nhắn. ',
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Future<void> toggleAction() async {
                        if (userId == null) return;
                        if (isBlock) {
                          // confirm block
                          final sure = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Xác nhận chặn'),
                              content: const Text(
                                'Bạn có chắc chắn muốn chặn người dùng này?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Không'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Có'),
                                ),
                              ],
                            ),
                          );
                          if (sure == true) {
                            await FirebaseUserService().blockUser(userId);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã chặn tài khoản '),
                              ),
                            );
                            // simply close the sheet; profile widget will react
                            // via the blockedIds stream and show placeholder.
                            Navigator.pop(c);
                            return;
                          }
                        } else if (restricted) {
                          // confirm unrestrict
                          final sure = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Xác nhận bỏ hạn chế'),
                              content: const Text(
                                'Bạn có chắc chắn muốn bỏ hạn chế người dùng này?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Không'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Có'),
                                ),
                              ],
                            ),
                          );
                          if (sure == true) {
                            await FirebaseUserService().unrestrictUser(userId);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Đã bỏ hạn chế')),
                            );
                            setState(() {
                              restricted = false;
                            });
                          } else {
                            // keep restricted state unchanged
                          }
                        } else {
                          final sure = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Xác nhận hạn chế'),
                              content: const Text(
                                'Bạn có chắc chắn muốn hạn chế người dùng này?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Không'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Có'),
                                ),
                              ],
                            ),
                          );
                          if (sure == true) {
                            await FirebaseUserService().restrictUser(userId);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã hạn chế tài khoản'),
                              ),
                            );
                            setState(() {
                              restricted = true;
                            });
                          }
                        }
                      }

                      await toggleAction();
                      Navigator.pop(c);
                    },
                    child: Text(
                      isBlock
                          ? 'Chặn'
                          : (restricted ? 'Bỏ hạn chế' : 'Hạn chế'),
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

Future<dynamic> Menuprofile(
  BuildContext context, {
  String? userName,
  String? userId,
}) async {
  bool isRestricted = false;
  if (userId != null) {
    isRestricted = await FirebaseUserService().isRestricted(userId);
  }
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (c) {
      Widget item(
        String text, {
        Color color = Colors.black,
        bool bold = false,
        VoidCallback? onTap,
      }) {
        return ListTile(
          dense: true,
          title: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          onTap: onTap ?? () => Navigator.pop(c),
        );
      }

      const divider = Divider(
        height: 1,
        color: Color(0xFFE0E0E0), // xám nhạt giống iOS
      );

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// ===== MENU =====
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    item(
                      isRestricted ? 'Bỏ hạn chế' : 'Hạn chế',
                      color: Colors.red,
                      onTap: () {
                        Navigator.pop(c);
                        _showLimitSheet(
                          context,
                          userName,
                          userId,
                          isRestricted,
                        );
                      },
                    ),
                    divider,
                    item(
                      'Chặn',
                      color: Colors.red,
                      onTap: () {
                        Navigator.pop(c);
                        _showLimitSheet(
                          context,
                          userName,
                          userId,
                          isRestricted,
                          isBlock: true,
                        );
                      },
                    ),
                    divider,
                    item('Báo cáo', color: Colors.red),
                    divider,
                    item('Xem hoạt động chung'),
                    divider,
                    item('Ẩn tin của bạn'),
                    divider,
                    item('Sao chép URL trang cá nhân'),
                    divider,
                    item('Chia sẻ trang cá nhân này'),
                    divider,
                    item('Mã QR'),
                  ],
                ),
              ),

              const SizedBox(height: 13),

              Container(
                // Cancel button
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: item('Hủy', bold: true),
              ),
            ],
          ),
        ),
      );
    },
  );
}
