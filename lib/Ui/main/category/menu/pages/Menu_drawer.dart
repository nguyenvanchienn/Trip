import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tourn/Ui/main/category/home/widgets/profile/Profile.dart';
import 'package:tourn/Ui/main/category/menu/pages/settings_page.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Confirm.dart';
import 'package:tourn/Ui/main/category/menu/pages/Help.dart';
import 'package:tourn/Ui/main/category/menu/widgets/language.dart';
import 'package:tourn/Ui/main/category/business/business_account_action.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tourn/ultils.enums/image_utils.dart';
import 'package:tourn/domain/user_repository/user_repository.dart';

class MenuDrawer extends StatelessWidget {
  const MenuDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final userRepo = context.read<UserRepository>();

    return StreamBuilder(
      stream: userRepo.streamCurrentUser(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final displayName =
            user?.displayName ??
            FirebaseAuth.instance.currentUser?.displayName ??
            'Người dùng';
        final photoUrl = user?.photoUrl;

        return SizedBox(
          width: 320,
          child: Drawer(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: () {
                                // Đóng drawer rồi điều hướng đến route '/profile'
                                Navigator.of(context).pop();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const Profile(
                                      showBottomNav: true,
                                      initialTab: 4,
                                    ),
                                  ),
                                );
                              },
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundImage:
                                        photoUrl != null && photoUrl.isNotEmpty
                                        ? getImageProvider(photoUrl)
                                        : const AssetImage(
                                                'asset/images/OIP.jpg',
                                              )
                                              as ImageProvider,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          displayName,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        InkWell(
                                          onTap: () {
                                            Navigator.of(context).pop();
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => const Profile(
                                                  showBottomNav: true,
                                                  initialTab: 4,
                                                ),
                                              ),
                                            );
                                          },
                                          child: Row(children: []),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  BusinessAccountAction(
                                    asAvatar: true,
                                    onTap: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),
                            const Divider(),

                            // Menu list
                            _buildMenuItem(
                              context,
                              icon: Icons.help_outline,
                              label: 'Trợ giúp và hỗ trợ',
                            ),
                            _buildMenuItem(
                              context,
                              icon: Icons.settings,
                              label: 'Cài đặt và quyền riêng tư',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    buildlanguage(context),
                    _buildSignOutButton(context),
                    const SizedBox(height: 8),
                    // Footer: version + update
                    Row(
                      children: [
                        const Text(
                          'Trip@v28.5.61 (5)',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 8,
                            ),
                          ),
                          child: const Text('Cập nhật'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuItem(
    // xây dựng một mục menu tùy chỉnh
    BuildContext context, {
    required IconData icon, // biểu tượng của mục
    required String label, // nhãn của mục
    Widget? trailing, // tùy chọn widget ở cuối mục
  }) {
    return Container(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        minLeadingWidth: 40,
        horizontalTitleGap: 0, // Khoảng cách giữa biểu tượng và tiêu đề
        leading: Icon(icon, color: Colors.brown), // Màu biểu tượng tùy chỉnh
        title: Text(label),
        trailing:
            trailing ?? // Nếu không có widget tùy chỉnh, sử dụng mũi tên mặc định
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.grey,
            ), // Mũi tên mặc định
        onTap: () {
          // Xử lý sự kiện nhấn mục menu ở đây
          Navigator.of(context).pop(); // Đóng drawer khi chọn mục
          if (label == 'Cài đặt và quyền riêng tư') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            );
          } else if (label == 'Trợ giúp và hỗ trợ') {
            // Xử lý điều hướng đến trang trợ giúp và hỗ trợ
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Help()),
            );
          }
        },
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context) {
    // Nút đăng xuất bây giờ dùng widget tùy chỉnh để có hiệu ứng nhấn (scale + màu nhạt + ripple)
    return Container(
      margin: const EdgeInsets.only(top: 10),
      child: SizedBox(
        width: double.infinity,
        child: _PressableElevated(
          onPressed: () {
            Navigator.of(context).pop();
            confirm(context);
          },
          color: const Color(0xFF6200EE),
          child: Text(
            "signout_buttom".tr(),
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

Widget buildlanguage(BuildContext context) {
  return InkWell(
    onTap: () {
      Navigator.of(context).pop();
      language(context);
    },
    borderRadius: BorderRadius.circular(30),
    child: Row(
      children: [
        const Icon(Icons.language),
        const SizedBox(width: 8),
        const Text("icon_language").tr(),
        const Spacer(),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.locale.languageCode == 'vi'
                  ? 'Tiếng Việt'
                  : context.locale.languageCode == 'en'
                  ? 'English'
                  : context.locale.languageCode == 'zh'
                  ? '简体中文'
                  : context.locale.languageCode == 'ko'
                  ? 'Korean'
                  : '日本語',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color.fromARGB(255, 196, 196, 196),
                  width: 4,
                ),
              ),
              child: ClipOval(
                child: Image.asset(
                  context.locale.languageCode == 'vi'
                      ? "asset/icon/vietnam.webp"
                      : context.locale.languageCode == 'en'
                      ? "asset/icon/english.png"
                      : context.locale.languageCode == 'zh'
                      ? "asset/icon/tiengtrung.webp"
                      : context.locale.languageCode == 'ko'
                      ? "asset/icon/tienghan.png"
                      : "asset/icon/tiengnhat.webp",
                  width: 22,
                  height: 22,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

// Widget cung cấp hiệu ứng nhấn: scale + làm nhạt màu + ripple
class _PressableElevated extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Color color;
  const _PressableElevated({
    required this.onPressed,
    required this.child,
    required this.color,
  });

  @override
  State<_PressableElevated> createState() => _PressableElevatedState();
}

class _PressableElevatedState extends State<_PressableElevated> {
  bool pressed = false;
  final GlobalKey innerKey =
      GlobalKey(); // key để kiểm tra điểm nhấn nằm trong vùng hiển thị nút

  void setPressed(bool v) =>
      setState(() => pressed = v); // Cập nhật trạng thái nhấn

  // Kiểm tra xem global position có nằm trong bounds của inner container không
  bool isInsideInner(Offset globalPosition) {
    final ctx = innerKey.currentContext;
    if (ctx == null) return false;
    final box = ctx.findRenderObject() as RenderBox;
    final local = box.globalToLocal(globalPosition);
    return local.dx >= 0 &&
        local.dx <= box.size.width &&
        local.dy >= 0 &&
        local.dy <= box.size.height;
  }

  @override
  Widget build(BuildContext context) {
    // Xây dựng widget với hiệu ứng nhấn
    final double scale = pressed ? 0.98 : 1.0; // Giảm kích thước khi nhấn
    final Color bgColor = Color.lerp(
      // màu nền nhạt hơn khi nhấn
      widget.color,
      Colors.white,
      pressed ? 0.12 : 0.0, // điều chỉnh hệ số nhạt màu khi nhấn (nhẹ hơn)
    )!;

    return AnimatedScale(
      scale: scale, // áp dụng hiệu ứng scale
      duration: const Duration(milliseconds: 90), // thời gian hiệu ứng
      curve: Curves.easeOut, // Hiệu ứng thu nhỏ khi nhấn
      child: Padding(
        // mở rộng vùng nhạy: chỉ mở rộng ở phải/top/bottom, để left = 0 giúp nút hiển thị thẳng hàng với icon
        padding: const EdgeInsets.only(
          left: 0,
          top: 8.0,
          right: 0,
          bottom: 8.0,
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapDown: (details) {
            if (isInsideInner(details.globalPosition)) setPressed(true);
          },
          onTapUp: (details) {
            final wasInside = isInsideInner(details.globalPosition);
            setPressed(false); // kết thúc nhấn
            if (wasInside) widget.onPressed();
          },
          onTapCancel: () => setPressed(false), // hủy nhấn
          child: AnimatedContainer(
            key: innerKey,
            duration: const Duration(milliseconds: 110), // thời gian chuyển màu
            curve: Curves.easeOut, // Hiệu ứng chuyển màu
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: bgColor, // màu nền với hiệu ứng nhạt màu
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(pressed ? 0.10 : 0.16),
                  blurRadius: pressed ? 2 : 5,
                  offset: Offset(0, pressed ? 1 : 2),
                ),
              ],
            ),
            child: Center(
              child: DefaultTextStyle.merge(
                style: const TextStyle(),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
