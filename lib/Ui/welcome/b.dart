import 'package:flutter/material.dart';
import 'package:tourn/Ui/login/login.dart';
import 'package:easy_localization/easy_localization.dart'; // Thêm gói easy_localization

class WelcomePagee extends StatelessWidget {
  final bool isFirsTimeinstallApp; // Biến để kiểm tra lần đầu cài đặt ứng dụng

  const WelcomePagee({super.key, required this.isFirsTimeinstallApp});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        automaticallyImplyLeading: false, // Tắt nút back mặc định
        leading: isFirsTimeinstallApp
            ? IconButton(
                // Chỉ hiển thị nút quay lại nếu là lần đầu cài đặt ứng dụng
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    // Kiểm tra nếu có thể quay lại
                    Navigator.pop(context); // Thực hiện quay lại
                  }
                }, // Xử lý khi nhấn nút quay lại
                icon: const Icon(
                  Icons.arrow_back_ios_new_outlined,
                  size: 20,
                  color: Colors.white,
                ),
              )
            : null, // Nếu không phải lần đầu cài đặt, không hiển thị nút quay lại
        actions: [
          // Nút menu ở góc phải
          IconButton(
            onPressed: () {
              _showAttachOptions(context);
            },
            icon: Container(
              padding: const EdgeInsets.all(1), // khoảng cách icon ↔ viền
              decoration: BoxDecoration(
                // Viền tròn
                shape: BoxShape.circle, // Hình tròn
                border: Border.all(
                  color: const Color.fromARGB(255, 196, 196, 196),
                  width: 4,
                ), // Viền trắng
              ),
              child: ClipOval(
                child: Image.asset(
                  context.locale.languageCode ==
                          'vi' // Kiểm tra ngôn ngữ hiện tại
                      ? "asset/icon/vietnam.webp"
                      : context.locale.languageCode == 'en'
                      ? "asset/icon/english.png"
                      : context.locale.languageCode == 'zh'
                      ? "asset/icon/tiengtrung.webp"
                      : context.locale.languageCode == 'ko'
                      ? "asset/icon/tienghan.png"
                      : "asset/icon/tiengnhat.webp",
                  width: 25,
                  height: 25,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),

      body: Column(
        children: [_buildtitleanddesc(), _buildgetstartedbutton(context)],
      ),
    );
  }

  Widget _buildtitleanddesc() {
    return Container(
      alignment: Alignment.center,
      margin: const EdgeInsets.only(top: 110),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            "welcome_title".tr(),
            style: const TextStyle(
              fontSize: 36,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2, // Giới hạn tối đa 2 dòng
            overflow: TextOverflow.visible, // Xử lý tràn văn bản nếu vượt quá
          ),
          const SizedBox(height: 20),
          Text(
            "welcome_desc".tr(),
            style: const TextStyle(fontSize: 18, color: Colors.white70),
            textAlign: TextAlign.center,
            maxLines: 2, // Giới hạn tối đa 2 dòng
            overflow: TextOverflow.visible, // Xử lý tràn văn bản nếu vượt quá
          ),
        ],
      ),
    );
  }

  Widget _buildgetstartedbutton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 150),
      child: ElevatedButton(
        onPressed: () {
          // Xử lý khi nhấn nút Get Started
          _gotologinpage(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6200EE),
          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(
          "getstarted".tr(),
          style: const TextStyle(fontSize: 20, color: Colors.white),
        ),
      ),
    );
  }

  void _gotologinpage(BuildContext context) {
    // Hàm chuyển đến trang chính của ứng dụng welcome_page.dart
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const loginpage()),
    );
  }
}

void _showAttachOptions(BuildContext parentContext) {
  showDialog<void>(
    context: parentContext,
    builder: (dialogContext) {
      final currentCode = parentContext.locale.languageCode;

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
                            width: 3,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

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
                            width: 3,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

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
                            width: 3,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

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
                            width: 3,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
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
                            width: 3,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Container(
                          width: 8,
                          height: 8,
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


// final locale = context.locale;
//               if (locale.languageCode == 'en') {
//                 context.setLocale(const Locale('vi'));
//               } else {
//                 context.setLocale(const Locale('en'));
//               }
//             },
            // icon: ClipOval(
            //   child: context.locale.languageCode == 'vi'
            //       ? Image.asset(
            //           "asset/icon/vietnam.webp",
            //           width: 26,
            //           height: 26,
            //           fit: BoxFit.cover,
            //         )
//                   : Image.asset(
//                       "asset/icon/english.png",
//                       width: 26,
//                       height: 26,
//                       fit: BoxFit.cover,
//                     ),
//             ),
//  ScaffoldMessenger.of(context).showSnackBar( // Hiện thông báo chưa bật chức năng
//                           SnackBar(
//                             content = Text('Chức năng tải ảnh chưa được bật'),