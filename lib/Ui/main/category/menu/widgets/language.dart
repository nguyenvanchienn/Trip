import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

Future<void> language(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final currentCode = context.locale.languageCode;
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
                  context.setLocale(const Locale('vi')); // ngôn ngữ tiếng việt
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
                  context.setLocale(const Locale('en'));
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
                  context.setLocale(const Locale('zh'));
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

                  context.setLocale(const Locale('ko'));
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

                  context.setLocale(const Locale('ja'));
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
