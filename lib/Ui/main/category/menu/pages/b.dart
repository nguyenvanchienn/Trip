import 'package:flutter/material.dart';
import 'package:tourn/Ui/main/category/menu/widgets/language.dart';
import 'package:easy_localization/easy_localization.dart';

class MenuDrawer extends StatelessWidget {
  const MenuDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: Drawer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
          child: Column(
            children: [
              InkWell(
                onTap: () {
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
              ),
              _buildSignOutButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 150),
      child: ElevatedButton(
        onPressed: () {
          // TODO: implement sign out action
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6200EE),
          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(
          "signout_buttom".tr(),
          style: const TextStyle(fontSize: 20, color: Colors.white),
        ),
      ),
    );
  }
}
