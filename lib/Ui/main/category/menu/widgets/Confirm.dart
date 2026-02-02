import 'package:flutter/material.dart';
import 'package:tourn/Ui/welcome/welcome_page.dart';

Future<dynamic> confirm(BuildContext context) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tiêu đề
              const Text(
                "Thoát",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              const Text(
                "Bạn có chắc chắn muốn đăng xuất không?",
                style: TextStyle(fontSize: 14),
              ),

              const SizedBox(height: 24),

              // Nút hành động
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                    },
                    child: const Text("Huỷ"),
                  ),

                  const SizedBox(width: 8),

                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const WelcomePage(isFirsTimeinstallApp: false),
                        ),
                      );
                    },
                    child: const Text("OK"),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
