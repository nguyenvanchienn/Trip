import 'package:flutter/material.dart';
import 'package:tourn/Ui/domain/domain_authentication_repository/authentication_repository.dart';
import 'package:provider/provider.dart';
import 'package:tourn/Ui/splash/splash.dart';

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
                    onPressed: () async {
                      final nav = Navigator.of(
                        dialogContext,
                        rootNavigator: true,
                      );
                      final authRepo = dialogContext
                          .read<AuthenticationRepository>();

                      nav.pop(); // close dialog

                      // close drawer if this dialog was opened from one
                      if (context.mounted) {
                        Scaffold.maybeOf(context)?.closeEndDrawer();
                      }

                      // perform sign out in background to avoid UI hangs
                      Future<void>.microtask(() async {
                        try {
                          await authRepo.signOut().timeout(
                            const Duration(seconds: 5),
                          );
                        } catch (_) {
                          // ignore errors
                        }
                      });

                      nav.pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (ctx) => const SplashScreen(),
                        ),
                        (route) => false,
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
