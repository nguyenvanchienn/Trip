import 'package:flutter/material.dart';
import 'package:tourn/Ui/login/login.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:tourn/Ui/sign.up/sign_up_page.dart';

class WelcomePage extends StatelessWidget {
  final bool isFirsTimeinstallApp;

  const WelcomePage({super.key, required this.isFirsTimeinstallApp});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: isFirsTimeinstallApp
            ? IconButton(
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
                icon: const Icon(
                  Icons.arrow_back_ios_new_outlined,
                  size: 20,
                  color: Colors.white,
                ),
              )
            : null,
        actions: [
          IconButton(
            onPressed: () {
              _showAttachOptions(context);
            },
            icon: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
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
                  width: 24,
                  height: 24,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          /// ẢNH NỀN
          SizedBox(
            width: size.width, // full width
            height: size.height, // full height
            child: Image.asset('asset/images/welcom.png', fit: BoxFit.cover),
          ),

          /// CARD TRẮNG BÊN DƯỚI
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: size.width,
                  padding: const EdgeInsets.fromLTRB(24, 64, 24, 32),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      // topLeft: Radius.circular(28),
                      // topRight: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 16),
                      const Text(
                        'Chào mừng đến với Trip',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF9800),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      /// NÚT ĐĂNG Nhập
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const loginpage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF9800),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Đăng Nhập',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      /// ĐĂNG Ký
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const signuppage(),
                            ),
                          );
                        },
                        child: const Text(
                          'Đăng Ký',
                          style: TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                      ),

                      const SizedBox(height: 35),
                    ],
                  ),
                ),
                Positioned(
                  top: -50,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Image.asset(
                      'asset/icon/logo.png',
                      width: 90,
                      height: 90,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void _showAttachOptions(BuildContext parentContext) {
  showDialog<void>(
    context: parentContext,
    builder: (dialogContext) {
      final currentCode = parentContext.locale.languageCode;
      const divider = Divider(
        // vạch chia các ngôn ngữ
        height: 1,
        thickness: 1, // độ dày của vạch chia
        indent: 40, // khoảng cách từ đầu đến vạch chia
        endIndent: 8, // khoảng cách từ cuối đến vạch chia
      );
      return Dialog(
        insetPadding: const EdgeInsets.all(24), // Khoảng cách
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "language_selection".tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // 🇻🇳 Tiếng Việt
              InkWell(
                onTap: () {
                  parentContext.setLocale(
                    const Locale('vi'),
                  ); // ngôn ngữ tiếng việt
                  Navigator.pop(
                    dialogContext,
                  ); // Đóng dialog sau khi chọn ngôn ngữ
                },
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  children: [
                    ClipOval(
                      child: Image.asset(
                        "asset/icon/vietnam.webp",
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Tiếng Việt',
                      style: TextStyle(fontSize: 12),
                    ), // tên ngôn ngữ
                    const Spacer(),
                    if (currentCode ==
                        'vi') // nếu chọn ngôn ngữ tiếng việt sẽ tinh năng này
                      Container(
                        width: 14, // kích thước vòng ngoài
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.orange, // màu cam bọc ngoài
                            width: 4,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              divider,

              const SizedBox(height: 12),

              // 🇬🇧 English
              InkWell(
                onTap: () {
                  parentContext.setLocale(const Locale('en'));
                  Navigator.pop(dialogContext);
                },
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  children: [
                    ClipOval(
                      child: Image.asset(
                        "asset/icon/english.png",
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('English', style: TextStyle(fontSize: 12)),
                    const Spacer(),
                    if (currentCode == 'en')
                      Container(
                        width: 14, // kích thước vòng ngoài
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.orange, // màu cam bọc ngoài
                            width: 4,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              divider,

              const SizedBox(height: 12),

              // 🇨🇳 Tiếng Trung
              InkWell(
                onTap: () {
                  // ScaffoldMessenger.of(parentContext).showSnackBar(
                  //   const SnackBar(
                  //     content: Text('Chức năng này chưa được bật'),
                  //   ),
                  // );
                  parentContext.setLocale(const Locale('zh'));
                  Navigator.pop(dialogContext);
                },
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  children: [
                    ClipOval(
                      child: Image.asset(
                        "asset/icon/tiengtrung.webp",
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('简体中文', style: TextStyle(fontSize: 12)),
                    const Spacer(),
                    if (currentCode == 'zh')
                      Container(
                        width: 14, // kích thước vòng ngoài
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.orange, // màu cam bọc ngoài
                            width: 4,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              divider,

              const SizedBox(height: 12),

              // 🇰🇷 Tiếng Hàn
              InkWell(
                onTap: () {
                  // ScaffoldMessenger.of(parentContext).showSnackBar(
                  //   const SnackBar(
                  //     content: Text('Chức năng này chưa được bật'),
                  //   ),
                  // );

                  parentContext.setLocale(const Locale('ko'));
                  Navigator.pop(dialogContext);
                },
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  children: [
                    ClipOval(
                      child: Image.asset(
                        "asset/icon/tienghan.png",
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('Korean', style: TextStyle(fontSize: 12)),
                    const Spacer(),
                    if (currentCode == 'ko')
                      Container(
                        width: 14, // kích thước vòng ngoài
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.orange, // màu cam bọc ngoài
                            width: 4,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              divider,
              const SizedBox(height: 12),
              InkWell(
                onTap: () {
                  // ScaffoldMessenger.of(parentContext).showSnackBar(
                  //   const SnackBar(
                  //     content: Text('Chức năng này chưa được bật'),
                  //   ),
                  // );

                  parentContext.setLocale(const Locale('ja'));
                  Navigator.pop(dialogContext);
                },
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  children: [
                    ClipOval(
                      child: Image.asset(
                        "asset/icon/tiengnhat.webp",
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('日本語', style: TextStyle(fontSize: 12)),
                    const Spacer(),
                    if (currentCode == 'ja')
                      Container(
                        width: 14, // kích thước vòng ngoài
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.orange, // màu cam bọc ngoài
                            width: 4,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
